from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from proving_fixture_runner import build_state_segments, load_fixture, validate_capture


class ProvingFixtureRunnerTests(unittest.TestCase):
    def test_load_fixture_resolves_relative_video_and_windows(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            video_path = root / "clip.mp4"
            video_path.write_bytes(b"fake")
            fixture_path = root / "clip.fixture.yaml"
            fixture_path.write_text(
                "\n".join(
                    [
                        "schema_version: 1",
                        "fixture_id: test_fixture",
                        "family: boxing",
                        "video:",
                        "  path: ./clip.mp4",
                        "expected_gestures:",
                        "  - name: punch_left",
                        "    windows:",
                        "      - start_ms: 100",
                        "        end_ms: 300",
                        "  - name: guard",
                        "    surface: state",
                        "    windows:",
                        "      - start_ms: 0",
                        "        end_ms: 90",
                        "forbidden_gestures:",
                        "  - name: punch_right",
                    ]
                ),
                encoding="utf-8",
            )

            fixture = load_fixture(fixture_path)

            self.assertEqual(fixture.fixture_id, "test_fixture")
            self.assertEqual(fixture.video_path, video_path.resolve())
            self.assertEqual(fixture.expected_gestures[0]["windows"][0], {"start_ms": 100, "end_ms": 300})
            self.assertEqual(fixture.expected_gestures[1]["surface"], "state")
            self.assertEqual(fixture.forbidden_gestures, [{"name": "punch_right"}])

    def test_validate_capture_flags_missing_window_hit_and_forbidden_hit(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            video_path = root / "clip.mp4"
            video_path.write_bytes(b"fake")
            fixture_path = root / "clip.fixture.yaml"
            fixture_path.write_text(
                "\n".join(
                    [
                        "schema_version: 1",
                        "fixture_id: test_fixture",
                        "family: boxing",
                        "video:",
                        "  path: ./clip.mp4",
                        "expected_gestures:",
                        "  - name: punch_left",
                        "    windows:",
                        "      - start_ms: 100",
                        "        end_ms: 300",
                        "forbidden_gestures:",
                        "  - name: punch_right",
                    ]
                ),
                encoding="utf-8",
            )
            fixture = load_fixture(fixture_path)
            capture_report = {
                "fixture_capture": {
                    "time_basis": "harness_monotonic_ms_since_ready",
                    "event_timeline": [
                        {"name": "punch_left", "timestamp_ms": 420, "payload": {}},
                        {"name": "punch_right", "timestamp_ms": 500, "payload": {}},
                    ],
                    "state_timeline": [{"timestamp_ms": 0, "reason": "ready"}],
                }
            }

            result = validate_capture(fixture, capture_report)

            self.assertFalse(result.ok)
            failures = [assertion for assertion in result.assertions if assertion["status"] == "fail"]
            self.assertEqual(len(failures), 3)
            self.assertEqual({failure["kind"] for failure in failures}, {
                "expected_gesture_window",
                "expected_gesture_extras",
                "forbidden_gesture",
            })

    def test_build_state_segments_and_validate_state_windows(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            video_path = root / "clip.mp4"
            video_path.write_bytes(b"fake")
            fixture_path = root / "clip.fixture.yaml"
            fixture_path.write_text(
                "\n".join(
                    [
                        "schema_version: 1",
                        "fixture_id: test_fixture",
                        "family: boxing",
                        "video:",
                        "  path: ./clip.mp4",
                        "expected_gestures:",
                        "  - name: guard",
                        "    surface: state",
                        "    windows:",
                        "      - start_ms: 0",
                        "        end_ms: 150",
                        "      - start_ms: 250",
                        "        end_ms: 450",
                    ]
                ),
                encoding="utf-8",
            )
            fixture = load_fixture(fixture_path)
            capture_report = {
                "fixture_capture": {
                    "time_basis": "harness_monotonic_ms_since_ready",
                    "event_timeline": [],
                    "state_timeline": [
                        {"timestamp_ms": 0, "gesture_states": {"guard": True}},
                        {"timestamp_ms": 100, "gesture_states": {"guard": True}},
                        {"timestamp_ms": 200, "gesture_states": {"guard": False}},
                        {"timestamp_ms": 300, "gesture_states": {"guard": True}},
                        {"timestamp_ms": 400, "gesture_states": {"guard": True}},
                        {"timestamp_ms": 500, "gesture_states": {"guard": False}},
                    ],
                }
            }

            segments = build_state_segments(capture_report["fixture_capture"]["state_timeline"], "guard")
            self.assertEqual(
                segments,
                [
                    {"index": 0, "name": "guard", "start_ms": 0, "end_ms": 100, "sample_count": 2, "first_state_index": 0, "last_state_index": 1},
                    {"index": 1, "name": "guard", "start_ms": 300, "end_ms": 400, "sample_count": 2, "first_state_index": 3, "last_state_index": 4},
                ],
            )

            result = validate_capture(fixture, capture_report)
            self.assertTrue(result.ok)
            self.assertEqual(
                {assertion["kind"] for assertion in result.assertions},
                {"expected_state_window", "expected_state_extras"},
            )


if __name__ == "__main__":
    unittest.main()
