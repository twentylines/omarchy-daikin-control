# External server history

Use external history when the Omarchy PC may sleep, shut down, or restart but
you still want the temperature chart to keep recording.

The external server must be the **same Linux host that runs Home Assistant**.
The logger calls that host's local Home Assistant API once per minute, and the
plugin reads the resulting history file over SSH. An unrelated SSH machine
cannot provide this chart data.

This guide is written for an Omarchy PC and a Linux Home Assistant host. The
Home Assistant host needs Python 3, an SSH server, and systemd user services.
Home Assistant OS or another appliance that does not provide a normal Linux
user systemd environment is not supported by this logger.

The setup is user-owned. It does not use `sudo`, install packages, open ports,
enable SSH forwarding, create a tunnel, call Home Assistant control endpoints,
or send telemetry.

## Quick setup

There are two machines involved:

- **Omarchy PC:** owns the SSH private key and runs the plugin.
- **Home Assistant host:** owns the logger, token, history file, and timer.

Complete the steps in order. Do not continue to the plugin until the final SSH
test prints `SSH key authentication works`.

### 1. Prepare the Omarchy PC

Open a terminal on the Omarchy PC. Edit only `target` and `port` in this block.
The target is an SSH login such as `user@192.168.1.20`; the port is entered
separately. Do **not** put `:22`, `http://`, or `ssh://` in `target`.

This block is safe to run again. It keeps an existing private key instead of
generating a different one.

```bash
target="user@192.168.1.20"
port="22"
identity="$HOME/.ssh/omarchy-homeassistant-ac"
agent_socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ssh-agent.socket"

install -d -m 700 "$HOME/.ssh"

if [[ -e "$identity" ]]; then
  echo "Keeping existing SSH key: $identity"
else
  ssh-keygen -t ed25519 -f "$identity" -C "omarchy-homeassistant-ac"
fi

if [[ ! -e "$identity.pub" ]]; then
  ssh-keygen -y -f "$identity" > "$identity.pub"
fi
chmod 600 "$identity"
chmod 644 "$identity.pub"

# Omarchy's plugin is a GUI process, so use a stable per-user agent socket.
# This keeps a passphrase-protected key encrypted on disk while the agent is
# unlocked for the desktop session.
systemctl --user enable --now ssh-agent.socket
if [[ ! -S "$agent_socket" ]]; then
  echo "The SSH agent socket did not start: $agent_socket" >&2
  exit 1
fi

SSH_AUTH_SOCK="$agent_socket" ssh-add "$identity"
SSH_AUTH_SOCK="$agent_socket" ssh-add -l
```

When `ssh-keygen` asks for a passphrase, use a strong one. The private key
stays on the Omarchy PC; the agent holds the unlocked key for this user
session. The plugin recognizes this standard socket even when the Quickshell
GUI did not inherit a terminal's `SSH_AUTH_SOCK`.

A blank passphrase is supported but is weaker: anyone who obtains the private
key file can use it. The old guide forced a blank passphrase; this guide does
not. Never upload the private key or paste it into the Home Assistant host.

### 2. Authorize the key on the Home Assistant host

Run this on the Omarchy PC in the same terminal. It may ask for the normal
password of the remote SSH user once. It may also ask you to confirm the
server's host fingerprint; verify that fingerprint before accepting it.

```bash
SSH_AUTH_SOCK="$agent_socket" ssh-copy-id \
  -p "$port" \
  -i "$identity.pub" \
  "$target"
```

If the key was already authorized, `ssh-copy-id` is not needed again. If it is
not available, add the single line from `"$identity.pub"` to the remote user's
`~/.ssh/authorized_keys` using that host's normal SSH administration process.

### 3. Prove non-interactive SSH works

This is the gate for the rest of setup. It must finish without asking for a
password or passphrase:

```bash
SSH_AUTH_SOCK="$agent_socket" ssh \
  -p "$port" \
  -o BatchMode=yes \
  -o IdentitiesOnly=yes \
  -o ConnectTimeout=8 \
  -i "$identity" \
  "$target" \
  'printf "SSH key authentication works\\n"'
```

If it fails, fix SSH before opening the plugin. The common causes are a wrong
user/host/port, a key that was not authorized, or a key that was added to a
different agent socket.

### 4. Configure the plugin

For a fresh install, install the plugin first:

```bash
omarchy plugin add https://github.com/twentylines/omarchy-daikin-control.git --enable
```

Then open **Daikin AC Controls → Settings** and complete the normal Home
Assistant setup first. The plugin needs a Home Assistant URL and a long-lived
token before it can display the AC state. The token is stored locally with
owner-only permissions.

In **Preferences**:

1. Enable **Ambient temperature chart**.
2. Choose **EXTERNAL SERVER** as the history source.
3. Enter the same SSH target from step 1, for example `user@192.168.1.20`.
4. Enter the SSH port in the separate port field, for example `22`.
5. Enter the Home Assistant URL as seen **from the Home Assistant host**.
   Usually this is `http://127.0.0.1:8123`.

Use the correct button for the state of the remote host:

| Button | Use it when | What it changes remotely |
| --- | --- | --- |
| **CONNECT TO SERVER** | The logger/timer is already installed | Nothing. It verifies SSH, checks the configured history path, and saves the pairing locally. It does not copy files, send the token, or reinstall the timer. |
| **INSTALL / UPDATE TIMER** | First-time setup, or the logger/token/path needs changing | Copies the reviewed logger and installer, writes the token-bearing config through SSH standard input, installs/updates the user timer, and runs one sample. |

If you are reconnecting after reinstalling the plugin, use **RECONNECT / CHANGE**
and then **CONNECT TO SERVER**. Do not use the install button merely to
reconnect to a timer that already exists.

The first successful SSH connection may still show no chart data until the
remote timer writes its first sample. The plugin only shows **CONNECTED** and a
latency after a real history read succeeds; an invalid or unavailable server
does not get a green status or a made-up ping.

## What the installer creates

On the Home Assistant host, **INSTALL / UPDATE TIMER** creates or updates only
these user-owned paths:

- `~/.local/bin/omarchy-homeassistant-ac-history.py`
- `~/.local/bin/install-omarchy-homeassistant-ac-history.sh`
- `~/.config/omarchy/homeassistant-ac-history.json` — mode `600`, contains the
  Home Assistant token
- `~/.config/systemd/user/omarchy-homeassistant-ac-history.service`
- `~/.config/systemd/user/omarchy-homeassistant-ac-history.timer`
- `~/.local/state/omarchy/homeassistant-ac-temperature.json` — mode `600`

The logger discovers every currently available `climate.*` entity, skips
unavailable entities, writes history atomically, and retains up to 31 days.
Changing which ACs are selected in the plugin does not require a reinstall.

The installer attempts to enable user lingering without administrator access so
the timer can continue while that user is logged out. If the host's policy
does not permit lingering or the user systemd manager is unavailable, the
installer reports that limitation instead of using `sudo`.

## Verify the remote timer

Run these from the Omarchy PC after installing. They use the same variables
from step 1:

```bash
SSH_AUTH_SOCK="$agent_socket" ssh \
  -p "$port" \
  -o BatchMode=yes \
  -o IdentitiesOnly=yes \
  -i "$identity" \
  "$target" \
  'systemctl --user is-enabled omarchy-homeassistant-ac-history.timer && \
   systemctl --user is-active omarchy-homeassistant-ac-history.timer'

SSH_AUTH_SOCK="$agent_socket" ssh \
  -p "$port" \
  -o BatchMode=yes \
  -o IdentitiesOnly=yes \
  -i "$identity" \
  "$target" \
  'journalctl --user -u omarchy-homeassistant-ac-history.service -n 30 --no-pager'
```

The expected history path is:

```text
~/.local/state/omarchy/homeassistant-ac-temperature.json
```

If the timer is active but the file is missing, start one sample manually on
the Home Assistant host:

```bash
systemctl --user start omarchy-homeassistant-ac-history.service
```

## Reconnect, update, or remove

- **Reconnect:** use **RECONNECT / CHANGE**, enter the target and port, then
  choose **CONNECT TO SERVER**. Existing remote files are kept.
- **Update:** choose **INSTALL / UPDATE TIMER** only when the logger, token,
  Home Assistant URL, or history path needs changing.
- **Remove the remote logger:** use **Maintenance → Uninstall → Remove app +
  logger**, or run the reviewed `uninstall-remote-history.sh` script. It stops
  and removes only this plugin's named user units and files.
- **Remove only the plugin:** choose **Remove plugin only**. The external
  logger and Home Assistant resources remain untouched.

The install and cleanup operations are scoped to the named plugin files. They
do not remove Home Assistant, Docker, unrelated services, or other server
data.

## Troubleshooting

### `Could not open a connection to your authentication agent`

Use the standard Omarchy user socket, not a temporary terminal agent:

```bash
identity="$HOME/.ssh/omarchy-homeassistant-ac"
agent_socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ssh-agent.socket"
systemctl --user enable --now ssh-agent.socket
SSH_AUTH_SOCK="$agent_socket" ssh-add "$identity"
SSH_AUTH_SOCK="$agent_socket" ssh-add -l
```

The plugin recognizes the same socket. No `eval`, Hyprland config edit, or
`omarchy restart shell` is required for this setup.

### `Permission denied (publickey)`

The target, port, or remote user is wrong, or the public key is not in that
user's `~/.ssh/authorized_keys`. Re-run step 2 and step 3. Do not generate a
new key unless the private key file is actually missing.

### `Could not resolve hostname`

Check the SSH address. Enter `user@host` in the address field and `22` in the
port field. `host:22`, `http://host`, and `ssh://host` are not valid values for
the SSH address field.

### The terminal prints `^[[200~` or a command ends with an extra `~`

Those are terminal paste-control characters, not part of the command. Press
`Ctrl+C`, copy only the text inside the code block, and paste with the
terminal's normal paste shortcut. Do not copy the shell prompt (`~ ❯`) or the
backticks around a code block.

### The app says `NOT CONFIGURED`, `NOT VERIFIED`, or `UNAVAILABLE`

- **NOT CONFIGURED:** no SSH target has been saved yet; fill in the address and
  port.
- **NOT VERIFIED:** the address, port, or history path changed after the last
  successful check; choose **CONNECT TO SERVER**.
- **UNAVAILABLE:** the last history read failed. Run step 3, then verify the
  timer and service log. If the timer has never been installed, choose
  **INSTALL / UPDATE TIMER** once.

The app deliberately does not show **CONNECTED** or a latency when the current
server cannot be read.

### The first sample fails

On the Home Assistant host, inspect:

```bash
journalctl --user -u omarchy-homeassistant-ac-history.service -n 50 --no-pager
```

Confirm that the URL works from that host, the long-lived token can read
`/api/states`, at least one available `climate.*` entity exists, and the host
provides Python 3 plus systemd user services.

### I followed the old blank-passphrase guide

If the existing key is already authorized and you want to protect it, add a
passphrase without changing the public key:

```bash
identity="$HOME/.ssh/omarchy-homeassistant-ac"
ssh-keygen -p -f "$identity"
agent_socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ssh-agent.socket"
systemctl --user enable --now ssh-agent.socket
SSH_AUTH_SOCK="$agent_socket" ssh-add "$identity"
SSH_AUTH_SOCK="$agent_socket" ssh-add -l
```

You do not need to run `ssh-keygen` or `ssh-copy-id` again just because a
passphrase was added; the public key did not change.

## Review the source

The plugin's exact reviewable files are:

- [`remote-history-logger.py`](remote-history-logger.py)
- [`install-remote-history.sh`](install-remote-history.sh)
- [`uninstall-remote-history.sh`](uninstall-remote-history.sh)
- [`uninstall-plugin.sh`](uninstall-plugin.sh)

The plugin's **COPY SOURCE** action copies the current installer, logger, and
cleanup source to the clipboard.
