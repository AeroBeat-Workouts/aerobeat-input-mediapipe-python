# AeroBeat MediaPipe Python — Boxing Fixture System Truth and Schema

**Date:** 2026-05-13  
**Status:** In Progress  
**Agent:** Pico 🐱‍🏍

---

## Goal

Make the prerecorded fixture system trustworthy enough to become the golden-truth validation path for Boxing first, then Flow, starting with a truthful fixture schema, machine-checkable expected gesture windows, and a clean path for Derrick’s boxing video inventory to be normalized into reusable fixtures.

---

## Overview

Derrick’s latest manual review of the Boxing proving harness confirms that the current detector/runtime state is still not truthful against the left-punch guard clip: squat stays latched the whole video, `punch_left` never fires, and `uppercut_right` appears randomly. At the same time, yesterday’s work already established that the fixture system itself is not yet ready to act as a reliable validation harness. Subagents do not yet have a dependable way to use it, some YAML fields appear hallucinated or at least ungrounded in current source, and Derrick has a growing set of raw/trimmed boxing videos that still need to be normalized into the repo’s fixture format.

Because the detector surface and the fixture surface are both currently untrustworthy, the next best move is to harden the fixture system first. That means we should stop pretending the current YAML contract is already settled and instead identify the minimum durable truth the system actually needs. Derrick’s stated priority is correct: fixture name, video path, and the set of expected gestures with time ranges should be the core golden-truth contract. Those time ranges should reflect human-authored review truth: close, second-scale windows gathered by scrubbing the video, not fake millisecond precision. Current target fidelity is roughly second-accurate timing within about ±0.5 seconds per gesture window. If we can make that contract precise, machine-checkable, and easy to author against Derrick’s boxing clips, then future detector work can be audited against a real source of truth instead of screenshots and ad hoc interpretation.

This plan therefore pivots from trying more Boxing detector tuning first into building the validation foundation around fixtures. Boxing goes first because Derrick already has the raw video library there. Flow should be kept in scope only to ensure the schema/design does not paint us into a Boxing-only corner. Derrick will work in parallel on trimming/editing videos while subagents audit the current fixture system, design a truthful schema, and define the normalization + validation path that future fixture authoring and automated QA can follow.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current Boxing oddities/follow-up plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-12-boxing-oddities-audit-and-fixes.md` |
| `REF-02` | Shared proving harness | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-03` | Boxing proving harness layer | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-04` | Fixture assets root | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/assets/fixtures/` |
| `REF-05` | Existing left-punch Boxing fixture YAML | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/assets/fixtures/boxing/punch_left/boxing__punch_left__positive__guard_start_end__take_01.fixture.yaml` |
| `REF-06` | Detector substrate that current fixture truth will eventually validate | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/detectors/pose_detector_substrate.gd` |
| `REF-07` | Today’s memory handoff / known context | `/home/derrick/.openclaw/workspace/memory/2026-05-12.md` |

---

## Tasks

### Task 1: Audit the current fixture system and reduce it to truthful required fields

**Bead ID:** `oc-qmku`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Use bead `oc-qmku`. Claim it on start with `bd update oc-qmku --status in_progress --json` and close it on completion with `bd close oc-qmku --reason "Fixture schema audit complete" --json`. Audit the current prerecorded fixture system end-to-end. Identify which YAML fields are actually consumed, which fields are unimplemented / hallucinated / stale, and what the minimum truthful fixture contract should be if the goal is golden-truth validation. Prioritize Derrick’s proposed essentials: fixture identity, video path/reference, expected gestures, and their timestamp windows. Recommend which current fields should stay, change, or be removed.

**Folders Created/Deleted/Modified:**
- `.plans/`
- fixture/docs/source paths only if needed for the audit

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny truth-revealing note is required

**Status:** ✅ Complete

**Results:** Task 1 audit completed from source and current fixture assets.

- **Current fixture-asset reality (`REF-04`):** `.testbed/assets/fixtures/` currently contains many bare prerecorded `.webm` clips plus only **two** YAML-backed Boxing fixtures under `boxing/punch_left/` and `boxing/punch_right/`. So the repo does not yet have a normalized fixture library; most assets are just videos, not full machine-readable fixtures.
- **Exact YAML fields currently consumed today:**
  - `fixture_id` is consumed only by `scripts/run_proving_fixture_capture.sh:26-30,46` to name the output run directory. If missing, the script falls back to the YAML filename basename.
  - `family` is consumed only by `scripts/run_proving_fixture_capture.sh:27,32-43` to choose `boxing_proving.tscn` vs `flow_proving.tscn`.
  - **Nothing else in the YAML is parsed or enforced anywhere in the runtime/harness path.** There is no YAML loader in the proving harness, Boxing harness, provider, or detector substrate.
- **Important current non-truth about video selection:** the active run path does **not** use YAML `video_file` at all. Instead, `scripts/run_proving_fixture_capture.sh:9-12,21-23,51,59-64` requires a separate `<video.mp4>` CLI argument, exports it as `AEROBEAT_MEDIAPIPE_CAMERA_SOURCE`, and passes it directly into the capture script. The harness itself resolves prerecorded source from scene override or env var in `.testbed/scripts/proving_harness.gd:93,1246-1269`. That means fixture-to-video binding is currently external/manual, not fixture-driven.
- **Capture-script truth (`REF-02`):** `.testbed/scripts/capture_fixture_proving.gd:22-25,78-123` only records the fixture path string and video path string into the output report; it does not open or validate the YAML contents.
- **Detector/debug truth (`REF-06`):** provider state comes from `src/providers/mediapipe_provider.gd:96-99` and detector debug state from `src/detectors/pose_detector_substrate.gd:471-475`. Today `gesture_debug` contains only `ready` plus Flow-specific debug under `flow`. There is **no** `gesture_debug.boxing.left.*` / `gesture_debug.boxing.right.*` subtree in source. So the Boxing fixture fields `expected_observability.required_debug_fields` that reference `gesture_debug.boxing.left/right.punch_distance|punch_velocity|punch_extension` in `REF-05` are currently hallucinated/unimplemented.
- **Consumed vs unconsumed field audit for the current left-punch fixture (`REF-05`):**
  - **Consumed:**
    - `fixture_id` (`REF-05` lines 2) — keep, but truthfully document current use as run/report identity only.
    - `family` (`REF-05` line 4) — keep, because it currently selects the proving scene.
  - **Present but not consumed anywhere today:**
    - `schema_version` (line 1)
    - `approval_level` (line 3)
    - `feature` / `intent` / `motion_shape` (lines 5-7)
    - `video_file` (line 8) — especially important stale field because it *looks* authoritative but is ignored by the runner.
    - `captured_at` / `captured_by` / `capture_host` (lines 9-11)
    - `camera.*` (lines 12-19)
    - `environment.*` (lines 20-23)
    - `clip_timing.*` (lines 24-29)
    - `claims` / `non_claims` (lines 30-36)
    - `review.*` (lines 37-41)
    - `expected_detector_behavior.expected_events` (lines 43-46)
    - `expected_detector_behavior.forbidden_events` (lines 47-54)
    - `expected_detector_behavior.expected_state_windows` (line 55)
    - `expected_detector_behavior.expected_ready_transitions` (lines 56-62)
    - `expected_observability.scene` / `required_scene_surfaces` / `required_debug_fields` (lines 63-74)
    - `artifacts.*` (lines 75-78)
- **Keep / change / remove recommendations for a truthful contract:**
  - **Keep:** `fixture_id`; `family` (or equivalent harness selector); an explicit fixture-owned video reference; expected gestures; timestamp windows; optional forbidden gestures.
  - **Change:** replace current ignored `video_file` basename with a real authoritative video reference such as `video.path` or `video_file` resolved relative to the YAML, and make the runner consume it instead of a separate required CLI video arg. Replace `expected_events + count only` with gesture expectations that can carry per-occurrence windows, because `count: 4` alone is too weak for golden truth.
  - **Remove from the minimum contract for now:** approval/provenance/environment/review/claims/non-claims/artifacts/observability-path fields should not be treated as required schema until code actually consumes them. They can live as optional authoring metadata later, but keeping them in the “required” core contract is currently overclaiming.
  - **Remove or rewrite immediately as stale/hallucinated:** Boxing `required_debug_fields` that reference nonexistent `gesture_debug.boxing.*` paths, and any docs/template language implying the harness already validates `expected_events`, `forbidden_events`, `expected_state_windows`, or `expected_ready_transitions`.
- **Recommended minimal truthful fixture contract for golden-truth validation (Boxing first, Flow-compatible):**
  ```yaml
  schema_version: 1
  fixture_id: boxing__punch_left__positive__guard_start_end__take_01
  family: boxing
  video:
    path: ./boxing__punch_left__positive__guard_start_end__take_01.mp4
  expected_gestures:
    - name: punch_left
      windows_ms:
        - { start: 900, end: 1300 }
        - { start: 1900, end: 2300 }
        - { start: 2900, end: 3300 }
        - { start: 3900, end: 4300 }
  clip_window_ms:
    start: 900
    end: 5000
  forbidden_gestures:
    - punch_right
    - uppercut_right
  ```
  Notes: `forbidden_gestures` should stay **optional** and only be authored when false positives matter enough to assert. `count` can be derived from `windows_ms.length`, so it does not need to be separate in the minimal contract.
- **Concise coder follow-up guidance:**
  1. Implement a real fixture loader/parser and stop treating YAML as comments-only metadata.
  2. Make the fixture itself own video resolution/path selection; the capture runner should accept `fixture.yaml` as the source of truth, not require a second authoritative video argument.
  3. Emit/collect a machine-checkable event timeline from the proving run, then compare actual emitted gestures against expected per-window occurrences (plus optional forbidden gestures).
  4. Shrink docs/template/schema to the truthful minimum first; add provenance/review/observability metadata back only after corresponding code paths actually consume them.
- **Reference check:** verified directly against `REF-02`, `REF-03`, `REF-04`, `REF-05`, and `REF-06`. Main concrete source anchors: `scripts/run_proving_fixture_capture.sh`, `.testbed/scripts/capture_fixture_proving.gd`, `.testbed/scripts/proving_harness.gd`, `src/providers/mediapipe_provider.gd`, and `src/detectors/pose_detector_substrate.gd`.

---

### Task 2: Design a machine-checkable gesture-window validation contract for Boxing first, Flow-compatible second

**Bead ID:** `oc-mqnk`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Use bead `oc-mqnk`. Claim it on start with `bd update oc-mqnk --status in_progress --json` and close it on completion with `bd close oc-mqnk --reason "Fixture validation path design complete" --json`. Design the fixture validation contract that future QA and subagents can actually run. The contract should let a prerecorded fixture declare expected gesture families and time ranges, plus any forbidden gestures when useful. Boxing is the first target, but the design must remain compatible with future Flow fixtures. Recommend where event capture should happen, how time windows should be compared, and what output/evidence a machine-checkable validator should emit.

**Folders Created/Deleted/Modified:**
- `.plans/`
- design/docs paths if a design note is needed

**Files Created/Deleted/Modified:**
- plan updates only unless a truthful design note is required

**Status:** ✅ Complete

**Results:** Completed design pass grounded in current source reality (`REF-02` through `REF-06`) and updated the contract around Derrick’s stated golden truth: **video fixture + expected gestures + overall timestamp ranges**.

Recommended validation contract:
- Keep the durable fixture truth anchored on the clip and sidecar, but narrow the validator-facing surface to a small machine-checkable core:
  - `fixture_id`, `family`, `video_file`
  - `expectations.events[]` for emitted detector signals with per-expectation windows, counts, and optional payload checks
  - `expectations.states[]` for sustained state windows like `guard`, `squat`, `trail_left`, with required active windows and optional start/end assertions
  - optional `expectations.forbidden_events[]` with explicit forbidden windows when useful, or clip-wide scope when a whole-fixture ban is intended
  - optional `expectations.ready[]` only where reset/re-arm matters materially
- For repeated Boxing clips, do **not** force humans to encode fake exact punch timestamps. Derrick’s intended authoring truth is close hand-scrubbed windows that are second-accurate within roughly ±0.5 seconds, not millisecond-exact labels.
- Support both:
  - human-authored near-second per-occurrence windows when Derrick has scrubbed the clip closely enough to mark approximate start/end times
  - one coarse aggregate expectation (`punch_left` count `4`) for clips that are not yet worth tighter per-rep labeling
- If a future canonical clip is reviewed tightly enough for finer timing, that should be an explicit upgrade in the fixture authoring, not the default requirement.
- Treat Flow payload checks as first-class on event expectations (`placement`, `direction`) but keep the same contract shape as Boxing so Flow is an extension, not a separate validator design.

Recommended event-capture / comparison architecture:
- Capture events in the **shared proving harness**, not by scraping rendered UI text and not by reading fixture YAML directly from the shell wrapper.
- Concretely, the best current event hook is `proving_harness.gd::_record_event()` because all Boxing and Flow detector signals already converge there after `mediapipe_provider.gd` maps substrate events into emitted Godot signals.
- Add a shared fixture-run recorder layer inside/alongside `proving_harness.gd` that records:
  - every emitted event from `_record_event()` with clip-relative timestamp, payload, count sequence, and source family
  - detector-state snapshots from `_on_pose_updated()` / `provider.get_detector_state()` for active states, ready flags, tracking state, and Flow candidate-vs-emitted debug fields
  - optional harness status markers such as `provider_started`, `tracking_lost`, `tracking_restored`, and fixture-run start/stop markers
- Prefer comparing against **structured state snapshots** from `provider.get_detector_state()` / `PoseDetectorSubstrate`, not against panel strings like `signal_status_label.text`; panel text is presentation, not truth.
- Time basis recommendation:
  - long-term canonical basis should be **clip/media-relative milliseconds** from prerecorded playback, because Derrick’s golden truth is tied to the video itself
  - if the current provider path cannot yet expose media timestamp cleanly, first implementation may temporarily compare on harness monotonic milliseconds from first processed prerecorded pose frame, but the report must label that basis explicitly so it does not overclaim exact video-time truth
  - reserve the contract now for `time_basis` / clip-relative semantics so Boxing-first implementation does not block future Flow parity
- Validation should run in two passes over one collected timeline:
  1. collect raw run data once from the shared harness
  2. evaluate fixture expectations against that timeline into pass/fail assertions and deltas
  This keeps capture separate from policy and makes re-evaluation possible without replaying the clip.

Forbidden-gesture design:
- Support forbidden gestures, but make them explicit and narrow:
  - `forbidden_events: ["uppercut_right"]` may apply to the whole actionable span by default
  - fixtures may optionally scope a forbidden event to a narrower window when overlap outside that window is acceptable
- Forbidden events should be evaluated as **actual emitted detector events**, not candidate/debug values.
- For Boxing first, this is especially useful for sibling-family false positives (`hook_*`, `uppercut_*`, `knee_*`) on straight-punch fixtures.
- For Flow, the same structure can forbid wrong-hand swings/trails or wrong payload combinations without inventing a second schema.

Recommended evidence / output shape for QA and audit:
- The current `capture_fixture_proving.gd` / `run_proving_fixture_capture.sh` path is only an evidence-capture scaffold today: it reads `fixture_id` and `family`, selects a scene, and emits screenshot/text surfaces, but it does **not** validate `expected_detector_behavior` yet.
- The future validator should emit a per-run artifact folder such as `.testbed/test-results/fixtures/<run-id>/` containing:
  - `summary.json` — overall result, commit, dirty state, fixture id, time basis, pass/fail counts
  - `assertions.json` — one row per expectation/forbidden check with expected window, actual hits, delta, and verdict
  - `event_timeline.json` — ordered emitted events with timestamps/payloads
  - `state_timeline.json` — sampled state/ready/tracking snapshots for state-window and re-arm checks
  - `report.md` — concise human-readable explanation of passes/failures
  - `proving.png` or equivalent screenshot(s) — optional but useful observability evidence
  - raw Godot/stdout log when available
- Each failed assertion should name:
  - expectation id or derived label
  - expected window/count/payload
  - actual matching events
  - missing or extra events
  - whether the failure is timing, count, payload, forbidden-event, or state-window related
- This evidence shape gives QA and audit something machine-checkable **and** something human-legible without depending on screenshot interpretation alone.

Design conclusion / implementation guidance for the next coding slice:
- The highest-value first slice is **not** more YAML surface area; it is a shared harness recorder + validator that can truthfully evaluate Boxing fixture timelines.
- Boxing should ship first with coarse count/window validation for the existing repeated punch fixtures, plus forbidden-event checks.
- Flow compatibility should come from using the same event/state timeline contract, with payload assertions added on top rather than a separate system.
- References rechecked during this design pass:
  - `REF-02` / `REF-03`: proving harnesses already centralize event observation and UI surfacing
  - `REF-06`: `PoseDetectorSubstrate` already produces the structured events, state flags, ready flags, and Flow debug data the validator should compare against
  - `REF-05`: existing Boxing fixture YAML proves why the contract needs coarse-vs-exact timing flexibility and forbidden false-positive checks.

---

### Task 3: Define the Boxing fixture-library normalization workflow for Derrick’s trimmed videos

**Bead ID:** `oc-5ru0`  
**SubAgent:** `primary` (for `research` or `coder` workflow role depending on findings)  
**Role:** `research`  
**References:** `REF-04`, `REF-05`  
**Prompt:** Use bead `oc-5ru0`. Claim it on start with `bd update oc-5ru0 --status in_progress --json` and close it on completion with `bd close oc-5ru0 --reason "Boxing fixture normalization workflow defined" --json`. Define the practical repo workflow for turning Derrick’s Boxing video inventory into clean reusable fixtures. Cover folder naming, file naming, YAML generation expectations, positive/negative clip organization, and any helper tooling that would reduce manual formatting mistakes. Do not assume all videos are ready today; design for an incremental boxing-first rollout while Derrick trims clips in parallel.

**Folders Created/Deleted/Modified:**
- `.plans/`
- fixture/docs/tooling paths only if needed for the design

**Files Created/Deleted/Modified:**
- plan updates only unless a small truthful helper/doc stub is required

**Status:** ✅ Complete

**Results:** Completed from plan/doc review plus direct inspection of `REF-04` and the current Boxing fixture tree. The current tree is mixed: curated per-feature fixture pairs already exist for `punch_left/` and `punch_right/`, but many older Boxing clips still sit loose under `.testbed/assets/fixtures/boxing/` as top-level `.webm` files without sibling YAML sidecars. Recommended Boxing-first normalization workflow:

- **Treat the curated fixture library as a normalized layer, not a dumping ground for every trimmed export.**
  - Keep normalized reusable fixtures under `.testbed/assets/fixtures/boxing/<feature>/<intent>/`.
  - Use `_incoming/` for work-in-progress trims that Derrick has exported but not yet normalized, for example `.testbed/assets/fixtures/boxing/_incoming/punch_left/`.
  - Do not leave new loose curated clips at `.testbed/assets/fixtures/boxing/*.webm`; migrate or quarantine legacy loose clips gradually instead of requiring a big-bang cleanup.

- **Recommended folder rule for Boxing fixtures.**
  - Canonical normalized path: `.testbed/assets/fixtures/boxing/<feature>/<intent>/`
  - Examples:
    - `.testbed/assets/fixtures/boxing/punch_left/positive/`
    - `.testbed/assets/fixtures/boxing/punch_left/negative/`
    - `.testbed/assets/fixtures/boxing/guard/rearm/`
    - `.testbed/assets/fixtures/boxing/squat/boundary/`
  - Rationale: feature-first browsing stays easy, while intent-specific clips stop becoming a flat pile once negatives/boundaries/rearm cases start arriving.

- **Recommended basename rule for new normalized Boxing fixtures.**
  - Use: `boxing__<feature>__<intent>__<variant>__take_<nn>`
  - Examples:
    - `boxing__punch_left__positive__guard_start_end__take_01.mp4`
    - `boxing__punch_left__negative__idle_guard_only__take_01.mp4`
    - `boxing__guard__rearm__enter_hold_exit__take_02.mp4`
    - `boxing__uppercut_right__positive__repeat_04__take_01.mp4`
  - Practical rule for `<variant>`: keep it short and human-meaningful; describe the clip shape, not camera provenance. Good values include `guard_start_end`, `neutral_single`, `repeat_04`, `hold_2s`, `occluded_left_arm`, `tight_framing`.
  - Keep `take_<nn>` monotonic within the same feature + intent + variant; never overwrite an earlier take in place.
  - Prefer `.mp4` for newly normalized fixtures so the curated library does not keep mixing `.webm` and `.mp4` without a reason. Legacy `.webm` assets can remain until intentionally migrated.

- **Recommended YAML-generation expectations.**
  - Every normalized curated clip should have a sibling `.fixture.yaml` with the exact same basename and `fixture_id`.
  - The first authoring pass does **not** need perfect final windows before the clip can enter the library. New clips may start as `approval_level: candidate` with approximate timing windows plus truthful review notes.
  - Minimum practical fields Derrick should fill immediately when normalizing a clip:
    - `schema_version`
    - `fixture_id`
    - `approval_level` (default `candidate`)
    - `family`
    - `feature`
    - `intent`
    - `motion_shape`
    - `video_file`
    - `captured_at`, `captured_by`, `capture_host`, `camera`
    - `clip_timing`
    - `claims`, `non_claims`
    - `review.status`, `review.notes`
    - `expected_detector_behavior` with whichever of `expected_events`, `forbidden_events`, `expected_state_windows`, and `expected_ready_transitions` are already known
  - For Boxing-first ergonomics, timing windows should be authored in two passes:
    1. **trim-time pass:** approximate `action_start_ms` / `action_end_ms`, rough expected event counts, obvious forbidden events
    2. **truth-pass later:** tighten exact event windows and re-arm windows after proving review
  - This keeps fixture normalization unblocked while Derrick is still trimming inventory.

- **Positive / negative / boundary organization guidance.**
  - Use the `intent` folder plus the `intent` filename token together; do not rely on only one of them.
  - `positive`: target gesture/state should happen.
  - `negative`: clip is deliberately similar context where the target should not fire.
  - `boundary`: near-threshold or ambiguous clips; useful for tuning, but not must-pass baseline fixtures yet.
  - `rearm`: repeated-rep or enter/exit timing clips whose main purpose is reset/ready behavior.
  - Boxing-first recommendation: start by pairing each important positive with an eventual neighboring negative for the same feature when practical, e.g. `punch_left/positive/...guard_start_end...` beside `punch_left/negative/...idle_guard_only...`.

- **Incremental normalization workflow Derrick can follow while trimming in parallel.**
  1. Trim/export a short single-purpose clip.
  2. Drop the raw trimmed export into `.testbed/assets/fixtures/boxing/_incoming/<feature>/`.
  3. Decide the target `feature`, `intent`, and short `variant` label.
  4. Rename to the normalized basename.
  5. Move it into `.testbed/assets/fixtures/boxing/<feature>/<intent>/`.
  6. Create the sibling YAML from the template/example and fill the minimum fields immediately.
  7. Mark it `approval_level: candidate` unless timing and behavior have already been reviewed tightly.
  8. Add approximate event/count/forbidden expectations now; tighten exact windows later during proving review instead of blocking ingestion.
  9. When a clip proves stable and useful, promote it from `candidate` to `canonical` rather than renaming or replacing it.

- **Lightweight helper recommendations for the coder slice (`oc-74wo`).**
  - Highest-value tiny helper: a repo-local scaffold command that creates the normalized folder, copies a YAML stub, and pre-fills basename-linked fields from CLI args like `family`, `feature`, `intent`, `variant`, `take`, and `video filename`.
  - Second tiny helper: a validator/linter that checks:
    - basename matches `fixture_id`
    - YAML `family` / `feature` / `intent` match the directory path
    - `video_file` exists beside the YAML
    - no curated normalized clip is missing a sibling YAML
    - no YAML points at a missing video
  - Third optional helper: an inventory report that lists legacy loose clips under `.testbed/assets/fixtures/boxing/` so migration can happen opportunistically instead of by memory.
  - Avoid bigger tooling for now; the first implementation slice should prefer scaffolding + validation over a full fixture authoring UI.

Net recommendation: keep the truthful schema work separate from library-ingestion ergonomics, but make normalized Boxing fixture ingestion cheap enough that Derrick can keep feeding the library clip-by-clip today without waiting for all Boxing inventory, exact windows, or validator tooling to be finished first.

---

### Task 4: Implement the first truthful fixture-system slice

**Bead ID:** `oc-74wo`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Use bead `oc-74wo`. Claim it on start with `bd update oc-74wo --status in_progress --json`. Before coding, read the completed results for `oc-qmku`, `oc-mqnk`, and `oc-5ru0`, and respect the current product decision that fixtures should use direct gesture windows and optional forbidden gestures, with no broader action-envelope feature. Then implement the smallest truthful fixture-system slice needed to make Boxing fixtures materially more real and usable. Prioritize the shared harness recorder + validator path, truthful fixture loading, and any minimal schema/template cleanup needed to support that. Run relevant validation, commit/push by default, and close the bead with `bd close oc-74wo --reason "First fixture-system slice implemented" --json` when done.

**Folders Created/Deleted/Modified:**
- `.plans/`
- exact fixture/harness/source/tooling paths required by the implementation

**Files Created/Deleted/Modified:**
- exact implementation files required by the approved slice

**Status:** ✅ Complete

**Results:** Implemented the first truthful fixture-system slice as a small real capture/validation path instead of expanding speculative schema.

- **Real fixture loading + fixture-owned video resolution landed:** `scripts/run_proving_fixture_capture.sh` is now a thin wrapper over new Python runner `scripts/proving_fixture_runner.py`, which parses fixture YAML, resolves `video.path` (with legacy `video_file` fallback), selects the proving scene from `family`, launches Godot capture, and writes structured validation artifacts.
- **Shared harness recorder landed around `REF-02`:** `.testbed/scripts/proving_harness.gd` now records a structured `event_timeline` from `_record_event()` plus lightweight structured `state_timeline` snapshots (tracking state, gesture states, ready map, Flow debug subtree, latest event). `.testbed/scripts/capture_fixture_proving.gd` now exports that recorder payload into `report.json` under `fixture_capture`.
- **Capture path bug fixed while landing the slice:** `capture_fixture_proving.gd` was exiting before producing artifacts; the slice replaces the broken frame-loop dependency with a deferred timed capture sequence and guards screenshot capture so headless/no-texture runs still emit reports instead of failing silently.
- **Truthful minimal schema/docs/template landed:** the template and docs were reduced to the fields this slice actually consumes (`schema_version`, `fixture_id`, `family`, `video.path`, `expected_gestures` direct windows, optional `forbidden_gestures`). This intentionally removes/backs away from earlier overclaimed observability/ready/state YAML requirements.
- **Boxing fixtures updated to the new minimal contract:** both existing repeated punch fixtures now use the fixture-owned `video.path` plus direct per-punch gesture windows and optional forbidden gestures, keeping the authored timing explicitly approximate/human-scale for this first pass.
- **Validation artifacts now produced per run:** `summary.json`, `assertions.json`, `event_timeline.json`, `state_timeline.json`, `report.md`, `report.json`, `godot.log`, and `proving.png` (when available).
- **Files touched:**
  - `scripts/run_proving_fixture_capture.sh`
  - `scripts/proving_fixture_runner.py`
  - `scripts/test_proving_fixture_runner.py`
  - `.testbed/scripts/capture_fixture_proving.gd`
  - `.testbed/scripts/proving_harness.gd`
  - `.testbed/assets/fixtures/boxing/punch_left/boxing__punch_left__positive__guard_start_end__take_01.fixture.yaml`
  - `.testbed/assets/fixtures/boxing/punch_right/boxing__punch_right__positive__guard_start_end__take_01.fixture.yaml`
  - `docs/proving-scene-video-fixture-template.fixture.yaml`
  - `docs/proving-scene-video-fixtures.md`
  - `docs/proving-scene-video-fixtures-plain-language.md`
- **Validation runs:**
  - `python3 -m py_compile scripts/proving_fixture_runner.py scripts/test_proving_fixture_runner.py`
  - `python3 scripts/test_proving_fixture_runner.py`
  - `godot --headless --path .testbed --import`
  - `scripts/run_proving_fixture_capture.sh .testbed/assets/fixtures/boxing/punch_left/boxing__punch_left__positive__guard_start_end__take_01.fixture.yaml`
- **Observed runtime truth from the real Boxing run:** the new fixture path works and emits structured evidence, but the left-punch fixture currently **fails** validation in a way consistent with the known detector truth problem: `punch_left` never emitted inside the authored windows, while forbidden `uppercut_right` emitted at `3623ms`. Run artifact folder: `.testbed/test-results/fixtures/20260513-111002__boxing__punch_left__positive__guard_start_end__take_01/`.
- **Follow-up truth explicitly recorded instead of hidden scope creep:** this slice builds the reusable fixture path, but richer ready/state-window assertions still need a later bead once Boxing event truth is cleaner.
- **Commit:** pending before handoff.

---

### Task 5: QA the first fixture-system slice against Boxing fixture authoring/validation reality

**Bead ID:** `oc-4wme`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-04`, `REF-05`, plus implementation references added during execution  
**Prompt:** Use bead `oc-4wme`. Claim it on start with `bd update oc-4wme --status in_progress --json`. After `oc-74wo` lands, verify that the first fixture-system slice is actually usable for Boxing fixture work. Check whether a subagent could understand the contract, whether the YAML fields line up with source reality, and whether the validation path emits evidence that Derrick can trust while continuing to trim/edit Boxing videos. Close with `bd close oc-4wme --reason "Fixture-system QA complete" --json` only if the QA truthfully passes.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / QA notes only unless a truthful docs correction is required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 6: Independently audit whether the fixture system is ready to become the golden-truth path for Boxing

**Bead ID:** `oc-wnnh`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** all relevant fixture/design/implementation references from the completed tasks  
**Prompt:** Use bead `oc-wnnh`. Claim it on start with `bd update oc-wnnh --status in_progress --json`. After QA completes, independently audit the new fixture-system work and decide whether it is actually ready to serve as the golden-truth validation path for Boxing clips, and what still blocks full Boxing detector truth passes if anything remains incomplete. Close with `bd close oc-wnnh --reason "Fixture-system audit complete" --json` only if the audit truthfully passes.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-13-boxing-fixture-system-truth-and-schema.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 7: Normalize the uncategorized Boxing and Flow videos into the new fixture layout with stub YAMLs

**Bead ID:** `oc-h9pl`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-04`, `REF-05`, plus implementation references added during Task 4  
**Prompt:** Use bead `oc-h9pl`. Claim it on start with `bd update oc-h9pl --status in_progress --json`. After `oc-74wo` lands, take the current uncategorized Boxing and Flow videos in `.testbed/assets/fixtures/` that do not yet live in their own per-fixture folder with sibling YAML, normalize them into the updated fixture layout, rename them to match the curated fixture naming convention already used by the existing tested fixtures, and generate stub YAML sidecars that follow the updated truthful schema. Do not invent gesture-event timing truth: leave the event/timing sections in clearly marked manual-fill state for Derrick to complete later. Close with `bd close oc-h9pl --reason "Uncategorized fixtures normalized with stub YAMLs" --json` when the rename/move/stub generation pass is done.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/assets/fixtures/`

**Files Created/Deleted/Modified:**
- uncategorized Boxing/Flow fixture videos moved into per-fixture folders
- matching stub YAML sidecars generated using the updated truthful schema

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Draft

**What We Built:**
- Pending execution.

**Reference Check:**
- Not yet executed.

**Commits:**
- Pending.

**Lessons Learned:**
- Pending.

---

*Created on 2026-05-13*