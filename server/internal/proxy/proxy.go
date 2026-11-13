package proxy

import (
	"bytes"
	"context"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"time"
)

const (
	DefaultTTL      = 30 * time.Minute
	requestLimit    = 1 << 20
	responseLimit   = 8 << 20
	upstreamTimeout = 30 * time.Second
	proxyPrefix     = "/v1/hn"
)

var variantHeaders = []string{"Accept", "Accept-Encoding", "Accept-Language", "User-Agent"}

// Config deliberately has no upstream URL option: production requests can only
// reach Hacker News, even if a caller supplies an absolute URL or redirect.
type Config struct {
	APIKey string
	TTL    time.Duration
	Logger *slog.Logger
}

type flight struct {
	done     chan struct{}
	response *cachedResponse
	state    string
	err      error
	callers  int // Calls registered with this flight; guarded by Handler.mu.
}

type Handler struct {
	cache    *Cache
	keyHash  [32]byte
	ttl      time.Duration
	logger   *slog.Logger
	client   *http.Client
	upstream *url.URL
	now      func() time.Time
	mu       sync.Mutex
	flights  map[string]*flight
}

func NewHandler(config Config, cache *Cache) (*Handler, error) {
	if strings.TrimSpace(config.APIKey) == "" {
		return nil, errors.New("HACKI_API_KEY is required")
	}
	if cache == nil {
		return nil, errors.New("cache is required")
	}
	if config.TTL == 0 {
		config.TTL = DefaultTTL
	}
	if config.TTL < 0 {
		return nil, errors.New("cache TTL must be positive")
	}
	if config.Logger == nil {
		config.Logger = slog.Default()
	}
	transport := http.DefaultTransport.(*http.Transport).Clone()
	transport.DisableCompression = true // Preserve the original bytes and Content-Encoding.
	transport.MaxConnsPerHost = 4
	transport.ResponseHeaderTimeout = 20 * time.Second
	return &Handler{
		cache: cache, keyHash: sha256.Sum256([]byte(config.APIKey)), ttl: config.TTL,
		logger: config.Logger,
		client: &http.Client{
			Transport: transport, Timeout: upstreamTimeout,
			CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
		},
		upstream: &url.URL{Scheme: "https", Host: "news.ycombinator.com"},
		now:      time.Now, flights: make(map[string]*flight),
	}, nil
}

func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store")
	if r.URL.Path == "/healthz" && (r.Method == http.MethodGet || r.Method == http.MethodHead) {
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Cache-Control", "no-store")
		if r.Method != http.MethodHead {
			io.WriteString(w, "{\"status\":\"ok\"}\n")
		}
		return
	}
	// Hashing both sides gives the constant-time comparison a fixed length.
	keyHash := sha256.Sum256([]byte(r.Header.Get("X-API-Key")))
	if subtle.ConstantTimeCompare(keyHash[:], h.keyHash[:]) != 1 {
		http.Error(w, "invalid API key", http.StatusUnauthorized)
		return
	}
	if r.Method == http.MethodConnect || r.Method == http.MethodTrace {
		http.Error(w, "method not supported", http.StatusMethodNotAllowed)
		return
	}
	escapedPath := r.URL.EscapedPath()
	if escapedPath != proxyPrefix && !strings.HasPrefix(escapedPath, proxyPrefix+"/") {
		http.NotFound(w, r)
		return
	}
	escapedPath = strings.TrimPrefix(escapedPath, proxyPrefix)
	if escapedPath == "" {
		escapedPath = "/"
	}
	path, err := url.PathUnescape(escapedPath)
	if err != nil {
		http.Error(w, "invalid request path", http.StatusBadRequest)
		return
	}
	if r.ContentLength > requestLimit {
		http.Error(w, "request body too large", http.StatusRequestEntityTooLarge)
		return
	}
	// Limits chunked requests as well as requests with a Content-Length.
	r.Body = http.MaxBytesReader(w, r.Body, requestLimit)
	body, err := io.ReadAll(r.Body)
	if err != nil {
		var maxBytesErr *http.MaxBytesError
		if errors.As(err, &maxBytesErr) {
			http.Error(w, "request body too large", http.StatusRequestEntityTooLarge)
		} else {
			http.Error(w, "could not read request body", http.StatusBadRequest)
		}
		return
	}
	target := *h.upstream
	target.Path, target.RawPath, target.RawQuery, target.ForceQuery = path, escapedPath, r.URL.RawQuery, r.URL.ForceQuery
	request, err := http.NewRequestWithContext(r.Context(), r.Method, target.String(), bytes.NewReader(body))
	if err != nil {
		http.Error(w, "invalid upstream request", http.StatusBadRequest)
		return
	}
	request.Header = cleanHeaders(r.Header)
	request.Header.Del("X-API-Key")
	// Forwarded client IPs are neither needed by HN nor part of cache variants.
	for name := range request.Header {
		if strings.HasPrefix(strings.ToLower(name), "x-forwarded-") || strings.EqualFold(name, "Forwarded") ||
			strings.EqualFold(name, "X-Real-IP") {
			request.Header.Del(name)
		}
	}
	var response *cachedResponse
	state := "BYPASS"
	if cacheableRequest(request, len(body)) {
		response, state, err = h.cached(r.Context(), cacheKey(request), request)
	} else {
		response, err = h.fetch(request)
	}
	if err != nil {
		// Do not log URLs, bodies, headers, or error strings: all may contain
		// usernames, HN credentials, or other request secrets.
		h.logger.Warn("upstream request failed")
		status := http.StatusBadGateway
		if errors.Is(err, context.DeadlineExceeded) {
			status = http.StatusGatewayTimeout
		}
		http.Error(w, "Hacker News request failed", status)
		return
	}
	for name, values := range response.header {
		w.Header()[name] = append([]string(nil), values...)
	}
	// The SQLite cache is private to this service. Intermediate HTTP caches
	// must never answer a request without checking its API key.
	w.Header().Set("Cache-Control", "no-store")
	w.Header().Set("X-Hacki-Cache", state)
	if state == "HIT" || state == "STALE" {
		age := max(int64(h.now().Sub(response.storedAt).Seconds()), 0)
		w.Header().Set("Age", strconv.FormatInt(age, 10))
	}
	if state == "STALE" {
		w.Header().Add("Warning", `110 hacki "Response is stale"`)
	}
	w.WriteHeader(response.status)
	if r.Method != http.MethodHead {
		w.Write(response.body)
	}
}

func (h *Handler) cached(ctx context.Context, key string, request *http.Request) (*cachedResponse, string, error) {
	// Read on every request, so persisted entries remain usable after restart.
	stored, err := h.cache.get(ctx, key)
	if err != nil {
		h.logger.Warn("cache read failed")
	}
	if stored != nil && h.now().Sub(stored.storedAt) < h.ttl {
		return stored, "HIT", nil
	}
	h.mu.Lock()
	f, exists := h.flights[key]
	if !exists {
		f = &flight{done: make(chan struct{})}
		h.flights[key] = f
		go func() {
			// One disconnected caller must not cancel the fetch shared by others.
			fetchCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), upstreamTimeout)
			defer cancel()
			f.response, f.state, f.err = h.refresh(fetchCtx, key, request.Clone(fetchCtx))
			h.mu.Lock()
			delete(h.flights, key)
			close(f.done)
			h.mu.Unlock()
		}()
	}
	f.callers++
	h.mu.Unlock()
	select {
	case <-f.done:
		// A response that turned out to be personalized (Set-Cookie, no-store,
		// unsupported Vary) belongs only to the caller which fetched it.
		// Waiters must make independent requests rather than share its session.
		// Public errors can be shared with the current waiters even though
		// they are not successful snapshots and must not be persisted.
		if exists && f.err == nil && f.state == "BYPASS" && !shareableResponse(f.response) {
			response, err := h.fetch(request)
			return response, "BYPASS", err
		}
		return f.response, f.state, f.err
	case <-ctx.Done():
		return nil, "", ctx.Err()
	}
}

func (h *Handler) refresh(ctx context.Context, key string, request *http.Request) (*cachedResponse, string, error) {
	// Recheck inside the flight in case an earlier flight completed between
	// the initial read and registering this one.
	stored, err := h.cache.get(ctx, key)
	if err != nil {
		h.logger.Warn("cache read failed")
	}
	if stored != nil && h.now().Sub(stored.storedAt) < h.ttl {
		return stored, "HIT", nil
	}
	response, err := h.fetch(request)
	if err != nil {
		return nil, "", err
	}
	if stored != nil && rateLimited(response.status) {
		return stored, "STALE", nil
	}
	state := "MISS"
	if stored != nil {
		state = "REFRESH"
	}
	if cacheableResponse(response) {
		if err := h.cache.put(ctx, key, response); err != nil {
			h.logger.Warn("cache write failed")
		}
	} else {
		state = "BYPASS"
	}
	return response, state, nil
}

func (h *Handler) fetch(request *http.Request) (*cachedResponse, error) {
	response, err := h.client.Do(request)
	if err != nil {
		return nil, err
	}
	defer response.Body.Close()
	body, err := io.ReadAll(io.LimitReader(response.Body, responseLimit+1))
	if err != nil {
		return nil, err
	}
	if len(body) > responseLimit {
		return nil, errors.New("upstream response too large")
	}
	header := cleanHeaders(response.Header)
	if request.Method == http.MethodHead && response.Header.Get("Content-Length") != "" {
		header.Set("Content-Length", response.Header.Get("Content-Length"))
	}
	return &cachedResponse{
		status: response.StatusCode, header: header,
		body: body, storedAt: h.now(),
	}, nil
}

func cacheableRequest(request *http.Request, bodyLength int) bool {
	if request.Method != http.MethodGet || bodyLength != 0 ||
		len(request.Header.Values("Cookie")) != 0 || len(request.Header.Values("Authorization")) != 0 ||
		request.Header.Get("Range") != "" || disallowsCaching(strings.Join(request.Header.Values("Cache-Control"), ","), false) ||
		strings.Contains(strings.ToLower(request.Header.Get("Pragma")), "no-cache") {
		return false
	}
	for name := range request.Header {
		if strings.HasPrefix(strings.ToLower(name), "if-") {
			return false
		}
	}
	// HN has GET endpoints which mutate state (vote, fave, hide, logout).
	// Only known public read paths and query parameters enter the shared cache.
	var allowed string
	switch request.URL.Path {
	case "/", "/news", "/best", "/ask", "/show", "/jobs", "/active", "/classic", "/asknew", "/shownew":
		allowed = "p"
	case "/newest", "/newcomments", "/bestcomments":
		allowed = "p,n,next"
	case "/item":
		allowed = "id,p"
	case "/user", "/threads", "/submitted":
		allowed = "id,p,n,next"
	case "/favorites":
		allowed = "id,p,comments"
	case "/from":
		allowed = "site,p,n,next"
	case "/front", "/past":
		allowed = "day,p"
	default:
		return false
	}
	query, err := url.ParseQuery(request.URL.RawQuery)
	if err != nil {
		return false
	}
	for name := range query {
		if !strings.Contains(","+allowed+",", ","+name+",") {
			return false
		}
	}
	return true
}

func cacheableResponse(response *cachedResponse) bool {
	return response.status == http.StatusOK && shareableResponse(response)
}

func shareableResponse(response *cachedResponse) bool {
	if len(response.header.Values("Set-Cookie")) != 0 ||
		disallowsCaching(strings.Join(response.header.Values("Cache-Control"), ","), true) {
		return false
	}
	for _, vary := range response.header.Values("Vary") {
		for _, name := range strings.Split(vary, ",") {
			name = http.CanonicalHeaderKey(strings.TrimSpace(name))
			if name == "" {
				continue
			}
			found := false
			for _, allowed := range variantHeaders {
				if name == allowed {
					found = true
					break
				}
			}
			if !found {
				return false
			}
		}
	}
	return true
}

func disallowsCaching(value string, publicSnapshot bool) bool {
	for _, directive := range strings.Split(value, ",") {
		name, _, _ := strings.Cut(strings.TrimSpace(strings.ToLower(directive)), "=")
		// HN marks even anonymous public HTML "private; max-age=0". This
		// application cache intentionally retains public snapshots for 30m;
		// strict request eligibility prevents storing authenticated pages.
		if (!publicSnapshot && name == "private") || name == "no-store" || name == "no-cache" {
			return true
		}
	}
	return false
}

func cacheKey(request *http.Request) string {
	variants := make(http.Header)
	for _, name := range variantHeaders {
		if values := request.Header.Values(name); len(values) != 0 {
			variants[name] = values
		}
	}
	encoded, _ := json.Marshal(struct {
		URL     string
		Headers http.Header
	}{request.URL.RequestURI(), variants})
	sum := sha256.Sum256(encoded)
	return hex.EncodeToString(sum[:])
}

func rateLimited(status int) bool {
	return status == http.StatusForbidden || status == http.StatusTooManyRequests || status == http.StatusServiceUnavailable
}

func cleanHeaders(source http.Header) http.Header {
	header := source.Clone()
	// Connection can nominate additional hop-by-hop headers.
	for _, connection := range header.Values("Connection") {
		for _, name := range strings.Split(connection, ",") {
			header.Del(strings.TrimSpace(name))
		}
	}
	for _, name := range []string{
		"Connection", "Proxy-Connection", "Keep-Alive", "Proxy-Authenticate", "Proxy-Authorization",
		"Te", "Trailer", "Transfer-Encoding", "Upgrade", "Content-Length",
	} {
		header.Del(name)
	}
	return header
}
