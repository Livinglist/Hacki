#!/usr/bin/env bash
set -Eeuo pipefail

# Called by Actions after building/saving one immutable image. Values remain data;
# remote command arguments use a deliberately restricted character set.
: "${VPS_HOST:?Set VPS_HOST}"
: "${VPS_USER:?Set VPS_USER}"
: "${VPS_SSH_KEY:?Set VPS_SSH_KEY}"
: "${VPS_SSH_KNOWN_HOSTS:?Set VPS_SSH_KNOWN_HOSTS}"
: "${GITHUB_SHA:?Missing commit SHA}"
: "${GITHUB_RUN_ID:?Missing run ID}"
: "${GITHUB_RUN_ATTEMPT:?Missing run attempt}"
: "${HACKI_IMAGE_ARCHIVE:?Missing saved Docker image}"
VPS_PORT=${VPS_PORT:-22}
VPS_DEPLOY_PATH=${VPS_DEPLOY_PATH:-/opt/hacki-server}
if [[ ! $VPS_HOST =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*$ ||
      ! $VPS_USER =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ||
      ! $VPS_PORT =~ ^[0-9]{1,5}$ || $((10#$VPS_PORT)) -lt 1 || $((10#$VPS_PORT)) -gt 65535 ||
      ! $VPS_DEPLOY_PATH =~ ^/[a-zA-Z0-9_./-]+$ || $VPS_DEPLOY_PATH == / ||
      /$VPS_DEPLOY_PATH/ == */../* || /$VPS_DEPLOY_PATH/ == */./* ||
      ! $GITHUB_SHA =~ ^([a-f0-9]{40}|[a-f0-9]{64})$ ||
      ! $GITHUB_RUN_ID =~ ^[0-9]+$ || ! $GITHUB_RUN_ATTEMPT =~ ^[0-9]+$ ]]; then
  echo "Invalid VPS deployment configuration" >&2
  exit 2
fi
[[ -f $HACKI_IMAGE_ARCHIVE ]] || { echo "Saved image archive is missing" >&2; exit 2; }
script_path=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
work_path=$(mktemp -d)
remote_path="$VPS_DEPLOY_PATH/.incoming-$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT"
destination="$VPS_USER@$VPS_HOST"
umask 077
printf '%s\n' "$VPS_SSH_KEY" >"$work_path/key"
printf '%s\n' "$VPS_SSH_KNOWN_HOSTS" >"$work_path/known_hosts"
ssh_options=(-i "$work_path/key" -o BatchMode=yes -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile="$work_path/known_hosts" -o ConnectTimeout=15)
remote_created=false
remote_started=false
cleanup() {
  if [[ $remote_created == true && $remote_started == false ]]; then
    ssh "${ssh_options[@]}" -p "$VPS_PORT" "$destination" "rm -rf -- '$remote_path'" >/dev/null 2>&1 || true
  fi
  rm -rf -- "$work_path"
}
trap cleanup EXIT

ssh "${ssh_options[@]}" -p "$VPS_PORT" "$destination" "mkdir -p -- '$VPS_DEPLOY_PATH' && mkdir -- '$remote_path'"
remote_created=true
scp "${ssh_options[@]}" -P "$VPS_PORT" "$HACKI_IMAGE_ARCHIVE" "$destination:$remote_path/image.tar.gz"
scp "${ssh_options[@]}" -P "$VPS_PORT" "$script_path/deploy.sh" "$script_path/compose.production.yaml" "$destination:$remote_path/"
# After this point, the VPS script owns bundle cleanup. An interrupted SSH
# connection must not remove a compose file that a deployment is still using.
remote_started=true
ssh "${ssh_options[@]}" -p "$VPS_PORT" "$destination" "bash '$remote_path/deploy.sh' '$VPS_DEPLOY_PATH' '$GITHUB_SHA' '$remote_path'"
