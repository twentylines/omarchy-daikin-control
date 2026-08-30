# Daikin Air for Omarchy

Daikin Air puts your Home Assistant climate entity in the Omarchy bar: see the
room temperature, compare it with the target, adjust the set point, and turn
the air conditioner on or off without opening a dashboard.

The widget talks to Home Assistant's local REST API. It does not talk directly
to a Daikin unit or replace the Home Assistant Daikin integration. That makes
the widget deliberately small and dependable: if Home Assistant exposes your
unit as an available `climate.*` entity, Daikin Air can control it.

## Install

Review the source before enabling it. Omarchy plugins run as unsandboxed code
inside the long-lived `omarchy-shell` process.

```bash
omarchy plugin add https://github.com/twentylines/omarchy-homeassistant-ac.git --enable
```

The plugin ships its small Python helper and needs only `python3`, which is
available on a normal Omarchy install. No daemon, package, cloud account, or
extra Home Assistant add-on is required.

## First-run setup

Click the Daikin Air glyph in the bar. The centered setup panel asks for:

1. Your Home Assistant base address, such as `http://homeassistant.local:8123`,
   `http://192.168.1.20:8123`, or an HTTPS reverse-proxy URL.
2. A Home Assistant long-lived access token. Create one from your Home
   Assistant profile under **Security → Long-Lived Access Tokens**.
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
the small settings button in the hero card.

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
temperature capabilities. If your unit is not supported by the official local
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

Temperature changes preview immediately and are committed after interaction
stops. Power changes remain visibly pending while Home Assistant settles, with
a final state check after 15 seconds if the controller is slow to report.

## Requirements

- Omarchy with the Quickshell plugin system
- Home Assistant reachable from this computer
- The Daikin AC (or another climate) integration already configured in Home
  Assistant
- A Home Assistant long-lived access token with permission to read and control
  the chosen climate entity
- `python3`

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

MIT — see [LICENSE](LICENSE).
