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


if __name__ == "__main__":
    unittest.main()
