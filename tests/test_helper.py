import contextlib
import importlib.util
import io
import json
import tempfile
import unittest
from importlib.machinery import SourceFileLoader
from pathlib import Path


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

    def test_history_is_capped_to_the_latest_24_hours(self):
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
                            "timestamp": now - 25 * 60 * 60,
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


if __name__ == "__main__":
    unittest.main()
