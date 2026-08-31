#!/usr/bin/env bash
set -euo pipefail

# Safe by design: this removes only the Home Assistant Container and data
# created by setup-homeassistant.sh. It refuses a container with the same name
# unless the plugin's management label is present. It does not remove Docker,
# the Home Assistant image, firewall rules, or any other container/data.

umask 077

if [[ -z "${HOME:-}" ]]; then
  echo "Local Home Assistant cleanup stopped: HOME is not set." >&2
  exit 2
fi

readonly CONTAINER_NAME="omarchy-homeassistant"
readonly MANAGED_LABEL="io.omarchy.homeassistant-ac.managed"
readonly DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
readonly CONFIG_DIR="${DATA_HOME}/omarchy/homeassistant"

if (($# > 0)); then
  case "$1" in
    --help|-h)
      echo "Usage: uninstall-local-homeassistant.sh"
      echo "Removes only the plugin-managed local Home Assistant container and data."
      exit 0
      ;;
    *)
      echo "Local Home Assistant cleanup stopped: unknown option: $1" >&2
      exit 2
      ;;
  esac
fi

if [[ "$CONFIG_DIR" != "$DATA_HOME/omarchy/homeassistant" || "$CONFIG_DIR" == "/" || "$CONFIG_DIR" == "$HOME" ]]; then
  echo "Local Home Assistant cleanup stopped: the data path is unsafe." >&2
  exit 2
fi

docker_bin="$(command -v docker || true)"
docker_cmd=()

if [[ -n "$docker_bin" ]]; then
  docker_cmd=("$docker_bin")
  if ! "${docker_cmd[@]}" info >/dev/null 2>&1; then
    if command -v pkexec >/dev/null 2>&1 && pkexec "$docker_bin" info >/dev/null 2>&1; then
      docker_cmd=(pkexec "$docker_bin")
    else
      echo "Local Home Assistant cleanup stopped: Docker is not available." >&2
      echo "No container or data was removed." >&2
      exit 3
    fi
  fi
else
  if [[ -e "$CONFIG_DIR" || -L "$CONFIG_DIR" ]]; then
    echo "Local Home Assistant cleanup stopped: Docker is not installed, so the container could not be checked." >&2
    echo "No local server data was removed." >&2
    exit 3
  fi
  echo "No plugin-managed local Home Assistant installation was found."
  exit 0
fi

docker_exec() {
  "${docker_cmd[@]}" "$@"
}

container_found=0
if docker_exec container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
  container_found=1
  managed="$(docker_exec container inspect \
    --format '{{ index .Config.Labels "io.omarchy.homeassistant-ac.managed" }}' \
    "$CONTAINER_NAME" 2>/dev/null || true)"
  if [[ "$managed" != "true" ]]; then
    echo "A different Docker container already uses the name $CONTAINER_NAME." >&2
    echo "Nothing was removed." >&2
    exit 4
  fi

  running="$(docker_exec container inspect --format '{{.State.Running}}' \
    "$CONTAINER_NAME" 2>/dev/null || true)"
  if [[ "$running" == "true" ]]; then
    echo "Stopping the plugin-managed Home Assistant container…"
    docker_exec stop --time 60 "$CONTAINER_NAME" >/dev/null
  fi
  docker_exec rm "$CONTAINER_NAME" >/dev/null
  echo "Plugin-managed Home Assistant container removed."
fi

if [[ -e "$CONFIG_DIR" || -L "$CONFIG_DIR" ]]; then
  echo "Removing plugin-managed Home Assistant data from $CONFIG_DIR…"
  rm -rf -- "$CONFIG_DIR"
  echo "Plugin-managed Home Assistant data removed."
elif ((container_found == 0)); then
  echo "No plugin-managed local Home Assistant installation was found."
fi

echo "Docker, the Home Assistant image, and other containers were left untouched."
