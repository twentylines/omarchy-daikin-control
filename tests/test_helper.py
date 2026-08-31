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
loader = SourceFileLoader("ha_helper", str(HELPER))
spec = importlib.util.spec_from_loader(loader.name, loader)
assert spec and spec.loader
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)


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
        self.assertIn("external server must be the same host", guide)
        self.assertIn("COPY SOURCE", guide)
        self.assertIn("ssh-copy-id", guide)

    def test_ssh_auth_error_points_to_manual_guide(self):
        result = helper.remote_history_command_error(
            helper.subprocess.CompletedProcess(
                ["ssh"], 255, "", "Permission denied (publickey,password)."
            )
        )
        self.assertIn("Open GUIDE", result)
        self.assertNotIn("Copy the SSH guide", result)
        self.assertIn("dedicated plugin key", result)

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

    def test_settings_uses_maintenance_without_privacy_banner_or_copy_guide(self):
        panel = (HELPER.parent / "Panel.qml").read_text(encoding="utf-8")
        self.assertIn('label: "MAINTENANCE"', panel)
        self.assertNotIn("PRIVACY & DATA", panel)
        self.assertNotIn("NO TELEMETRY LOGGING", panel)
        self.assertNotIn("COPY GUIDE", panel)
        self.assertIn("EXTERNAL_SERVER_HISTORY.md", panel)

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
