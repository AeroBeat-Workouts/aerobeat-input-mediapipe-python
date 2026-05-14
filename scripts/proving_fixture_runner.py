#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_OUTPUT_ROOT = REPO_ROOT / ".testbed/test-results/fixtures"
DEFAULT_CAPTURE_DELAY_MS = 5000
SUPPORTED_FAMILIES = {
    "boxing": "res://scenes/boxing_proving.tscn",
    "flow": "res://scenes/flow_proving.tscn",
}


class FixtureError(RuntimeError):
    pass


@dataclass
class Fixture:
    path: Path
    fixture_id: str
    family: str
    video_path: Path
    scene_path: str
    expected_gestures: list[dict[str, Any]]
    forbidden_gestures: list[dict[str, Any]]
    warnings: list[str]
    raw: dict[str, Any]


@dataclass
class ValidationResult:
    ok: bool
    assertions: list[dict[str, Any]]
    warnings: list[str]
    matched_events: dict[str, list[int]]


def main(argv: list[str]) -> int:
    if len(argv) < 2 or len(argv) > 4:
        print(
            "usage: scripts/run_proving_fixture_capture.sh <fixture.yaml> [output-dir] [capture-delay-ms]",
            file=sys.stderr,
        )
        return 2

    fixture_path = resolve_cli_path(argv[1])
    output_root = resolve_cli_path(argv[2]) if len(argv) >= 3 else DEFAULT_OUTPUT_ROOT
    capture_delay_ms = parse_capture_delay(argv[3]) if len(argv) >= 4 else DEFAULT_CAPTURE_DELAY_MS

    fixture = load_fixture(fixture_path)
    run_id = f"{datetime.now().strftime('%Y%m%d-%H%M%S')}__{fixture.fixture_id}"
    out_dir = output_root / run_id
    out_dir.mkdir(parents=True, exist_ok=True)
    log_path = out_dir / "godot.log"

    print(f"[run_proving_fixture_capture] fixture={fixture.path}")
    print(f"[run_proving_fixture_capture] video={fixture.video_path}")
    print(f"[run_proving_fixture_capture] scene={fixture.scene_path}")
    print(f"[run_proving_fixture_capture] out_dir={out_dir}")

    run_capture(fixture, out_dir, log_path, capture_delay_ms)

    capture_report_path = out_dir / "report.json"
    if not capture_report_path.is_file():
        raise FixtureError(f"capture report missing: {capture_report_path}")

    with capture_report_path.open("r", encoding="utf-8") as handle:
        capture_report = json.load(handle)

    validation = validate_capture(fixture, capture_report)
    write_outputs(fixture, capture_report, validation, out_dir)

    print(f"log={log_path}")
    print(f"capture_report={capture_report_path}")
    print(f"summary={out_dir / 'summary.json'}")
    print(f"assertions={out_dir / 'assertions.json'}")
    print(f"event_timeline={out_dir / 'event_timeline.json'}")
    print(f"state_timeline={out_dir / 'state_timeline.json'}")
    print(f"report_md={out_dir / 'report.md'}")
    print(f"screenshot={out_dir / 'proving.png'}")
    return 0


def resolve_cli_path(raw_path: str) -> Path:
    path = Path(raw_path)
    if not path.is_absolute():
        path = REPO_ROOT / path
    return path.resolve()


def parse_capture_delay(raw_value: str) -> int:
    try:
        value = int(raw_value)
    except ValueError as exc:
        raise FixtureError(f"capture delay must be an integer, got: {raw_value}") from exc
    return max(value, 1000)


def load_fixture(path: Path) -> Fixture:
    if not path.is_file():
        raise FixtureError(f"fixture not found: {path}")

    with path.open("r", encoding="utf-8") as handle:
        raw = yaml.safe_load(handle) or {}
    if not isinstance(raw, dict):
        raise FixtureError(f"fixture must be a YAML mapping: {path}")

    fixture_id = str(raw.get("fixture_id") or path.stem.replace(".fixture", "")).strip()
    if not fixture_id:
        raise FixtureError(f"fixture_id missing in {path}")

    family = str(raw.get("family") or "boxing").strip().lower()
    if family not in SUPPORTED_FAMILIES:
        raise FixtureError(f"unsupported fixture family in {path}: {family}")

    warnings: list[str] = []
    video_path = resolve_fixture_video_path(path, raw)
    expected_gestures = normalize_expected_gestures(raw, warnings)
    forbidden_gestures = normalize_forbidden_gestures(raw)

    return Fixture(
        path=path,
        fixture_id=fixture_id,
        family=family,
        video_path=video_path,
        scene_path=SUPPORTED_FAMILIES[family],
        expected_gestures=expected_gestures,
        forbidden_gestures=forbidden_gestures,
        warnings=warnings,
        raw=raw,
    )


def resolve_fixture_video_path(fixture_path: Path, raw: dict[str, Any]) -> Path:
    video_value: Any = None
    video_node = raw.get("video")
    if isinstance(video_node, dict):
        video_value = video_node.get("path")
    if not video_value:
        video_value = raw.get("video_file")
    if not isinstance(video_value, str) or not video_value.strip():
        raise FixtureError(f"fixture video path missing in {fixture_path}; expected video.path or video_file")
    candidate = Path(video_value.strip())
    if not candidate.is_absolute():
        candidate = (fixture_path.parent / candidate).resolve()
    if not candidate.is_file():
        raise FixtureError(f"fixture video not found for {fixture_path}: {candidate}")
    return candidate


def normalize_expected_gestures(raw: dict[str, Any], warnings: list[str]) -> list[dict[str, Any]]:
    normalized: list[dict[str, Any]] = []
    if isinstance(raw.get("expected_gestures"), list):
        source_items = raw["expected_gestures"]
        for index, item in enumerate(source_items):
            normalized.append(normalize_expected_gesture_item(item, index))
        return normalized

    legacy = ((raw.get("expected_detector_behavior") or {}).get("expected_events"))
    if isinstance(legacy, list):
        for index, item in enumerate(legacy):
            if not isinstance(item, dict):
                raise FixtureError(f"legacy expected_events[{index}] must be a mapping")
            if "window_ms" not in item and "windows_ms" not in item and "windows" not in item:
                warnings.append(
                    "legacy expected_events entries without direct windows were ignored; author expected_gestures windows for real validation"
                )
                continue
            normalized.append(normalize_expected_gesture_item(item, index, legacy_mode=True))
    return normalized


def normalize_expected_gesture_item(item: Any, index: int, legacy_mode: bool = False) -> dict[str, Any]:
    if not isinstance(item, dict):
        raise FixtureError(f"expected_gestures[{index}] must be a mapping")
    name = str(item.get("name") or "").strip()
    if not name:
        raise FixtureError(f"expected_gestures[{index}] is missing name")

    payload = item.get("payload") if isinstance(item.get("payload"), dict) else {}
    surface = str(item.get("surface") or "event").strip().lower()
    if surface not in {"event", "state"}:
        raise FixtureError(f"expected_gestures[{index}] for {name} surface must be 'event' or 'state'")
    windows_source = item.get("windows")
    if windows_source is None:
        windows_source = item.get("windows_ms")
    if windows_source is None and isinstance(item.get("window_ms"), dict):
        windows_source = [item.get("window_ms")]
    if not isinstance(windows_source, list) or not windows_source:
        raise FixtureError(f"expected_gestures[{index}] for {name} must declare one or more {surface} windows")

    windows: list[dict[str, int]] = []
    for window_index, window in enumerate(windows_source):
        windows.append(normalize_window(window, f"expected_gestures[{index}].windows[{window_index}]") )

    return {
        "name": name,
        "payload": payload,
        "surface": surface,
        "windows": windows,
        "source": "legacy_expected_events" if legacy_mode else "expected_gestures",
    }


def normalize_window(window: Any, label: str) -> dict[str, int]:
    if not isinstance(window, dict):
        raise FixtureError(f"{label} must be a mapping")
    start_value = window.get("start_ms", window.get("start"))
    end_value = window.get("end_ms", window.get("end"))
    if start_value is None or end_value is None:
        raise FixtureError(f"{label} must define start/start_ms and end/end_ms")
    try:
        start_ms = int(start_value)
        end_ms = int(end_value)
    except (TypeError, ValueError) as exc:
        raise FixtureError(f"{label} start/end must be integers") from exc
    if end_ms < start_ms:
        raise FixtureError(f"{label} end must be >= start")
    return {"start_ms": start_ms, "end_ms": end_ms}


def normalize_forbidden_gestures(raw: dict[str, Any]) -> list[dict[str, Any]]:
    source = raw.get("forbidden_gestures")
    if source is None:
        source = ((raw.get("expected_detector_behavior") or {}).get("forbidden_events"))
    if source is None:
        return []
    if not isinstance(source, list):
        raise FixtureError("forbidden_gestures must be a list")

    normalized: list[dict[str, Any]] = []
    for index, item in enumerate(source):
        if isinstance(item, str):
            name = item.strip()
            if not name:
                raise FixtureError(f"forbidden_gestures[{index}] cannot be empty")
            normalized.append({"name": name})
            continue
        if isinstance(item, dict):
            name = str(item.get("name") or "").strip()
            if not name:
                raise FixtureError(f"forbidden_gestures[{index}] is missing name")
            normalized.append({"name": name})
            continue
        raise FixtureError(f"forbidden_gestures[{index}] must be a string or mapping")
    return normalized


def run_capture(fixture: Fixture, out_dir: Path, log_path: Path, capture_delay_ms: int) -> None:
    env = os.environ.copy()
    env["AEROBEAT_MEDIAPIPE_CAMERA_SOURCE"] = str(fixture.video_path)
    env["AEROBEAT_MEDIAPIPE_SHOW_WINDOW"] = "0"

    command = [
        "godot",
        "--path",
        ".testbed",
        "-s",
        "res://scripts/capture_fixture_proving.gd",
        "--",
        fixture.scene_path,
        str(fixture.path),
        str(out_dir),
        str(capture_delay_ms),
    ]

    with log_path.open("w", encoding="utf-8") as log_handle:
        completed = subprocess.run(
            command,
            cwd=REPO_ROOT,
            env=env,
            stdout=log_handle,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
        )
    if completed.returncode != 0:
        raise FixtureError(f"godot capture failed with exit code {completed.returncode}; see {log_path}")


def validate_capture(fixture: Fixture, capture_report: dict[str, Any]) -> ValidationResult:
    harness_capture = capture_report.get("fixture_capture") or {}
    if not isinstance(harness_capture, dict):
        harness_capture = {}
    event_timeline = harness_capture.get("event_timeline") or []
    state_timeline = harness_capture.get("state_timeline") or []
    warnings = list(fixture.warnings)
    assertions: list[dict[str, Any]] = []

    if not event_timeline:
        warnings.append("capture report did not include a structured event timeline")
    if not state_timeline:
        warnings.append("capture report did not include structured state snapshots")

    indexed_events = []
    for idx, event in enumerate(event_timeline):
        if not isinstance(event, dict):
            continue
        indexed_events.append({
            "index": idx,
            "name": str(event.get("name") or ""),
            "timestamp_ms": int(event.get("timestamp_ms") or 0),
            "payload": event.get("payload") if isinstance(event.get("payload"), dict) else {},
            "raw": event,
        })

    matched_events: dict[str, list[int]] = {}
    for gesture in fixture.expected_gestures:
        name = gesture["name"]
        surface = gesture.get("surface", "event")
        if surface == "state":
            state_segments = build_state_segments(state_timeline, name)
            matched_segment_indexes: set[int] = set()
            for window_index, window in enumerate(gesture["windows"]):
                overlapping_segments = [
                    segment
                    for segment in state_segments
                    if windows_overlap(window, segment)
                ]
                for segment in overlapping_segments:
                    matched_segment_indexes.add(int(segment["index"]))
                assertions.append({
                    "kind": "expected_state_window",
                    "name": name,
                    "surface": surface,
                    "window_index": window_index,
                    "expected_window_ms": window,
                    "actual_matches": [simplify_segment(segment) for segment in overlapping_segments],
                    "status": "pass" if overlapping_segments else "fail",
                    "message": (
                        f"expected {name} state to be true at least once in {window['start_ms']}-{window['end_ms']}ms; found {len(overlapping_segments)} overlapping true segment(s)"
                    ),
                })
            extra_segments = [segment for segment in state_segments if int(segment["index"]) not in matched_segment_indexes]
            assertions.append({
                "kind": "expected_state_extras",
                "name": name,
                "surface": surface,
                "expected_count": len(gesture["windows"]),
                "actual_count": len(state_segments),
                "extra_segments": [simplify_segment(segment) for segment in extra_segments],
                "status": "pass" if not extra_segments else "fail",
                "message": f"expected all {name} true-state segments to overlap authored windows; found {len(extra_segments)} unmatched segment(s)",
            })
            continue

        gesture_events = [event for event in indexed_events if event["name"] == name]
        used_indexes: set[int] = set()
        for window_index, window in enumerate(gesture["windows"]):
            candidates = [
                event for event in gesture_events
                if window["start_ms"] <= event["timestamp_ms"] <= window["end_ms"] and event["index"] not in used_indexes
            ]
            passed = len(candidates) == 1
            chosen = candidates[0] if candidates else None
            if chosen is not None:
                used_indexes.add(chosen["index"])
                matched_events.setdefault(name, []).append(chosen["index"])
            assertions.append({
                "kind": "expected_gesture_window",
                "name": name,
                "surface": surface,
                "window_index": window_index,
                "expected_window_ms": window,
                "actual_matches": [simplify_event(event) for event in candidates],
                "status": "pass" if passed else "fail",
                "message": (
                    f"expected exactly one {name} event in {window['start_ms']}-{window['end_ms']}ms; found {len(candidates)}"
                ),
            })
        extras = [event for event in gesture_events if event["index"] not in used_indexes]
        assertions.append({
            "kind": "expected_gesture_extras",
            "name": name,
            "surface": surface,
            "expected_count": len(gesture["windows"]),
            "actual_count": len(gesture_events),
            "extra_events": [simplify_event(event) for event in extras],
            "status": "pass" if not extras and len(gesture_events) == len(gesture["windows"]) else "fail",
            "message": f"expected {len(gesture['windows'])} total {name} events and no extras; found {len(gesture_events)}",
        })

    for forbidden in fixture.forbidden_gestures:
        name = forbidden["name"]
        forbidden_hits = [event for event in indexed_events if event["name"] == name]
        assertions.append({
            "kind": "forbidden_gesture",
            "name": name,
            "hits": [simplify_event(event) for event in forbidden_hits],
            "status": "pass" if not forbidden_hits else "fail",
            "message": f"forbidden gesture {name} should not appear",
        })

    if not fixture.expected_gestures:
        warnings.append("fixture has no direct expected_gestures windows yet; only forbidden-gesture checks can run")

    ok = all(assertion["status"] == "pass" for assertion in assertions)
    return ValidationResult(ok=ok, assertions=assertions, warnings=warnings, matched_events=matched_events)


def build_state_segments(state_timeline: list[Any], name: str) -> list[dict[str, Any]]:
    segments: list[dict[str, Any]] = []
    current: dict[str, Any] | None = None

    for idx, raw_state in enumerate(state_timeline):
        if not isinstance(raw_state, dict):
            continue
        timestamp_ms = int(raw_state.get("timestamp_ms") or 0)
        gesture_states = raw_state.get("gesture_states") if isinstance(raw_state.get("gesture_states"), dict) else {}
        active = bool(gesture_states.get(name))
        if active:
            if current is None:
                current = {
                    "index": len(segments),
                    "name": name,
                    "start_ms": timestamp_ms,
                    "end_ms": timestamp_ms,
                    "sample_count": 1,
                    "first_state_index": idx,
                    "last_state_index": idx,
                }
            else:
                current["end_ms"] = timestamp_ms
                current["sample_count"] = int(current["sample_count"]) + 1
                current["last_state_index"] = idx
        elif current is not None:
            segments.append(current)
            current = None

    if current is not None:
        segments.append(current)
    return segments


def windows_overlap(left: dict[str, int], right: dict[str, int]) -> bool:
    return left["start_ms"] <= right["end_ms"] and right["start_ms"] <= left["end_ms"]


def simplify_segment(segment: dict[str, Any]) -> dict[str, Any]:
    return {
        "name": segment["name"],
        "start_ms": segment["start_ms"],
        "end_ms": segment["end_ms"],
        "sample_count": segment["sample_count"],
        "index": segment["index"],
    }


def simplify_event(event: dict[str, Any]) -> dict[str, Any]:
    return {
        "name": event["name"],
        "timestamp_ms": event["timestamp_ms"],
        "payload": event["payload"],
        "index": event["index"],
    }


def write_outputs(
    fixture: Fixture,
    capture_report: dict[str, Any],
    validation: ValidationResult,
    out_dir: Path,
) -> None:
    fixture_capture = capture_report.get("fixture_capture") if isinstance(capture_report.get("fixture_capture"), dict) else {}
    event_timeline = fixture_capture.get("event_timeline") or []
    state_timeline = fixture_capture.get("state_timeline") or []

    summary = {
        "fixture_id": fixture.fixture_id,
        "fixture_path": str(fixture.path),
        "family": fixture.family,
        "video_path": str(fixture.video_path),
        "scene_path": fixture.scene_path,
        "time_basis": fixture_capture.get("time_basis", "unknown"),
        "result": "pass" if validation.ok else "fail",
        "assertion_counts": {
            "total": len(validation.assertions),
            "passed": sum(1 for assertion in validation.assertions if assertion["status"] == "pass"),
            "failed": sum(1 for assertion in validation.assertions if assertion["status"] == "fail"),
        },
        "warnings": validation.warnings,
        "capture_report": "report.json",
        "event_timeline": "event_timeline.json",
        "state_timeline": "state_timeline.json",
        "assertions": "assertions.json",
    }

    write_json(out_dir / "summary.json", summary)
    write_json(out_dir / "assertions.json", validation.assertions)
    write_json(out_dir / "event_timeline.json", event_timeline)
    write_json(out_dir / "state_timeline.json", state_timeline)
    (out_dir / "report.md").write_text(build_markdown_report(summary, validation.assertions), encoding="utf-8")


def build_markdown_report(summary: dict[str, Any], assertions: list[dict[str, Any]]) -> str:
    counts = summary["assertion_counts"]
    lines = [
        "# Proving Fixture Validation",
        "",
        f"- Fixture: `{summary['fixture_id']}`",
        f"- Result: **{summary['result'].upper()}**",
        f"- Family: `{summary['family']}`",
        f"- Video: `{summary['video_path']}`",
        f"- Scene: `{summary['scene_path']}`",
        f"- Time basis: `{summary['time_basis']}`",
        f"- Assertions: {counts['passed']} passed / {counts['failed']} failed / {counts['total']} total",
        "",
    ]
    warnings = summary.get("warnings") or []
    if warnings:
        lines.extend(["## Warnings", ""])
        lines.extend([f"- {warning}" for warning in warnings])
        lines.append("")

    lines.extend(["## Assertions", ""])
    if not assertions:
        lines.append("- No assertions were evaluated.")
    for assertion in assertions:
        status_icon = "✅" if assertion["status"] == "pass" else "❌"
        lines.append(f"- {status_icon} `{assertion['kind']}` `{assertion['name']}` — {assertion['message']}")
    lines.append("")
    return "\n".join(lines)


def write_json(path: Path, payload: Any) -> None:
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)
        handle.write("\n")


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv))
    except FixtureError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
