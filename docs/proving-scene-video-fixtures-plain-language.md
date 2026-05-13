# Proving Scene Video Fixtures — Plain Language

A fixture is now just:

- one short video clip
- one YAML file beside it
- optional human notes

For this first real slice, the YAML needs to answer only three practical questions:

1. which family is this (`boxing` or `flow`)?
2. which video should run?
3. which gestures should happen when, and which gestures should definitely not happen?

## Minimal example

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

## The important rule

The timing windows are **approximate human truth**.

Do not pretend they are frame-perfect. If all you honestly know is “roughly around one second,” write a broad honest window.

## How to run one

```bash
scripts/run_proving_fixture_capture.sh <fixture.yaml>
```

That command now reads the fixture, finds the video from the fixture itself, runs the proving scene, and writes a result folder with:

- raw capture report
- event timeline
- state timeline
- pass/fail assertions
- markdown summary
- screenshot

## What this slice does well

- stops treating fixture YAML like comments-only metadata
- makes the fixture own the video path
- gives Boxing clips a real event-window validator
- records structured harness evidence for later audit

## What it does not claim yet

- perfect timing truth
- full state-window validation
- full ready/re-arm validation from YAML
- replacing live human verification
