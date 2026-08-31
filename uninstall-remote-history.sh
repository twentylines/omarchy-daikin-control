#!/usr/bin/env bash
set -euo pipefail

# Safe by design: this removes only the user-owned history files created by
# install-remote-history.sh. It does not use sudo, remove packages, change
# firewall rules, touch Home Assistant data, or disable shared user lingering.
# Review this file before running it.

umask 077

usage() {
  cat <<'USAGE'
Usage: uninstall-remote-history.sh [--history-path PATH]

Removes the Omarchy AC external-history timer and its user-owned files.
USAGE
}

die() {
  echo "External history cleanup stopped: $1" >&2
  exit 2
}

default_history_path="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/homeassistant-ac-temperature.json"
history_path="$default_history_path"
while (($# > 0)); do
  case "$1" in
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

if [[ "$history_path" == "~/*" ]]; then
  history_path="$HOME/${history_path#~/}"
elif [[ "$history_path" != /* ]]; then
  die "history path must start with ~/ or /"
fi
if [[ ! "$history_path" =~ ^[A-Za-z0-9_./~_-]+$ ]] || [[ "$history_path" == *..* ]]; then
  die "history path contains unsupported characters"
fi

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
logger_path="$HOME/.local/bin/omarchy-homeassistant-ac-history.py"
installer_path="$HOME/.local/bin/install-omarchy-homeassistant-ac-history.sh"
config_path="$config_home/omarchy/homeassistant-ac-history.json"
service_dir="$config_home/systemd/user"
service_path="$service_dir/omarchy-homeassistant-ac-history.service"
timer_path="$service_dir/omarchy-homeassistant-ac-history.timer"

paths=(
  "$logger_path"
  "$installer_path"
  "$config_path"
  "$service_path"
  "$timer_path"
  "$history_path"
)
if [[ "$history_path" != "$default_history_path" ]]; then
  paths+=("$default_history_path")
fi

found=0
for path in "${paths[@]}"; do
  if [[ -e "$path" || -L "$path" ]]; then
    found=1
    break
  fi
done

if ((found == 0)); then
  echo "No matching external history installation was found."
  exit 0
fi

runtime_dir="/run/user/$(id -u)"
if [[ -z "${XDG_RUNTIME_DIR:-}" && -d "$runtime_dir" ]]; then
  export XDG_RUNTIME_DIR="$runtime_dir"
fi

# Stop the loaded units before deleting their definitions. Linger is deliberately
# left alone because other user services may depend on it.
if [[ -e "$service_path" || -e "$timer_path" ]]; then
  if ! command -v systemctl >/dev/null 2>&1; then
    die "systemctl is required to stop the installed user timer"
  fi
  if [[ -e "$timer_path" ]]; then
    if ! systemctl --user disable --now omarchy-homeassistant-ac-history.timer >/dev/null 2>&1; then
      echo "Could not stop the external history timer; no files were removed." >&2
      exit 3
    fi
  fi
  if [[ -e "$service_path" ]]; then
    if ! systemctl --user stop omarchy-homeassistant-ac-history.service >/dev/null 2>&1; then
      echo "Could not stop the external history service; no files were removed." >&2
      exit 3
    fi
  fi
  if ! systemctl --user daemon-reload >/dev/null 2>&1; then
    echo "Could not reload the user systemd manager; no files were removed." >&2
    exit 3
  fi
fi

removed=0
for path in "${paths[@]}"; do
  if [[ -e "$path" || -L "$path" ]]; then
    rm -f -- "$path"
    removed=1
  fi
done

if ((removed == 1)); then
  echo "External history logger removed for $USER."
  echo "Home Assistant, Docker, and other server data were not changed."
else
  echo "No matching external history installation was found."
fi
