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
| `REF-08` | Boxing proving-scene UI vocabulary surface | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-09` | Shared proving harness Boxing signal/state surface | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-10` | Current authored Boxing chart examples | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-docs/docs/examples/workout-packages/demo-neon-boxing-bootcamp/charts/` |
| `REF-11` | Current content-core Boxing chart contract and README | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core/data_types/chart.gd` and `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core/README.md` |
| `REF-12` | New trimmed Boxing left fixture YAML from Derrick | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/assets/fixtures/boxing/punch_left/boxing_punch_left_x4_while_guarding_take_01.yaml` |
| `REF-13` | New trimmed Boxing left fixture video from Derrick | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/assets/fixtures/boxing/punch_left/boxing_punch_left_x4_while_guarding_take_01.mp4` |
| `REF-14` | Salvaged patched validation artifacts for the trimmed Boxing-left run | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/test-results/fixtures/20260514-183547__boxing_punch_left_x4_while_guarding_take_01/` |

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
- **Commit:** `666d4db` — `Implement first truthful fixture-system slice`.

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

**Status:** ✅ Complete

**Results:** QA pass for the fixture-system slice itself, with the Boxing detector truth still failing openly as expected.

- **Scope kept narrow per retry:** reviewed Task 4's landed scope/results, inspected the existing left-punch artifact folder, and re-ran only lightweight validation (no new long Godot proving run).
- **Contract is understandable and matches the landed slice:** checked `docs/proving-scene-video-fixtures.md`, `docs/proving-scene-video-fixtures-plain-language.md`, and `docs/proving-scene-video-fixture-template.fixture.yaml` against `.testbed/assets/fixtures/boxing/punch_left/boxing__punch_left__positive__guard_start_end__take_01.fixture.yaml`. The active fixture uses exactly the documented minimal contract (`schema_version`, `fixture_id`, `family`, `video.path`, `expected_gestures` windows, optional `forbidden_gestures`) with no misleading extra schema claims.
- **Fixture-owned video resolution is real, not aspirational:** loaded the fixture through `scripts.proving_fixture_runner.load_fixture(...)` and confirmed it resolves the expected Boxing scene plus a real existing sibling MP4 path, with no loader warnings.
- **Existing validation artifacts are concrete and audit-friendly:** inspected `.testbed/test-results/fixtures/20260513-111002__boxing__punch_left__positive__guard_start_end__take_01/` and confirmed the full expected bundle exists: `report.json`, `summary.json`, `assertions.json`, `event_timeline.json`, `state_timeline.json`, `report.md`, `godot.log`, and `proving.png`.
- **The artifact verdict is truthful about detector reality:** `summary.json` reports `result: fail` with 6 passed / 6 failed assertions. `assertions.json` and `report.md` clearly show that authored `punch_left` windows found zero matching events and that forbidden `uppercut_right` fired at `3623ms`. `event_timeline.json` corroborates that no `punch_left` event was emitted while other events (`provider_started`, `squat_start`, `guard_start`, `guard_end`, `uppercut_right`) were captured. This is exactly the kind of honest evidence Derrick needs while trimming/editing Boxing clips.
- **Lightweight validation rerun:**
  - `python3 -m py_compile scripts/proving_fixture_runner.py scripts/test_proving_fixture_runner.py`
  - `python3 scripts/test_proving_fixture_runner.py`
  - `python3 - <<'PY' ... load_fixture(...) ... PY` to confirm parsed fields, resolved video path, and warnings
  - `python3 - <<'PY' ... inspect report.json keys ... PY` to confirm structured capture payload shape
- **QA verdict:** the first fixture-system slice is **usable for Boxing fixture authoring/validation now** because it truthfully loads fixture-owned videos, applies the documented minimal schema, and emits evidence Derrick can trust even when detector truth fails. The current left-punch failure is a **Boxing detector/truth problem surfaced by the fixture system**, not a failure of the fixture-system slice itself.
- **Non-blocking QA note for later follow-up:** `report.json` is still the raw capture artifact and does not embed the validation summary directly; the canonical pass/fail verdict currently lives in `summary.json` / `assertions.json` / `report.md`. That is acceptable for this slice because the sidecar artifacts are present and unambiguous, but future polish could inline the validation block for easier single-file consumption.

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

**Status:** ✅ Complete

**Results:** Completed as a narrow safe normalization pass only; ambiguous legacy names were intentionally left untouched instead of being guessed into the new schema.

- **Normalized into per-fixture folders with sibling stub YAMLs:**
  - `boxing_knee_left_x4.webm` → `.testbed/assets/fixtures/boxing/knee_left/boxing__knee_left__positive__repeat_04__take_01/boxing__knee_left__positive__repeat_04__take_01.webm`
  - `boxing_knee_right_x4.webm` → `.testbed/assets/fixtures/boxing/knee_right/boxing__knee_right__positive__repeat_04__take_01/boxing__knee_right__positive__repeat_04__take_01.webm`
  - `boxing_leg_lift_left_x4.webm` → `.testbed/assets/fixtures/boxing/leg_lift_left/boxing__leg_lift_left__positive__repeat_04__take_01/boxing__leg_lift_left__positive__repeat_04__take_01.webm`
  - `boxing_leg_lift_right_x4.webm` → `.testbed/assets/fixtures/boxing/leg_lift_right/boxing__leg_lift_right__positive__repeat_04__take_01/boxing__leg_lift_right__positive__repeat_04__take_01.webm`
  - `boxing_sidestep_left_x4.webm` → `.testbed/assets/fixtures/boxing/sidestep_left/boxing__sidestep_left__positive__repeat_04__take_01/boxing__sidestep_left__positive__repeat_04__take_01.webm`
  - `boxing_sidestep_right_x4.webm` → `.testbed/assets/fixtures/boxing/sidestep_right/boxing__sidestep_right__positive__repeat_04__take_01/boxing__sidestep_right__positive__repeat_04__take_01.webm`
  - `boxing_squat_x4.webm` → `.testbed/assets/fixtures/boxing/squat/boxing__squat__positive__repeat_04__take_01/boxing__squat__positive__repeat_04__take_01.webm`
  - `boxing_uppercut_left_x4.webm` → `.testbed/assets/fixtures/boxing/uppercut_left/boxing__uppercut_left__positive__repeat_04__take_01/boxing__uppercut_left__positive__repeat_04__take_01.webm`
  - `boxing_uppercut_right_x4.webm` → `.testbed/assets/fixtures/boxing/uppercut_right/boxing__uppercut_right__positive__repeat_04__take_01/boxing__uppercut_right__positive__repeat_04__take_01.webm`
- **Stub sidecars created for each normalized clip:** each new per-fixture folder now includes a sibling `.fixture.yaml` using the truthful minimal schema (`schema_version`, `fixture_id`, `family`, `video.path`, and `notes`). The stubs intentionally do **not** invent `expected_gestures` or timing windows; each file includes explicit manual-fill comments for Derrick to author later.
- **Validation performed:** repo-local fixture parsing was rechecked by loading every new stub through `scripts/proving_fixture_runner.py::load_fixture()`. All new stub YAMLs resolved their sibling video paths successfully and stayed at zero authored `expected_gestures`, which is the intended truthful placeholder state for this pass.
- **Explicit unresolved clips left untouched because the naming/feature mapping was not safe enough to guess:**
  - Boxing: `boxing_cross_left_x4.webm`, `boxing_cross_right_x4.webm`, `boxing_run_in_place_x1.webm`, `boxing_stance_change_x4.webm`, `boxing_weave_left_x4.webm`, `boxing_weave_right_x4.webm`
  - Flow: `flow_swing_left_3_right_3_to_left_6_right_6_x4.webm`, `flow_swing_left_6_right_6_to_left_3_right_3_x4.webm`
- **Reason for leaving those unresolved:** the current filenames do not map cleanly enough to a single truthful curated fixture name without making assumptions about gameplay-family equivalence (`cross` vs `punch`), unsupported/non-emitted runtime semantics (`run_in_place`, `stance_change`, `weave`), or multi-hand/payload truth for the Flow clips.
- **Post-normalization naming truth from Derrick:** `cross_left/right` are **not** the same family as the current canonical straight `punch_*`; they refer to the horizontal punch family and need their own proper canonical naming aligned to beat-chart truth. `run_in_place` is a legitimate candidate active/inactive Boxing gameplay gesture. `stance_change` is a legitimate possible scored or at least detectable orthodox/southpaw state/event family. `weave_left/right` are likely the intended canonical replacement for the current UI’s `dodge` naming and need beat-chart / gesture-vocabulary alignment before fixture normalization continues.

---

### Task 8: Audit Boxing gesture vocabulary against beat-chart YAML truth and resolve unresolved fixture naming

**Bead ID:** `oc-i6u4`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-04`, `REF-06`, `REF-08`, `REF-09`, `REF-10`, `REF-11`
**Prompt:** Use bead `oc-i6u4`. Claim it on start with `bd update oc-i6u4 --status in_progress --json`. Audit the current Boxing gesture vocabulary across fixture names, proving-scene UI naming, detector/event naming, and beat-chart YAML truth to identify drift and resolve the remaining unresolved Boxing fixture names. Confirm the proper canonical naming for the horizontal punch family currently labeled `cross_left/right`, decide how `run_in_place`, `stance_change`, and `weave_left/right` should map into the current Boxing contract, and explicitly check whether current beat-chart YAML content has drifted from the intended vocabulary. Update this plan with the naming decisions, exact source references, and recommended follow-up fixture renames / UI naming updates. Close with `bd close oc-i6u4 --reason "Boxing gesture vocabulary audit complete" --json` when the naming truth pass is complete.

**Folders Created/Deleted/Modified:**
- `.plans/`
- source/docs/chart paths only if a tiny truthful note is needed

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny truth-revealing note is required

**Status:** ✅ Complete

**Results:** Completed audit across the unresolved Boxing fixture filenames (`REF-04`), current detector/provider signal surface (`REF-06`), proving-harness/shared-UI naming (`REF-08`, `REF-09`), and current chart/content-core vocabulary (`REF-10`, `REF-11`).

- **Exact unresolved fixture files audited (`REF-04`):**
  - `.testbed/assets/fixtures/boxing/boxing_cross_left_x4.webm`
  - `.testbed/assets/fixtures/boxing/boxing_cross_right_x4.webm`
  - `.testbed/assets/fixtures/boxing/boxing_run_in_place_x1.webm`
  - `.testbed/assets/fixtures/boxing/boxing_stance_change_x4.webm`
  - `.testbed/assets/fixtures/boxing/boxing_weave_left_x4.webm`
  - `.testbed/assets/fixtures/boxing/boxing_weave_right_x4.webm`

- **Detector/event truth today (`REF-06`):**
  - The only Boxing attack event families currently emitted by `src/providers/mediapipe_provider.gd:12-17,268-279` and generated by `src/detectors/pose_detector_substrate.gd:625-688` are `punch_left/right`, `hook_left/right`, and `uppercut_left/right`.
  - The only current Boxing state/simple-event families in the detector/provider path are `guard`, `squat`, `lean_left/right`, `sidestep_left/right`, `knee_left/right`, and `leg_lift_left/right` via `src/providers/mediapipe_provider.gd:22-39,288-323` and `src/detectors/pose_detector_substrate.gd:614-624,930-976`.
  - There is **no current detector/provider/runtime event or state family** for `cross_*`, `run_in_place`, `stance_change`, `orthodox`, `southpaw`, or `weave_*`.

- **Proving-scene / UI truth today (`REF-08`, `REF-09`):**
  - Shared Boxing harness wiring only knows the same emitted families above: `punch`, `hook`, `uppercut`, `knee`, `guard`, `squat`, `lean`, `sidestep`, and `leg_lift` in `.testbed/scripts/proving_harness.gd:23-48,57-78,309-314`.
  - The Boxing proving scene already has a dedicated **Hook** tile and labels in `.testbed/scripts/boxing_proving_harness.gd:9-18,46-62`.
  - The current UI still presents `lean_left/right` as **Dodge Left/Right** and has a `dodge` tile/icon in `.testbed/scripts/boxing_proving_harness.gd:18,33-36,109-116`.
  - Therefore the product-facing Boxing UI surface currently disagrees with the unresolved fixture filenames: fixture files say `weave_*`, detector internals say `lean_*`, and UI says `dodge`.

- **Beat-chart / content-core truth today (`REF-10`, `REF-11`):**
  - Current authored Boxing chart examples use `punch_left`, `punch_right`, `guard`, `hook_left`, `hook_right`, `squat`, `knee_left`, `leg_lift_left`, `leg_lift_right`, `sidestep_left`, `sidestep_right`, `uppercut_left`, `uppercut_right`, plus stance cues `orthodox` and `southpaw` in `ab-chart-neon-stride-boxing-medium.yaml:20-49` and `ab-chart-midnight-sprint-boxing-hard.yaml:20-55`.
  - `run_in_place` is already present in the Boxing example chart at `ab-chart-neon-stride-boxing-medium.yaml:47-49`, so chart-facing Boxing vocabulary already includes it even though runtime detection does not.
  - Content-core explicitly documents straight punches as `punch_left` / `punch_right` and accepts `orthodox` / `southpaw` as authored stance semantics in `../aerobeat-content-core/README.md:22-25,60-62`.
  - Content-core still carries a **legacy** replacement map `cross -> punch_right` / `cross_right -> punch_right` in `../aerobeat-content-core/data_types/chart.gd:6-13,78-89`. That is stale against Derrick’s product truth because `cross_*` is not supposed to alias the straight-punch family anymore.
  - No current chart example uses `dodge`, `weave`, or `stance_change` literal beat types.

- **Resolved naming decisions from this audit:**
  1. **Horizontal punch family currently labeled `cross_left/right`: canonical replacement should be `hook_left/right`, not `punch_*`.**
     - Why: the runtime already has a distinct horizontal Boxing family named `hook_left/right` in detector, provider, proving harness, and UI (`REF-06`, `REF-08`, `REF-09`), while chart examples also use `hook_left/right` (`REF-10`).
     - This matches Derrick’s truth that `cross_*` is a different family from the current straight `punch_*` family.
     - **Recommended fixture renames:**
       - `boxing_cross_left_x4.webm` → `.testbed/assets/fixtures/boxing/hook_left/boxing__hook_left__positive__repeat_04__take_01/boxing__hook_left__positive__repeat_04__take_01.webm`
       - `boxing_cross_right_x4.webm` → `.testbed/assets/fixtures/boxing/hook_right/boxing__hook_right__positive__repeat_04__take_01/boxing__hook_right__positive__repeat_04__take_01.webm`
     - **Recommended follow-up outside this repo slice:** update `aerobeat-content-core/data_types/chart.gd` so legacy `cross` no longer points at `punch_right`; it should either be rejected without a straight-punch alias or remapped to `hook_right` only if Derrick explicitly wants that legacy compatibility.

  2. **`run_in_place`: treat as canonical authored/gameplay vocabulary now, but runtime support is missing.**
     - Why: Boxing chart examples already author `run_in_place` (`REF-10`), and Derrick confirmed it is a legitimate Boxing gameplay gesture candidate.
     - Current drift: chart/docs include it, unresolved fixture filename includes it, but detector/provider/proving harness have no `run_in_place` state or event surface (`REF-06`, `REF-08`, `REF-09`).
     - **Recommended canonical naming:** `run_in_place`.
     - **Recommended fixture normalization target:** `.testbed/assets/fixtures/boxing/run_in_place/boxing__run_in_place__positive__repeat_01__take_01/boxing__run_in_place__positive__repeat_01__take_01.webm`
     - **Recommended runtime follow-up:** model it as a stateful Boxing family similar to `guard` / `squat` (very likely `run_in_place_start` / `run_in_place_end` plus `gesture_states.run_in_place`, or an equivalent active-window representation).

  3. **`stance_change`: keep as detector/fixture family wording only if we mean a transition, but chart-facing authored truth should remain `orthodox` / `southpaw`.**
     - Why: current Boxing charts and content-core already treat `orthodox` / `southpaw` as the authored semantics (`REF-10`, `REF-11`), and there is no existing `stance_change` chart type.
     - Current drift: unresolved fixture filename says `stance_change`, while chart truth expresses stance by target stance labels instead.
     - **Recommended canonical mapping:**
       - **Chart/authored surface:** `orthodox`, `southpaw`
       - **Potential detector/runtime family:** `stance_change` only if the implementation is specifically about detecting the transition event or active stance state machine.
     - **Recommended fixture follow-up:** do **not** invent a chart beat type `stance_change`. Normalize the existing unresolved clip only after a quick human review confirms whether it is `orthodox_to_southpaw`, `southpaw_to_orthodox`, alternating stance swaps, or simply generic stance-change exercise footage. If Derrick wants a holding-name before that review, use `.testbed/assets/fixtures/boxing/stance_change/boxing__stance_change__positive__orthodox_southpaw_repeat_04__take_01/...` with an explicit note that authored chart parity still lives in `orthodox` / `southpaw`, not `stance_change`.

  4. **`weave_left/right` should be the canonical product-facing replacement for the current UI’s `dodge` wording.**
     - Why: Derrick explicitly called out `weave_left/right` as the intended canonical term, and the current mismatch is already obvious: unresolved fixtures say `weave_*`, UI says `dodge`, detector internals say `lean_*`.
     - **Recommended canonical naming:**
       - **Product-facing / fixture / eventual chart term:** `weave_left`, `weave_right`
       - **Internal geometry helper term:** `lean_left`, `lean_right` may stay internal if useful, but emitted/public detector vocabulary should stop surfacing `dodge` once the rename pass happens.
     - **Recommended fixture renames:**
       - `boxing_weave_left_x4.webm` → `.testbed/assets/fixtures/boxing/weave_left/boxing__weave_left__positive__repeat_04__take_01/boxing__weave_left__positive__repeat_04__take_01.webm`
       - `boxing_weave_right_x4.webm` → `.testbed/assets/fixtures/boxing/weave_right/boxing__weave_right__positive__repeat_04__take_01/boxing__weave_right__positive__repeat_04__take_01.webm`
     - **Recommended UI/runtime follow-up:** rename the Boxing proving-scene `dodge` tile/labels in `.testbed/scripts/boxing_proving_harness.gd` to `weave`, and decide whether provider/substrate public events should graduate from `lean_left/right_*` to `weave_left/right_*` or expose an explicit alias layer.

- **Drift summary by surface:**
  - **Fixtures vs detector/UI:** `cross_*`, `run_in_place`, `stance_change`, and `weave_*` exist as raw fixture filenames, but none of those names currently exist as emitted Boxing runtime vocabulary.
  - **UI vs intended product truth:** proving-scene UI still says `dodge`, while Derrick’s intended canonical term is `weave`.
  - **Charts/content-core vs detector/runtime:** chart examples already include `run_in_place` and stance semantics (`orthodox` / `southpaw`) that are not represented in the detector/provider/harness event vocabulary.
  - **Content-core legacy map vs Derrick’s truth:** `cross -> punch_right` is the clearest stale rule remaining in shared chart validation.

- **Small truthful follow-up bead that should likely exist after this audit:** a narrow rename/alignment pass to (1) normalize the six unresolved Boxing fixture files using the mappings above, (2) rename the proving-scene `dodge` UI surface to `weave`, and (3) update content-core legacy Boxing vocabulary so `cross` no longer aliases straight punches.

- **Bottom-line naming truth for future work:**
  - `punch_left/right` = straight punches
  - `hook_left/right` = horizontal punch family that old raw filenames called `cross_left/right`
  - `uppercut_left/right` = unchanged
  - `weave_left/right` = preferred product-facing name replacing current UI `dodge` wording and current internal `lean_*` public surfacing
  - `run_in_place` = legitimate authored/gameplay vocabulary, runtime support still missing
  - `orthodox` / `southpaw` = authored stance chart semantics; `stance_change` is only a possible detector/fixture transition family, not today’s chart type

- **Reference check:** validated directly against `REF-04`, `REF-06`, `REF-08`, `REF-09`, `REF-10`, and `REF-11`.

---

### Task 9: Implement Boxing naming alignment after the vocabulary audit

**Bead ID:** `oc-08zs`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`, `REF-06`, `REF-08`, `REF-09`, `REF-10`, `REF-11`
**Prompt:** Use bead `oc-08zs`. Claim it on start with `bd update oc-08zs --status in_progress --json`. Implement the Boxing naming-alignment slice from Task 8. Normalize unresolved Boxing fixture filenames and folders to the agreed canonical vocabulary (`cross_*` → `hook_*`, standardize public-facing naming to `weave_*`, keep `run_in_place`, and use a clearer transition-oriented name for the current stance-change fixture). Update the Boxing proving UI from `dodge` to `weave`. Before changing shared chart-contract code, truth-check whether the current content-core `cross -> punch_right` mapping is actually stale or intentionally serving straight-punch legacy semantics; only change shared contract code if the surrounding source makes it clearly wrong. Update this plan with exactly what landed, commands run, and any intentionally deferred follow-up. Commit/push by default, then close with `bd close oc-08zs --reason "Boxing naming alignment implemented" --json`.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/assets/fixtures/`
- `.testbed/scripts/`
- shared chart-contract repo/files only if truthfully warranted by the mapping audit

**Files Created/Deleted/Modified:**
- unresolved Boxing fixture videos / stub YAMLs normalized to agreed naming
- Boxing proving UI naming updated from `dodge` to `weave`
- any minimal shared-contract cleanup only if the `cross` mapping is confirmed stale

**Status:** ✅ Complete

**Results:** Implemented the Boxing naming-alignment slice as a tight normalization/UI pass plus one justified shared contract fix.

- **Unresolved Boxing fixtures normalized into per-fixture folders with truthful stub YAML sidecars (`REF-04`):**
  - `boxing_cross_left_x4.webm` → `.testbed/assets/fixtures/boxing/hook_left/boxing__hook_left__positive__repeat_04__take_01/boxing__hook_left__positive__repeat_04__take_01.webm`
  - `boxing_cross_right_x4.webm` → `.testbed/assets/fixtures/boxing/hook_right/boxing__hook_right__positive__repeat_04__take_01/boxing__hook_right__positive__repeat_04__take_01.webm`
  - `boxing_run_in_place_x1.webm` → `.testbed/assets/fixtures/boxing/run_in_place/boxing__run_in_place__positive__repeat_01__take_01/boxing__run_in_place__positive__repeat_01__take_01.webm`
  - `boxing_stance_change_x4.webm` → `.testbed/assets/fixtures/boxing/stance_transition/boxing__stance_transition__positive__orthodox_southpaw_swap_repeat_04__take_01/boxing__stance_transition__positive__orthodox_southpaw_swap_repeat_04__take_01.webm`
  - `boxing_weave_left_x4.webm` → `.testbed/assets/fixtures/boxing/weave_left/boxing__weave_left__positive__repeat_04__take_01/boxing__weave_left__positive__repeat_04__take_01.webm`
  - `boxing_weave_right_x4.webm` → `.testbed/assets/fixtures/boxing/weave_right/boxing__weave_right__positive__repeat_04__take_01/boxing__weave_right__positive__repeat_04__take_01.webm`
- **Stub YAMLs created for all six normalized fixtures:** each new sibling `.fixture.yaml` stays on the truthful minimal schema (`schema_version`, `fixture_id`, `family`, `video.path`, `notes`) and explicitly avoids inventing `expected_gestures` or timing windows.
- **Boxing proving UI wording updated from `dodge` to `weave` (`REF-08`, `REF-09`):** `.testbed/scripts/boxing_proving_harness.gd` now presents the tile as `Weave` and labels lean-start/end events as `Weave Left/Right` while intentionally keeping the current underlying detector/internal event names `lean_left/right_*` unchanged.
- **Shared content-core legacy mapping audited and updated because it was clearly stale against surrounding source truth (`REF-10`, `REF-11`):**
  - `../aerobeat-content-core/data_types/chart.gd` changed legacy replacements from `cross -> punch_right` / `cross_right -> punch_right` to `cross -> hook_right` / `cross_right -> hook_right`.
  - This was justified by the surrounding README/examples already defining `punch_*` as straight punches and `hook_*` as the horizontal punch family; leaving `cross` mapped to `punch_right` would have kept contradicting the current contract truth.
- **Commands run:**
  - `python3 - <<'PY' ... from scripts.proving_fixture_runner import load_fixture ... PY` to load and validate all six new Boxing stub fixtures
  - `godot --headless --path .testbed --import`
  - `godot --headless --path ../aerobeat-content-core/.testbed --script res://../tests/run_contract_tests.gd`
  - `git fetch origin main && git rebase origin/main && git push origin main` in `../aerobeat-content-core` after the shared-repo push rejected on first attempt due to remote drift
- **Intentionally deferred / kept truthful:**
  - No Flow fixture work was pulled into this slice.
  - No gesture timing truth was invented in the new YAML sidecars.
  - No detector/provider runtime rename from internal `lean_*` to public `weave_*` was attempted here; this slice only updates the proving-scene public wording.
  - The new `stance_transition` fixture naming is an explicit transition-oriented holding name around orthodox/southpaw swaps, but it does **not** claim exact authored chart semantics beyond that until human review confirms a tighter truth.
- **Commits:**
  - `c77875f` — `Align legacy boxing cross mapping with hook naming`
  - `c0d8087` — `Align boxing fixture naming with vocabulary audit`

---

### Task 10: QA Boxing naming alignment and unresolved fixture normalization

**Bead ID:** `oc-fplk`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-04`, `REF-06`, `REF-08`, `REF-09`, `REF-10`, `REF-11` plus implementation references added during Task 9
**Prompt:** Use bead `oc-fplk`. Claim it on start with `bd update oc-fplk --status in_progress --json`. After `oc-08zs` lands, verify that the Boxing naming alignment is truthful across fixture files, proving-scene UI wording, and any shared chart-contract changes. Check that unresolved Boxing fixtures were normalized safely, that `dodge` no longer leaks on the Boxing proving surface if that rename landed, and that any content-core contract change is justified by source truth rather than guesswork. Update this plan with exact checks run and close with `bd close oc-fplk --reason "Boxing naming alignment QA complete" --json` only if QA truthfully passes.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / QA notes only unless a tiny truthful docs correction is required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 11: Audit Boxing naming alignment against chart truth

**Bead ID:** `oc-g1ew`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** all relevant boxing-vocabulary and implementation references from Tasks 8-10
**Prompt:** Use bead `oc-g1ew`. Claim it on start with `bd update oc-g1ew --status in_progress --json`. After QA completes, independently audit the Boxing naming-alignment work against the chart truth and Derrick’s clarified vocabulary decisions. Confirm whether the implementation is truly aligned across fixtures, UI wording, and any shared-contract behavior, and call out any remaining drift explicitly. Update this plan and close with `bd close oc-g1ew --reason "Boxing naming alignment audit complete" --json` only if the audit truthfully passes.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-13-boxing-fixture-system-truth-and-schema.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 12: Rename internal Boxing lean wording to weave across detector/provider surfaces

**Bead ID:** `oc-r095`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-06`, `REF-08`, `REF-09`, `REF-10`, `REF-11` plus implementation references added during Task 9
**Prompt:** Use bead `oc-r095`. Claim it on start with `bd update oc-r095 --status in_progress --json`. Implement the internal naming-alignment pass so Boxing detector/provider/public runtime wording uses `weave` instead of `lean` where that family is intended to be product-facing. Update detector/provider/harness/public surfaces carefully, keep compatibility in mind for existing validation and fixture tooling, update this plan with exactly what landed and what compatibility/deferred choices were made, commit/push by default, and close with `bd close oc-r095 --reason "Internal Boxing weave naming alignment implemented" --json`.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `src/detectors/`
- `src/providers/`
- `.testbed/scripts/`
- `docs/`

**Files Created/Deleted/Modified:**
- `src/detectors/pose_detector_substrate.gd`
- `src/providers/mediapipe_provider.gd`
- `src/input_provider.gd`
- `.testbed/scripts/proving_harness.gd`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `docs/proving-scene-human-verification-checklist.md`
- `docs/proving-scene-human-verification-log-template.md`
- `README.md`
- `.plans/2026-05-13-boxing-fixture-system-truth-and-schema.md`

**Status:** ✅ Complete

**Results:**
- Renamed the Boxing detector’s primary state/event family from `lean_*` to `weave_*` in `src/detectors/pose_detector_substrate.gd`, including the internal state keys, emitted event names, and shared proving/fixture-visible `gesture_states` output.
- Added a narrow compatibility bridge instead of pretending the old surface vanished instantly:
  - detector `gesture_states` now publish `weave_left` / `weave_right` as primary while also mirroring `lean_left` / `lean_right` aliases for legacy readers;
  - `src/providers/mediapipe_provider.gd` now declares and emits `weave_left/right_start/end` as the primary provider signals while still emitting the legacy `lean_*` aliases from the same detector events;
  - `src/input_provider.gd` now exposes addon-local `weave_*` signals and still relays inherited `lean_*` signals for compatibility.
- Updated the shared Boxing proving harness and Boxing proving UI surface to consume/display `weave_*` instead of `lean_*`, so future fixture capture reports and event timelines are truthful to the current Boxing product wording.
- Updated the targeted detector unit slice plus directly related Boxing verification docs/README to use `weave` terminology, while documenting the retained `lean_*` aliases as compatibility-only.
- Validation run during this coder pass:
  - `bd update oc-r095 --status in_progress --json`
  - `git diff --check` *(reported pre-existing trailing whitespace in this active plan section before cleanup)*
  - `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/proving_harness.gd`
  - `~/.local/bin/godot --headless --path .testbed --check-only --script addons/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd`
  - `~/.local/bin/godot --headless --path .testbed --check-only --script addons/aerobeat-input-mediapipe-python/src/input_provider.gd`
  - `~/.local/bin/godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gexit` → `12/12 passed`
- Commit hash(es): code/docs/tests landed in `6e96c15` (`Align boxing weave runtime naming`). This Task 12 plan update is being recorded in the follow-up plan/doc commit for the coder handoff.

---

### Task 13: QA internal Boxing weave naming alignment

**Bead ID:** `oc-4663`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-06`, `REF-08`, `REF-09`, `REF-10`, `REF-11` plus implementation references added during Task 12
**Prompt:** Use bead `oc-4663`. Claim it on start with `bd update oc-4663 --status in_progress --json`. After `oc-r095` lands, verify that the Boxing runtime/public naming alignment from `lean` to `weave` is truthful and consistent across detector/provider/proving/fixture validation surfaces, and that no stale public `lean_*` wording remains where `weave_*` is now intended. Update this plan with exact checks run and close with `bd close oc-4663 --reason "Internal Boxing weave naming QA complete" --json` only if QA truthfully passes.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / QA notes only unless a tiny truthful docs correction is required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 14: Audit internal Boxing weave naming alignment

**Bead ID:** `oc-1tao`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** all relevant boxing-naming references from Tasks 9-13
**Prompt:** Use bead `oc-1tao`. Claim it on start with `bd update oc-1tao --status in_progress --json`. After QA completes, independently audit the internal/public `weave` naming alignment and call out any remaining drift or compatibility caveats clearly. Update this plan and close with `bd close oc-1tao --reason "Internal Boxing weave naming audit complete" --json` only if the audit truthfully passes.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-13-boxing-fixture-system-truth-and-schema.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 15: Remove legacy Boxing lean compatibility aliases after weave migration

**Bead ID:** `oc-loxi`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-06`, `REF-08`, `REF-09` plus implementation references added during Task 12
**Prompt:** Use bead `oc-loxi`. Claim it on start with `bd update oc-loxi --status in_progress --json`. Derrick has explicitly decided that the temporary `lean_*` compatibility aliases are no longer needed after the `weave_*` migration. Remove the legacy Boxing `lean_*` compatibility layer from detector/provider/public runtime surfaces, keep the implementation truthful and Boxing-only, update any directly related tests/docs/validation surfaces required by the removal, update this plan with exactly what landed, commit/push by default, and close with `bd close oc-loxi --reason "Legacy Boxing lean compatibility removed" --json`.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `src/detectors/`
- `src/providers/`
- `src/`
- `.testbed/scripts/`
- directly related tests/docs only if required by the removal

**Files Created/Deleted/Modified:**
- `src/input_provider.gd`
- `src/providers/mediapipe_provider.gd`
- `src/detectors/pose_detector_substrate.gd`
- `README.md`
- `.plans/2026-05-13-boxing-fixture-system-truth-and-schema.md`

**Status:** ✅ Complete

**Results:** Removed the repo-local Boxing `lean_*` compatibility layer so `weave_*` is now the only authored wording on this repo's detector/provider/input-provider path. `src/providers/mediapipe_provider.gd` no longer declares or emits `lean_*` alias signals; `src/input_provider.gd` no longer falls back to provider `lean_*` signals or re-emits inherited `lean_*` aliases when weave events fire; and `src/detectors/pose_detector_substrate.gd` no longer injects `lean_left` / `lean_right` into public gesture state dictionaries. `README.md` was tightened to remove the stale compatibility-alias claim. Targeted validation run: `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/proving_harness.gd`; `~/.local/bin/godot --headless --path .testbed --check-only --script addons/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd`; `~/.local/bin/godot --headless --path .testbed --check-only --script addons/aerobeat-input-mediapipe-python/src/input_provider.gd`; `~/.local/bin/godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gexit` (`12/12` passed); plus a repo-local grep sweep confirming no remaining `lean_left` / `lean_right` references in `src`, `README.md`, `docs`, or `.testbed/tests`. Landed as `Remove boxing lean compatibility aliases` and pushed to `origin/main`. Caveat kept explicit: legacy `lean_*` signal declarations still exist in the mounted `aerobeat-input-core` testbed dependency outside this repo's owned scope, so this task only removes the compatibility layer implemented here.

---

### Task 16: QA removal of legacy Boxing lean compatibility aliases

**Bead ID:** `oc-u9xn`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-06`, `REF-08`, `REF-09` plus implementation references added during Task 15
**Prompt:** Use bead `oc-u9xn`. Claim it on start with `bd update oc-u9xn --status in_progress --json`. After `oc-loxi` lands, verify that the temporary Boxing `lean_*` compatibility layer has been removed cleanly and that primary `weave_*` runtime/provider/proving surfaces still parse, validate, and present truthfully. Also explicitly answer whether the fixture system is now ready for Derrick to continue trimming videos and start filling out fixture YAML truth, and whether the remaining blocker for deeper `punch_left` / `punch_right` work is now primarily incomplete YAML authoring rather than fixture-system infrastructure. Update this plan with exact checks run and close with `bd close oc-u9xn --reason "Legacy Boxing lean compatibility QA complete" --json` only if QA truthfully passes.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / QA notes only unless a tiny truthful docs correction is required

**Status:** ✅ Complete

**Results:** QA pass for the lean→weave compatibility removal, with the fixture-readiness answer now explicit and separated from detector-truth follow-up.

- **Task 15 landing inspected directly:** reviewed the Task 15 results plus the landed removal diff on `78458fa` (`Remove boxing lean compatibility aliases`). The code-level removal matches the plan claim: repo-owned `lean_*` compatibility wiring was removed from `src/providers/mediapipe_provider.gd`, `src/input_provider.gd`, and the detector’s public `gesture_states` output in `src/detectors/pose_detector_substrate.gd`, while `weave_*` remains the primary authored/runtime wording.
- **Repo-owned public/runtime surface sweep passed:** searched repo-owned sources and directly related validation surfaces for stale Boxing `lean_*` wording after the removal.
  - `grep -RInE "lean_(left|right)|lean\\*|lean_" src README.md docs .testbed/scripts .testbed/tests .testbed/assets/fixtures 2>/dev/null || true` → no matches
  - `grep -RInE "lean_(left|right)|Lean (Left|Right)|Dodge (Left|Right)|dodge" src .testbed/scripts README.md docs .testbed/tests 2>/dev/null || true` found only `.testbed/scripts/boxing_proving_harness.gd:18` referencing the asset filename `boxing-dodge-1.svg`; this is an icon file path/name, not a leaked public/runtime wording surface. The actual displayed UI/event wording remains `weave`.
- **Primary `weave_*` surface verified in source:** confirmed `weave_*` is the active repo-owned runtime/public vocabulary in `src/providers/mediapipe_provider.gd`, `src/input_provider.gd`, `src/detectors/pose_detector_substrate.gd`, `.testbed/scripts/proving_harness.gd`, `.testbed/scripts/boxing_proving_harness.gd`, unit tests, docs, README, and normalized Boxing weave fixtures.
- **Targeted validation rerun passed after compatibility removal:**
  - `python3 scripts/test_proving_fixture_runner.py` → `OK`
  - `python3 - <<'PY' ... fixture sweep via load_fixture(...) ... PY` → all `17` fixture YAMLs loaded successfully; all resolved existing sibling video files; `2` fixtures currently contain authored `expected_gestures` and `15` remain truthful stub fixtures awaiting manual authoring
  - `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/proving_harness.gd`
  - `~/.local/bin/godot --headless --path .testbed --check-only --script addons/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd`
  - `~/.local/bin/godot --headless --path .testbed --check-only --script addons/aerobeat-input-mediapipe-python/src/input_provider.gd`
  - `~/.local/bin/godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gexit` → `12/12 passed`
- **Fixture-system readiness verdict:** **PASS.** The fixture infrastructure is ready for Derrick to keep trimming videos and filling in YAML truth. Task 4’s runner/capture/validation path is still intact after Task 15, fixture-owned video loading still works, the minimal schema is still coherent, and the repo now has a broad normalized fixture inventory whose stub YAMLs load cleanly.
- **Remaining YAML authoring work:** still substantial, but this is **authoring backlog, not fixture-system failure**. The fixture sweep showed only `2/17` current fixture YAMLs have authored `expected_gestures`; the other `15` are truthful placeholders waiting for Derrick’s manual timing/event truth.
- **Unresolved detector-behavior truth:** still a real blocker for deeper `punch_left` / `punch_right` trust work. Task 4 / Task 5 already established that the known left-punch fixture run emits truthful failure evidence: expected `punch_left` windows do not match actual emitted events and a false-positive sibling event (`uppercut_right`) appears instead. That means deeper punch-fixture progress is **not** blocked only by incomplete YAML authoring; detector behavior itself still needs follow-up investigation/correction.
- **Practical readiness answer for Derrick:**
  - **Yes:** Derrick can safely continue trimming Boxing videos and filling out fixture YAML truth now.
  - **Yes:** incomplete YAML authoring is the main blocker for expanding broad fixture coverage across the newly normalized inventory.
  - **No:** incomplete YAML authoring is **not** the only blocker before deeper `punch_left` / `punch_right` work, because known detector-truth failures remain exposed by the current punch fixture evidence.
- **QA verdict:** pass the Task 15 cleanup itself, pass fixture-system readiness, but keep punch-detector truth explicitly open as a separate blocker rather than folding it into authoring or infrastructure.

---

### Task 17: Audit removal of legacy Boxing lean compatibility aliases

**Bead ID:** `oc-fiyc`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** all relevant weave-alignment references from Tasks 12-16
**Prompt:** Use bead `oc-fiyc`. Claim it on start with `bd update oc-fiyc --status in_progress --json`. After QA completes, independently audit that the old Boxing `lean_*` compatibility layer is actually gone where intended and that the project now speaks `weave_*` consistently without hidden public drift. Also independently audit the practical readiness question: is the fixture system now ready for Derrick to keep trimming videos and manually fill out YAML truth, and if so is incomplete YAML authoring now the main blocker before more precise `punch_left` / `punch_right` fixture-driven work proceeds? Update this plan and close with `bd close oc-fiyc --reason "Legacy Boxing lean compatibility audit complete" --json` only if the audit truthfully passes.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-13-boxing-fixture-system-truth-and-schema.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 18: Validate Derrick's trimmed boxing-left fixture YAML and make the minimum truthful repair if needed

**Bead ID:** `oc-nj4q`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-12`, `REF-13`
**Prompt:** Use bead `oc-nj4q`. Claim it on start with `bd update oc-nj4q --status in_progress --json`. Derrick trimmed the current videos for the fixture system and authored the new Boxing-left YAML at `REF-12`. Validate that YAML against the actual fixture runner/harness contract, make only the minimum truthful repair required if it is invalid, and then run the boxing harness fixture path against the trimmed video/YAML. Keep scope tight: do not invent detector truth or broaden schema semantics. Capture exactly what failed or passed — including whether the YAML itself was invalid, whether any authored gesture names are unsupported by the current validator/runtime surface, and whether the harness run emits trustworthy evidence. Run relevant validation, commit/push by default, update the active plan with what actually happened, and close with `bd close oc-nj4q --reason "Trimmed boxing-left fixture validated and run" --json` when done.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/assets/fixtures/boxing/punch_left/`
- `.testbed/test-results/fixtures/`
- exact runner/docs paths only if truthfully required

**Files Created/Deleted/Modified:**
- `.testbed/assets/fixtures/boxing/punch_left/boxing_punch_left_x4_while_guarding_take_01.yaml`
- exact runner/docs/source files only if required by the truthful repair

**Status:** ✅ Complete

**Results:** Took over directly from a failed/cut-off coder subagent after it incorrectly removed Derrick's manually authored `guard` windows. Restored the authored `guard` truth in `REF-12` and landed the minimum truthful contract extension required to validate it instead of flattening it away: `scripts/proving_fixture_runner.py` now supports `expected_gestures[].surface` with default `event` and explicit `state` support for simple state-window truth, `scripts/test_proving_fixture_runner.py` now covers state-segment extraction/validation, and `docs/proving-scene-video-fixtures.md` now documents the `surface: state` path. The trimmed fixture YAML now preserves Derrick's human-validated `guard` windows as `surface: state` while keeping the event-name normalization fixes for forbidden emitted events (`squat_start`, `leg_lift_*_start`, `weave_*_start`, `sidestep_*_start`).

Validation truth after the repair:
- `python3 -m unittest -v scripts/test_proving_fixture_runner.py` passed.
- The trimmed fixture YAML loads cleanly and resolves the sibling video in `REF-13`.
- A fresh capture run at `REF-14` was partially interrupted before wrapper-side validation files were written, but the underlying `report.json`/`godot.log`/`proving.png` were saved. I salvaged that run by feeding the saved `report.json` through the patched validator, which produced `summary.json`, `assertions.json`, `event_timeline.json`, `state_timeline.json`, and `report.md` in `REF-14`.
- The fixture system now truthfully separates contract validity from detector truth: the repaired run produced **25 assertions: 15 pass / 10 fail**.
- Remaining failures are detector/runtime truth, not fixture-schema breakage: no `punch_left` events were emitted in any of the four authored windows; `guard` only overlapped the middle authored windows; and forbidden false positives still fired (`uppercut_right` three times and `squat_start` once).
- Fresh runtime evidence from `REF-14` shows actual emitted events of `provider_started`, `squat_start`, `uppercut_right`, and several `guard_start`/`guard_end` transitions, with real `guard` state segments around `2867-3334ms`, `4020-4084ms`, and `4336-4453ms`.

Net result: Derrick's trimmed YAML/video pair is now **valid and usable in the current fixture system**, including authored guard-state truth, but the clip still **fails truthfully** because current Boxing detection does not match the authored left-punch gold truth. No commit yet in this task block at the time of writing; cleanup/commit follows immediately after this plan update.

---

### Task 19: QA the trimmed boxing-left fixture YAML and harness evidence

**Bead ID:** `oc-sy8g`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-02`, `REF-04`, `REF-12`, `REF-13` plus implementation references added during Task 18
**Prompt:** Use bead `oc-sy8g`. Claim it on start with `bd update oc-sy8g --status in_progress --json`. After `oc-nj4q` lands, independently verify that Derrick's trimmed boxing-left fixture is now truthful against the current fixture-system contract and that the harness evidence is understandable. Explicitly answer: did the YAML parse cleanly; did any authored expectations need repair to match the current validator/runtime surface; did the fixture runner actually use the new trimmed video/YAML pair; and are any remaining failures now detector-truth failures rather than fixture-system breakage? Update this plan with exact checks run and close with `bd close oc-sy8g --reason "Trimmed boxing-left fixture QA complete" --json` only if QA truthfully passes.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / QA notes only unless a tiny truthful docs correction is required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 20: Audit the trimmed boxing-left fixture truth pass and readiness for further fixture authoring

**Bead ID:** `oc-3hac`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-02`, `REF-04`, `REF-12`, `REF-13` plus implementation/QA references added during Tasks 18-19
**Prompt:** Use bead `oc-3hac`. Claim it on start with `bd update oc-3hac --status in_progress --json`. After QA completes, independently audit the trimmed boxing-left fixture pass. Decide whether the new YAML/video pair is now valid and usable in the current fixture system, whether the evidence clearly separates fixture-contract issues from detector-truth issues, and what Derrick should do next when authoring more Boxing fixture YAMLs. Update this plan and close with `bd close oc-3hac --reason "Trimmed boxing-left fixture audit complete" --json` only if the audit truthfully passes.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-13-boxing-fixture-system-truth-and-schema.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 21: Audit the trimmed boxing-left detector mismatches directly and plan the truthful fixes needed to pass

**Bead ID:** `oc-uqf5`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-02`, `REF-04`, `REF-06`, `REF-12`, `REF-13`, `REF-14`
**Prompt:** Use bead `oc-uqf5`. Claim it on start with `bd update oc-uqf5 --status in_progress --json`. Starting from the now-valid trimmed Boxing-left fixture and the salvaged validation artifacts in `REF-14`, audit the detector mismatches directly and plan the smallest truthful fixes needed to make this clip pass. Focus on why `punch_left` never emits, why `uppercut_right` and `squat_start` false positives appear, and why `guard` only overlaps some of the authored windows. Distinguish likely timing-authoring issues from runtime/provider/detector bugs. Produce a concrete next-step fix plan with evidence-backed hypotheses, recommended code areas, and validation strategy. Update this plan with exact findings and close with `bd close oc-uqf5 --reason "Trimmed boxing-left detector audit and fix plan complete" --json` when done.

**Folders Created/Deleted/Modified:**
- `.plans/`
- source/docs paths only if a tiny truthful note is needed

**Files Created/Deleted/Modified:**
- `.plans/2026-05-13-boxing-fixture-system-truth-and-schema.md`
- exact analysis notes or tiny source/docs files only if required by the audit

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:**
- Task 4 landed a truthful first fixture-system slice: real fixture parsing, fixture-owned video resolution, shared harness event/state capture, and direct gesture-window validation artifacts for prerecorded proving runs.

**Reference Check:**
- `REF-02`, `REF-04`, and `REF-05` are now exercised directly by the new runner/capture path.
- `REF-06` remains the runtime detector truth source that the new fixture validator now exposes more clearly.

**Commits:**
- `666d4db` - Implement first truthful fixture-system slice
- `5dea008` - Update fixture-system plan with task 4 results

**Lessons Learned:**
- The old capture path had a real early-exit bug, so even the first slice needed to repair the evidence pipeline before validation truth was possible.
- The new fixture system is now materially usable, but Boxing detector truth still fails on the left-punch clip and should be handled in follow-up QA/audit work rather than hidden inside fixture scope.

---

*Created on 2026-05-13*
