# Omarchy Daikin Control

Daikin AC Controls puts your Home Assistant Daikin climate entity in the Omarchy bar:
see the room temperature, compare it with the target, adjust the set point,
and turn the air conditioner on or off without opening a dashboard.

The widget talks to Home Assistant's local REST API. It does not talk directly
to a Daikin unit or replace the Home Assistant Daikin integration. That makes
the widget deliberately small and dependable: if Home Assistant exposes your
unit as an available `climate.*` entity, Daikin AC Controls can control it.

## Install

Review the source before enabling it. Omarchy plugins run as unsandboxed code
inside the long-lived `omarchy-shell` process.

```bash
omarchy plugin add https://github.com/twentylines/omarchy-daikin-control.git --enable
```

The plugin ships its small Python helper and needs only `python3`, which is
available on a normal Omarchy install. It does not start a daemon or require a
cloud account by default. An optional local Home Assistant setup is available
below for computers that do not have a server yet.

## Updating

This plugin does not update itself in the background. When a new version is
published, update the Git-managed install with:

```bash
omarchy plugin update sai.homeassistant-ac --yes
```

The updated files are pulled into the local plugin directory and Omarchy
reloads them. If the new version does not appear, run `omarchy refresh shell`.

## First-run setup

Click the Daikin AC Controls glyph in the bar. The centered setup panel asks for:

1. Your Home Assistant base address, such as `http://homeassistant.local:8123`,
   `http://192.168.1.20:8123`, or an HTTPS reverse-proxy URL.
2. A Home Assistant long-lived access token. In Home Assistant, open your
   profile, go to **Security → Long-Lived Access Tokens**, choose **Create
   Token**, and copy the token immediately. Home Assistant only shows it once;
   paste it into Daikin AC Controls while the setup panel is open.
3. Which available climate entity to control when Home Assistant exposes more
   than one.

The connection is tested before anything is saved. A single available climate
entity is selected automatically; when there are several, the setup flow
offers a readable name plus the exact entity ID so there is no manual JSON
editing. The onboarding screen also lets you start with climate controls on
by default and optionally enable the MasterSwitch.

The token is sent to the bundled helper over stdin rather than as a command
line argument. It is stored at
`~/.config/omarchy/home-assistant-ac.json` with owner-only permissions (`600`),
never shown in the bar, and never printed by the helper. The helper sends
requests only to the Home Assistant address you entered.

To change the server, token, or selected entity later, open the panel and use
the small settings button in the hero card. Settings groups connection and
local-server setup together; **Preferences** can show supported climate modes
and fan speeds, choose whether the bar shows ambient temperature, target
temperature, or both, and enable the optional Ambient Temperature History
chart. **Experimental** contains the opt-in multi-aircon panel, extended
history ranges, and custom appearance controls. **Maintenance** contains
project help, reset controls, and uninstall options.

The chart keeps up to 31 days of ambient readings. By default it is a private
local log on this PC, so sleep, shutdown, network outages, and other gaps
remain empty. In **Settings → Preferences**, switch **History Source** to
**EXTERNAL SERVER** to install a server-side logger over SSH. The external
server must be the same host that runs Home Assistant; that is the only host
whose local API the logger can read. The chart then reads only the external
file and labels itself with that host's address; it never falls back to the
local log. A user systemd timer records once per minute while the external
Home Assistant host is on, so it can continue while this PC sleeps, shuts
down, or restarts.

Enter the SSH target (for example `sai@192.168.1.20`), the SSH port, and the
Home Assistant URL as seen from that same external host (usually
`http://127.0.0.1:8123`), then choose **INSTALL SERVER TIMER**. SSH key access
is required because the widget cannot safely prompt for a password. If you
currently use password login, the dedicated guide explains the one-time
dedicated-key `ssh-keygen` and `ssh-copy-id` setup. **HOME ASSISTANT SETTINGS**
opens the Home Assistant address used by the widget.
**GUIDE** opens the dedicated GitHub guide. **COPY SOURCE** is an
optional clipboard action for reviewing the exact files locally before
installing.

The external-server installer is intentionally transparent. It copies the two
named scripts in this repository, sends the token-bearing config through the
encrypted SSH connection's standard input rather than a command-line
argument, stores that config and the history file with owner-only permissions,
and creates one user-owned systemd service plus timer. It does not use `sudo`,
install packages, open ports, send telemetry, or call Home Assistant control
endpoints. The optional `loginctl enable-linger` step is best-effort so the
user timer can run while nobody is logged in; it does not request administrator
approval. Review the source before running it.

The chart can show the latest 1, 3, 6, 12, or 24 hours. **Experimental →
Extended chart history** unlocks 7-day and 30-day presets plus custom ranges
up to 744 hours. Longer ranges use date labels automatically. An always-on
external logger on the Home Assistant host is recommended for long recordings.

### Experimental features

The multi-aircon panel lets you add several available climate entities below
the main selector. **Globally synced controls** sends every change, including
power, to every selected AC. When it is off, **Sync non-power controls** is
enabled by default: temperature, mode, and fan changes stay synced while each
AC gets its own latched power button. Turn that option off to show a compact
remote for each selected unit. The bar ambient summary can show the average,
all values, one unit, or a chosen subset.

The appearance mode can follow Omarchy automatically or use a custom accent.
Custom mode includes a color picker/hex value and typed values for
transparency, softness, and corner radius. The compositor still controls
system-wide blur; the plugin's softness value only changes its own surface
treatment.

### Optional local Home Assistant server

If you do not have a Home Assistant server, choose **Set up locally** in the
connection screen. The plugin runs the supported Home Assistant Container
installation using the official
`ghcr.io/home-assistant/home-assistant:stable` image. It stores the container
data in `~/.local/share/omarchy/homeassistant`, uses host networking so a local
Daikin integration can reach the AC, and configures Docker to restart the
container automatically. Host networking can make Home Assistant reachable
from other devices on your LAN, so your firewall controls that access.

This is an explicit, user-triggered action. If Docker is missing, the script
uses the Omarchy Arch package manager through `pkexec` and may ask for
administrator approval to install Docker and enable its service. It downloads
the image from the Home Assistant GitHub Container Registry. The plugin does
not silently install this server, remove other containers, or change an
existing remote Home Assistant connection.

When the container starts, Daikin AC Controls opens `http://127.0.0.1:8123` in your
browser. Finish Home Assistant onboarding, add the Daikin integration, create
a long-lived access token, and paste that token into the connection form. The
Container installation does not include Home Assistant apps, so integrations
that depend on those apps may need Home Assistant OS or another supported
installation type instead.

The local container is independent of the plugin. Removing or disabling Daikin
AC Controls does not remove the container or its data by default. The Settings
panel's **REMOVE EVERYTHING** uninstall scope can remove the plugin-managed
container and `~/.local/share/omarchy/homeassistant` data when they exist. It
refuses a same-named container without the plugin's management label. Docker,
the Home Assistant image, and unrelated containers are never removed.

### External server history

This optional feature is for the same Linux host that runs Home Assistant,
accepts SSH connections, and has a user systemd service manager. A different
SSH machine cannot provide the history because the logger reads Home
Assistant's local API on the host where it runs.

Read the dedicated [External server history guide](EXTERNAL_SERVER_HISTORY.md)
for the requirements, manual checklist, installed files, review notes, and
uninstall behavior.

#### What is installed and what is not

The files are installed under the SSH user's home directory, with the config
and history file limited to that owner. The installer uses no `sudo`, package
installation, open ports, cloud service, usage analytics, or developer
telemetry. It does not call Home Assistant control endpoints. The optional
`loginctl enable-linger` step is best-effort and is used only so the user timer
can continue while nobody is logged in.

The exact files are available for review as
[`remote-history-logger.py`](remote-history-logger.py) and
[`install-remote-history.sh`](install-remote-history.sh). The cleanup source is
also available as [`uninstall-remote-history.sh`](uninstall-remote-history.sh),
[`uninstall-local-homeassistant.sh`](uninstall-local-homeassistant.sh), and
[`uninstall-plugin.sh`](uninstall-plugin.sh).
The **COPY SOURCE** action copies the installer, logger, and cleanup scripts
together.
After installation, inspect the timer with:

```bash
systemctl --user status omarchy-homeassistant-ac-history.timer
journalctl --user -u omarchy-homeassistant-ac-history.service
```

The uninstall flow sends `uninstall-remote-history.sh` over the same SSH
connection only when **REMOVE APP + LOGGER** or **REMOVE EVERYTHING** is
confirmed. It stops the matching user timer and removes only the named logger,
installer, config, service, timer, and 31-day history file. If that external
installation is absent, cleanup succeeds without changing anything on the
server.

### Uninstall scopes

Settings → **Maintenance** opens three separately confirmed choices:

- **REMOVE EVERYTHING** removes the plugin, its saved data, the external
  history logger if configured, and the plugin-managed local Home Assistant
  container/data if present.
- **REMOVE APP + LOGGER** removes the plugin, its saved data, and the external
  history logger if configured, while keeping local Home Assistant.
- **REMOVE PLUGIN ONLY** removes only the installed plugin files and keeps all
  plugin data, Home Assistant resources, and external history.

Home Assistant itself is never contacted by the uninstall scripts. Docker, the
Home Assistant image, unrelated containers, and unrelated server data remain
untouched. The local plugin is removed through Omarchy's supported
`omarchy plugin remove --yes` command.

## Daikin compatibility

Compatibility is provided by Home Assistant's **Daikin AC** integration. The
official integration currently documents these controller families and paths:

- European Wi-Fi Controller Units `BRP069A41`, `BRP069A42`, `BRP069A43`,
  `BRP069A45`, plus confirmed `BRP069B41` and `BRP069B45` units.
- Australian `BRP072A42` units, including `BRP072Cxx` units and Zena devices.
  The documented example is a Cora reverse-cycle split system
  `FTXM25QVMA`.
- United States `BRP072A43` units. Home Assistant documents confirmed wall
  units `FTXS09LVJU`, `FTXS15LVJU`, `FTXS18LVJU`, and floor unit `FVXS15NVJU`.
- `BRP084Cxx` units running firmware `2.8.0` or newer support as documented by
  Home Assistant.
- Australian AirBase controller `BRP15B61` units and SKYFi-based units,
  including extra zone climate entities when Linear Zone Control is exposed.

This list is controller-focused because the Wi-Fi module and Home Assistant
integration determine compatibility more than the indoor unit's marketing
name. Some models do not expose fan or swing controls, but Daikin AC Controls only
needs the climate entity's power, mode, ambient temperature, and target
temperature capabilities. Fan-speed and extra mode controls appear only when
Home Assistant exposes them. Swing and preset controls are intentionally not
shown because support varies widely between units. If your unit is not supported by the official local
integration, Home Assistant also documents ESP32-Faikout as an alternative
path; Daikin AC Controls can use its resulting `climate.*` entity too.

See the [Home Assistant Daikin AC documentation](https://www.home-assistant.io/integrations/daikin/)
for the maintained hardware list, regional caveats, firewall requirements,
and integration setup instructions.

## Controls

| Input | Action |
| --- | --- |
| Left-click the bar widget | Open the panel |
| Right-click the bar widget | Turn the AC on/off; reverse a cancellable pending request |
| Middle-click the bar widget | Refresh Home Assistant |
| `+` / `=` and `-` / `_` | Raise or lower the target temperature |
| `P` | Toggle power; cancel a pending power request when available |
| `R` or Enter | Refresh |
| `Esc` | Close the panel |
| Settings button | Re-run connection setup |

When climate controls are enabled, supported Home Assistant climate modes and
fan speeds appear in the main panel. Changes preview immediately and are sent
to Home Assistant in the background.

Preferences also includes MasterSwitch. Its two-step confirmations can send
`climate.turn_off` or `climate.turn_on` to every available Home Assistant
climate entity, including rooms other than the selected one. Reset App has its
own confirmation and only removes Daikin AC Controls data from this PC.

Temperature changes preview immediately and are committed after interaction
stops. Power changes remain visibly pending while Home Assistant settles, with
a final state check after 15 seconds if the controller is slow to report.

See [PATCHNOTES.md](PATCHNOTES.md) for the project update history.

The project page has setup help, Home Assistant notes, and future tutorials:
[github.com/twentylines/omarchy-daikin-control](https://github.com/twentylines/omarchy-daikin-control).
Daikin AC Controls is made by Sai.

## Requirements

- Omarchy with the Quickshell plugin system
- Home Assistant reachable from this computer
- The Daikin AC (or another climate) integration already configured in Home
  Assistant
- A Home Assistant long-lived access token with permission to read and control
  the chosen climate entity
- `python3`

The optional local server flow also needs internet access, Docker, and the
ability to approve Docker package and service setup when those are not already
available.

The optional server-history flow also needs the `ssh` client on this PC, SSH
key access to the Home Assistant host, and a Linux server with Python 3 and
systemd user services.

## Troubleshooting

### The setup panel says Home Assistant cannot be reached

Confirm the address includes the correct port (`8123` is the usual local
Home Assistant port), that the computer can reach it, and that any reverse
proxy forwards `/api/` and `/api/states`.

### No climate entity appears

Open Home Assistant and confirm the Daikin integration has finished setup and
the entity is not `unknown` or `unavailable`. The widget lists every available
`climate.*` entity, not just entities whose name contains “Daikin”.

### The widget does not appear

```bash
omarchy plugin list
omarchy plugin enable sai.homeassistant-ac --section right
omarchy-shell shell rescanPlugins
```

### Reset the connection

Use the settings button in the panel. If you need to remove the saved
credentials manually, delete `~/.config/omarchy/home-assistant-ac.json` and
open the widget again; the setup flow will return automatically.

### Reset the app

Use **Plugin Setup > Reset App** in the settings panel to remove Daikin AC Controls'
saved connection, preferences, and local temperature history. The action asks
for confirmation and does not reset Home Assistant, Docker, the local
Home Assistant container, or any Home Assistant data.

### Uninstall the plugin

Use **Settings → Maintenance → UNINSTALL PLUGIN**. The first click opens
three choices; each choice shows its own removal notice and requires a second
confirmation. If external history is configured, the logger cleanup is
idempotent: it also succeeds when the timer was already removed or was never
installed.

### External server history is unavailable

Confirm that the SSH target works without a password prompt, that the server
is powered on, and that the server logger's Home Assistant URL is reachable
from the same host that runs Home Assistant. Reinstall the timer from
**Settings → Preferences → EXTERNAL SERVER** if the user timer or token
changed. Open the [external-server guide](EXTERNAL_SERVER_HISTORY.md) or use
**COPY SOURCE** to inspect the exact files again.

## Development

From the repository root:

```bash
omarchy plugin validate .
python3 -m py_compile omarchy-homeassistant-ac
python3 -m unittest discover -s tests -v
git diff --check
```

For a local copy while developing, place the repository at
`~/.config/omarchy/plugins/sai.homeassistant-ac/`, then run
`omarchy-shell shell rescanPlugins`. Keep credentials outside the repository.

## License

MIT, see [LICENSE](LICENSE).
