# Hacki fallback API

This Go service proxies Hacker News HTML when a mobile device is rate limited.
Hacki still tries Hacker News directly first. After an HTTP **403, 429, or 503**,
the configured app retries the same request through this service. The existing
HTML parsers consume the returned HTML; the Firebase and search APIs are unchanged.

The service requires one shared API key and only connects to
`https://news.ycombinator.com`. It is not a general URL proxy.

## Run on a VPS with Docker

Requirements: Docker Engine with Compose and a public HTTPS endpoint. A domain
name is optional: use the Caddy hostname example below, or follow
[HTTPS with a public IP address](#https-with-a-public-ip-address).
For automated deployment, follow the complete
[GitHub Actions setup guide](#deploy-automatically-from-github-actions).

For a manual deployment, run these commands from `server/`:

```sh
if [ ! -e .env ]; then
    cp .env.example .env
fi
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

If using a hostname, point its DNS record at the VPS and make TCP ports 80/443
available. Install Caddy on the host using its official instructions, then add
this to `/etc/caddy/Caddyfile`, substituting your hostname:

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

The steps below assume an Ubuntu 24.04 VPS and a macOS/Linux terminal on your
computer. Run commands labelled **VPS** as root; if you log in as a different
administrator, start a root shell with `sudo -i`. Run commands labelled
**your computer** in a separate local terminal.

Replace `YOUR_VPS_IP` with your public IPv4 address. Examples use SSH port 22;
substitute your actual SSH port throughout. Use placeholders in shared
documentation: keep real API keys, populated `.env` files, SSH private keys,
and TLS private keys on the VPS or in GitHub Actions secrets.

1. **VPS: install prerequisites and check architecture.**

   ```sh
   uname -m
   docker --version
   docker compose version
   ```

   | Architecture | `VPS_PLATFORM` |
   | --- | --- |
   | `x86_64` | `linux/amd64` |
   | `aarch64` | `linux/arm64` |

   Install the supporting tools even if Docker is already present:

   ```sh
   apt-get update
   apt-get install -y curl gzip util-linux openssl nano
   ```

   If Docker is missing on Ubuntu 24.04, install Docker Engine and Compose:

   ```sh
   apt-get install -y docker.io docker-compose-v2
   systemctl enable --now docker
   ```

   Confirm that the daemon and Compose are available:

   ```sh
   docker info --format 'Docker server: {{.ServerVersion}}'
   docker compose version
   ```

   Keep an existing working Docker installation. For other distributions, use
   [Docker's official installation guide](https://docs.docker.com/engine/install/).
   If OpenVPN is already running, check its connection after installing Docker,
   which adds network/firewall rules. Inspect existing listeners with
   `ss -lntup` and choose an available HTTPS port. The IP-only example below
   uses TCP 8443 for the API and TCP 80 for certificate validation.

2. **VPS: create the account and shared API key.**

   Create a dedicated deployment user, or reuse it if already created:

   ```sh
   useradd --create-home --shell /bin/bash hacki-deploy
   usermod -aG docker hacki-deploy
   install -d -m 0750 -o hacki-deploy -g hacki-deploy /opt/hacki-server
   ```

   Docker group membership gives root-equivalent control of the VPS; dedicate
   this account and its SSH key to deployment.

   Generate one API key, or reuse your existing key when updating a deployment:

   ```sh
   openssl rand -hex 32
   ```

   Save the generated value privately. The VPS and mobile build must use the
   same value. Prepare the file without overwriting an existing configuration:

   ```sh
   touch /opt/hacki-server/.env
   chown hacki-deploy:hacki-deploy /opt/hacki-server/.env
   chmod 600 /opt/hacki-server/.env
   nano /opt/hacki-server/.env
   ```

   Enter the following, replacing the placeholder with your generated key:

   ```dotenv
   HACKI_API_KEY=PASTE_YOUR_GENERATED_KEY_HERE
   HACKI_CACHE_TTL=30m
   ```

   In Nano, save with Ctrl+O, Enter, then exit with Ctrl+X.

3. **Your computer: generate a deployment SSH key.**

   ```sh
   mkdir -p ~/.ssh
   ssh-keygen -t ed25519 -f ~/.ssh/hacki-deploy-github \
     -C 'Hacki GitHub deployment' -N ''
   cat ~/.ssh/hacki-deploy-github.pub
   ```

   The file without `.pub` is the private key for GitHub's `VPS_SSH_KEY`
   secret. The `.pub` file is the public key to authorize on the VPS. The
   dedicated key has no passphrase so the workflow can use it unattended.

   **VPS:** prepare the deployment account's authorized keys:

   ```sh
   install -d -m 0700 -o hacki-deploy -g hacki-deploy /home/hacki-deploy/.ssh
   touch /home/hacki-deploy/.ssh/authorized_keys
   chown hacki-deploy:hacki-deploy /home/hacki-deploy/.ssh/authorized_keys
   chmod 0600 /home/hacki-deploy/.ssh/authorized_keys
   nano /home/hacki-deploy/.ssh/authorized_keys
   ```

   Append `restrict ` followed by the entire public-key line from your computer,
   on one line. Preserve any existing entries. The `restrict` prefix disables
   forwarding and PTY allocation while allowing commands and file transfers.

4. **Your computer: collect and verify the VPS host key.**

   ```sh
   ssh-keyscan -t ed25519 -p 22 YOUR_VPS_IP > ~/.ssh/hacki-vps-known-hosts
   ssh-keygen -lf ~/.ssh/hacki-vps-known-hosts
   ```

   Through your provider's trusted **VPS console**, compare the fingerprint with:

   ```sh
   ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
   ```

   The SHA256 fingerprints must match. `ssh-keyscan` alone does not authenticate
   the key. Use the same host and SSH port here as in the workflow settings.
   For a custom SSH port, scan that port; known-host entries use
   `[hostname]:port` for non-22 ports. The verified file becomes the
   `VPS_SSH_KNOWN_HOSTS` secret.

5. **GitHub: create the production environment.**

   In the repository's **Settings → Environments**, create `production`.
   Under deployment branches, allow `master`. Required reviewers are optional.
   Add these **environment variables**:

   | Name | Value |
   | --- | --- |
   | `VPS_HOST` | Your public IPv4 address or DNS hostname, without `ssh://`. |
   | `VPS_USER` | `hacki-deploy` |
   | `VPS_PORT` | Your SSH port; defaults to `22`. This is separate from the API's HTTPS port. |
   | `VPS_DEPLOY_PATH` | `/opt/hacki-server` by default; use an absolute path without spaces. |
   | `VPS_PLATFORM` | `linux/amd64` by default, or `linux/arm64`, from step 1. |

   Add these **environment secrets**:

   | Name | Value |
   | --- | --- |
   | `VPS_SSH_KEY` | Entire contents of your computer's `~/.ssh/hacki-deploy-github`, including the private-key header and footer. |
   | `VPS_SSH_KNOWN_HOSTS` | Entire contents of the verified `~/.ssh/hacki-vps-known-hosts` file. |

   IPv6-only servers can use a DNS hostname; literal IPv6 addresses are not
   accepted by the transport script. Allow the configured SSH port from
   GitHub's hosted runners through your existing firewall; their outbound
   addresses can change.

6. **GitHub: configure the mobile app at repository scope.**

   Under **Settings → Secrets and variables → Actions → Variables**, add:

   | Repository variable | Value |
   | --- | --- |
   | `HACKI_BACKEND_URL` | Your public HTTPS base URL, such as `https://YOUR_VPS_IP:8443` or `https://hacki-api.example.com`. Leave off `/v1/hn`. |

   Under **Actions → Secrets**, add:

   | Repository secret | Value |
   | --- | --- |
   | `HACKI_BACKEND_API_KEY` | The exact value stored as `HACKI_API_KEY` in the VPS `.env` file. |

   These two settings must be repository-level settings: the Android and iOS
   release jobs do not select the `production` environment. Keep your existing
   mobile signing secrets. Deployment needs no GitHub personal access token,
   registry credentials, VPS root password, or Hacker News credentials.

7. **VPS: configure public HTTPS.**

   Choose the [Caddy hostname example](#run-on-a-vps-with-docker) or the complete
   [IP-only Nginx and Certbot guide](#https-with-a-public-ip-address) below.
   Both forward to `127.0.0.1:8080`. TLS certificate files stay on the VPS and
   do not need GitHub secrets. Keep port 8080 private and preserve your existing
   SSH/OpenVPN firewall rules when allowing certificate-validation and HTTPS
   traffic. The workflow does not install or configure the reverse proxy.

8. **Your computer: test deployment access.**

   ```sh
   ssh -i ~/.ssh/hacki-deploy-github -p 22 \
     -o BatchMode=yes -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes \
     -o UserKnownHostsFile="$HOME/.ssh/hacki-vps-known-hosts" \
     hacki-deploy@YOUR_VPS_IP \
     'docker info >/dev/null &&
      docker compose version &&
      test -r /opt/hacki-server/.env &&
      test -w /opt/hacki-server'
   ```

   This fresh SSH session picks up the account's Docker group membership.
   The command should finish successfully without requesting a password.

9. **GitHub: deploy and verify.**

   The workflow must exist on `master`. Merging a change to the server or its
   deployment workflow into `master` triggers deployment automatically. For
   a manual deployment, select **Actions → Deploy Server → Run workflow**
   and choose `master`.

   After the workflow succeeds, check health on the **VPS**:

   ```sh
   curl --fail http://127.0.0.1:8080/healthz
   ```

   Expected response:

   ```json
   {"status":"ok"}
   ```

   Check authentication and caching using the key in your own VPS configuration:

   ```sh
   (
       . /opt/hacki-server/.env
       curl -i -H "X-API-Key: $HACKI_API_KEY" \
         'http://127.0.0.1:8080/v1/hn/item?id=1'
       curl -i -H "X-API-Key: $HACKI_API_KEY" \
         'http://127.0.0.1:8080/v1/hn/item?id=1'
   )
   ```

   A successful initial fetch reports `X-Hacki-Cache: MISS`; a cached response
   reports `HIT`. **From your computer**, also verify the public HTTPS endpoint,
   substituting your configured URL:

   ```sh
   curl --fail https://YOUR_VPS_IP:8443/healthz
   ```

   Finally, run the Android or iOS release workflow with the repository backend
   settings configured. Install the new app build to enable fallback; existing
   installed builds need updating.

Deployments are serialized, and a lock on the VPS also protects against
concurrent manual deployments. The script verifies the running image ID and
health. If startup or health fails, it restores the previous exact image ID and
last-known-good Compose configuration, then checks health using that restored
configuration and fails the workflow. On an unsuccessful first deployment it
stops the unhealthy service. Keep the previous image locally for rollback.

Both manual Compose and CI use project `hacki-server` and volume
`hacki-server_cache`, so deployments preserve SQLite. If an older manual install
used a different project name, migrate its cache volume before switching.
Before migrating a running manual service, save its working Compose configuration
as `/opt/hacki-server/compose.production.yaml` (or the configured deployment path).
Resolve any relative resource paths against that deployment directory. The script
refuses to replace an existing service without a saved configuration to restore.
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
does not deploy merely by opening a pull request. The backend API key stays in
the VPS configuration during server deployment and is never copied into the
server image or its deployment archive. Mobile release builds embed the key
as described under [Configure Hacki](#configure-hacki).

## HTTPS with a public IP address

A domain is optional. This Ubuntu example uses Nginx on TCP 8443 and a publicly
trusted Let's Encrypt certificate for your public IPv4 address. Use a stable
public IP, replace `YOUR_VPS_IP` throughout, and run these commands as root on
the VPS. If HTTPS already works, keep your existing reverse proxy configuration.

1. **Check ports and install Nginx and Certbot.**

   ```sh
   ss -lntup
   apt-get update
   apt-get install -y nginx snapd
   snap install --classic certbot
   /snap/bin/certbot --version
   ```

   TCP 80 must be available for Nginx and reachable from the internet for
   validation. TCP 8443 must be available for the API. Add any required rules
   to your existing provider/VPS firewall, preserving SSH and OpenVPN access.
   If UFW is already active, allow these ports with:

   ```sh
   ufw allow 80/tcp
   ufw allow 8443/tcp
   ```

   Certbot must be version 5.4 or newer for IP certificates with webroot
   validation. Keep an existing current installation; the absolute snap path
   above avoids accidentally using an older apt-installed executable. See
   [Certbot's installation instructions](https://certbot.eff.org/instructions?os=snap&ws=nginx).

2. **Configure HTTP validation first.**

   ```sh
   mkdir -p /var/www/letsencrypt/.well-known/acme-challenge
   nano /etc/nginx/sites-available/hacki-api
   ```

   Enter this configuration, replacing the IP placeholder:

   ```nginx
   server {
       listen 80;
       server_name YOUR_VPS_IP;

       location ^~ /.well-known/acme-challenge/ {
           root /var/www/letsencrypt;
       }

       location / {
           return 404;
       }
   }
   ```

   Enable and load the site:

   ```sh
   ln -s /etc/nginx/sites-available/hacki-api /etc/nginx/sites-enabled/hacki-api
   nginx -t
   systemctl enable --now nginx
   systemctl reload nginx
   ```

   If the link already exists, check its target with
   `readlink -f /etc/nginx/sites-enabled/hacki-api`. A link already pointing at
   the configuration above can be reused. A successful `nginx -t` confirms
   configuration syntax; external port-80 reachability is still required.

3. **Obtain a trusted IP certificate.**

   ```sh
   /snap/bin/certbot certonly \
     --webroot \
     --webroot-path /var/www/letsencrypt \
     --preferred-profile shortlived \
     --ip-address YOUR_VPS_IP \
     --cert-name hacki-api
   ```

   Follow the email and terms prompts. This uses Let's Encrypt's production
   service; staging certificates are not publicly trusted. IP certificates
   use the short-lived profile and expire after roughly six days, so automated
   renewal is essential. See
   [Let's Encrypt's IP certificate guide](https://letsencrypt.org/2026/03/11/shorter-certs-certbot.html).

4. **Add HTTPS after certificate issuance succeeds.**

   Edit `/etc/nginx/sites-available/hacki-api` again. Keep the HTTP validation
   block and append the following, replacing the IP placeholder:

   ```nginx
   server {
       listen 8443 ssl;
       server_name YOUR_VPS_IP;

       ssl_certificate /etc/letsencrypt/live/hacki-api/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/hacki-api/privkey.pem;
       ssl_protocols TLSv1.2 TLSv1.3;

       location / {
           proxy_pass http://127.0.0.1:8080;
       }
   }
   ```

   ```sh
   nginx -t
   systemctl reload nginx
   ```

   Nginx's root master can read the certificate files; keep private-key
   permissions restricted. The public API URL is now
   `https://YOUR_VPS_IP:8443`. The backend health endpoint becomes available
   after the server deployment succeeds.

5. **Configure and test renewal.**

   Create an executable hook so Nginx loads renewed certificates:

   ```sh
   mkdir -p /etc/letsencrypt/renewal-hooks/deploy
   cat > /etc/letsencrypt/renewal-hooks/deploy/reload-nginx <<'EOF'
   #!/bin/sh
   /usr/bin/systemctl reload nginx
   EOF
   chmod 750 /etc/letsencrypt/renewal-hooks/deploy/reload-nginx

   systemctl list-timers --all '*certbot*'
   /snap/bin/certbot renew --dry-run --run-deploy-hooks
   ```

   The snap installation normally schedules renewal automatically. Confirm
   that a renewal timer is listed and the dry run succeeds. Keep the HTTP
   challenge location on port 80 working for future renewals. The deploy hook
   reloads only Nginx; it does not restart OpenVPN. See
   [Certbot's renewal documentation](https://eff-certbot.readthedocs.io/en/stable/using.html#renewing-certificates).

## Run as a native systemd service

Install the Go version declared in `go.mod` or newer and build from `server/`:

```sh
go mod download
CGO_ENABLED=0 go build -trimpath -o hacki-server ./cmd/hacki-server
sudo install -m 0755 hacki-server /usr/local/bin/hacki-server
sudo install -m 0644 deploy/hacki-server.service \
  /etc/systemd/system/hacki-server.service
if ! sudo test -e /etc/hacki-server.env; then
    sudo install -m 0600 .env.example /etc/hacki-server.env
fi
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
Anonymous rate-limit responses can also be shared with callers already waiting
for that fetch, without being saved to SQLite. Responses that set session cookies
or otherwise cannot safely be shared still receive independent fetches.

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
on server changes. Tests use a local upstream stub, temporary SQLite files, and
isolated command stubs to exercise deployment rollback without contacting a VPS.
