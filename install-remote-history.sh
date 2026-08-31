#!/usr/bin/env bash
set -euo pipefail

# Safe by design: this installs only user-owned files and a user systemd timer.
# It does not use sudo, install packages, open ports, send telemetry, or call
# Home Assistant control endpoints. Review this file before running it.

umask 077

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
logger_path="$HOME/.local/bin/omarchy-homeassistant-ac-history.py"
config_path="$config_home/omarchy/homeassistant-ac-history.json"
service_dir="$config_home/systemd/user"
service_path="$service_dir/omarchy-homeassistant-ac-history.service"
timer_path="$service_dir/omarchy-homeassistant-ac-history.timer"

if [[ ! -x "$logger_path" ]]; then
  echo "Logger not found at $logger_path" >&2
  exit 2
fi
if [[ ! -f "$config_path" ]]; then
  echo "Logger config not found at $config_path" >&2
  exit 2
fi

mkdir -p "$service_dir"
chmod 600 "$config_path"

if ! command -v systemctl >/dev/null 2>&1; then
  echo "This host needs systemd user services to keep the logger running." >&2
  exit 3
fi

runtime_dir="/run/user/$(id -u)"
if [[ -z "${XDG_RUNTIME_DIR:-}" && -d "$runtime_dir" ]]; then
  export XDG_RUNTIME_DIR="$runtime_dir"
fi

# Linger lets the user timer continue while nobody is logged into the server.
# This is best-effort and visible: no privilege escalation is attempted here.
if command -v loginctl >/dev/null 2>&1; then
  if ! loginctl enable-linger "$(id -un)" >/dev/null 2>&1; then
    echo "Notice: could not enable user lingering; the timer may pause when logged out." >&2
  fi
fi

cat > "$service_path" <<'SERVICE'
[Unit]
Description=Omarchy Home Assistant AC history sample

[Service]
Type=oneshot
ExecStart=%h/.local/bin/omarchy-homeassistant-ac-history.py
SERVICE

cat > "$timer_path" <<'TIMER'
[Unit]
Description=Record Omarchy Home Assistant AC history

[Timer]
OnBootSec=20s
OnUnitActiveSec=60s
Persistent=true
Unit=omarchy-homeassistant-ac-history.service

[Install]
WantedBy=timers.target
TIMER

if ! systemctl --user daemon-reload; then
  echo "The user systemd bus is unavailable. Enable lingering for this SSH user and run the installer again." >&2
  exit 3
fi
systemctl --user enable --now omarchy-homeassistant-ac-history.timer
if ! systemctl --user start omarchy-homeassistant-ac-history.service; then
  echo "The timer is installed, but the first sample failed." >&2
  echo "Inspect it with: systemctl --user status omarchy-homeassistant-ac-history.service" >&2
  echo "See details with: journalctl --user -u omarchy-homeassistant-ac-history.service" >&2
  exit 4
fi

echo "External Home Assistant history timer installed for $USER."
echo "It discovers every available Home Assistant climate entity and records temperatures once per minute on this host."
echo "The logger keeps up to 31 days of samples in the owner-selected path (mode 600)."
echo "No sudo, package installation, open port, telemetry, or Home Assistant control call was used."
