# External server history

External history keeps recording while the Omarchy PC sleeps, shuts down, or
restarts. The logger runs on the Linux host that runs Home Assistant, records
one temperature sample per minute, and the plugin reads the resulting file
over SSH.

> **Important:** the external server must be the same host that runs Home
> Assistant. The logger uses that host's local Home Assistant API; an unrelated
> SSH machine cannot provide this history.

## What you need

- A Linux Home Assistant host that is powered on when samples should be saved.
- Python 3 and systemd user services on that host.
- SSH access from the Omarchy PC to that host.
- A dedicated, passwordless SSH key for this plugin.
- A Home Assistant long-lived token that can read the climate states.

The installer is user-owned. It does not use `sudo`, install packages, open
ports, call Home Assistant control endpoints, or send telemetry.

## 1. Prepare SSH access

Run these commands on the Omarchy PC. Replace `user@192.168.1.20` and `22`
with the SSH user, address, and port of the Home Assistant host.

Create the dedicated key once. Do not run `ssh-keygen` again if the file
already exists:

```bash
ssh-keygen -t ed25519 -N "" \
  -f ~/.ssh/omarchy-homeassistant-ac \
  -C "omarchy-homeassistant-ac"
```

The empty passphrase is intentional: the plugin uses non-interactive SSH.
The private key stays on the Omarchy PC and is not copied to the server.

Authorize the public key on the Home Assistant host. This one-time command
may ask for the server user's normal login password:

```bash
ssh-copy-id -p 22 -i ~/.ssh/omarchy-homeassistant-ac.pub \
  user@192.168.1.20
```

Verify that the dedicated key works without a password prompt:

```bash
ssh -p 22 -o BatchMode=yes -o IdentitiesOnly=yes \
  -i ~/.ssh/omarchy-homeassistant-ac \
  user@192.168.1.20 true
```

If this command succeeds, the plugin can use the same target and port. If
`ssh-copy-id` is unavailable, add the `.pub` file's single line to the remote
user's `~/.ssh/authorized_keys` using the server's normal SSH login process.

## 2. Recommended installation from the plugin

1. Open **Daikin AC Controls → Settings → Preferences**.
2. Enable **Ambient temperature chart**.
3. Set **History Source** to **EXTERNAL SERVER**.
4. Enter the SSH target, such as `user@192.168.1.20`, and its port.
5. Enter the Home Assistant URL as seen from the external host. This is often
   `http://127.0.0.1:8123`, but use the address that actually works from that
   host.
6. Choose **INSTALL SERVER TIMER**.

The plugin copies the reviewable logger and installer over encrypted SSH,
writes the token-bearing config through SSH standard input, installs the
user-owned timer, and performs the first sample. It automatically uses
`~/.ssh/omarchy-homeassistant-ac` when that key exists.

The logger discovers every available `climate.*` entity on each sample,
skipping entities that Home Assistant reports as unavailable. The plugin still
decides which entity or multi-AC average appears in the chart.

## 3. Verify the timer

From the Omarchy PC, inspect the timer and its first run:

```bash
ssh -p 22 -o BatchMode=yes -o IdentitiesOnly=yes \
  -i ~/.ssh/omarchy-homeassistant-ac user@192.168.1.20 \
  'systemctl --user is-enabled omarchy-homeassistant-ac-history.timer && \
   systemctl --user is-active omarchy-homeassistant-ac-history.timer'

ssh -p 22 -o BatchMode=yes -o IdentitiesOnly=yes \
  -i ~/.ssh/omarchy-homeassistant-ac user@192.168.1.20 \
  'journalctl --user -u omarchy-homeassistant-ac-history.service -n 30 --no-pager'
```

The default history file is:

```text
~/.local/state/omarchy/homeassistant-ac-temperature.json
```

After the first successful sample, choose **EXTERNAL SERVER** in the plugin
and refresh the chart. The file is kept owner-only and retains up to 31 days
of samples.

## Manual installation

Use this only if you want to review and run each step yourself. These commands
assume the server uses the default `~/.config` and `~/.local` directories.
From a checkout of this repository on the Omarchy PC:

```bash
cd /path/to/omarchy-daikin-control

target="user@192.168.1.20"
port="22"
identity="$HOME/.ssh/omarchy-homeassistant-ac"

ssh -p "$port" -o IdentitiesOnly=yes -i "$identity" "$target" \
  'umask 077; mkdir -p "$HOME/.local/bin" "$HOME/.config/omarchy"'

scp -P "$port" -o IdentitiesOnly=yes -i "$identity" \
  remote-history-logger.py \
  "$target:.local/bin/omarchy-homeassistant-ac-history.py"

scp -P "$port" -o IdentitiesOnly=yes -i "$identity" \
  install-remote-history.sh \
  "$target:.local/bin/install-omarchy-homeassistant-ac-history.sh"

ssh -p "$port" -o IdentitiesOnly=yes -i "$identity" "$target" \
  'chmod 700 "$HOME/.local/bin/omarchy-homeassistant-ac-history.py" \
   "$HOME/.local/bin/install-omarchy-homeassistant-ac-history.sh"'
```

Keep this shell open while following the remaining manual steps; `target`,
`port`, and `identity` are reused below. If the server uses `XDG_CONFIG_HOME`
or `XDG_STATE_HOME`, use those same locations in the commands and config.

Create the config on the external host. Use an editor through SSH so the token
does not appear in the shell history or in a process argument:

```bash
ssh -t -p "$port" -o IdentitiesOnly=yes -i "$identity" "$target" \
  'umask 077; mkdir -p "$HOME/.config/omarchy"; \
   touch "$HOME/.config/omarchy/homeassistant-ac-history.json"; \
   chmod 600 "$HOME/.config/omarchy/homeassistant-ac-history.json"; \
   ${EDITOR:-vi} "$HOME/.config/omarchy/homeassistant-ac-history.json"'
```

Use this JSON shape. Replace the URL and token; `record_all_entities` should
remain `true` unless you deliberately want a fixed entity list:

```json
{
  "url": "http://127.0.0.1:8123",
  "token": "YOUR_HOME_ASSISTANT_LONG_LIVED_TOKEN",
  "record_all_entities": true,
  "history_path": "~/.local/state/omarchy/homeassistant-ac-temperature.json"
}
```

If you set `record_all_entities` to `false`, also add `entity_id` or
`entity_ids`, for example: `"entity_ids": ["climate.living_room"]`.

Run the supplied installer on the external host:

```bash
ssh -p "$port" -o IdentitiesOnly=yes -i "$identity" "$target" \
  '~/.local/bin/install-omarchy-homeassistant-ac-history.sh'
```

The installer creates the user service and timer, enables the timer, and runs
one sample immediately. If you create the systemd units yourself, use the
definitions in [`install-remote-history.sh`](install-remote-history.sh), then
run these commands on the external host:

```bash
systemctl --user daemon-reload
systemctl --user enable --now omarchy-homeassistant-ac-history.timer
systemctl --user start omarchy-homeassistant-ac-history.service
```

## What gets installed

On the external host, the installer creates:

- `~/.local/bin/omarchy-homeassistant-ac-history.py`
- `~/.local/bin/install-omarchy-homeassistant-ac-history.sh`
- `~/.config/omarchy/homeassistant-ac-history.json` — mode `600`, contains
  the Home Assistant token
- `~/.config/systemd/user/omarchy-homeassistant-ac-history.service`
- `~/.config/systemd/user/omarchy-homeassistant-ac-history.timer`
- `~/.local/state/omarchy/homeassistant-ac-temperature.json` — mode `600`

The logger performs a read-only `GET /api/states`, skips unavailable climate
entities, and writes the history atomically. It never sends AC control
commands.

If the Home Assistant URL, token, or logger source changes, run
**INSTALL SERVER TIMER** again. Changing which ACs are selected in the plugin
does not require reinstalling because discovery runs on every sample.

If the server's user systemd manager is not available over SSH, or if lingering
cannot be enabled, the timer may only run while that user has an active
session. The installer reports this rather than requesting administrator
access.

## Reconfigure or remove it

For a paired installation, use **Preferences → EXTERNAL SERVER → RECONFIGURE**
and install again. To remove the remote logger from the plugin, choose
**Maintenance → Uninstall → Remove app + logger** or **Remove everything**.

To remove only the remote logger manually from the Omarchy PC, run the cleanup
script from the repository. It stops the named user timer and removes only the
plugin-managed files:

```bash
ssh -p "$port" -o BatchMode=yes -o IdentitiesOnly=yes \
  -i "$identity" "$target" \
  'bash -s -- --history-path "~/.local/state/omarchy/homeassistant-ac-temperature.json"' \
  < uninstall-remote-history.sh
```

The cleanup script does not remove Home Assistant, Docker, unrelated user
services, or other server data. **Remove plugin only** leaves the external
logger untouched.

## Troubleshooting

### SSH key setup is incomplete

Run the passwordless test from [step 1](#1-prepare-ssh-access) using the same
port entered in the plugin. The plugin uses `BatchMode=yes`, so an interactive
password prompt is treated as a failed setup.

### The timer is inactive or stops after logout

On the external host, check:

```bash
systemctl --user status omarchy-homeassistant-ac-history.timer
loginctl show-user "$USER" -p Linger
```

The installer attempts to enable user lingering without `sudo`. If the host's
policy does not allow that, ask its administrator or keep a user session active
while the timer runs.

### No samples are appearing

Inspect the service log:

```bash
journalctl --user -u omarchy-homeassistant-ac-history.service -n 50 --no-pager
```

Confirm that the Home Assistant URL works from the external host, the token can
read `/api/states`, and at least one available `climate.*` entity has a
`current_temperature` attribute.

## Review the source

The exact files used by the plugin are available here:

- [`remote-history-logger.py`](remote-history-logger.py)
- [`install-remote-history.sh`](install-remote-history.sh)
- [`uninstall-remote-history.sh`](uninstall-remote-history.sh)
- [`uninstall-plugin.sh`](uninstall-plugin.sh)

The plugin's **COPY SOURCE** action copies the current installer, logger, and
cleanup source to the clipboard for review.
