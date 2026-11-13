#!/usr/bin/env bash
set -Eeuo pipefail

# Executed on the VPS. The API key stays in the pre-provisioned .env file.
if [[ $# -ne 3 ]]; then
  echo "Usage: deploy.sh DEPLOY_PATH COMMIT_SHA BUNDLE_PATH" >&2
  exit 2
fi
deploy_path=$1
commit_sha=$2
bundle_path=$3
bundle_suffix=${bundle_path#"$deploy_path"/.incoming-}
if [[ ! $deploy_path =~ ^/[a-zA-Z0-9_./-]+$ || $deploy_path == / ||
      /$deploy_path/ == */../* || /$deploy_path/ == */./* ||
      ! $commit_sha =~ ^([a-f0-9]{40}|[a-f0-9]{64})$ ||
      $bundle_path != "$deploy_path"/.incoming-* ||
      ! $bundle_suffix =~ ^[0-9]+-[0-9]+$ ]]; then
  echo "Invalid deployment arguments" >&2
  exit 2
fi
for command in docker curl flock gzip; do
  command -v "$command" >/dev/null || { echo "Missing VPS dependency: $command" >&2; exit 2; }
done
[[ -f $deploy_path/.env ]] || { echo "Provision $deploy_path/.env before deploying" >&2; exit 2; }
[[ -f $bundle_path/image.tar.gz && -f $bundle_path/compose.production.yaml ]] || {
  echo "Deployment bundle is incomplete" >&2
  exit 2
}
trap 'rm -rf -- "$bundle_path"' EXIT

# Also prevents a manual deployment from racing a GitHub deployment.
exec 9>"$deploy_path/.deploy.lock"
flock -n 9 || { echo "Another deployment holds the VPS lock" >&2; exit 1; }
chmod 600 -- "$deploy_path/.env"
new_image="hacki-server:$commit_sha"
compose=(docker compose --project-name hacki-server --env-file "$deploy_path/.env" --file "$bundle_path/compose.production.yaml")
previous_container=$(HACKI_IMAGE="$new_image" "${compose[@]}" ps -aq hacki-server)
previous_image=
if [[ -n $previous_container ]]; then
  previous_image=$(docker inspect --format '{{.Image}}' "$previous_container")
fi

gzip -dc -- "$bundle_path/image.tar.gz" | docker load >/dev/null
expected_image=$(docker image inspect --format '{{.Id}}' "$new_image")

healthy() {
  local image=$1 container actual running attempt
  for attempt in {1..15}; do
    container=$(HACKI_IMAGE="$image" "${compose[@]}" ps -q hacki-server)
    if [[ -n $container ]]; then
      actual=$(docker inspect --format '{{.Image}}' "$container" 2>/dev/null) || actual=
      running=$(docker inspect --format '{{.State.Running}}' "$container" 2>/dev/null) || running=false
      if [[ $actual == "$image" && $running == true ]] &&
         curl --fail --silent --max-time 2 http://127.0.0.1:8080/healthz >/dev/null; then
        return 0
      fi
    fi
    sleep 2
  done
  return 1
}

rollback() {
  if [[ -n $previous_image ]]; then
    echo "Deployment failed; restoring the previous image" >&2
    if HACKI_IMAGE="$previous_image" "${compose[@]}" up --detach --no-build --pull never --remove-orphans &&
       healthy "$previous_image"; then
      printf '%s\n' "$previous_image" >"$deploy_path/.deployed-image"
      echo "Previous image restored" >&2
    else
      echo "Rollback failed; inspect the service on the VPS" >&2
    fi
  else
    echo "Initial deployment failed; stopping the unhealthy service" >&2
    HACKI_IMAGE="$new_image" "${compose[@]}" stop hacki-server || true
  fi
}

if ! HACKI_IMAGE="$new_image" "${compose[@]}" up --detach --no-build --pull never --remove-orphans; then
  rollback
  exit 1
fi
if ! healthy "$expected_image"; then
  rollback
  exit 1
fi

install -m 0644 "$bundle_path/compose.production.yaml" "$deploy_path/compose.production.yaml"
printf '%s\n' "$expected_image" >"$deploy_path/.deployed-image"
echo "Deployed $new_image; health check passed"
