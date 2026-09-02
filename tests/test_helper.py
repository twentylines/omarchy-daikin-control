import contextlib
import importlib.util
import io
import json
import tempfile
import unittest
from importlib.machinery import SourceFileLoader
from pathlib import Path
from unittest.mock import patch


HELPER = Path(__file__).resolve().parents[1] / "omarchy-homeassistant-ac"
LOGGER = Path(__file__).resolve().parents[1] / "remote-history-logger.py"
loader = SourceFileLoader("ha_helper", str(HELPER))
spec = importlib.util.spec_from_loader(loader.name, loader)
assert spec and spec.loader
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)
logger_loader = SourceFileLoader("ha_remote_history_logger", str(LOGGER))
logger_spec = importlib.util.spec_from_loader(logger_loader.name, logger_loader)
assert logger_spec and logger_spec.loader
logger = importlib.util.module_from_spec(logger_spec)
logger_spec.loader.exec_module(logger)


class FakeResponse:
    def __init__(self, payload):
        self.payload = json.dumps(payload).encode("utf-8")

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        return False

    def read(self):
        return self.payload


class HelperTests(unittest.TestCase):
    def test_removed_single_bar_temperature_mode_migrates_to_average(self):
        self.assertEqual(helper.bar_temperature_mode("single"), "average")
        self.assertEqual(helper.bar_temperature_mode("average"), "average")
        self.assertEqual(helper.bar_temperature_mode("selected"), "selected")

    def test_normalize_url_accepts_host_port_and_strips_api_suffix(self):
        self.assertEqual(
            helper.normalize_url("homeassistant.local:8123/api/"),
            "http://homeassistant.local:8123",
        )
        self.assertEqual(
            helper.normalize_url("HTTPS://ha.example.test/ha/"),
            "https://ha.example.test/ha",
        )

    def test_normalize_url_rejects_credentials_and_query(self):
        with self.assertRaises(helper.HomeAssistantError):
            helper.normalize_url("http://user:password@homeassistant.local:8123")
        with self.assertRaises(helper.HomeAssistantError):
            helper.normalize_url("http://homeassistant.local:8123/?token=secret")

    def test_configure_discovers_multiple_entities_without_saving_token(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            original_urlopen = helper.urlopen
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"

            def fake_urlopen(request, timeout):
                self.assertEqual(timeout, 6)
                if request.full_url.endswith("/api/"):
                    return FakeResponse({"message": "API running."})
                return FakeResponse([
                    {
                        "entity_id": "climate.bedroom",
                        "state": "off",
                        "attributes": {"friendly_name": "Bedroom"},
                    },
                    {
                        "entity_id": "climate.living_room",
                        "state": "cool",
                        "attributes": {"friendly_name": "Living room"},
                    },
                ])

            helper.urlopen = fake_urlopen
            try:
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    result = helper.configure(
                        {"url": "homeassistant.local:8123", "token": "test-secret"},
                        {},
                    )
                self.assertEqual(result, 0)
                parsed = json.loads(output.getvalue())
                self.assertTrue(parsed["ok"])
                self.assertTrue(parsed["needs_entity"])
                self.assertNotIn("test-secret", output.getvalue())
                self.assertFalse(helper.CONFIG_PATH.exists())
            finally:
                helper.CONFIG_PATH = original_path
                helper.urlopen = original_urlopen

    def test_configure_saves_a_single_entity_with_owner_only_permissions(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            original_urlopen = helper.urlopen
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            helper.urlopen = lambda request, timeout: FakeResponse(
                {"message": "API running."}
                if request.full_url.endswith("/api/")
                else [{
                    "entity_id": "climate.office",
                    "state": "cool",
                    "attributes": {"friendly_name": "Office"},
                }]
            )
            try:
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    result = helper.configure(
                        {"url": "ha.local:8123", "token": "test-secret"},
                        {},
                    )
                self.assertEqual(result, 0)
                self.assertTrue(json.loads(output.getvalue())["configured"])
                self.assertEqual(helper.CONFIG_PATH.stat().st_mode & 0o777, 0o600)
                saved = json.loads(helper.CONFIG_PATH.read_text(encoding="utf-8"))
                self.assertEqual(saved["entity_id"], "climate.office")
                self.assertTrue(saved["advanced_controls"])
                self.assertFalse(saved["master_switch_enabled"])
            finally:
                helper.CONFIG_PATH = original_path
                helper.urlopen = original_urlopen

    def test_configure_can_reconnect_to_the_same_address_with_saved_token(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            original_urlopen = helper.urlopen
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            current_config = {
                "url": "http://ha.local:8123",
                "token": "test-secret",
                "entity_id": "climate.office",
            }
            helper.CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
            helper.CONFIG_PATH.write_text(json.dumps(current_config), encoding="utf-8")
            requests = []

            def fake_urlopen(request, timeout):
                requests.append(request)
                return FakeResponse(
                    {"message": "API running."}
                    if request.full_url.endswith("/api/")
                    else [{
                        "entity_id": "climate.office",
                        "state": "cool",
                        "attributes": {"friendly_name": "Office"},
                    }]
                )

            helper.urlopen = fake_urlopen
            try:
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    result = helper.configure(
                        {
                            "url": "ha.local:8123/api/",
                            "reuse_saved_token": True,
                        },
                        current_config,
                    )
                self.assertEqual(result, 0)
                self.assertEqual(len(requests), 2)
                self.assertTrue(all(
                    request.headers.get("Authorization") == "Bearer test-secret"
                    for request in requests
                ))
                self.assertNotIn("test-secret", output.getvalue())
                saved = json.loads(helper.CONFIG_PATH.read_text(encoding="utf-8"))
                self.assertEqual(saved["token"], "test-secret")
            finally:
                helper.CONFIG_PATH = original_path
                helper.urlopen = original_urlopen

    def test_configure_does_not_reuse_saved_token_for_a_new_address(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            current_config = {
                "url": "http://old-ha.local:8123",
                "token": "test-secret",
                "entity_id": "climate.office",
            }
            helper.CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
            helper.CONFIG_PATH.write_text(json.dumps(current_config), encoding="utf-8")
            try:
                with patch.object(helper, "urlopen") as urlopen:
                    output = io.StringIO()
                    with contextlib.redirect_stdout(output):
                        result = helper.configure(
                            {
                                "url": "http://new-ha.local:8123",
                                "reuse_saved_token": True,
                            },
                            current_config,
                        )
                    urlopen.assert_not_called()
                self.assertEqual(result, 1)
                self.assertIn("Paste a Home Assistant long-lived access token", output.getvalue())
            finally:
                helper.CONFIG_PATH = original_path

    def test_configure_preserves_existing_external_server_pairing(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            original_urlopen = helper.urlopen
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            current_config = {
                "url": "http://old-ha.local:8123",
                "token": "old-secret",
                "entity_id": "climate.office",
                "history_source": "server",
                "history_remote_target": "sai@192.168.1.20",
                "history_remote_port": 2222,
                "history_remote_url": "http://127.0.0.1:8123",
                "history_remote_path": "~/.local/state/custom-ac.json",
            }
            helper.CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
            helper.CONFIG_PATH.write_text(json.dumps(current_config), encoding="utf-8")
            helper.urlopen = lambda request, timeout: FakeResponse(
                {"message": "API running."}
                if request.full_url.endswith("/api/")
                else [{
                    "entity_id": "climate.office",
                    "state": "cool",
                    "attributes": {"friendly_name": "Office"},
                }]
            )
            try:
                with contextlib.redirect_stdout(io.StringIO()):
                    result = helper.configure(
                        {"url": "new-ha.local:8123", "token": "new-secret"},
                        current_config,
                    )
                self.assertEqual(result, 0)
                saved = json.loads(helper.CONFIG_PATH.read_text(encoding="utf-8"))
                self.assertEqual(saved["history_source"], "server")
                self.assertEqual(saved["history_remote_target"], "sai@192.168.1.20")
                self.assertEqual(saved["history_remote_port"], 2222)
                self.assertEqual(saved["history_remote_path"], "~/.local/state/custom-ac.json")
            finally:
                helper.CONFIG_PATH = original_path
                helper.urlopen = original_urlopen

    def test_main_can_connect_to_external_history_without_local_token(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            helper.CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
            helper.CONFIG_PATH.write_text(json.dumps({
                "url": "http://ha.local:8123",
                "entity_id": "climate.office",
                "history_source": "server",
            }), encoding="utf-8")
            payload = json.dumps({
                "ssh_target": "sai@192.168.1.20",
                "ssh_port": "22",
                "home_assistant_url": "http://127.0.0.1:8123",
                "history_path": "~/.local/state/omarchy/homeassistant-ac-temperature.json",
            }) + "\n"
            fake_result = helper.subprocess.CompletedProcess(
                ["ssh"], 0, "server\n", ""
            )
            try:
                with patch.object(helper.subprocess, "run", return_value=fake_result) as run, \
                        patch.object(helper.sys, "stdin", io.StringIO(payload)):
                    output = io.StringIO()
                    with contextlib.redirect_stdout(output):
                        result = helper.main([str(HELPER), "connect-remote-history"])
                self.assertEqual(result, 0)
                self.assertEqual(run.call_count, 1)
                saved = json.loads(helper.CONFIG_PATH.read_text(encoding="utf-8"))
                self.assertEqual(saved["history_remote_target"], "sai@192.168.1.20")
                self.assertTrue(json.loads(output.getvalue())["ok"])
            finally:
                helper.CONFIG_PATH = original_path

    def test_state_payload_includes_optional_fan_controls(self):
        payload = helper.state_payload(
            {
                "entity_id": "climate.office",
                "state": "cool",
                "attributes": {
                    "friendly_name": "Office",
                    "current_temperature": 24,
                    "temperature": 22,
                    "temperature_unit": "C",
                    "hvac_modes": ["off", "cool", "heat"],
                    "fan_mode": "Auto",
                    "fan_modes": ["Auto", "Low", "High"],
                },
            },
            ["climate.office"],
        )
        self.assertEqual(payload["fan_mode"], "Auto")
        self.assertEqual(payload["fan_modes"], ["Auto", "Low", "High"])
        self.assertEqual(payload["history"], [])

    def test_history_is_capped_to_the_latest_31_days(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.HISTORY_PATH
            original_time = helper.time.time
            helper.HISTORY_PATH = Path(directory) / "state" / "temperature.json"
            now = 2_000_000_000
            helper.time.time = lambda: now
            try:
                helper.save_temperature_history({
                    "climate.office": [
                        {
                            "timestamp": now - 32 * 24 * 60 * 60,
                            "temperature": 19,
                            "unit": "°C",
                        },
                    ],
                })
                samples = helper.record_temperature_history("climate.office", 24, "C")
                self.assertEqual(len(samples), 1)
                self.assertEqual(samples[0]["temperature"], 24)
                self.assertEqual(helper.HISTORY_PATH.stat().st_mode & 0o777, 0o600)
            finally:
                helper.HISTORY_PATH = original_path
                helper.time.time = original_time

    def test_preferences_support_custom_history_ranges(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            try:
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    result = helper.set_preference(
                        {
                            "url": "http://ha.local:8123",
                            "token": "test-secret",
                            "entity_id": "climate.office",
                            "experimental_history_enabled": True,
                        },
                        "history_range",
                        "custom:2.5",
                    )
                self.assertEqual(result, 0)
                parsed = json.loads(output.getvalue())
                self.assertEqual(parsed["preference"], "history_range")
                self.assertEqual(parsed["history_hours"], 2.5)
                self.assertTrue(parsed["history_custom"])
                saved = json.loads(helper.CONFIG_PATH.read_text(encoding="utf-8"))
                self.assertEqual(saved["history_hours"], 2.5)
                self.assertTrue(saved["history_custom"])
            finally:
                helper.CONFIG_PATH = original_path

    def test_extended_history_ranges_require_the_experimental_setting(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            try:
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    result = helper.set_preference(
                        {
                            "url": "http://ha.local:8123",
                            "token": "test-secret",
                            "entity_id": "climate.office",
                        },
                        "history_range",
                        "custom:2.5",
                    )
                self.assertEqual(result, 1)
                parsed = json.loads(output.getvalue())
                self.assertFalse(parsed["ok"])
                self.assertIn("Experimental", parsed["error"])
                self.assertFalse(helper.CONFIG_PATH.exists())
            finally:
                helper.CONFIG_PATH = original_path

    def test_disabling_extended_history_returns_to_the_basic_range(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            try:
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    result = helper.set_preference(
                        {
                            "url": "http://ha.local:8123",
                            "token": "test-secret",
                            "entity_id": "climate.office",
                            "experimental_history_enabled": True,
                            "history_hours": 720,
                            "history_custom": True,
                        },
                        "experimental_history_enabled",
                        "off",
                    )
                self.assertEqual(result, 0)
                parsed = json.loads(output.getvalue())
                self.assertFalse(parsed["value"])
                self.assertEqual(parsed["history_hours"], 24)
                self.assertFalse(parsed["history_custom"])
                saved = json.loads(helper.CONFIG_PATH.read_text(encoding="utf-8"))
                self.assertEqual(saved["history_hours"], 24)
                self.assertFalse(saved["history_custom"])
            finally:
                helper.CONFIG_PATH = original_path

    def test_preferences_support_server_history_source(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            try:
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    result = helper.set_preference(
                        {
                            "url": "http://ha.local:8123",
                            "token": "test-secret",
                            "entity_id": "climate.office",
                        },
                        "history_source",
                        "server",
                    )
                self.assertEqual(result, 0)
                parsed = json.loads(output.getvalue())
                self.assertEqual(parsed["preference"], "history_source")
                self.assertEqual(parsed["value"], "server")
                saved = json.loads(helper.CONFIG_PATH.read_text(encoding="utf-8"))
                self.assertEqual(saved["history_source"], "server")
            finally:
                helper.CONFIG_PATH = original_path

    def test_average_temperature_decimals_is_off_by_default_and_persistable(self):
        self.assertFalse(helper.experimental_settings({})["average_temperature_decimals"])
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            try:
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    result = helper.set_preference(
                        {
                            "url": "http://ha.local:8123",
                            "token": "test-secret",
                            "entity_id": "climate.office",
                        },
                        "average_temperature_decimals",
                        "on",
                    )
                self.assertEqual(result, 0)
                self.assertTrue(json.loads(output.getvalue())["value"])
                saved = json.loads(helper.CONFIG_PATH.read_text(encoding="utf-8"))
                self.assertTrue(saved["average_temperature_decimals"])
            finally:
                helper.CONFIG_PATH = original_path

    def test_keyboard_shortcuts_have_safe_defaults_and_normalize_keys(self):
        defaults = helper.experimental_settings({})
        self.assertFalse(defaults["shortcuts_enabled"])
        self.assertEqual(defaults["shortcuts"]["open_panel"]["key"], "SUPER+ALT+A")
        self.assertEqual(
            helper.normalize_shortcut("shift + alt + ctrl + escape"),
            "CTRL+ALT+SHIFT+ESC",
        )
        self.assertEqual(helper.normalize_shortcut("SUPER+ALT"), "")
        self.assertEqual(helper.normalize_shortcut("SUPER+A+B"), "")

    def test_keyboard_shortcuts_persist_and_generate_reversible_hyprland_bindings(self):
        with tempfile.TemporaryDirectory() as directory:
            original_config_path = helper.CONFIG_PATH
            original_bindings_path = helper.HYPR_BINDINGS_PATH
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            helper.HYPR_BINDINGS_PATH = Path(directory) / "hypr" / "bindings.lua"
            helper.HYPR_BINDINGS_PATH.parent.mkdir(parents=True, exist_ok=True)
            helper.HYPR_BINDINGS_PATH.write_text("-- keep my bindings\n", encoding="utf-8")
            reload_result = helper.subprocess.CompletedProcess(["hyprctl", "reload"], 0)
            try:
                config = {
                    "url": "http://ha.local:8123",
                    "token": "test-secret",
                    "entity_id": "climate.office",
                    "multi_unit_enabled": True,
                    "global_sync_controls": False,
                    "selected_entities": ["climate.office", "climate.bedroom"],
                }
                with patch.object(helper.subprocess, "run", return_value=reload_result):
                    self.assertEqual(
                        helper.sync_hyprland_shortcuts({**config, "shortcuts_enabled": True}),
                        "",
                    )
                bindings = helper.HYPR_BINDINGS_PATH.read_text(encoding="utf-8")
                self.assertIn("-- keep my bindings", bindings)
                self.assertIn("sai.homeassistant-ac:open_panel", bindings)
                self.assertIn("SUPER + ALT + P + 1", bindings)
                self.assertIn("sai.homeassistant-ac:power_2", bindings)

                globally_synced = helper.shortcut_bindings({
                    **config, "shortcuts_enabled": True, "global_sync_controls": True
                })
                self.assertFalse(any("power_1" in line for line in globally_synced))

                output = io.StringIO()
                with patch.object(helper, "sync_hyprland_shortcuts", return_value=""), \
                        contextlib.redirect_stdout(output):
                    result = helper.set_preference(
                        config, "shortcut_open_panel", "shift + ctrl + b"
                    )
                self.assertEqual(result, 0)
                self.assertEqual(json.loads(output.getvalue())["value"], "CTRL+SHIFT+B")
                saved = json.loads(helper.CONFIG_PATH.read_text(encoding="utf-8"))
                self.assertEqual(saved["shortcuts"]["open_panel"]["key"], "CTRL+SHIFT+B")

                output = io.StringIO()
                with patch.object(helper, "sync_hyprland_shortcuts", return_value=""), \
                        contextlib.redirect_stdout(output):
                    result = helper.set_preference(
                        config, "reset_shortcuts", "default"
                    )
                self.assertEqual(result, 0)
                self.assertEqual(
                    json.loads(output.getvalue())["shortcuts"],
                    helper.shortcut_settings({}),
                )

                with patch.object(helper.subprocess, "run", return_value=reload_result):
                    self.assertEqual(helper.sync_hyprland_shortcuts({}), "")
                self.assertNotIn(helper.SHORTCUT_MARKER_START, helper.HYPR_BINDINGS_PATH.read_text(encoding="utf-8"))
                self.assertIn("-- keep my bindings", helper.HYPR_BINDINGS_PATH.read_text(encoding="utf-8"))
            finally:
                helper.CONFIG_PATH = original_config_path
                helper.HYPR_BINDINGS_PATH = original_bindings_path

    def test_temperature_units_support_fahrenheit_and_kelvin_by_default(self):
        defaults = helper.experimental_settings({})
        self.assertEqual(defaults["temperature_unit"], "source")
        self.assertEqual(
            helper.experimental_settings(
                {"temperature_unit": "kelvin", "experimental_kelvin_enabled": False}
            )["temperature_unit"],
            "kelvin",
        )

        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            try:
                config = {
                    "url": "http://ha.local:8123",
                    "token": "test-secret",
                    "entity_id": "climate.office",
                }
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    result = helper.set_preference(config, "temperature_unit", "fahrenheit")
                self.assertEqual(result, 0)
                self.assertEqual(json.loads(output.getvalue())["value"], "fahrenheit")

                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    result = helper.set_preference(config, "temperature_unit", "kelvin")
                self.assertEqual(result, 0)
                self.assertEqual(json.loads(output.getvalue())["value"], "kelvin")
                saved = json.loads(helper.CONFIG_PATH.read_text(encoding="utf-8"))
                self.assertEqual(saved["temperature_unit"], "kelvin")
            finally:
                helper.CONFIG_PATH = original_path

    def test_reset_appearance_restores_defaults_without_disabling_customisations(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            try:
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    result = helper.set_preference(
                        {
                            "url": "http://ha.local:8123",
                            "token": "test-secret",
                            "custom_appearance_enabled": True,
                            "appearance_auto_accent": False,
                            "appearance_auto_background": False,
                            "appearance_accent": "#C89AAB",
                            "appearance_control": "#8EA7C7",
                            "appearance_background": "#2A3031",
                            "appearance_device_colors_enabled": True,
                            "appearance_device_colors": {"climate.office": "#C89AAB"},
                            "appearance_transparency": 45,
                            "appearance_blur": 18,
                            "appearance_radius": 30,
                        },
                        "reset_appearance",
                        "default",
                    )
                self.assertEqual(result, 0)
                parsed = json.loads(output.getvalue())
                self.assertTrue(parsed["appearance_reset"])
                self.assertTrue(parsed["custom_appearance_enabled"])
                self.assertTrue(parsed["appearance_auto_accent"])
                self.assertTrue(parsed["appearance_auto_background"])
                self.assertEqual(parsed["appearance_accent"], helper.DEFAULT_APPEARANCE_ACCENT)
                self.assertEqual(parsed["appearance_control"], helper.DEFAULT_APPEARANCE_CONTROL)
                self.assertEqual(
                    parsed["appearance_background"], helper.DEFAULT_APPEARANCE_BACKGROUND
                )
                self.assertFalse(parsed["appearance_device_colors_enabled"])
                self.assertEqual(parsed["appearance_device_colors"], {})
                self.assertEqual(parsed["appearance_transparency"], 0)
                self.assertEqual(parsed["appearance_blur"], 0)
                self.assertEqual(parsed["appearance_radius"], helper.DEFAULT_APPEARANCE_RADIUS)
                saved = json.loads(helper.CONFIG_PATH.read_text(encoding="utf-8"))
                self.assertTrue(saved["custom_appearance_enabled"])
                self.assertTrue(saved["appearance_auto_accent"])
            finally:
                helper.CONFIG_PATH = original_path

    def test_appearance_background_can_be_fixed_and_is_validated(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            config = {
                "url": "http://ha.local:8123",
                "token": "test-secret",
                "custom_appearance_enabled": True,
            }
            try:
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    result = helper.set_preference(
                        config, "appearance_auto_background", "off"
                    )
                self.assertEqual(result, 0)
                self.assertFalse(json.loads(output.getvalue())["value"])

                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    result = helper.set_preference(
                        config, "appearance_background", "#2A3031"
                    )
                self.assertEqual(result, 0)
                self.assertEqual(json.loads(output.getvalue())["value"], "#2A3031")
                saved = json.loads(helper.CONFIG_PATH.read_text(encoding="utf-8"))
                self.assertFalse(saved["appearance_auto_background"])
                self.assertEqual(saved["appearance_background"], "#2A3031")
                settings = helper.experimental_settings(saved)
                self.assertFalse(settings["appearance_auto_background"])
                self.assertEqual(settings["appearance_background"], "#2A3031")

                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    result = helper.set_preference(
                        config, "appearance_background", "not-a-colour"
                    )
                self.assertEqual(result, 1)
                self.assertIn("six-digit hex", output.getvalue())
            finally:
                helper.CONFIG_PATH = original_path

    def test_config_file_mode_saves_preferences_without_exposing_token(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            helper.CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
            helper.CONFIG_PATH.write_text(json.dumps({
                "url": "http://ha.example.test:8123",
                "token": "do-not-print-this-token",
                "entity_id": "climate.office",
            }), encoding="utf-8")
            payload = json.dumps({
                "advanced_controls": False,
                "appearance_background": "#202426",
                "appearance_compact": True,
                "config_file_mode_enabled": True,
            }) + "\n"
            try:
                output = io.StringIO()
                with patch.object(helper.sys, "stdin", io.StringIO(payload)), \
                        contextlib.redirect_stdout(output):
                    result = helper.main([str(HELPER), "set-config-file"])
                self.assertEqual(result, 0)
                parsed = json.loads(output.getvalue())
                self.assertTrue(parsed["config_file_saved"])
                self.assertNotIn("do-not-print-this-token", output.getvalue())
                self.assertNotIn("url", parsed)
                saved = json.loads(helper.CONFIG_PATH.read_text(encoding="utf-8"))
                self.assertEqual(saved["token"], "do-not-print-this-token")
                self.assertFalse(saved["advanced_controls"])
                self.assertEqual(saved["appearance_background"], "#202426")
                self.assertTrue(saved["appearance_compact"])
                self.assertTrue(saved["config_file_mode_enabled"])
            finally:
                helper.CONFIG_PATH = original_path

    def test_config_file_mode_rejects_invalid_values_before_saving(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            helper.CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
            original = {
                "url": "http://ha.example.test:8123",
                "token": "test-secret",
                "entity_id": "climate.office",
                "appearance_background": "#131516",
            }
            helper.CONFIG_PATH.write_text(json.dumps(original), encoding="utf-8")
            payload = json.dumps({"appearance_background": "grey"}) + "\n"
            try:
                output = io.StringIO()
                with patch.object(helper.sys, "stdin", io.StringIO(payload)), \
                        contextlib.redirect_stdout(output):
                    result = helper.main([str(HELPER), "set-config-file"])
                self.assertEqual(result, 1)
                self.assertIn("six-digit hex", output.getvalue())
                self.assertEqual(json.loads(helper.CONFIG_PATH.read_text(encoding="utf-8")), original)
            finally:
                helper.CONFIG_PATH = original_path

    def test_appearance_transparency_accepts_the_full_range(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            try:
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    result = helper.set_preference(
                        {
                            "url": "http://ha.local:8123",
                            "token": "test-secret",
                            "custom_appearance_enabled": True,
                        },
                        "appearance_transparency",
                        "100",
                    )
                self.assertEqual(result, 0)
                parsed = json.loads(output.getvalue())
                self.assertEqual(parsed["value"], 100)
                saved = json.loads(helper.CONFIG_PATH.read_text(encoding="utf-8"))
                self.assertEqual(saved["appearance_transparency"], 100)
                self.assertEqual(
                    helper.experimental_settings({"appearance_transparency": 101})[
                        "appearance_transparency"
                    ],
                    100,
                )
            finally:
                helper.CONFIG_PATH = original_path

    def test_appearance_control_and_device_colours_are_saved(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            config = {
                "url": "http://ha.local:8123",
                "token": "test-secret",
                "entity_id": "climate.office",
                "selected_entities": ["climate.office", "climate.bedroom"],
                "custom_appearance_enabled": True,
                "appearance_auto_accent": False,
            }
            try:
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    result = helper.set_preference(config, "appearance_control", "#C89AAB")
                self.assertEqual(result, 0)
                self.assertEqual(json.loads(output.getvalue())["value"], "#C89AAB")

                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    result = helper.set_preference(
                        config, "appearance_device_colors_enabled", "on"
                    )
                self.assertEqual(result, 0)

                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    result = helper.set_preference(
                        config,
                        "appearance_device_colors",
                        json.dumps({
                            "climate.office": "#8EA7C7",
                            "climate.bedroom": "#D0A66A",
                            "sensor.outside": "#FFFFFF",
                        }),
                    )
                self.assertEqual(result, 0)
                saved = json.loads(helper.CONFIG_PATH.read_text(encoding="utf-8"))
                self.assertEqual(saved["appearance_control"], "#C89AAB")
                self.assertTrue(saved["appearance_device_colors_enabled"])
                self.assertEqual(saved["appearance_device_colors"], {
                    "climate.office": "#8EA7C7",
                    "climate.bedroom": "#D0A66A",
                })
                settings = helper.experimental_settings(saved)
                self.assertEqual(settings["appearance_control"], "#C89AAB")
                self.assertEqual(settings["appearance_device_colors"]["climate.office"], "#8EA7C7")
            finally:
                helper.CONFIG_PATH = original_path

    def test_external_logger_discovers_all_available_climate_entities(self):
        with tempfile.TemporaryDirectory() as directory:
            original_config_path = logger.CONFIG_PATH
            original_history_path = logger.HISTORY_PATH
            original_urlopen = logger.urlopen
            original_time = logger.time.time
            logger.CONFIG_PATH = Path(directory) / "config" / "homeassistant-ac-history.json"
            logger.HISTORY_PATH = Path(directory) / "state" / "temperature.json"
            logger.CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
            logger.CONFIG_PATH.write_text(json.dumps({
                "url": "http://ha.local:8123",
                "token": "test-secret",
                "entity_id": "climate.office",
                "history_path": str(logger.HISTORY_PATH),
            }), encoding="utf-8")
            states = [
                {
                    "entity_id": "climate.office",
                    "state": "cool",
                    "attributes": {"current_temperature": 24, "temperature_unit": "C"},
                },
                {
                    "entity_id": "climate.bedroom",
                    "state": "off",
                    "attributes": {"current_temperature": 27, "temperature_unit": "C"},
                },
                {
                    "entity_id": "climate.guest",
                    "state": "unavailable",
                    "attributes": {"current_temperature": 22, "temperature_unit": "C"},
                },
                {
                    "entity_id": "sensor.outside",
                    "state": "25",
                    "attributes": {"unit_of_measurement": "°C"},
                },
            ]
            requests = []

            def fake_urlopen(request, timeout):
                requests.append((request.full_url, timeout, request.headers.get("Authorization")))
                return FakeResponse(states)

            logger.urlopen = fake_urlopen
            logger.time.time = lambda: 2_000_000_000
            try:
                logger.record_once()
                history = logger.load_history(logger.HISTORY_PATH)
                self.assertEqual(set(history), {"climate.office", "climate.bedroom"})
                self.assertEqual(history["climate.office"][0]["temperature"], 24)
                self.assertEqual(history["climate.bedroom"][0]["temperature"], 27)
                self.assertEqual(len(requests), 1)
                self.assertEqual(requests[0][0], "http://ha.local:8123/api/states")
                self.assertEqual(requests[0][2], "Bearer test-secret")
                self.assertTrue(logger.record_all_entities_enabled(None))
            finally:
                logger.CONFIG_PATH = original_config_path
                logger.HISTORY_PATH = original_history_path
                logger.urlopen = original_urlopen
                logger.time.time = original_time

    def test_server_status_uses_remote_history_without_writing_local_history(self):
        state = {
            "entity_id": "climate.office",
            "state": "cool",
            "attributes": {
                "friendly_name": "Office",
                "current_temperature": 24,
                "temperature": 22,
                "temperature_unit": "C",
                "hvac_modes": ["off", "cool"],
            },
        }
        remote_samples = [{"timestamp": 2_000_000_000, "temperature": 23.5, "unit": "°C"}]
        output = io.StringIO()
        with patch.object(helper, "resolve_state", return_value=(state, ["climate.office"])), \
                patch.object(helper, "load_remote_temperature_history", return_value={
                    "climate.office": remote_samples,
                }), \
                patch.object(helper, "record_temperature_history") as record_local:
            with contextlib.redirect_stdout(output):
                result = helper.status(
                    "http://ha.local:8123",
                    "secret",
                    "climate.office",
                    {
                        "history_source": "server",
                        "history_remote_target": "sai@192.168.1.20",
                        "history_remote_port": 22,
                        "history_remote_url": "http://127.0.0.1:8123",
                    },
                )
        self.assertEqual(result, 0)
        parsed = json.loads(output.getvalue())
        self.assertEqual(parsed["history_source"], "server")
        self.assertEqual(parsed["history_server"], "192.168.1.20")
        self.assertEqual(parsed["history"], remote_samples)
        self.assertTrue(parsed["history_available"])
        self.assertGreaterEqual(parsed["history_ping_ms"], 0)
        record_local.assert_not_called()

    def test_server_status_does_not_report_remote_history_as_available_on_ssh_error(self):
        state = {
            "entity_id": "climate.office",
            "state": "cool",
            "attributes": {
                "friendly_name": "Office",
                "current_temperature": 24,
                "temperature": 22,
                "temperature_unit": "C",
            },
        }
        output = io.StringIO()
        with patch.object(helper, "resolve_state", return_value=(state, ["climate.office"])), \
                patch.object(
                    helper,
                    "load_remote_temperature_history",
                    side_effect=helper.HomeAssistantError("Cannot read server history over SSH"),
                ), \
                patch.object(helper, "record_temperature_history") as record_local:
            with contextlib.redirect_stdout(output):
                result = helper.status(
                    "http://ha.local:8123",
                    "secret",
                    "climate.office",
                    {
                        "history_source": "server",
                        "history_remote_target": "sai@192.168.1.20",
                        "history_remote_port": 22,
                        "history_remote_url": "http://127.0.0.1:8123",
                    },
                )
        self.assertEqual(result, 0)
        parsed = json.loads(output.getvalue())
        self.assertFalse(parsed["history_available"])
        self.assertEqual(parsed["history_ping_ms"], -1)
        self.assertIn("Cannot read server history", parsed["history_error"])
        record_local.assert_not_called()

    def test_remote_installer_saves_server_settings_after_ssh_success(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            helper.CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
            helper.CONFIG_PATH.write_text(json.dumps({
                "url": "http://ha.example.test:8123",
                "token": "test-secret",
                "entity_id": "climate.office",
            }), encoding="utf-8")
            try:
                fake_results = [
                    helper.subprocess.CompletedProcess(["ssh"], 0, "", ""),
                    helper.subprocess.CompletedProcess(["scp"], 0, "", ""),
                    helper.subprocess.CompletedProcess(["scp"], 0, "", ""),
                    helper.subprocess.CompletedProcess(["ssh"], 0, "", ""),
                    helper.subprocess.CompletedProcess(["ssh"], 0, "", ""),
                    helper.subprocess.CompletedProcess(
                        ["ssh"], 0, "External Home Assistant history timer installed.\n", ""
                    ),
                ]
                with patch.object(helper.subprocess, "run", side_effect=fake_results) as run:
                    output = io.StringIO()
                    with contextlib.redirect_stdout(output):
                        result = helper.install_remote_history(
                            helper.load_config(),
                            {
                                "ssh_target": "sai@192.168.1.20",
                                "ssh_port": "2222",
                                "home_assistant_url": "http://127.0.0.1:8123",
                                "entity_id": "climate.office",
                                "entity_ids": ["climate.office", "climate.living_room"],
                            },
                        )
                self.assertEqual(result, 0)
                self.assertEqual(run.call_count, 6)
                commands = [call.args[0] for call in run.call_args_list]
                self.assertEqual(commands[0][-2:], ["bash", "-s"])
                self.assertEqual(commands[1][0], "scp")
                self.assertEqual(commands[2][0], "scp")
                self.assertEqual(commands[3][-2:], ["bash", "-s"])
                self.assertEqual(commands[5][-2:], ["bash", "-s"])
                for call in run.call_args_list:
                    self.assertNotIn("test-secret", call.args[0])
                config_inputs = [call.kwargs.get("input") or "" for call in run.call_args_list]
                self.assertEqual(sum("test-secret" in value for value in config_inputs), 1)
                remote_config = next(value for value in config_inputs if "test-secret" in value)
                self.assertEqual(
                    json.loads(remote_config)["entity_ids"],
                    ["climate.office", "climate.living_room"],
                )
                self.assertTrue(json.loads(remote_config)["record_all_entities"])
                self.assertEqual(json.loads(remote_config)["retention_hours"], 744)
                saved = json.loads(helper.CONFIG_PATH.read_text(encoding="utf-8"))
                self.assertEqual(saved["history_source"], "server")
                self.assertEqual(saved["history_remote_target"], "sai@192.168.1.20")
                self.assertEqual(saved["history_remote_port"], 2222)
                self.assertEqual(json.loads(output.getvalue())["ok"], True)
            finally:
                helper.CONFIG_PATH = original_path

    def test_remote_history_source_includes_cleanup_scripts(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            result = helper.remote_history_source()
        self.assertEqual(result, 0)
        parsed = json.loads(output.getvalue())
        self.assertNotIn("guide", parsed)
        source = parsed["source"]
        self.assertIn("install-remote-history.sh", source)
        self.assertIn("remote-history-logger.py", source)
        self.assertIn("uninstall-remote-history.sh", source)
        self.assertIn("uninstall-local-homeassistant.sh", source)
        self.assertIn("uninstall-plugin.sh", source)
        self.assertIn("--remove-everything", source)

        guide = (HELPER.parent / "EXTERNAL_SERVER_HISTORY.md").read_text(encoding="utf-8")
        self.assertIn("external server must be the **same Linux host", guide)
        self.assertIn("every currently available", guide)
        self.assertIn("COPY SOURCE", guide)
        self.assertIn("ssh-copy-id", guide)
        self.assertIn("systemctl --user enable --now ssh-agent.socket", guide)
        self.assertIn("SSH key authentication works", guide)
        self.assertIn("terminal paste-control characters", guide)
        self.assertIn("ssh-add", guide)
        self.assertNotIn('eval "$(ssh-agent -s)"', guide)
        self.assertNotIn('ssh-keygen -t ed25519 -N ""', guide)

    def test_ssh_auth_error_points_to_manual_guide(self):
        result = helper.remote_history_command_error(
            helper.subprocess.CompletedProcess(
                ["ssh"], 255, "", "Permission denied (publickey,password)."
            )
        )
        self.assertIn("Open GUIDE", result)
        self.assertNotIn("Copy the SSH guide", result)
        self.assertIn("dedicated plugin key", result)

    def test_ssh_agent_errors_explain_the_gui_session_requirement(self):
        result = helper.remote_history_command_error(
            helper.subprocess.CompletedProcess(
                ["ssh"], 255, "",
                "Could not open a connection to your authentication agent."
            )
        )
        self.assertIn("not available to Omarchy", result)
        self.assertIn("desktop SSH agent", result)

    def test_remote_history_uses_dedicated_key_when_present(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.REMOTE_HISTORY_IDENTITY_PATH
            helper.REMOTE_HISTORY_IDENTITY_PATH = Path(directory) / "omarchy-homeassistant-ac"
            helper.REMOTE_HISTORY_IDENTITY_PATH.write_text("test key placeholder", encoding="utf-8")
            try:
                command = helper.remote_history_ssh_command("sai@192.168.0.10", 22)
                self.assertIn("-i", command)
                self.assertIn(str(helper.REMOTE_HISTORY_IDENTITY_PATH), command)
                self.assertIn("IdentitiesOnly=yes", command)
            finally:
                helper.REMOTE_HISTORY_IDENTITY_PATH = original_path

    def test_remote_history_uses_standard_user_agent_when_terminal_socket_is_missing(self):
        with tempfile.TemporaryDirectory() as directory:
            runtime_dir = Path(directory)
            socket_path = runtime_dir / "ssh-agent.socket"
            socket_path.touch()
            with patch.dict(
                helper.os.environ,
                {"SSH_AUTH_SOCK": "", "XDG_RUNTIME_DIR": str(runtime_dir)},
                clear=False,
            ), patch.object(helper.Path, "is_socket", return_value=True):
                self.assertEqual(
                    helper.remote_history_agent_args(),
                    ["-o", f"IdentityAgent={socket_path}"],
                )

    def test_settings_uses_maintenance_without_privacy_banner_or_copy_guide(self):
        panel = (HELPER.parent / "Panel.qml").read_text(encoding="utf-8")
        self.assertIn('label: "MAINTENANCE"', panel)
        self.assertNotIn("PRIVACY & DATA", panel)
        self.assertNotIn("NO TELEMETRY LOGGING", panel)
        self.assertNotIn("COPY GUIDE", panel)
        self.assertIn("EXTERNAL_SERVER_HISTORY.md", panel)

    def test_external_server_reconnect_does_not_always_install(self):
        panel = (HELPER.parent / "Panel.qml").read_text(encoding="utf-8")
        self.assertIn('command = ["python3", root.helperPath, "connect-remote-history"]', panel)
        self.assertIn('"CONNECT TO SERVER"', panel)
        self.assertIn('"INSTALL / UPDATE TIMER"', panel)
        self.assertNotIn('"INSTALL SERVER TIMER"', panel)
        self.assertIn("remoteHistoryConnected", panel)
        self.assertIn("history_available", panel)
        self.assertIn("history_ping_ms", panel)
        self.assertNotIn('text: "PAIRED"', panel)
        self.assertNotIn(
            'id: externalHistoryConnectionStatus\n'
            '                          connected: root.connected',
            panel,
        )

    def test_external_server_address_stays_a_draft_while_typing(self):
        panel = (HELPER.parent / "Panel.qml").read_text(encoding="utf-8")
        self.assertIn("property bool remoteHistoryPairingSaved: false", panel)
        self.assertIn(
            'readonly property bool remoteHistoryConfigured: historySource === "server"\n'
            '    && remoteHistoryPairingSaved',
            panel,
        )
        target_field = panel.split('id: remoteHistoryTargetField', 1)[1].split(
            'id: remoteHistoryPortField', 1
        )[0]
        self.assertIn("onTextChanged", target_field)
        self.assertNotIn("startRemoteHistoryConnect", target_field)

    def test_settings_sections_put_experimental_before_maintenance(self):
        panel = (HELPER.parent / "Panel.qml").read_text(encoding="utf-8")
        start = panel.index("readonly property var settingsSections:")
        end = panel.index("readonly property bool setupCanSubmit:", start)
        section_model = panel[start:end]
        values = [
            "preferences",
            "shortcuts",
            "customisation",
            "experimental",
            "maintenance",
        ]
        positions = [section_model.index(f'value: "{value}"') for value in values]
        self.assertEqual(positions, sorted(positions))

    def test_shortcut_display_uses_compact_arrow_symbols(self):
        panel = (HELPER.parent / "Panel.qml").read_text(encoding="utf-8")
        self.assertIn('LEFT: "←", RIGHT: "→", UP: "↑", DOWN: "↓"', panel)
        self.assertIn("return displayNames[part] || part", panel)

    def test_dropdown_trigger_toggles_using_visible_popup_state(self):
        dropdown = (HELPER.parent / "AcDropdown.qml").read_text(encoding="utf-8")
        self.assertIn("readonly property bool popupOpen: popup.visible", dropdown)
        self.assertIn("function toggle() { popup.visible ? popup.close() : popup.open() }", dropdown)
        self.assertNotIn("popup.opened ? popup.close() : popup.open()", dropdown)

    def test_multi_ac_ambient_card_keeps_the_standard_label(self):
        panel = (HELPER.parent / "Panel.qml").read_text(encoding="utf-8")
        self.assertIn('text: "AMBIENT"', panel)
        self.assertNotIn('text: root.multiUnitActive ? "AVG AMBIENT" : "AMBIENT"', panel)
        self.assertIn("width: parent.width - Style.space(16)", panel)
        self.assertIn("horizontalAlignment: Text.AlignHCenter", panel)
        self.assertIn("readonly property color ambientTemperatureTint", panel)
        self.assertIn("root.alpha(root.ambientTemperatureTint, 0.075)", panel)
        self.assertIn("root.mixTemperatureColors(green, amber", panel)
        self.assertNotIn("if (!connected || !isFinite(parsed)) return root.foreground", panel)
        self.assertIn("if (!isFinite(parsed)) return root.foreground", panel)
        self.assertIn('text: "EXPERIMENTAL · Optional extras; some details may be less polished."', panel)

    def test_temperature_units_and_chart_gradient_are_wired(self):
        panel = (HELPER.parent / "Panel.qml").read_text(encoding="utf-8")
        chart = (HELPER.parent / "TemperatureHistoryChart.qml").read_text(encoding="utf-8")
        self.assertIn('text: "TEMPERATURE UNIT"', panel)
        self.assertIn('{ value: "celsius", label: "CELSIUS" }', panel)
        self.assertIn('{ value: "fahrenheit", label: "FAHRENHEIT" }', panel)
        self.assertIn('{ value: "kelvin", label: "KELVIN" }', panel)
        self.assertNotIn('label: "Kelvin option"', panel)
        self.assertNotIn('text: "EXTRA CUSTOMISATIONS"', panel)
        self.assertNotIn("Adjust the plugin's accent and visual finish.", panel)
        self.assertIn('label: "Extra customisations"', panel)
        self.assertIn('text: "OPEN CUSTOMISATION"', panel)
        self.assertIn('{ value: "customisation", label: "CUSTOMISATION" }', panel)
        self.assertIn('{ value: "shortcuts", label: "SHORTCUTS" }', panel)
        self.assertIn('id: shortcutsCard', panel)
        self.assertIn('id: multiAcPowerShortcutsCard', panel)
        self.assertIn('"RESET SHORTCUTS"', panel)
        self.assertIn('fontSizeMode: Text.HorizontalFit', panel)
        self.assertIn('text: "AMBIENT TEMPERATURE CHART"', panel)
        self.assertIn('text: "HISTORY SOURCE"', panel)
        self.assertIn('settingsSection === "customisation"', panel)
        self.assertIn('id: appearanceOptionsComponent', panel)
        self.assertIn('id: customisationCard', panel)
        self.assertIn('id: customisationOptionsLoader', panel)
        self.assertIn("id: multiAirconOptionsCard", panel)
        self.assertIn("implicitHeight: multiAirconOptions.implicitHeight + Style.space(20)", panel)
        self.assertIn("borderSpec: Border.none()", panel)
        self.assertIn("- barTemperatureChoices.spacing * 2) / 3", panel)
        self.assertNotIn('label: "CURRENT"', panel)
        self.assertNotIn('{ value: "single"', panel)
        self.assertNotIn("barTemperatureEntity", panel)
        self.assertIn("property bool showClimateControls: true", panel)
        self.assertIn("showClimateControls: root.showClimateControls", panel)
        self.assertIn("root.setShowClimateControlsEnabled(!root.showClimateControls)", panel)
        self.assertIn('visible: root.customAppearanceEnabled', panel)
        self.assertIn('label: "Auto · Omarchy background"', panel)
        self.assertIn('label: "PANEL BACKGROUND"', panel)
        self.assertIn("appearance_auto_background", panel)
        self.assertIn("appearanceBackgroundColor", panel)
        self.assertIn('label: "CONFIG FILE MODE"', panel)
        self.assertIn('id: configFileCard', panel)
        self.assertIn('id: configFileEditor', panel)
        self.assertIn('command = ["python3", root.helperPath, "set-config-file"]', panel)
        self.assertIn("Ctrl+Enter", panel)
        self.assertIn('label: "Compact UI · remove cards and borders"', panel)
        self.assertIn("appearance_compact", panel)
        self.assertIn('label: "Auto · Omarchy accent"', panel)
        self.assertIn('"RESET CUSTOMISATIONS"', panel)
        self.assertIn('label: "SWITCH & SLIDER COLOUR"', panel)
        self.assertIn('label: "Per-device colours"', panel)
        self.assertIn("AppearanceColorRow", panel)
        self.assertIn("appearance_device_colors_enabled", panel)
        self.assertIn("controlAccentColor", panel)
        self.assertIn("readonly property real uiRadius", panel)
        self.assertIn("readonly property real panelRadius: uiRadius", panel)
        self.assertIn("readonly property real nestedRadius: uiRadius", panel)
        self.assertIn("readonly property real compactRadius: uiRadius", panel)
        self.assertIn("panelRadius: root.uiRadius", panel)
        self.assertIn("maximum: 100", panel)
        self.assertIn("temperatureValueFontSize(", panel)
        self.assertIn("function temperatureCelsius(value)", chart)
        self.assertIn("function addTemperatureGradientStops", chart)
        self.assertIn("root.addTemperatureGradientStops(lineGradient", chart)
        self.assertIn("33, 35", chart)
        self.assertIn("function historySummary()", chart)
        self.assertIn('{ key: "PEAK", label: "Peak" }', chart)
        self.assertIn('{ key: "AVERAGE", label: "Average" }', chart)
        self.assertIn('{ key: "LOW", label: "Low" }', chart)
        self.assertIn('text: root.summaryValueText(summaryValue)', chart)
        self.assertIn("property bool showLiveIndicator: false", chart)
        self.assertIn("width: root.showLiveIndicator ? Style.space(8) : 0", chart)
        self.assertIn("spacing: root.showLiveIndicator ? Style.space(5) : 0", chart)
        self.assertIn("showLiveIndicator: root.historySource === \"server\"", panel)

    def test_remote_history_path_is_written_to_the_logger_config(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            helper.CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
            helper.CONFIG_PATH.write_text(json.dumps({
                "url": "http://ha.example.test:8123",
                "token": "test-secret",
                "entity_id": "climate.office",
            }), encoding="utf-8")
            try:
                fake_results = [
                    helper.subprocess.CompletedProcess(["ssh"], 0, "", ""),
                    helper.subprocess.CompletedProcess(["scp"], 0, "", ""),
                    helper.subprocess.CompletedProcess(["scp"], 0, "", ""),
                    helper.subprocess.CompletedProcess(["ssh"], 0, "", ""),
                    helper.subprocess.CompletedProcess(["ssh"], 0, "", ""),
                    helper.subprocess.CompletedProcess(["ssh"], 0, "", ""),
                ]
                with patch.object(helper.subprocess, "run", side_effect=fake_results) as run:
                    with contextlib.redirect_stdout(io.StringIO()):
                        result = helper.install_remote_history(
                            helper.load_config(),
                            {
                                "ssh_target": "sai@192.168.1.20",
                                "ssh_port": 22,
                                "home_assistant_url": "http://127.0.0.1:8123",
                                "history_path": "~/.local/state/custom-ac.json",
                                "entity_id": "climate.office",
                            },
                        )
                self.assertEqual(result, 0)
                config_inputs = [call.kwargs.get("input") or "" for call in run.call_args_list]
                remote_config = next(value for value in config_inputs if "test-secret" in value)
                self.assertEqual(json.loads(remote_config)["history_path"], "~/.local/state/custom-ac.json")
            finally:
                helper.CONFIG_PATH = original_path

    def test_reset_app_removes_only_plugin_data(self):
        with tempfile.TemporaryDirectory() as directory:
            original_config_path = helper.CONFIG_PATH
            original_history_path = helper.HISTORY_PATH
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            helper.HISTORY_PATH = Path(directory) / "omarchy" / "temperature.json"
            server_marker = Path(directory) / "homeassistant-server-data"
            server_marker.write_text("keep", encoding="utf-8")
            try:
                helper.CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
                helper.CONFIG_PATH.write_text('{"token":"test-secret"}\n', encoding="utf-8")
                helper.HISTORY_PATH.write_text('{"entities":{}}\n', encoding="utf-8")
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    result = helper.reset_app()
                self.assertEqual(result, 0)
                parsed = json.loads(output.getvalue())
                self.assertTrue(parsed["reset"])
                self.assertFalse(helper.CONFIG_PATH.exists())
                self.assertFalse(helper.HISTORY_PATH.exists())
                self.assertTrue(server_marker.exists())
            finally:
                helper.CONFIG_PATH = original_config_path
                helper.HISTORY_PATH = original_history_path

    def test_mode_and_fan_requests_use_home_assistant_capabilities(self):
        original_urlopen = helper.urlopen
        requests = []
        state = {
            "entity_id": "climate.office",
            "state": "cool",
            "attributes": {
                "friendly_name": "Office",
                "current_temperature": 24,
                "temperature": 22,
                "temperature_unit": "C",
                "hvac_modes": ["off", "cool", "heat"],
                "fan_mode": "Auto",
                "fan_modes": ["Auto", "Low", "High"],
            },
        }

        def fake_urlopen(request, timeout):
            requests.append((request.full_url, json.loads(request.data) if request.data else None))
            return FakeResponse(state if request.method == "GET" else {"ok": True})

        helper.urlopen = fake_urlopen
        try:
            mode_output = io.StringIO()
            with contextlib.redirect_stdout(mode_output):
                self.assertEqual(
                    helper.set_hvac_mode("http://ha.local:8123", "secret", "climate.office", "Heat"),
                    0,
                )
            mode_result = json.loads(mode_output.getvalue())
            self.assertEqual(mode_result["requested_mode"], "heat")
            self.assertTrue(mode_result["restarting"])
            self.assertEqual(requests[-2][0], "http://ha.local:8123/api/services/climate/set_hvac_mode")
            self.assertEqual(requests[-2][1]["hvac_mode"], "heat")
            self.assertEqual(requests[-1][0], "http://ha.local:8123/api/services/climate/turn_on")
            self.assertEqual(requests[-1][1]["entity_id"], "climate.office")

            fan_output = io.StringIO()
            with contextlib.redirect_stdout(fan_output):
                self.assertEqual(
                    helper.set_fan_mode("http://ha.local:8123", "secret", "climate.office", "High"),
                    0,
                )
            self.assertEqual(json.loads(fan_output.getvalue())["requested_fan_mode"], "High")
            self.assertEqual(requests[-1][1]["fan_mode"], "High")
        finally:
            helper.urlopen = original_urlopen

    def test_turn_off_all_targets_every_available_climate_entity(self):
        original_urlopen = helper.urlopen
        requests = []
        states = [
            {
                "entity_id": "climate.bedroom",
                "state": "cool",
                "attributes": {"friendly_name": "Bedroom"},
            },
            {
                "entity_id": "climate.living_room",
                "state": "off",
                "attributes": {"friendly_name": "Living room"},
            },
            {
                "entity_id": "climate.garage",
                "state": "unavailable",
                "attributes": {"friendly_name": "Garage"},
            },
        ]

        def fake_urlopen(request, timeout):
            requests.append((request.full_url, json.loads(request.data) if request.data else None))
            if request.method == "GET":
                return FakeResponse(states)
            return FakeResponse({"ok": True})

        helper.urlopen = fake_urlopen
        try:
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                result = helper.turn_off_all("http://ha.local:8123", "secret")
            self.assertEqual(result, 0)
            parsed = json.loads(output.getvalue())
            self.assertEqual(parsed["count"], 2)
            self.assertEqual(parsed["turned_off"], ["climate.bedroom", "climate.living_room"])
            self.assertEqual(
                requests[-1][0],
                "http://ha.local:8123/api/services/climate/turn_off",
            )
            self.assertEqual(
                requests[-1][1]["entity_id"],
                ["climate.bedroom", "climate.living_room"],
            )
        finally:
            helper.urlopen = original_urlopen

    def test_turn_on_all_targets_every_available_climate_entity(self):
        original_urlopen = helper.urlopen
        requests = []
        states = [
            {
                "entity_id": "climate.bedroom",
                "state": "off",
                "attributes": {"friendly_name": "Bedroom"},
            },
            {
                "entity_id": "climate.living_room",
                "state": "cool",
                "attributes": {"friendly_name": "Living room"},
            },
            {
                "entity_id": "climate.garage",
                "state": "unavailable",
                "attributes": {"friendly_name": "Garage"},
            },
        ]

        def fake_urlopen(request, timeout):
            requests.append((request.full_url, json.loads(request.data) if request.data else None))
            if request.method == "GET":
                return FakeResponse(states)
            return FakeResponse({"ok": True})

        helper.urlopen = fake_urlopen
        try:
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                result = helper.turn_on_all("http://ha.local:8123", "secret")
            self.assertEqual(result, 0)
            parsed = json.loads(output.getvalue())
            self.assertEqual(parsed["count"], 2)
            self.assertEqual(parsed["turned_on"], ["climate.bedroom", "climate.living_room"])
            self.assertEqual(
                requests[-1][0],
                "http://ha.local:8123/api/services/climate/turn_on",
            )
            self.assertEqual(
                requests[-1][1]["entity_id"],
                ["climate.bedroom", "climate.living_room"],
            )
        finally:
            helper.urlopen = original_urlopen

    def test_turn_off_all_reports_verified_success_after_transport_timeout(self):
        original_urlopen = helper.urlopen
        requests = []
        off_states = [
            {
                "entity_id": "climate.bedroom",
                "state": "off",
                "attributes": {"friendly_name": "Bedroom"},
            },
            {
                "entity_id": "climate.living_room",
                "state": "off",
                "attributes": {"friendly_name": "Living room"},
            },
        ]

        def fake_urlopen(request, timeout):
            requests.append((request.full_url, request.method))
            if request.method == "GET":
                return FakeResponse(off_states)
            raise helper.HomeAssistantError(
                "Home Assistant request timed out at http://ha.local:8123"
            )

        helper.urlopen = fake_urlopen
        try:
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                result = helper.turn_off_all("http://ha.local:8123", "secret")
            self.assertEqual(result, 0)
            parsed = json.loads(output.getvalue())
            self.assertTrue(parsed["ok"])
            self.assertTrue(parsed["verified"])
            self.assertEqual(parsed["turned_off"], [
                "climate.bedroom",
                "climate.living_room",
            ])
            self.assertIn("reports every climate device off", parsed["message"])
            self.assertEqual(requests[-1][1], "GET")
        finally:
            helper.urlopen = original_urlopen

    def test_multi_status_returns_selected_units_in_order(self):
        original_urlopen = helper.urlopen
        states = [
            {
                "entity_id": "climate.living_room",
                "state": "cool",
                "attributes": {
                    "friendly_name": "Living room",
                    "current_temperature": 25,
                    "temperature": 22,
                    "temperature_unit": "C",
                    "hvac_modes": ["off", "cool", "heat"],
                },
            },
            {
                "entity_id": "climate.bedroom",
                "state": "off",
                "attributes": {
                    "friendly_name": "Bedroom",
                    "current_temperature": 24,
                    "temperature": 23,
                    "temperature_unit": "C",
                    "hvac_modes": ["off", "cool"],
                },
            },
        ]

        def fake_urlopen(request, timeout):
            self.assertEqual(request.full_url, "http://ha.local:8123/api/states")
            return FakeResponse(states)

        helper.urlopen = fake_urlopen
        try:
            output = io.StringIO()
            with patch.object(helper, "record_temperature_history", return_value=[]), \
                    contextlib.redirect_stdout(output):
                result = helper.status(
                    "http://ha.local:8123",
                    "secret",
                    "climate.bedroom",
                    {
                        "multi_unit_enabled": True,
                        "global_sync_controls": True,
                        "selected_entities": ["climate.bedroom", "climate.living_room"],
                    },
                )
            self.assertEqual(result, 0)
            parsed = json.loads(output.getvalue())
            self.assertEqual(
                [unit["entity_id"] for unit in parsed["units"]],
                ["climate.bedroom", "climate.living_room"],
            )
            self.assertEqual(parsed["entity_id"], "climate.bedroom")
            self.assertEqual(parsed["selected_entities"], [
                "climate.bedroom",
                "climate.living_room",
            ])
            self.assertGreaterEqual(parsed["ping_ms"], 0)
            self.assertFalse(parsed["units"][0]["state"] != "off")
            self.assertTrue(parsed["units"][1]["state"] != "off")
        finally:
            helper.urlopen = original_urlopen

    def test_set_selection_persists_active_entity_and_selected_list(self):
        with tempfile.TemporaryDirectory() as directory:
            original_path = helper.CONFIG_PATH
            helper.CONFIG_PATH = Path(directory) / "omarchy" / "home-assistant-ac.json"
            try:
                config = {
                    "url": "http://ha.local:8123",
                    "token": "secret",
                    "entity_id": "climate.office",
                }
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    result = helper.set_selection(config, {
                        "entity_id": "climate.living_room",
                        "entities": ["climate.office", "climate.living_room"],
                    })
                self.assertEqual(result, 0)
                parsed = json.loads(output.getvalue())
                self.assertEqual(parsed["entity_id"], "climate.living_room")
                self.assertEqual(parsed["selected_entities"], [
                    "climate.office",
                    "climate.living_room",
                ])
                saved = json.loads(helper.CONFIG_PATH.read_text(encoding="utf-8"))
                self.assertEqual(saved["entity_id"], "climate.living_room")
                self.assertEqual(saved["selected_entities"], [
                    "climate.office",
                    "climate.living_room",
                ])
            finally:
                helper.CONFIG_PATH = original_path

    def test_multi_temperature_sends_one_service_call_to_selected_units(self):
        original_urlopen = helper.urlopen
        requests = []
        states = [
            {
                "entity_id": "climate.bedroom",
                "state": "cool",
                "attributes": {
                    "current_temperature": 24,
                    "temperature": 22,
                    "temperature_unit": "C",
                    "min_temp": 16,
                    "max_temp": 30,
                },
            },
            {
                "entity_id": "climate.living_room",
                "state": "cool",
                "attributes": {
                    "current_temperature": 25,
                    "temperature": 22,
                    "temperature_unit": "C",
                    "min_temp": 16,
                    "max_temp": 30,
                },
            },
        ]

        def fake_urlopen(request, timeout):
            requests.append((request.full_url, json.loads(request.data) if request.data else None))
            return FakeResponse(states if request.method == "GET" else {"ok": True})

        helper.urlopen = fake_urlopen
        try:
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                result = helper.set_temperature(
                    "http://ha.local:8123",
                    "secret",
                    "climate.bedroom",
                    "23",
                    ["climate.bedroom", "climate.living_room"],
                )
            self.assertEqual(result, 0)
            self.assertEqual(len(requests), 2)
            self.assertEqual(requests[-1][1]["entity_id"], [
                "climate.bedroom",
                "climate.living_room",
            ])
            self.assertEqual(json.loads(output.getvalue())["entity_ids"], [
                "climate.bedroom",
                "climate.living_room",
            ])
        finally:
            helper.urlopen = original_urlopen

    def test_non_power_sync_keeps_batch_controls_when_power_is_separate(self):
        selected = ["climate.bedroom", "climate.living_room"]
        config = {
            "multi_unit_enabled": True,
            "global_sync_controls": False,
            "sync_non_power_controls": True,
            "selected_entities": selected,
            "entity_id": selected[0],
        }
        self.assertEqual(
            helper.control_entity_ids(config, selected[0]), selected
        )
        self.assertEqual(
            helper.control_entity_ids(config, selected[0], selected[1]), [selected[1]]
        )

        config["sync_non_power_controls"] = False
        self.assertEqual(
            helper.control_entity_ids(config, selected[0]), [selected[0]]
        )


if __name__ == "__main__":
    unittest.main()
