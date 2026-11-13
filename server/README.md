# Hacki fallback API

This Go service proxies Hacker News HTML when a mobile device is rate limited.
Hacki still tries Hacker News directly first. After an HTTP **403, 429, or 503**,
the configured app retries the same request through this service. The existing
HTML parsers consume the returned HTML; the Firebase and search APIs are unchanged.

The service requires one shared API key and only connects to
`https://news.ycombinator.com`. It is not a general URL proxy.

## Run on a VPS with Docker

Requirements: Docker Engine with Compose, a domain pointing to the VPS, and ports
80/443 available for HTTPS. Run these commands from `server/`:

```sh
cp .env.example .env
chmod 600 .env
openssl rand -hex 32
# Edit .env and replace HACKI_API_KEY with the generated value.
docker compose up -d --build
curl --fail http://127.0.0.1:8080/healthz
```

The container runs as an unprivileged user. Compose binds port 8080 to loopback
and stores SQLite in the `cache` named volume. Restarting or rebuilding the
container preserves the cache. `docker compose down` preserves the volume;
`docker compose down -v` deletes it.

Install Caddy on the host using its official instructions, then add this to
`/etc/caddy/Caddyfile`, substituting your domain:

```caddyfile
hacki-api.example.com {
    reverse_proxy 127.0.0.1:8080
}
```

Validate and reload Caddy:

```sh
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

Caddy obtains and renews the HTTPS certificate. Keep port 8080 private and expose
the service to mobile clients over HTTPS. If you enable proxy access logs,
redact the API key, cookies, request bodies, and sensitive query parameters.

Set `HACKI_API_KEY` in your local shell to the value in `.env`, then verify:

```sh
# Expected: 401 without a key.
curl -i 'https://hacki-api.example.com/v1/hn/item?id=1'

# Expected: Hacker News HTML. The second request should report HIT.
curl -i -H "X-API-Key: $HACKI_API_KEY" \
  'https://hacki-api.example.com/v1/hn/item?id=1'
curl -i -H "X-API-Key: $HACKI_API_KEY" \
  'https://hacki-api.example.com/v1/hn/item?id=1'
```

Update with `git pull` followed by `docker compose up -d --build`. To back up
SQLite, stop the service and back up the complete volume, including SQLite's
`-wal` and `-shm` files if present, before restarting it. An online SQLite backup
is also suitable; copying only an active database file can omit recent writes.

## Deploy automatically from GitHub Actions

The **Deploy Server** workflow tests the Go server, builds an image tagged with
the commit SHA, copies it over SSH, and starts it on the VPS. It runs for changes
to `server/**` on `master` and can also be started with **Run workflow**. No image
registry or GitHub package token is needed. It does not provision the VPS,
overwrite its `.env`, or configure the HTTPS reverse proxy.

Prepare the VPS once:

1. Install Docker Engine with Compose, Bash, `curl`, `gzip`, and `flock`
   (`util-linux` on Debian/Ubuntu). Use Docker's official installation guide.
2. Create a deployment user and writable deployment directory, for example:

   ```sh
   sudo useradd --create-home --shell /bin/bash hacki-deploy
   sudo usermod -aG docker hacki-deploy
   sudo install -d -m 0750 -o hacki-deploy -g hacki-deploy /opt/hacki-server
   sudo install -m 0600 -o hacki-deploy -g hacki-deploy /dev/null /opt/hacki-server/.env
   sudoedit /opt/hacki-server/.env
   ```

   Put `HACKI_API_KEY=<your-random-key>` and `HACKI_CACHE_TTL=30m` in that file.
   Use the same key as the app's `HACKI_BACKEND_API_KEY` secret. Docker group
   membership gives root-equivalent control of the VPS; dedicate this account
   and SSH key to deployment. Start a new login session after changing groups.
3. Generate a dedicated SSH key on a trusted machine:

   ```sh
   ssh-keygen -t ed25519 -f ~/.ssh/hacki-deploy-github -N ''
   ```

   Install the public key in the deployment user's `~/.ssh/authorized_keys`
   with directory mode 0700 and file mode 0600, owned by that user. Prefixing
   the key with `restrict` disables forwarding and PTY allocation while still
   allowing the deployment's SSH commands and file transfers.
4. Collect the VPS SSH host key, then verify its fingerprint against a trusted
   VPS console or your provider's published fingerprint before using it:

   ```sh
   ssh-keyscan -t ed25519 -p 22 your-vps.example.com > /tmp/hacki-vps-known-hosts
   ssh-keygen -lf /tmp/hacki-vps-known-hosts
   # On the VPS console, compare with:
   # ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
   ```

   `ssh-keyscan` alone does not authenticate the key. For a custom SSH port,
   scan that port; known-host entries must use `[hostname]:port` for non-22
   ports. Keep the verified lines for the next step.
5. Configure Caddy and DNS using the earlier HTTPS example. Keep HTTP port 8080
   private. Allow the configured SSH port from GitHub's hosted runners; an SSH
   allowlist must account for their changing outbound addresses.

In GitHub **Settings → Environments**, create `production`. Restrict its
deployment branches to `master`; add required reviewers if you want an approval
before production deploys. Add these Actions variables and secrets at repository
or `production` environment scope:

| Type | Name | Value |
| --- | --- | --- |
| Variable | `VPS_HOST` | VPS DNS hostname or IPv4 address; do not include `ssh://`. |
| Variable | `VPS_USER` | Deployment user, for example `hacki-deploy`. |
| Variable | `VPS_PORT` | SSH port; optional, defaults to `22`. |
| Variable | `VPS_DEPLOY_PATH` | Absolute path without spaces, for example `/opt/hacki-server`; this is the default. |
| Variable | `VPS_PLATFORM` | `linux/amd64` by default, or `linux/arm64` for an ARM VPS. Check `uname -m` on the VPS. |
| Secret | `VPS_SSH_KEY` | Complete dedicated private key, including its header/footer. |
| Secret | `VPS_SSH_KNOWN_HOSTS` | The verified known-host lines for `VPS_HOST` and `VPS_PORT`. |

The deployment account must be able to run `docker` without `sudo`, write the
deployment directory, and read its `.env`. IPv6-only servers can use a DNS
hostname; literal IPv6 addresses are not accepted by the transport script.
The backend key stays on the VPS during deployment and is never copied into the
image or an Actions artifact.

Run **Actions → Deploy Server → Run workflow**, selecting `master`, for the
initial deployment. Subsequent matching pushes deploy automatically. Deployments
are serialized, and a lock on the VPS also protects against concurrent manual
deployments. The script checks that the running container uses the image just
loaded, then checks `http://127.0.0.1:8080/healthz`. If startup or health fails,
it restores the previous exact image ID and fails the workflow. On an unsuccessful
first deployment it stops the unhealthy service. The previous image must remain
available locally for rollback.

Both manual Compose and CI use project `hacki-server` and volume
`hacki-server_cache`, so deployments preserve SQLite. If an older manual install
used a different project name, migrate its cache volume before switching.
The deployment saves the current exact image ID in `.deployed-image` and its Compose
file in the deployment directory. To inspect logs on the VPS:

```sh
cd /opt/hacki-server
HACKI_IMAGE="$(cat .deployed-image)" docker compose \
  --project-name hacki-server --env-file .env \
  -f compose.production.yaml logs --tail=100
```

Successful transfers remove their temporary bundle. Images remain on the VPS
for rollback; monitor disk usage and remove obsolete images deliberately while
retaining the current and previous image. Deleting the Compose volume deletes
the cache. The workflow has no VPS credentials until you configure them, and
does not deploy merely by opening a pull request.

## Run as a native systemd service

Install the Go version declared in `go.mod` or newer and build from `server/`:

```sh
go mod download
CGO_ENABLED=0 go build -trimpath -o hacki-server ./cmd/hacki-server
sudo install -m 0755 hacki-server /usr/local/bin/hacki-server
sudo install -m 0644 deploy/hacki-server.service \
  /etc/systemd/system/hacki-server.service
sudo install -m 0600 .env.example /etc/hacki-server.env
# Edit /etc/hacki-server.env and set a random HACKI_API_KEY.
sudo systemctl daemon-reload
sudo systemctl enable --now hacki-server
sudo systemctl status hacki-server
```

The unit creates a dedicated dynamic user and a persistent state directory at
`/var/lib/hacki-server`. Use the same Caddy configuration above for HTTPS.
View logs with `journalctl -u hacki-server`. The SQLite driver is pure Go;
the binary does not require a C compiler or a system SQLite library.

For local development:

```sh
export HACKI_API_KEY='a-development-key'
go run ./cmd/hacki-server
```

Configuration:

| Environment variable | Default | Meaning |
| --- | --- | --- |
| `HACKI_API_KEY` | Required | Shared value expected in `X-API-Key`. |
| `HACKI_LISTEN_ADDR` | `127.0.0.1:8080` | HTTP bind address; TLS terminates at the reverse proxy. |
| `HACKI_CACHE_PATH` | `./data/cache.sqlite` | SQLite database; its parent directory is created if needed. |
| `HACKI_CACHE_TTL` | `30m` | Freshness period, as a positive Go duration such as `30m` or `1h`. |

## Configure Hacki

Use the same API key as the server and the public HTTPS base URL when building
the app:

```sh
flutter build apk --release \
  --dart-define=HACKI_BACKEND_URL=https://hacki-api.example.com \
  --dart-define=HACKI_BACKEND_API_KEY="$HACKI_API_KEY"

flutter build ipa --release \
  --dart-define=HACKI_BACKEND_URL=https://hacki-api.example.com \
  --dart-define=HACKI_BACKEND_API_KEY="$HACKI_API_KEY"
```

Pass the same defines to `flutter run` for development. Both values are required;
without them Hacki keeps its existing behavior. The URL must use HTTPS except
for loopback development addresses. On a physical phone, loopback refers to the
phone, so use a reachable HTTPS development endpoint.

For the repository's Android APK/AAB and iOS TestFlight release workflows,
configure these under **Settings → Secrets and variables → Actions**:

| Type | Name | Value |
| --- | --- | --- |
| Repository variable | `HACKI_BACKEND_URL` | Public HTTPS base URL, such as `https://hacki-api.example.com`. |
| Repository secret | `HACKI_BACKEND_API_KEY` | The server's `HACKI_API_KEY` value. |

The workflows pass these values into the Flutter build through environment
variables. Fastlane suppresses command logging for the command containing the
key. If either setting is absent, fallback stays disabled. The secret remains
embedded in the distributed app, so GitHub secret storage protects build-time
handling rather than preventing extraction from the app.

The app retries through the backend once after a rate-limit response, preserving
the original request method, path, query, body, and relevant headers. This covers
the HTML story/comment/favorites clients and the form-based login/post client.
If the backend also fails, Hacki continues its existing error/API fallback flow.
The API key is sent only to the configured backend, never to Hacker News.

A shared key embedded in a mobile build can be extracted. It gates the service
but does not prove a request came from an official app. Keep it out of Git, use
HTTPS, rotate it when needed, and monitor proxy traffic. Changing the key requires
rebuilding the app with the new value. Since authenticated form requests forward
HN credentials/cookies, operate the backend on infrastructure you trust.

## HTTP contract and cache

`GET /healthz` is an unauthenticated liveness endpoint. It does not fetch Hacker
News or reveal the key. All `/v1/hn` proxy requests require `X-API-Key`.

Prepend `/v1/hn` to the original Hacker News path and retain the original query:

| Hacker News request | Backend request |
| --- | --- |
| `GET https://news.ycombinator.com/?p=2` | `GET /v1/hn/?p=2` |
| `GET https://news.ycombinator.com/item?id=123&p=2` | `GET /v1/hn/item?id=123&p=2` |
| `GET https://news.ycombinator.com/favorites?id=alice` | `GET /v1/hn/favorites?id=alice` |
| `POST https://news.ycombinator.com/login` | `POST /v1/hn/login` with the same form body |

GET, HEAD, POST, PUT, PATCH, DELETE, and OPTIONS are supported. CONNECT and TRACE
are rejected. There is no caller-supplied upstream host. The server forwards the
method, path, query, request body, and relevant headers, and returns the upstream
body, status, and relevant headers. It strips the backend key and hop-by-hop
headers before forwarding. It does not follow upstream redirects; HN `Location`
and `Set-Cookie` headers remain available to the app's existing form logic.

Request bodies are limited to 1 MiB and upstream response bodies to 8 MiB.
Oversized requests receive HTTP 413; an oversized upstream response receives
HTTP 502. Upstream requests have a 30-second timeout. Transport failures receive
HTTP 502 or 504; stale fallback applies specifically to HN rate-limit statuses.

For example, a form request (use your own HN credentials):

```sh
curl -i -H "X-API-Key: $HACKI_API_KEY" \
  --data-urlencode 'acct=your-hn-username' \
  --data-urlencode 'pw=your-hn-password' \
  'https://hacki-api.example.com/v1/hn/login'
```

The cache applies to HTTP 200 anonymous GETs for public read pages, including
story lists, items/comments, user profiles, and public favorites. It includes
the path and complete query in each cache key, so pages/items do not collide.
It also varies entries by `Accept`, `Accept-Encoding`, `Accept-Language`, and
`User-Agent`, so distinct representations do not share response bytes.
Concurrent requests for the same cacheable resource share one upstream fetch.

* Entries younger than 30 minutes are returned directly.
* An expired entry triggers a new upstream request. A successful cacheable
  response replaces the old entry and resets its age.
* If that request gets HTTP 403, 429, or 503, the latest saved entry is returned,
  even when older than the TTL. Serving it does not reset its age.
* Without a saved entry, the upstream rate-limit response is returned unchanged.
* Rate-limit/error responses and non-GET requests are never cached. Requests
  carrying cookies or upstream authorization, action URLs such as voting, and
  responses with `Set-Cookie`, `no-store`, or `no-cache` bypass the shared cache.

HN marks even anonymous public pages `Cache-Control: private; max-age=0`. This
application-level snapshot cache deliberately uses the configured TTL for its
strictly allowlisted anonymous public reads despite that header. Cookie-bearing,
authenticated, and sensitive or unrecognized query requests bypass it so those
responses are never shared between users.

The TTL is a freshness threshold, not a deletion deadline: stale entries remain
available across process restarts for rate-limit fallback. Monitor disk usage
as the number of distinct public URLs grows.
To reset snapshots, stop the service before deleting its database and any SQLite
sidecar files, or deliberately remove the Compose volume with `down -v`.

`X-Hacki-Cache` explains how a response was served:

| Value | Meaning |
| --- | --- |
| `HIT` | Returned an unexpired SQLite entry. |
| `MISS` | No entry existed; fetched from HN. |
| `REFRESH` | Replaced an expired entry with fresh HN data. |
| `STALE` | HN was rate limited; returned the saved entry. |
| `BYPASS` | Request or response was ineligible for shared caching. |

## Checks

```sh
go vet ./...
go test -race ./...
CGO_ENABLED=0 go build ./cmd/hacki-server
```

The server workflow runs formatting, vet, race-enabled tests, and a static build
on server changes. Tests use a local upstream stub and temporary SQLite files.
