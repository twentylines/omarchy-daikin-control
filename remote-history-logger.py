#!/usr/bin/env python3
"""Record one Home Assistant ambient temperature sample for the AC plugin.

This is a single-purpose, one-shot sampler copied to the external host that
runs Home Assistant. It performs one authenticated GET for one climate state,
writes one owner-only JSON file, and exits. It deliberately uses only Python's
standard library so it can run on a small Linux server without extra packages.

It does not install packages, open ports, call Home Assistant service/control
endpoints, or send telemetry. A separate user-owned systemd timer schedules it.
"""

from __future__ import annotations

import json
import os
import re
import sys
import tempfile
import time
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlsplit, urlunsplit
from urllib.request import Request, urlopen


CONFIG_PATH = (
    Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
    / "omarchy/homeassistant-ac-history.json"
)
HISTORY_PATH = (
    Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state")))
    / "omarchy/homeassistant-ac-temperature.json"
)
HISTORY_PATH_PATTERN = re.compile(r"^[A-Za-z0-9_./~_-]+$")
RETENTION_SECONDS = 24 * 60 * 60
MAX_SAMPLES = 6000


def fail(message: str) -> int:
    print(message, file=sys.stderr)
    return 1


def number(value: object) -> float | None:
    try:
        result = float(value)  # type: ignore[arg-type]
    except (TypeError, ValueError):
        return None
    return result if result == result else None


def unit(value: object) -> str:
    text = str(value or "°C").strip()
    if text in {"C", "c"}:
        return "°C"
    if text in {"F", "f"}:
        return "°F"
    return text if text.startswith("°") else f"°{text}"


def normalize_url(value: object) -> str:
    text = str(value or "").strip()
    if not text:
        raise ValueError("the Home Assistant URL is empty")
    if any(char.isspace() for char in text):
        raise ValueError("the Home Assistant URL contains spaces")
    if "://" not in text:
        text = f"http://{text}"
    parsed = urlsplit(text)
    if parsed.scheme.lower() not in {"http", "https"} or not parsed.netloc or not parsed.hostname:
        raise ValueError("the Home Assistant URL is invalid")
    if parsed.username or parsed.password or parsed.query or parsed.fragment:
        raise ValueError("the Home Assistant URL contains unsupported credentials or parameters")
    return urlunsplit((parsed.scheme.lower(), parsed.netloc, parsed.path.rstrip("/"), "", "")).rstrip("/")


def load_config() -> dict[str, object]:
    with CONFIG_PATH.open(encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError("the logger config must be a JSON object")
    return value


def configured_history_path(value: object) -> Path:
    """Resolve the configured chart path without accepting shell syntax."""
    text = str(value or "").strip() or "~/.local/state/omarchy/homeassistant-ac-temperature.json"
    if not HISTORY_PATH_PATTERN.fullmatch(text) or ".." in text:
        raise ValueError("the history path contains unsupported characters")
    if text.startswith("~/"):
        return Path.home() / text[2:]
    if not text.startswith("/"):
        raise ValueError("the history path must start with ~/ or /")
    return Path(text)


def load_history(history_path: Path = HISTORY_PATH) -> dict[str, list[dict[str, object]]]:
    try:
        with history_path.open(encoding="utf-8") as handle:
            raw = json.load(handle)
    except (FileNotFoundError, OSError, json.JSONDecodeError):
        return {}
    if not isinstance(raw, dict):
        return {}
    entities = raw.get("entities", raw)
    if not isinstance(entities, dict):
        return {}
    cleaned: dict[str, list[dict[str, object]]] = {}
    for entity_id, samples in entities.items():
        if not isinstance(entity_id, str) or not entity_id.startswith("climate."):
            continue
        if not isinstance(samples, list):
            continue
        valid: list[dict[str, object]] = []
        for sample in samples:
            if not isinstance(sample, dict):
                continue
            timestamp = number(sample.get("timestamp"))
            temperature = number(sample.get("temperature"))
            if timestamp is None or temperature is None:
                continue
            valid.append({
                "timestamp": int(timestamp),
                "temperature": temperature,
                "unit": unit(sample.get("unit")),
            })
        if valid:
            cleaned[entity_id] = valid[-MAX_SAMPLES:]
    return cleaned


def save_history(history: dict[str, list[dict[str, object]]], history_path: Path = HISTORY_PATH) -> None:
    history_path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=".homeassistant-ac-temperature.", dir=history_path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump({"version": 1, "entities": history}, handle, separators=(",", ":"))
            handle.write("\n")
        os.chmod(temporary, 0o600)
        os.replace(temporary, history_path)
        os.chmod(history_path, 0o600)
    except OSError:
        try:
            os.unlink(temporary)
        except OSError:
            pass
        raise


def prune(history: dict[str, list[dict[str, object]]], now: float) -> dict[str, list[dict[str, object]]]:
    cutoff = now - RETENTION_SECONDS
    return {
        entity_id: [sample for sample in samples if cutoff <= float(sample["timestamp"]) <= now + 300][-MAX_SAMPLES:]
        for entity_id, samples in history.items()
        if any(cutoff <= float(sample["timestamp"]) <= now + 300 for sample in samples)
    }


def api_state(url: str, token: str, entity_id: str) -> dict[str, object]:
    request = Request(
        url + f"/api/states/{quote(entity_id, safe='')}",
        headers={"Accept": "application/json", "Authorization": f"Bearer {token}"},
        method="GET",
    )
    try:
        with urlopen(request, timeout=8) as response:
            raw = response.read()
    except HTTPError as exc:
        raise ValueError(f"Home Assistant returned HTTP {exc.code}") from exc
    except (URLError, TimeoutError, OSError) as exc:
        raise ValueError(f"Home Assistant is unreachable: {exc}") from exc
    try:
        value = json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise ValueError("Home Assistant returned invalid JSON") from exc
    if not isinstance(value, dict):
        raise ValueError("Home Assistant returned no climate state")
    return value


def record_once() -> None:
    config = load_config()
    url = normalize_url(config.get("url"))
    token = str(config.get("token") or "").strip()
    entity_id = str(config.get("entity_id") or "").strip()
    history_path = configured_history_path(config.get("history_path"))
    if not token or not entity_id.startswith("climate."):
        raise ValueError("the logger config is missing a token or climate entity")
    state = api_state(url, token, entity_id)
    attrs = state.get("attributes") if isinstance(state.get("attributes"), dict) else {}
    ambient = number(attrs.get("current_temperature"))
    if ambient is None:
        return

    now = time.time()
    history = prune(load_history(history_path), now)
    samples = history.setdefault(entity_id, [])
    sample = {"timestamp": int(now), "temperature": ambient, "unit": unit(attrs.get("temperature_unit"))}
    if samples and int(samples[-1]["timestamp"]) >= int(now) - 45:
        samples[-1] = sample
    else:
        samples.append(sample)
    save_history(prune(history, now), history_path)


def main() -> int:
    try:
        record_once()
        return 0
    except (OSError, ValueError, KeyError) as exc:
        return fail(f"omarchy-homeassistant-ac-history: {exc}")


if __name__ == "__main__":
    raise SystemExit(main())
