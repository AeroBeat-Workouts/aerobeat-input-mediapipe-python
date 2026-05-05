# Proving Scene Video Fixtures

## Purpose

This document defines the reusable **video fixture format and workflow** for Boxing and Flow proving in `aerobeat-input-mediapipe-python`.

These fixtures are meant to be **regression aids** for detector behavior and proving-scene observability. They are **not** a replacement for live human verification on Cookie or other real camera setups.

Use them to answer questions like:

- does a known Boxing clip still emit the expected `punch_*`, `hook_*`, `uppercut_*`, `knee_*`, `guard`, `squat`, `lean_*`, `sidestep_*`, and `leg_lift_*` behavior?
- does a known Flow clip still emit the expected `swing_*` / `trail_*` payloads and show the same candidate-vs-emitted observability surfaces?
- did a detector or proving-harness change break reset/re-arm logic, payload labeling, or on-screen debug truth?

Do **not** use these fixtures to claim:

- universal threshold correctness
- robustness across body types, clothing, rooms, webcams, or frame rates
- correctness under fatigue, partial framing, or real-time interaction stress
- that prerecorded input makes live human testing unnecessary

---

## High-level design

The fixture system should use **short, feature-specific source videos** plus a **sidecar metadata file** describing what the clip is supposed to prove.

Each fixture consists of:

1. **one source video** — the recorded camera-style clip that should later be replayable into the detector path
2. **one metadata file** — machine-readable provenance, expectations, and bounded claims
3. **optional evidence artifacts** — screenshots, notes, or reviewer comments from the original capture/approval pass

The source video is the durable asset. The metadata file is the contract automation reads.

---

## Canonical storage layout

Use this repo-local layout:

```text
.testbed/assets/fixtures/
  README.md                         # optional future index
  boxing/
    punch_left/
      boxing__punch_left__positive__cam-cookie-logitech-c920__take-01.mp4
      boxing__punch_left__positive__cam-cookie-logitech-c920__take-01.fixture.json
      boxing__punch_left__positive__cam-cookie-logitech-c920__take-01.notes.md   # optional
    guard/
    squat/
    lean_left/
    sidestep_right/
    knee_left/
    leg_lift_right/
  flow/
    swing_left/
    swing_right/
    trail_left/
    trail_right/
```

Rules:

- group first by detector family: `boxing/`, `flow/`
- group second by the primary feature being proven
- keep the video and metadata file side-by-side with the same basename
- keep optional notes/evidence beside the fixture, not in a separate mystery folder
- do **not** mix generic demo/test videos into this tree; this tree is for curated proving fixtures only

Existing generic videos under `.testbed/assets/videos/` can remain as loose experiments/reference material, but curated proving fixtures should live under `.testbed/assets/fixtures/`.

---

## Fixture taxonomy

Each fixture should be tagged along four axes.

### 1. Detector family

- `boxing`
- `flow`

### 2. Fixture intent

- `positive` — should emit the target feature/state
- `negative` — should **not** emit the target feature/state
- `boundary` — near-threshold or intentionally ambiguous; useful for tuning but should not be part of a strict green baseline until expectations are stable
- `rearm` — specifically proves reset/re-arm behavior across repeated reps
- `occlusion` — deliberately tests partial visibility / clipping
- `framing` — deliberately tests too-close / too-far / edge-of-frame conditions

### 3. Motion shape

- `oneshot` — punch, hook, uppercut, knee, swing
- `state` — guard, squat, lean, sidestep, leg lift
- `continuous` — trail
- `mixed` — deliberate combination clips used later for interaction coverage once single-feature fixtures are stable

### 4. Approval level

- `canonical` — approved baseline fixture used in must-pass regression suites
- `candidate` — captured and documented but not yet promoted to must-pass baseline
- `deprecated` — retained for history but not used in current automation

Default rule for early implementation: start with **canonical positive single-feature clips** before adding negatives, boundaries, or mixed interactions.

---

## Naming convention

Use this basename format:

```text
<family>__<feature>__<intent>__cam-<capture-rig>__take-<nn>
```

Examples:

```text
boxing__punch_left__positive__cam-cookie-logitech-c920__take-01.mp4
boxing__guard__rearm__cam-cookie-logitech-c920__take-02.mp4
flow__swing_right__positive__cam-cookie-logitech-c920__take-01.mp4
flow__trail_left__positive__cam-cookie-logitech-c920__take-03.mp4
```

Guidelines:

- use lowercase kebab/snake-safe tokens only
- `<feature>` should match the proving-scene surface vocabulary where practical:
  - Boxing: `punch_left`, `punch_right`, `hook_left`, `hook_right`, `uppercut_left`, `uppercut_right`, `guard`, `squat`, `lean_left`, `lean_right`, `sidestep_left`, `sidestep_right`, `knee_left`, `knee_right`, `leg_lift_left`, `leg_lift_right`
  - Flow: `swing_left`, `swing_right`, `trail_left`, `trail_right`
- `take-<nn>` is the durable differentiator; do not overwrite a prior approved take in place
- camera/device info belongs in the filename only at a high level; fine-grained provenance goes in metadata

---

## Capture rules

Fixtures should be captured as **camera-style source clips**, not proving-scene screen recordings.

Why:

- source clips preserve the detector input domain
- proving-scene UI can change layout without invalidating the raw camera evidence
- the same source clip can later be used for both detector-only and proving-scene-observability checks

### Capture baseline

For canonical baseline fixtures, prefer:

- the same host/camera family Derrick uses for real testing when practical
- stable lighting
- stable background
- full body visible for lower-body Boxing features
- enough margin to avoid clipping during intended movement
- no edit effects, overlays, or music-driven cuts
- constant frame rate if possible
- no crop/zoom changes during the clip

### Clip shape

Each clip should have this structure:

1. **neutral lead-in**: 0.5-1.5s of still/ready pose
2. **action window**: the feature being exercised
3. **neutral settle**: 0.5-2.0s to observe reset/re-arm or state clear

### Granularity rules

Prefer **short clips with one primary proving purpose**.

Good:

- one left straight punch
- one 5-rep punch re-arm loop
- one guard enter/hold/exit cycle
- one left trail enter/sustain/exit clip

Bad:

- a 45-second kitchen-sink combo where six things happen at once
- clips that require a human to guess which event the metadata cared about

### Capture counts for the first fixture slice

For `oc-qu0`, the first useful implementation slice should target:

- Boxing:
  - `punch_left`, `punch_right`
  - `hook_left`, `hook_right`
  - `uppercut_left`, `uppercut_right`
  - `guard`
  - `knee_left`, `knee_right`
- Flow:
  - `swing_left`, `swing_right`
  - `trail_left`, `trail_right`

That gives one representative slice of:

- one-shot events
- sustained states
- Flow emitted payload behavior
- reset/re-arm expectations

Squat, lean, sidestep, and leg-lift fixtures should follow immediately after the first slice, but they do not need to block the initial harness implementation.

---

## Metadata contract

Each `.mp4` should have a sibling `.fixture.json` file.

Why JSON:

- easy to read from Godot, Python, and shell tooling
- explicit enough for automation without custom parsing rules
- stable for later schema evolution

The metadata file should include:

### Identity and provenance

- `schema_version`
- `fixture_id`
- `approval_level`
- `family`
- `feature`
- `intent`
- `motion_shape`
- `video_file`
- `captured_at`
- `captured_by`
- `capture_host`
- `camera`
- `room_notes`
- `lighting_notes`
- `mirrored_input`
- `frame_rate`
- `resolution`
- `duration_ms`

### Truth boundaries

- `claims` — what this clip is allowed to prove
- `non_claims` — what it explicitly does not prove
- `review_status`
- `review_notes`

### Expected detector behavior

- `expected_events`
- `forbidden_events`
- `expected_state_windows`
- `expected_payloads`
- `expected_ready_transitions`

### Observability expectations

- `expected_scene_surfaces`
- `expected_metrics`
- `expected_debug_fields`

### Timing windows

- `lead_in_ms`
- `action_start_ms`
- `action_end_ms`
- `settle_end_ms`
- optional per-event expected windows

### Evidence links

- related screenshots
- reviewer notes
- human verification session reference if the fixture came out of a live Cookie pass

A starter template lives in:

- `docs/proving-scene-video-fixture-template.fixture.json`

---

## Expected outputs from automation

The future fixture harness should produce outputs per run, not just pass/fail text.

At minimum each run should emit:

1. **fixture run summary JSON**
   - fixture id
   - code commit / dirty state
   - runtime/platform
   - pass/fail/soft-fail result
   - actual events observed
   - missing expected events
   - forbidden events that appeared
   - timing deltas

2. **scene evidence capture**
   - optional screenshots or short rendered clips showing the proving scene during the run
   - especially valuable for verifying persistent status-board truth, not just detector events

3. **raw detector trace**
   - actual event timeline
   - emitted payloads
   - relevant `gesture_debug` / metrics snapshots around the action window

4. **human-readable summary**
   - one concise markdown or text report for quick review

Suggested layout:

```text
.testbed/test-results/fixtures/<run-id>/
  summary.json
  report.md
  detector-trace.json
  screenshots/
```

---

## What each fixture should validate

A fixture should validate **three layers** whenever practical.

### Layer 1: detector event truth

Example:

- a `boxing__punch_left__positive...` fixture should emit exactly one `punch_left` in the expected window
- it should not emit `hook_left` or `uppercut_left` unless the fixture explicitly allows overlap

### Layer 2: state/reset truth

Example:

- a `guard` clip should show `guard_start`, sustained active state, then `guard_end`
- a multi-rep punch clip should show that `punch_left` re-arms between reps instead of sticking in reset forever
- a `trail_left` clip should show enter/sustain/exit behavior rather than a permanently sticky active state

### Layer 3: proving-scene observability truth

Example:

- Boxing rows show `READY` / `RESET` / `SUPPRESSED` honestly
- Flow rows show emitted placement/direction and candidate placement/direction coherently
- metrics that the scene claims to expose remain populated and legible during the action window

Not every fixture must assert every metric numerically. The first implementation can focus on:

- event presence/absence
- state transitions
- presence of required observability fields in the detector/proving state

Numeric metric threshold assertions should be added only when they are stable enough to be meaningful.

---

## Expected assertion style by feature family

### Boxing one-shot events

Fixtures for `punch_*`, `hook_*`, `uppercut_*`, and `knee_*` should usually assert:

- expected event occurs in the action window
- count equals expected count
- no forbidden sibling-class event occurs
- ready gate returns before settle end
- last power exists and is non-zero when appropriate

### Boxing sustained states

Fixtures for `guard`, `squat`, `lean_*`, `sidestep_*`, and `leg_lift_*` should usually assert:

- expected `*_start` occurs
- active state holds during the hold window
- expected `*_end` occurs by settle end
- mutually exclusive sibling state is not active at the same time unless explicitly allowed

### Flow swing fixtures

Should usually assert:

- exactly one `swing_*` event in the action window
- emitted `placement` and `direction` match the fixture expectation
- candidate placement/direction are present near the emitted window
- swing returns to ready by settle end

### Flow trail fixtures

Should usually assert:

- `trail_*` becomes active during sustain
- at least one emitted trail payload appears
- emitted `placement` and `direction` stay within the allowed set for the clip
- trail exits active state by settle end
- candidate payload fields remain populated and coherent during the sustain window

---

## Honest limits and review policy

A fixture becomes `canonical` only after:

1. the source clip is captured cleanly
2. the metadata is filled out completely
3. a human reviews the clip and agrees the intended gesture/state is actually readable
4. the expected detector/proving behavior is narrow enough to automate honestly

Do **not** promote clips to `canonical` if they are:

- visually ambiguous
- dependent on extreme/exaggerated motion that should really be tuned later
- inconsistent across repeated runs
- mislabeled but merely “close enough”

Ambiguous but still interesting clips should remain `candidate` or `boundary` fixtures.

---

## Relationship to human verification

Human verification and video fixtures should feed each other, but they are not interchangeable.

### Human verification is still required for:

- readability during real live movement
- real-time feel / lag / fatigue / ergonomics
- camera reacquisition behavior
- room/framing/occlusion robustness
- confidence that a real person can intentionally drive the feature repeatedly

### Fixtures are especially useful for:

- regression after detector threshold/code changes
- proving that a previously working feature still emits the same event class/payload
- catching observability regressions in the proving scene UI/debug surfaces
- creating reproducible bug reports and audit artifacts

Rule: if a fixture passes but Derrick reports the live feature feels bad, the live human result wins.

---

## Minimal implementation contract for `oc-qu0`

The next coding slice should not try to solve everything. A good first implementation is:

1. create `.testbed/assets/fixtures/boxing/` and `.testbed/assets/fixtures/flow/`
2. support loading one `.fixture.json` sidecar for one `.mp4`
3. implement a replay/evaluation path for a narrow first slice:
   - one Boxing one-shot fixture
   - one Boxing sustained-state fixture
   - one Flow swing fixture
   - one Flow trail fixture
4. emit a machine-readable run report
5. verify required detector/proving-scene surfaces exist during the run
6. document any gaps where the current provider/harness cannot yet accept prerecorded input cleanly

If prerecorded replay into the real provider path is harder than expected, the first implementation may use a clearly-labeled intermediate harness as long as it does **not** pretend to prove camera/live-runtime behavior.

---

## Recommended initial fixture set

Promote these first once clean captures exist:

- `boxing__punch_left__positive__cam-cookie-logitech-c920__take-01`
- `boxing__guard__positive__cam-cookie-logitech-c920__take-01`
- `boxing__knee_right__positive__cam-cookie-logitech-c920__take-01`
- `flow__swing_left__positive__cam-cookie-logitech-c920__take-01`
- `flow__trail_right__positive__cam-cookie-logitech-c920__take-01`

Then add:

- a `rearm` punch loop
- a `negative` guard-vs-punch suppression clip
- a `boundary` Flow placement/direction clip
- lower-body framing/occlusion clips for squat/knee/leg-lift

---

## Summary

The reusable fixture format is:

- **source clip**: short, feature-specific, camera-style `.mp4`
- **sidecar metadata**: `<same-basename>.fixture.json`
- **canonical storage**: `.testbed/assets/fixtures/<family>/<feature>/`
- **automation outputs**: summary JSON, detector trace, optional screenshots/report
- **truth boundary**: regression aid for detector/proving-scene behavior, not a substitute for live human verification
