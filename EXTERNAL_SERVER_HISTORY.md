# External server history

The optional external history logger records the temperature chart on the
Linux host that runs Home Assistant. That lets the chart continue recording
while the Omarchy PC sleeps, shuts down, or restarts.

> **Important:** the external server must be the same host that runs Home
> Assistant. The logger reads Home Assistant through that host's local API; a
> different SSH machine cannot provide this history.

## What you need

- A Linux Home Assistant host that is powered on when readings should be
  recorded.
- Python 3 and a systemd user service manager on that host.
- A dedicated SSH key for the logger from the Omarchy PC to the Home Assistant
  host, without a password prompt.
- The Home Assistant URL as seen from the external host, usually
  `http://127.0.0.1:8123`.

## One-time SSH key setup

The plugin does not collect or store an SSH password. If you currently log in
with a password, keep the same SSH target and authorize a dedicated logger key
once. This leaves any existing `~/.ssh/id_ed25519` key unchanged:

1. On the Omarchy PC, create a key if you do not already have one:

   ```bash
   ssh-keygen -t ed25519 -N "" -f ~/.ssh/omarchy-homeassistant-ac -C "omarchy-homeassistant-ac"
   ```

   The empty passphrase is intentional: the logger and the plugin must be
   able to connect without an interactive prompt. The private key is created
   with owner-only permissions and is used only for this plugin's server
   history connection.

2. Copy the public key to the Home Assistant host using the normal login
   password:

   ```bash
   ssh-copy-id -i ~/.ssh/omarchy-homeassistant-ac.pub sai@192.168.0.10
   ```

   Replace `sai@192.168.0.10` with your server's SSH target if needed. The
   password is used by `ssh-copy-id` only to add the public key to that user's
   `~/.ssh/authorized_keys`; it is never entered into the plugin. The
   password-protected `id_ed25519` key is not used by this feature.

3. Verify that key authentication works without a password prompt:

   ```bash
   ssh -o BatchMode=yes -o IdentitiesOnly=yes \
     -i ~/.ssh/omarchy-homeassistant-ac sai@192.168.0.10 true
   ```

   If that succeeds, use the same target in the plugin and choose **INSTALL
   SERVER TIMER**. The plugin automatically uses
   `~/.ssh/omarchy-homeassistant-ac` when it exists. If `ssh-copy-id` is
   unavailable, install it through your normal OpenSSH package or follow your
   distribution's documented `authorized_keys` setup instead.

## Install from the plugin

1. Open **Daikin AC Controls → Settings → Preferences**.
2. Set **History Source** to **EXTERNAL SERVER**.
3. Enter the SSH target and port for the Home Assistant host.
4. Enter the Home Assistant URL reachable from that host.
5. Review the source files, then choose **INSTALL SERVER TIMER**.

The plugin sends the selected Home Assistant token through encrypted SSH
standard input. It is not placed in a command-line argument. The installer
then creates a user-owned service and timer on the external host.

## What gets installed

The installer copies these reviewable files to the SSH user's home directory:

- `~/.local/bin/omarchy-homeassistant-ac-history.py`
- `~/.local/bin/install-omarchy-homeassistant-ac-history.sh`

It also creates:

- `~/.config/omarchy/homeassistant-ac-history.json` — the token-bearing
  configuration, mode `600`.
- `~/.config/systemd/user/omarchy-homeassistant-ac-history.service` — one
  read-only sample job.
- `~/.config/systemd/user/omarchy-homeassistant-ac-history.timer` — one sample
  per minute.
- The owner-only 24-hour JSON history file at the path selected in Preferences.

The logger reads one climate state from the local Home Assistant API and
writes the chart history. It does not send AC control commands.

## Scope and review

The installer is deliberately narrow:

- It uses no `sudo`, package installation, open port, cloud service, or usage
  analytics.
- It uses Python's standard library and a read-only Home Assistant state
  request.
- It creates only the named user files and user systemd units above.
- Its best-effort `loginctl enable-linger` step only lets the user timer run
  while nobody is logged in; it does not request administrator approval.

Use **COPY SOURCE** in the plugin to place the exact current installer,
logger, and cleanup source in the clipboard for review. The files are also
available directly in this repository:

- [`remote-history-logger.py`](remote-history-logger.py)
- [`install-remote-history.sh`](install-remote-history.sh)
- [`uninstall-remote-history.sh`](uninstall-remote-history.sh)
- [`uninstall-local-homeassistant.sh`](uninstall-local-homeassistant.sh)
- [`uninstall-plugin.sh`](uninstall-plugin.sh)

## Uninstall scopes

The plugin's **Maintenance → Uninstall Plugin** action has three separately
confirmed choices:

### Remove everything

Removes the plugin, its saved data, the configured external logger, and the
plugin-managed local Home Assistant container and data if present.

Local cleanup refuses to remove a same-named Docker container unless it has
the plugin management label. Docker itself, the Home Assistant image,
unrelated containers, and unrelated data remain untouched.

### Remove app + logger

Removes the plugin, its saved connection and local chart, and the configured
external logger. It leaves a local Home Assistant container and its data
untouched.

### Remove plugin only

Removes only the installed plugin files. It leaves plugin data, local Home
Assistant resources, and external history untouched.

External cleanup is idempotent: if the logger was never installed or has
already been removed, the cleanup reports that nothing matching was found and
continues. It removes only the named logger, installer, config, user service,
user timer, and selected history file.

## Inspect the timer

On the external Home Assistant host:

```bash
systemctl --user status omarchy-homeassistant-ac-history.timer
journalctl --user -u omarchy-homeassistant-ac-history.service
```

If the timer is not running, confirm that the SSH user has a user systemd
manager and that the Home Assistant URL in the logger config is reachable from
that host.
