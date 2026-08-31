#!/usr/bin/env bash
set -euo pipefail

# This is the local, user-triggered uninstall entry point for the plugin.
# It removes only this plugin and the cleanup items explicitly selected by the
# user. It never removes an unmanaged container, Docker itself, the Home
# Assistant image, or unrelated Home Assistant data.

PLUGIN_ID="sai.homeassistant-ac"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'USAGE'
Usage: uninstall-plugin.sh [options]

Options:
  --remove-local-data       Remove the plugin's saved config and local chart.
  --remove-external-history Remove the configured external history installation.
  --remove-local-homeassistant Remove the plugin-managed local Home Assistant container/data.
  --remove-everything       Select all cleanup actions above.
  --ssh-target TARGET       SSH target for external history cleanup.
  --ssh-port PORT           SSH port for external history cleanup (default: 22).
  --history-path PATH       External history path (default: ~/.local/state/omarchy/homeassistant-ac-temperature.json).
USAGE
}

die() {
  echo "Uninstall stopped: $1" >&2
  exit 2
}

remove_local_data=0
remove_external_history=0
remove_local_homeassistant=0
ssh_target=""
ssh_port="22"
history_path="~/.local/state/omarchy/homeassistant-ac-temperature.json"

while (($# > 0)); do
  case "$1" in
    --remove-local-data)
      remove_local_data=1
      shift
      ;;
    --remove-external-history)
      remove_external_history=1
      shift
      ;;
    --remove-local-homeassistant)
      remove_local_homeassistant=1
      shift
      ;;
    --remove-everything)
      remove_local_data=1
      remove_external_history=1
      remove_local_homeassistant=1
      shift
      ;;
    --ssh-target)
      (($# >= 2)) || die "--ssh-target needs a value"
      ssh_target="$2"
      shift 2
      ;;
    --ssh-port)
      (($# >= 2)) || die "--ssh-port needs a value"
      ssh_port="$2"
      shift 2
      ;;
    --history-path)
      (($# >= 2)) || die "--history-path needs a value"
      history_path="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

if ! command -v omarchy >/dev/null 2>&1; then
  die "the Omarchy command was not found"
fi

if ((remove_external_history == 1)); then
  [[ "$ssh_target" =~ ^[A-Za-z0-9_.:@\-\[\]]+$ ]] || die "the SSH target is invalid"
  [[ "$ssh_target" == *@* && "$ssh_target" != *"@"*"@"* ]] || die "the SSH target must look like user@host"
  [[ "$ssh_port" =~ ^[0-9]+$ ]] || die "the SSH port must be a number between 1 and 65535"
  ((10#$ssh_port >= 1 && 10#$ssh_port <= 65535)) || die "the SSH port must be a number between 1 and 65535"
  if [[ "$history_path" == "~/*" ]]; then
    :
  elif [[ "$history_path" == /* ]]; then
    :
  else
    die "the history path must start with ~/ or /"
  fi
  [[ "$history_path" =~ ^[A-Za-z0-9_./~_-]+$ ]] || die "the history path contains unsupported characters"
  [[ "$history_path" != *..* ]] || die "the history path cannot contain .."
  [[ -f "$SCRIPT_DIR/uninstall-remote-history.sh" ]] || die "the external cleanup script is missing"
fi
if ((remove_local_homeassistant == 1)); then
  [[ -f "$SCRIPT_DIR/uninstall-local-homeassistant.sh" ]] || die "the local Home Assistant cleanup script is missing"
fi

echo "Goodbye :( Removing Daikin AC Controls."

if ((remove_local_homeassistant == 1)); then
  if ! bash "$SCRIPT_DIR/uninstall-local-homeassistant.sh"; then
    echo "Local Home Assistant cleanup did not complete; the plugin is still installed." >&2
    exit 3
  fi
fi

if ((remove_external_history == 1)); then
  echo "Checking the external history installation on $ssh_target…"
  ssh_command=(
    ssh
    -T
    -o BatchMode=yes
    -o ConnectTimeout=8
    -o ServerAliveInterval=5
    -o ServerAliveCountMax=1
    -p "$ssh_port"
    "$ssh_target"
    bash -s --
    --history-path "$history_path"
  )
  if ! "${ssh_command[@]}" < "$SCRIPT_DIR/uninstall-remote-history.sh"; then
    echo "External history cleanup did not complete; the plugin is still installed." >&2
    exit 4
  fi
fi

if ((remove_local_data == 1)); then
  config_path="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/home-assistant-ac.json"
  history_file="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/home-assistant-ac-temperature.json"
  local_removed=0
  for path in "$config_path" "$history_file"; do
    if [[ -e "$path" || -L "$path" ]]; then
      rm -f -- "$path"
      local_removed=1
    fi
  done
  if ((local_removed == 1)); then
    echo "Local plugin data removed."
  else
    echo "No local plugin data was found."
  fi
fi

# Use Omarchy's supported removal path. It disables the plugin and preserves
# the normal handling for installed plugin directories; this script does not
# recursively delete the plugin directory itself.
if ! omarchy plugin remove "$PLUGIN_ID" --yes; then
  echo "The plugin could not be removed; review the Omarchy output and try again." >&2
  exit 5
fi

echo "Goodbye :( Daikin AC Controls has been removed."
