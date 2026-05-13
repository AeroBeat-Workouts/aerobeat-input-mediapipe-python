# Proving Scene Video Fixtures

## First truthful slice

This repo now supports a small real fixture flow for prerecorded proving runs:

1. a `.fixture.yaml` file is actually parsed
2. the fixture itself owns the video path
3. the proving harness records a structured event timeline and state snapshots
4. a validator compares detector events against direct gesture windows and optional forbidden gestures

This is a **Boxing-first** slice that keeps the contract compatible with future Flow fixtures, but it does **not** pretend to solve the full long-term fixture system yet.

## Current contract

Each fixture should declare only the fields this slice actually consumes:

```yaml
schema_version: 1
fixture_id: boxing__punch_left__positive__guard_start_end__take_01
family: boxing
video:
  path: ./boxing__punch_left__positive__guard_start_end__take_01.mp4
expected_gestures:
  - name: punch_left
    windows:
      - start_ms: 900
        end_ms: 1300
      - start_ms: 1900
        end_ms: 2300
forbidden_gestures:
  - name: punch_right
```

### Required fields

- `schema_version`
- `fixture_id`
- `family` (`boxing` or `flow`)
- `video.path` (preferred) or legacy `video_file`

### Validation-facing fields

- `expected_gestures[]`
  - `name`
  - `windows[]`
    - `start_ms`
    - `end_ms`
- `forbidden_gestures[]` (optional)
  - string form or `{ name: ... }`

## Timing truth

Fixture timing is **human-authored near-second truth**.

That means:

- prefer honest approximate windows
- do not fake frame-perfect precision
- tighten windows later only when a human has actually reviewed the clip that closely

## Runner

Use:

```bash
scripts/run_proving_fixture_capture.sh <fixture.yaml> [output-dir] [capture-delay-ms]
```

The runner now:

- loads the fixture YAML
- resolves the video path from the fixture
- chooses the proving scene from `family`
- runs the shared capture harness
- writes validation artifacts into `.testbed/test-results/fixtures/<run-id>/`

## Output artifacts

Each run produces:

- `report.json` — raw capture report from Godot
- `summary.json` — overall validation result
- `assertions.json` — one row per expected-window / forbidden-gesture check
- `event_timeline.json` — structured emitted-event timeline
- `state_timeline.json` — structured harness state snapshots
- `report.md` — concise human-readable summary
- `proving.png` — proving-scene screenshot
- `godot.log` — raw Godot log

## Truth boundary

This slice currently validates:

- emitted gesture events inside authored windows
- extra same-name gesture events outside authored windows
- optional forbidden gestures across the clip
- that the harness captured structured event/state evidence

This slice does **not** yet claim to validate:

- ready/re-arm assertions from fixture YAML
- rich state-window assertions from fixture YAML
- full observability-surface requirements from fixture YAML
- universal live-camera behavior

If a fixture still uses old `expected_detector_behavior.expected_events` entries without direct windows, the loader will treat those entries as authoring debt instead of pretending they are already machine-checkable truth.
