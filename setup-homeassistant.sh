#!/usr/bin/env bash
set -Eeuo pipefail

readonly IMAGE="ghcr.io/home-assistant/home-assistant:stable"
readonly CONTAINER_NAME="omarchy-homeassistant"
readonly SERVER_URL="http://127.0.0.1:8123"
readonly MANAGED_LABEL="io.omarchy.homeassistant-ac.managed"
readonly DATA_HOME="${XDG_DATA_HOME:-${HOME:-}/.local/share}"
readonly CONFIG_DIR="${DATA_HOME}/omarchy/homeassistant"

if [[ -z "${HOME:-}" ]]; then
  exit 1
fi

json_result() {
  local ok="$1"
  local status="$2"
  local message="$3"
  local ready="$4"
  python3 - "$ok" "$status" "$message" "$ready" "$SERVER_URL" "$CONFIG_DIR" <<'PY'
import json
import sys

ok, status, message, ready, url, config_dir = sys.argv[1:]
print(json.dumps({
    "ok": ok == "true",
    "action": "local_server",
    "status": status,
    "message": message,
    "ready": ready == "true",
    "url": url,
    "config_dir": config_dir,
}, separators=(",", ":")))
PY
}

fail() {
  json_result false error "$1" false
  exit 1
}

if ! command -v python3 >/dev/null 2>&1; then
  fail "Python 3 is required to check the local Home Assistant server."
fi

docker_bin=""
docker_cmd=()

ensure_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    if ! command -v pacman >/dev/null 2>&1 || ! command -v pkexec >/dev/null 2>&1; then
      fail "Docker is not installed. Install Docker from the official Linux guide, then try again."
    fi
    if ! pkexec pacman --noconfirm -S --needed docker >&2; then
      fail "Docker could not be installed. Nothing was changed by this setup step."
    fi
  fi

  docker_bin="$(command -v docker || true)"
  if [[ -z "$docker_bin" ]]; then
    fail "Docker is still unavailable after the install attempt."
  fi

  docker_cmd=("$docker_bin")
  if "${docker_cmd[@]}" info >/dev/null 2>&1; then
    return
  fi

  if command -v pkexec >/dev/null 2>&1 \
      && pkexec "$docker_bin" info >/dev/null 2>&1; then
    docker_cmd=(pkexec "$docker_bin")
    return
  fi

  if command -v pkexec >/dev/null 2>&1 \
      && pkexec systemctl enable --now docker >&2 \
      && pkexec "$docker_bin" info >/dev/null 2>&1; then
    docker_cmd=(pkexec "$docker_bin")
    return
  fi

  fail "Docker is installed, but its service is not available. Start Docker and try again."
}

docker_exec() {
  "${docker_cmd[@]}" "$@"
}

wait_for_server() {
  local attempt
  for ((attempt = 0; attempt < 45; attempt++)); do
    if python3 - "$SERVER_URL" >/dev/null 2>&1 <<'PY'
import sys
import urllib.request

try:
    with urllib.request.urlopen(sys.argv[1], timeout=2) as response:
        raise SystemExit(0 if response.status < 500 else 1)
except Exception:
    raise SystemExit(1)
PY
    then
      return 0
    fi
    sleep 2
  done
  return 1
}

ensure_docker

if ! mkdir -p "$CONFIG_DIR" || ! chmod 700 "$CONFIG_DIR"; then
  fail "The local Home Assistant data directory could not be created."
fi

if docker_exec container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
  managed="$(docker_exec container inspect \
    --format '{{ index .Config.Labels "io.omarchy.homeassistant-ac.managed" }}' \
    "$CONTAINER_NAME" 2>/dev/null || true)"
  if [[ "$managed" != "true" ]]; then
    fail "A different Docker container already uses the name $CONTAINER_NAME."
  fi

  running="$(docker_exec container inspect --format '{{.State.Running}}' \
    "$CONTAINER_NAME" 2>/dev/null || true)"
  if [[ "$running" != "true" ]]; then
    if ! docker_exec start "$CONTAINER_NAME" >&2; then
      fail "The existing Home Assistant container could not be started."
    fi
  fi

  if wait_for_server; then
    json_result true ready "Home Assistant is already running locally." true
  else
    json_result true starting "The Home Assistant container is running and is still starting up." false
  fi
  exit 0
fi

if ! docker_exec image inspect "$IMAGE" >/dev/null 2>&1; then
  if ! docker_exec pull "$IMAGE" >&2; then
    fail "The official Home Assistant image could not be downloaded. Check your internet connection."
  fi
fi

run_args=(
  run
  --detach
  --name "$CONTAINER_NAME"
  --restart unless-stopped
  --stop-timeout 60
  --network host
  --label "$MANAGED_LABEL=true"
  --volume "$CONFIG_DIR:/config"
)
if [[ -e /etc/localtime ]]; then
  run_args+=(--volume "/etc/localtime:/etc/localtime:ro")
fi
timezone=""
if [[ -L /etc/localtime ]]; then
  timezone="$(readlink /etc/localtime | sed 's#^.*/zoneinfo/##')"
fi
if [[ -n "$timezone" && "$timezone" != "/etc/localtime" ]]; then
  run_args+=(--env "TZ=$timezone")
fi
run_args+=("$IMAGE")

if ! docker_exec "${run_args[@]}" >&2; then
  fail "Home Assistant could not be started in Docker."
fi

if wait_for_server; then
  json_result true installed "Home Assistant is running locally. Finish its browser setup, then create a long-lived token for Daikin Air." true
else
  json_result true starting "The Home Assistant container started. It may need a little longer before the browser page responds." false
fi
