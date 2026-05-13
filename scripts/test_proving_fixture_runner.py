from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from proving_fixture_runner import load_fixture, validate_capture


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


if __name__ == "__main__":
    unittest.main()
