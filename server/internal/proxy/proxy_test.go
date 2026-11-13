package proxy

import (
	"bytes"
	"compress/gzip"
	"context"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"net/url"
	"path/filepath"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

const testAPIKey = "test-api-key"

type testProxy struct {
	handler *Handler
	cache   *Cache
	path    string
	clock   atomic.Int64
}

func newTestProxy(t *testing.T, upstream http.HandlerFunc) *testProxy {
	t.Helper()
	origin := httptest.NewServer(upstream)
	t.Cleanup(origin.Close)
	p := &testProxy{path: filepath.Join(t.TempDir(), "cache.sqlite")}
	var err error
	p.cache, err = OpenCache(p.path)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { p.cache.Close() })
	p.handler, err = NewHandler(Config{
		APIKey: testAPIKey,
		Logger: slog.New(slog.NewTextHandler(io.Discard, nil)),
	}, p.cache)
	if err != nil {
		t.Fatal(err)
	}
	p.handler.upstream, err = url.Parse(origin.URL)
	if err != nil {
		t.Fatal(err)
	}
	p.clock.Store(time.Date(2026, 1, 2, 3, 4, 5, 0, time.UTC).UnixMilli())
	p.handler.now = func() time.Time { return time.UnixMilli(p.clock.Load()) }
	return p
}

func (p *testProxy) advance(duration time.Duration) {
	p.clock.Add(duration.Milliseconds())
}

func (p *testProxy) request(method, path string, body []byte, headers http.Header) *httptest.ResponseRecorder {
	r := httptest.NewRequest(method, "http://proxy.test"+path, bytes.NewReader(body))
	r.Header.Set("X-API-Key", testAPIKey)
	for name, values := range headers {
		r.Header[name] = values
	}
	w := httptest.NewRecorder()
	p.handler.ServeHTTP(w, r)
	return w
}

func assertResponse(t *testing.T, response *httptest.ResponseRecorder, status int, body, state string) {
	t.Helper()
	if response.Code != status || response.Body.String() != body || response.Header().Get("X-Hacki-Cache") != state {
		t.Fatalf("response = status %d body %q cache %q; want %d %q %q", response.Code,
			response.Body.String(), response.Header().Get("X-Hacki-Cache"), status, body, state)
	}
}

func TestAuthenticationAndRoutes(t *testing.T) {
	var calls atomic.Int32
	p := newTestProxy(t, func(w http.ResponseWriter, _ *http.Request) {
		calls.Add(1)
		io.WriteString(w, "public")
	})
	for _, key := range []string{"", "wrong", testAPIKey + "x"} {
		w := p.request(http.MethodGet, "/v1/hn/item?id=1", nil, http.Header{"X-Api-Key": {key}})
		if w.Code != http.StatusUnauthorized {
			t.Fatalf("key %q: status %d", key, w.Code)
		}
	}
	for _, method := range []string{http.MethodConnect, http.MethodTrace} {
		w := p.request(method, "/v1/hn/item?id=1", nil, nil)
		if w.Code != http.StatusMethodNotAllowed {
			t.Fatalf("%s: status %d", method, w.Code)
		}
	}
	for _, path := range []string{"/item?id=1", "/v1/hn-other/item?id=1", "/v1/h%6e/item?id=1"} {
		w := p.request(http.MethodGet, path, nil, nil)
		if w.Code != http.StatusNotFound {
			t.Fatalf("%s: status %d", path, w.Code)
		}
	}
	for _, method := range []string{http.MethodGet, http.MethodHead} {
		w := p.request(method, "/healthz", nil, http.Header{"X-Api-Key": {""}})
		if w.Code != http.StatusOK || w.Header().Get("Content-Type") != "application/json" {
			t.Fatalf("health response: %d %s", w.Code, w.Body.String())
		}
		if method == http.MethodHead && w.Body.Len() != 0 {
			t.Fatal("HEAD health check returned a body")
		}
	}
	if calls.Load() != 0 {
		t.Fatalf("invalid requests reached origin %d times", calls.Load())
	}
	assertResponse(t, p.request(http.MethodGet, "/v1/hn", nil, nil), http.StatusOK, "public", "MISS")
	assertResponse(t, p.request(http.MethodGet, "/v1/hn/", nil, nil), http.StatusOK, "public", "HIT")
}

func TestForwardMethodsRawPathQueryBodyAndHeaders(t *testing.T) {
	for _, method := range []string{"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS", "CUSTOM"} {
		t.Run(method, func(t *testing.T) {
			body := []byte("a=hello%20world&x=1&x=2\x00\xff")
			p := newTestProxy(t, func(w http.ResponseWriter, r *http.Request) {
				if r.Method != method || r.RequestURI != "/encoded%2Fpath?x=a%2Bb&x=2&blank=" {
					t.Errorf("upstream request = %s %s", r.Method, r.RequestURI)
				}
				gotBody, err := io.ReadAll(r.Body)
				if err != nil || !bytes.Equal(gotBody, body) {
					t.Errorf("upstream body = %q, error %v", gotBody, err)
				}
				for _, name := range []string{"X-Api-Key", "X-Forwarded-For", "Forwarded", "X-Real-IP", "X-Remove-Me"} {
					if r.Header.Get(name) != "" {
						t.Errorf("forwarded forbidden header %s", name)
					}
				}
				if r.Header.Get("Content-Type") != "application/x-www-form-urlencoded" ||
					r.Header.Get("Cookie") != "user=hn-session" || r.Header.Get("Referer") != "https://news.ycombinator.com/item?id=1" {
					t.Errorf("lost end-to-end headers: %v", r.Header)
				}
				w.Header().Set("Content-Type", "application/octet-stream")
				w.Header().Set("Connection", "X-Origin-Hop")
				w.Header().Set("X-Origin-Hop", "must-strip")
				w.Header().Set("X-Origin", "preserved")
				w.Header().Add("Set-Cookie", "user=one; HttpOnly")
				w.Header().Add("Set-Cookie", "other=two; Secure")
				w.WriteHeader(http.StatusAccepted)
				w.Write([]byte("raw\x00\xff"))
			})
			response := p.request(method, "/v1/hn/encoded%2Fpath?x=a%2Bb&x=2&blank=", body, http.Header{
				"Content-Type":    {"application/x-www-form-urlencoded"},
				"Cookie":          {"user=hn-session"},
				"Referer":         {"https://news.ycombinator.com/item?id=1"},
				"Connection":      {"X-Remove-Me"},
				"X-Remove-Me":     {"secret"},
				"X-Forwarded-For": {"192.0.2.1"},
				"Forwarded":       {"for=192.0.2.1"},
				"X-Real-Ip":       {"192.0.2.1"},
			})
			wantBody := "raw\x00\xff"
			if method == http.MethodHead {
				wantBody = ""
			}
			assertResponse(t, response, http.StatusAccepted, wantBody, "BYPASS")
			if response.Header().Get("X-Origin") != "preserved" || response.Header().Get("X-Origin-Hop") != "" ||
				len(response.Header().Values("Set-Cookie")) != 2 {
				t.Fatalf("unexpected response headers: %v", response.Header())
			}
		})
	}
}

func TestUpstreamRedirectIsReturnedWithoutFollowing(t *testing.T) {
	var followed atomic.Int32
	destination := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		followed.Add(1)
		t.Errorf("followed redirect to %s", r.URL)
	}))
	defer destination.Close()
	p := newTestProxy(t, func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Location", destination.URL+"/private")
		w.Header().Set("Set-Cookie", "user=session; HttpOnly")
		w.WriteHeader(http.StatusFound)
		io.WriteString(w, "redirect body")
	})
	w := p.request(http.MethodPost, "/v1/hn/login", []byte("acct=alice&pw=secret"), nil)
	assertResponse(t, w, http.StatusFound, "redirect body", "BYPASS")
	if followed.Load() != 0 || w.Header().Get("Location") != destination.URL+"/private" || w.Header().Get("Set-Cookie") == "" {
		t.Fatalf("redirect/cookie not preserved: %v", w.Header())
	}
}

func TestCacheTTLRefreshAndPublicHNPrivateHeader(t *testing.T) {
	var calls atomic.Int32
	p := newTestProxy(t, func(w http.ResponseWriter, _ *http.Request) {
		call := calls.Add(1)
		// Real anonymous HN pages use this header. The application's deliberate
		// public snapshot policy must still cache them for thirty minutes.
		w.Header().Set("Cache-Control", "private; max-age=0")
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		fmt.Fprintf(w, "page %d", call)
	})
	path := "/v1/hn/item?id=123&p=2"
	assertResponse(t, p.request("GET", path, nil, nil), 200, "page 1", "MISS")
	p.advance(29 * time.Minute)
	w := p.request("GET", path, nil, nil)
	assertResponse(t, w, 200, "page 1", "HIT")
	if w.Header().Get("Age") != "1740" || w.Header().Get("Cache-Control") != "no-store" {
		t.Fatalf("cache metadata: %v", w.Header())
	}
	p.advance(time.Minute)
	assertResponse(t, p.request("GET", path, nil, nil), 200, "page 2", "REFRESH")
	assertResponse(t, p.request("GET", path, nil, nil), 200, "page 2", "HIT")
	if calls.Load() != 2 {
		t.Fatalf("origin called %d times, want 2", calls.Load())
	}
}

func TestExpiredCacheFallsBackOnlyOnRateLimitAndDoesNotRefreshItsAge(t *testing.T) {
	for _, status := range []int{http.StatusForbidden, http.StatusTooManyRequests, http.StatusServiceUnavailable} {
		t.Run(fmt.Sprint(status), func(t *testing.T) {
			var currentStatus atomic.Int32
			currentStatus.Store(http.StatusOK)
			p := newTestProxy(t, func(w http.ResponseWriter, _ *http.Request) {
				w.Header().Set("Retry-After", "120")
				w.WriteHeader(int(currentStatus.Load()))
				if currentStatus.Load() == 200 {
					io.WriteString(w, "last good HTML")
				} else {
					io.WriteString(w, "rate limited")
				}
			})
			path := "/v1/hn/item?id=123"
			assertResponse(t, p.request("GET", path, nil, nil), 200, "last good HTML", "MISS")
			p.advance(31 * time.Minute)
			currentStatus.Store(int32(status))
			w := p.request("GET", path, nil, nil)
			assertResponse(t, w, 200, "last good HTML", "STALE")
			if w.Header().Get("Age") != "1860" || !strings.Contains(w.Header().Get("Warning"), "stale") {
				t.Fatalf("missing stale metadata: %v", w.Header())
			}
			p.advance(time.Minute)
			w = p.request("GET", path, nil, nil)
			assertResponse(t, w, 200, "last good HTML", "STALE")
			if w.Header().Get("Age") != "1920" {
				t.Fatalf("stale response age was reset: %s", w.Header().Get("Age"))
			}
			// An ordinary upstream error must be returned as-is and must not
			// overwrite the most recent successful snapshot.
			currentStatus.Store(http.StatusInternalServerError)
			assertResponse(t, p.request("GET", path, nil, nil), 500, "rate limited", "BYPASS")
			currentStatus.Store(int32(status))
			assertResponse(t, p.request("GET", path, nil, nil), 200, "last good HTML", "STALE")
		})
	}
}

func TestRateLimitedMissIsReturnedAndNeverCached(t *testing.T) {
	var calls atomic.Int32
	p := newTestProxy(t, func(w http.ResponseWriter, _ *http.Request) {
		calls.Add(1)
		w.Header().Set("Retry-After", "60")
		w.WriteHeader(http.StatusTooManyRequests)
		io.WriteString(w, "slow down")
	})
	for range 2 {
		w := p.request("GET", "/v1/hn/item?id=123", nil, nil)
		assertResponse(t, w, 429, "slow down", "BYPASS")
		if w.Header().Get("Retry-After") != "60" {
			t.Fatal("lost Retry-After header")
		}
	}
	if calls.Load() != 2 {
		t.Fatalf("cached upstream rate limit response; calls %d", calls.Load())
	}
}

func TestSQLiteCacheSurvivesRestartIncludingStaleFallback(t *testing.T) {
	var calls atomic.Int32
	var limited atomic.Bool
	p := newTestProxy(t, func(w http.ResponseWriter, _ *http.Request) {
		calls.Add(1)
		if limited.Load() {
			w.WriteHeader(http.StatusServiceUnavailable)
			return
		}
		io.WriteString(w, "persisted HTML")
	})
	path := "/v1/hn/item?id=123"
	assertResponse(t, p.request("GET", path, nil, nil), 200, "persisted HTML", "MISS")
	if err := p.cache.Close(); err != nil {
		t.Fatal(err)
	}
	var err error
	p.cache, err = OpenCache(p.path)
	if err != nil {
		t.Fatal(err)
	}
	handler, err := NewHandler(Config{APIKey: testAPIKey}, p.cache)
	if err != nil {
		t.Fatal(err)
	}
	handler.upstream, handler.now = p.handler.upstream, p.handler.now
	p.handler = handler
	assertResponse(t, p.request("GET", path, nil, nil), 200, "persisted HTML", "HIT")
	limited.Store(true)
	p.advance(31 * time.Minute)
	assertResponse(t, p.request("GET", path, nil, nil), 200, "persisted HTML", "STALE")
	if calls.Load() != 2 {
		t.Fatalf("origin called %d times", calls.Load())
	}
}

func TestPersonalizedAndMutatingRequestsBypassSharedCache(t *testing.T) {
	cases := []struct {
		name, method, path string
		headers            http.Header
		body               []byte
	}{
		{name: "cookie", method: "GET", path: "/item?id=1", headers: http.Header{"Cookie": {"user=alice"}}},
		{name: "empty cookie", method: "GET", path: "/item?id=1", headers: http.Header{"Cookie": {""}}},
		{name: "authorization", method: "GET", path: "/item?id=1", headers: http.Header{"Authorization": {"Bearer hn-user"}}},
		{name: "empty authorization", method: "GET", path: "/item?id=1", headers: http.Header{"Authorization": {""}}},
		{name: "vote GET", method: "GET", path: "/vote?id=1&auth=secret"},
		{name: "logout GET", method: "GET", path: "/logout"},
		{name: "favorite GET", method: "GET", path: "/fave?id=1"},
		{name: "credential query", method: "GET", path: "/item?id=1&auth=secret"},
		{name: "password query", method: "GET", path: "/item?id=1&pw=secret"},
		{name: "unknown query", method: "GET", path: "/item?id=1&unknown=value"},
		{name: "POST", method: "POST", path: "/item?id=1", body: []byte("text=hello")},
		{name: "GET body", method: "GET", path: "/item?id=1", body: []byte("body")},
		{name: "conditional", method: "GET", path: "/item?id=1", headers: http.Header{"If-None-Match": {"etag"}}},
		{name: "range", method: "GET", path: "/item?id=1", headers: http.Header{"Range": {"bytes=0-20"}}},
		{name: "no-cache", method: "GET", path: "/item?id=1", headers: http.Header{"Cache-Control": {"no-cache"}}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			var calls atomic.Int32
			p := newTestProxy(t, func(w http.ResponseWriter, _ *http.Request) {
				fmt.Fprintf(w, "response %d", calls.Add(1))
			})
			assertResponse(t, p.request("GET", "/v1/hn/item?id=1", nil, nil), 200, "response 1", "MISS")
			assertResponse(t, p.request(tc.method, "/v1/hn"+tc.path, tc.body, tc.headers), 200, "response 2", "BYPASS")
			assertResponse(t, p.request(tc.method, "/v1/hn"+tc.path, tc.body, tc.headers), 200, "response 3", "BYPASS")
			assertResponse(t, p.request("GET", "/v1/hn/item?id=1", nil, nil), 200, "response 1", "HIT")
		})
	}
}

func TestUnsafeResponsesAreNotCached(t *testing.T) {
	cases := []struct {
		name    string
		headers http.Header
	}{
		{name: "session cookie", headers: http.Header{"Set-Cookie": {"user=session"}}},
		{name: "no-store", headers: http.Header{"Cache-Control": {"private, no-store"}}},
		{name: "no-cache", headers: http.Header{"Cache-Control": {"no-cache"}}},
		{name: "vary cookie", headers: http.Header{"Vary": {"Cookie"}}},
		{name: "vary authorization", headers: http.Header{"Vary": {"Authorization"}}},
		{name: "vary wildcard", headers: http.Header{"Vary": {"*"}}},
		{name: "vary unkeyed header", headers: http.Header{"Vary": {"Accept-Encoding, Referer"}}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			var calls atomic.Int32
			p := newTestProxy(t, func(w http.ResponseWriter, _ *http.Request) {
				for name, values := range tc.headers {
					w.Header()[name] = values
				}
				fmt.Fprintf(w, "response %d", calls.Add(1))
			})
			for i := 1; i <= 2; i++ {
				assertResponse(t, p.request("GET", "/v1/hn/item?id=1", nil, nil), 200, fmt.Sprintf("response %d", i), "BYPASS")
			}
		})
	}
}

func TestCacheKeysPreserveQueryAndResponseVariantsButIgnoreReferer(t *testing.T) {
	var calls atomic.Int32
	p := newTestProxy(t, func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Vary", "Accept-Language, User-Agent")
		fmt.Fprintf(w, "variant %d", calls.Add(1))
	})
	first := http.Header{"Accept-Language": {"en"}, "User-Agent": {"Hacki"}, "Referer": {"https://news.ycombinator.com/"}}
	assertResponse(t, p.request("GET", "/v1/hn/item?id=1&p=2", nil, first), 200, "variant 1", "MISS")
	changedReferer := first.Clone()
	changedReferer.Set("Referer", "https://news.ycombinator.com/item?id=2")
	assertResponse(t, p.request("GET", "/v1/hn/item?id=1&p=2", nil, changedReferer), 200, "variant 1", "HIT")
	changedLanguage := first.Clone()
	changedLanguage.Set("Accept-Language", "de")
	assertResponse(t, p.request("GET", "/v1/hn/item?id=1&p=2", nil, changedLanguage), 200, "variant 2", "MISS")
	assertResponse(t, p.request("GET", "/v1/hn/item?p=2&id=1", nil, first), 200, "variant 3", "MISS")
	assertResponse(t, p.request("GET", "/v1/hn/item?id=1&p=3", nil, first), 200, "variant 4", "MISS")
}

func TestConcurrentPublicGetsShareOneUpstreamFetch(t *testing.T) {
	var calls atomic.Int32
	entered := make(chan struct{})
	release := make(chan struct{})
	p := newTestProxy(t, func(w http.ResponseWriter, _ *http.Request) {
		if calls.Add(1) == 1 {
			close(entered)
		}
		<-release
		io.WriteString(w, "shared HTML")
	})
	const clients = 24
	responses := make(chan *httptest.ResponseRecorder, clients)
	var started sync.WaitGroup
	started.Add(clients)
	for range clients {
		go func() {
			started.Done()
			responses <- p.request("GET", "/v1/hn/item?id=1", nil, nil)
		}()
	}
	started.Wait()
	select {
	case <-entered:
	case <-time.After(5 * time.Second):
		t.Fatal("origin was not reached")
	}
	close(release)
	for range clients {
		select {
		case w := <-responses:
			if w.Code != 200 || w.Body.String() != "shared HTML" {
				t.Fatalf("coalesced response: %d %s", w.Code, w.Body.String())
			}
		case <-time.After(5 * time.Second):
			t.Fatal("coalesced request did not finish")
		}
	}
	if calls.Load() != 1 {
		t.Fatalf("concurrent requests generated %d upstream calls", calls.Load())
	}
}

func TestConcurrentRateLimitedMissesShareOneResponseWithoutCaching(t *testing.T) {
	for _, status := range []int{http.StatusForbidden, http.StatusTooManyRequests, http.StatusServiceUnavailable} {
		t.Run(fmt.Sprint(status), func(t *testing.T) {
			var calls atomic.Int32
			entered := make(chan struct{})
			release := make(chan struct{})
			var releaseOnce sync.Once
			defer releaseOnce.Do(func() { close(release) })
			p := newTestProxy(t, func(w http.ResponseWriter, _ *http.Request) {
				if calls.Add(1) == 1 {
					close(entered)
				}
				<-release
				w.Header().Set("Retry-After", "60")
				w.WriteHeader(status)
				io.WriteString(w, "slow down")
			})
			const clients = 24
			path := "/v1/hn/item?id=123"
			responses := make(chan *httptest.ResponseRecorder, clients)
			go func() { responses <- p.request("GET", path, nil, nil) }()
			select {
			case <-entered:
			case <-time.After(5 * time.Second):
				t.Fatal("origin was not reached")
			}
			for range clients - 1 {
				go func() { responses <- p.request("GET", path, nil, nil) }()
			}
			waitForFlightCallers(t, p.handler, clients)
			releaseOnce.Do(func() { close(release) })
			for range clients {
				select {
				case w := <-responses:
					assertResponse(t, w, status, "slow down", "BYPASS")
					if w.Header().Get("Retry-After") != "60" {
						t.Fatal("lost Retry-After header")
					}
				case <-time.After(5 * time.Second):
					t.Fatal("coalesced rate-limited request did not finish")
				}
			}
			if calls.Load() != 1 {
				t.Fatalf("concurrent rate-limited requests generated %d upstream calls", calls.Load())
			}
			var count int
			if err := p.cache.db.QueryRowContext(context.Background(), "SELECT COUNT(*) FROM responses").Scan(&count); err != nil || count != 0 {
				t.Fatalf("rate-limit response cached: rows %d error %v", count, err)
			}
			assertResponse(t, p.request("GET", path, nil, nil), status, "slow down", "BYPASS")
			if calls.Load() != 2 {
				t.Fatalf("a later request did not retry upstream: calls %d", calls.Load())
			}
		})
	}
}

func waitForFlightCallers(t *testing.T, h *Handler, want int) {
	t.Helper()
	timer := time.NewTimer(5 * time.Second)
	defer timer.Stop()
	ticker := time.NewTicker(time.Millisecond)
	defer ticker.Stop()
	for {
		h.mu.Lock()
		joined := false
		for _, f := range h.flights {
			joined = f.callers == want
		}
		h.mu.Unlock()
		if joined {
			return
		}
		select {
		case <-ticker.C:
		case <-timer.C:
			t.Fatalf("%d callers did not join the upstream flight", want)
		}
	}
}

func TestCompressedResponseBytesRemainUnchangedAcrossCacheHit(t *testing.T) {
	var compressed bytes.Buffer
	gz := gzip.NewWriter(&compressed)
	io.WriteString(gz, "<html>raw response</html>")
	if err := gz.Close(); err != nil {
		t.Fatal(err)
	}
	p := newTestProxy(t, func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Encoding", "gzip")
		w.Header().Set("Vary", "Accept-Encoding")
		w.Write(compressed.Bytes())
	})
	for _, state := range []string{"MISS", "HIT"} {
		w := p.request("GET", "/v1/hn/item?id=1", nil, http.Header{"Accept-Encoding": {"gzip"}})
		if w.Code != 200 || !bytes.Equal(w.Body.Bytes(), compressed.Bytes()) ||
			w.Header().Get("Content-Encoding") != "gzip" || w.Header().Get("X-Hacki-Cache") != state {
			t.Fatalf("compressed response changed: %d %v", w.Code, w.Header())
		}
	}
}

func TestConcurrentUncacheableResponsesNeverShareSessionCookies(t *testing.T) {
	for _, status := range []int{http.StatusOK, http.StatusTooManyRequests} {
		t.Run(fmt.Sprint(status), func(t *testing.T) {
			var calls atomic.Int32
			entered := make(chan struct{})
			release := make(chan struct{})
			var releaseOnce sync.Once
			defer releaseOnce.Do(func() { close(release) })
			p := newTestProxy(t, func(w http.ResponseWriter, _ *http.Request) {
				id := calls.Add(1)
				if id == 1 {
					close(entered)
				}
				<-release
				w.Header().Set("Set-Cookie", fmt.Sprintf("session=%d; HttpOnly", id))
				w.WriteHeader(status)
				fmt.Fprintf(w, "private response %d", id)
			})
			const clients = 24
			responses := make(chan *httptest.ResponseRecorder, clients)
			go func() { responses <- p.request("GET", "/v1/hn/item?id=1", nil, nil) }()
			select {
			case <-entered:
			case <-time.After(5 * time.Second):
				t.Fatal("origin was not reached")
			}
			for range clients - 1 {
				go func() {
					responses <- p.request("GET", "/v1/hn/item?id=1", nil, nil)
				}()
			}
			waitForFlightCallers(t, p.handler, clients)
			releaseOnce.Do(func() { close(release) })
			cookies := make(map[string]bool)
			for range clients {
				select {
				case w := <-responses:
					if w.Code != status || w.Header().Get("X-Hacki-Cache") != "BYPASS" {
						t.Fatalf("uncacheable response: %d %v", w.Code, w.Header())
					}
					cookie := w.Header().Get("Set-Cookie")
					if cookie == "" || cookies[cookie] {
						t.Fatalf("session cookie was shared between callers: %q", cookie)
					}
					cookies[cookie] = true
				case <-time.After(5 * time.Second):
					t.Fatal("uncacheable request did not finish")
				}
			}
			if calls.Load() != clients {
				t.Fatalf("%d clients generated %d upstream calls", clients, calls.Load())
			}
		})
	}
}

func TestDoubleSlashAndAbsoluteLookingPathsKeepFixedUpstreamHost(t *testing.T) {
	for _, path := range []string{"//attacker.invalid/item?id=1", "/https:%2F%2Fattacker.invalid/item?id=1"} {
		t.Run(path, func(t *testing.T) {
			var seen atomic.Bool
			p := newTestProxy(t, func(w http.ResponseWriter, r *http.Request) {
				seen.Store(true)
				if r.RequestURI != path {
					t.Errorf("path changed: %q, want %q", r.RequestURI, path)
				}
				io.WriteString(w, "fixed upstream")
			})
			assertResponse(t, p.request("GET", "/v1/hn"+path, nil, nil), 200, "fixed upstream", "BYPASS")
			if !seen.Load() {
				t.Fatal("request did not reach fixed upstream host")
			}
		})
	}
}

func TestBodySizeLimits(t *testing.T) {
	var calls atomic.Int32
	p := newTestProxy(t, func(w http.ResponseWriter, _ *http.Request) {
		calls.Add(1)
		w.Write(bytes.Repeat([]byte("x"), responseLimit+1))
	})
	for _, chunked := range []bool{false, true} {
		r := httptest.NewRequest("POST", "http://proxy.test/v1/hn/comment", bytes.NewReader(bytes.Repeat([]byte("x"), requestLimit+1)))
		r.Header.Set("X-API-Key", testAPIKey)
		if chunked {
			r.ContentLength = -1
			r.TransferEncoding = []string{"chunked"}
		}
		w := httptest.NewRecorder()
		p.handler.ServeHTTP(w, r)
		if w.Code != http.StatusRequestEntityTooLarge {
			t.Fatalf("oversize request (chunked=%t) returned %d", chunked, w.Code)
		}
	}
	if calls.Load() != 0 {
		t.Fatal("oversize request reached origin")
	}
	if w := p.request("GET", "/v1/hn/item?id=1", nil, nil); w.Code != http.StatusBadGateway {
		t.Fatalf("oversize response returned %d", w.Code)
	}
	var count int
	if err := p.cache.db.QueryRowContext(context.Background(), "SELECT COUNT(*) FROM responses").Scan(&count); err != nil || count != 0 {
		t.Fatalf("oversize response cached: rows %d error %v", count, err)
	}
}
