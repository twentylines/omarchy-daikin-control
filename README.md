# Omarchy Daikin Control via Home Assistant

Daikin Air puts your Home Assistant Daikin climate entity in the Omarchy bar:
see the room temperature, compare it with the target, adjust the set point,
and turn the air conditioner on or off without opening a dashboard.

The widget talks to Home Assistant's local REST API. It does not talk directly
to a Daikin unit or replace the Home Assistant Daikin integration. That makes
the widget deliberately small and dependable: if Home Assistant exposes your
unit as an available `climate.*` entity, Daikin Air can control it.

## Install

Review the source before enabling it. Omarchy plugins run as unsandboxed code
inside the long-lived `omarchy-shell` process.

```bash
omarchy plugin add https://github.com/twentylines/omarchy-ha-daikin.git --enable
```

The plugin ships its small Python helper and needs only `python3`, which is
available on a normal Omarchy install. It does not start a daemon or require a
cloud account by default. An optional local Home Assistant setup is available
below for computers that do not have a server yet.

## First-run setup

Click the Daikin Air glyph in the bar. The centered setup panel asks for:

1. Your Home Assistant base address, such as `http://homeassistant.local:8123`,
   `http://192.168.1.20:8123`, or an HTTPS reverse-proxy URL.
2. A Home Assistant long-lived access token. In Home Assistant, open your
   profile, go to **Security → Long-Lived Access Tokens**, choose **Create
   Token**, and copy the token immediately. Home Assistant only shows it once;
   paste it into Daikin Air while the setup panel is open.
3. Which available climate entity to control when Home Assistant exposes more
   than one.

The connection is tested before anything is saved. A single available climate
entity is selected automatically; when there are several, the setup flow
offers a readable name plus the exact entity ID so there is no manual JSON
editing.

The token is sent to the bundled helper over stdin rather than as a command
line argument. It is stored at
`~/.config/omarchy/home-assistant-ac.json` with owner-only permissions (`600`),
never shown in the bar, and never printed by the helper. The helper sends
requests only to the Home Assistant address you entered.

To change the server, token, or selected entity later, open the panel and use
the small settings button in the hero card. The separate Advanced Options
section can reveal supported climate modes and fan speeds, choose whether the
bar shows ambient temperature, target temperature, or both, and enable the
optional Temperature History for Nerds chart.

The chart is a private local log on this PC. Daikin Air keeps at most the latest
24 hours of ambient readings, and the PC must be active for new samples to be
recorded. Sleep, shutdown, network outages, and other gaps remain empty in the
chart. The chart can show the latest 1, 3, 6, 12, or 24 hours, or a custom range
between 1 and 24 hours.

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

When the container starts, Daikin Air opens `http://127.0.0.1:8123` in your
browser. Finish Home Assistant onboarding, add the Daikin integration, create
a long-lived access token, and paste that token into the connection form. The
Container installation does not include Home Assistant apps, so integrations
that depend on those apps may need Home Assistant OS or another supported
installation type instead.

The local container is independent of the plugin. Removing or disabling Daikin
Air does not remove the container or its data. Review the container and
`~/.local/share/omarchy/homeassistant` before removing them yourself.

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
name. Some models do not expose fan or swing controls, but Daikin Air only
needs the climate entity's power, mode, ambient temperature, and target
temperature capabilities. Fan-speed and extra mode controls appear only when
Home Assistant exposes them. Swing and preset controls are intentionally not
shown because support varies widely between units. If your unit is not supported by the official local
integration, Home Assistant also documents ESP32-Faikout as an alternative
path; Daikin Air can use its resulting `climate.*` entity too.

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

When Advanced Options are enabled, supported Home Assistant climate modes and
fan speeds appear in the main panel. Changes preview immediately and are sent
to Home Assistant in the background.

Temperature changes preview immediately and are committed after interaction
stops. Power changes remain visibly pending while Home Assistant settles, with
a final state check after 15 seconds if the controller is slow to report.

The project page has setup help, Home Assistant notes, and future tutorials:
[github.com/twentylines/omarchy-ha-daikin](https://github.com/twentylines/omarchy-ha-daikin).
Daikin Air is made by Sai.

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

Use **App Data > Reset App** in the settings panel to remove Daikin Air's
saved connection, preferences, and local temperature history. The action asks
for confirmation and does not reset Home Assistant, Docker, the local
Home Assistant container, or any Home Assistant data.

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
