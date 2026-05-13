# AeroBeat MediaPipe Python — Boxing Oddities Audit and Fixes

**Date:** 2026-05-12  
**Status:** In Progress  
**Agent:** Pico 🐱‍🏍

---

## Goal

Audit the current Boxing proving oddities from Derrick’s prerecorded left-punch screenshot and fix the highest-confidence shared issues so Boxing detection and overlay behavior become trustworthy enough for deeper feature work.

---

## Overview

Derrick’s latest Boxing screenshot and notes expose three concrete problem families in one repro surface: (1) hand trails still appear as raycast-like lines, (2) pose landmarks/skeleton can render outside the visible video feed instead of respecting the actual displayed preview bounds, and (3) Boxing gesture detection is materially wrong on a prerecorded left-punch clip, with no left-punch detections and repeated unrelated gesture firings such as knee strike / leg lift while the subject is in guard and punching left.

This plan keeps those three problems explicit and ordered. First we need a source-and-screenshot-backed audit that explains what the screenshot is actually telling us and which surfaces are shared versus Boxing-specific. That should distinguish overlay-coordinate bugs from trail-history bugs from detector/fixture interpretation bugs. After that, implementation should proceed in the smallest truthful slices: hide or clip landmarks/trails that fall outside the displayed feed bounds, fix any remaining trail continuity/raycast behavior, and then investigate the actual Boxing gesture false positives / missed left-punch detection on the prerecorded left-punch fixture.

The key risk is mixing overlay bugs with detector bugs. If skeleton/trail projection is wrong, Boxing may *look* more broken than it is; if detector logic is wrong, overlay cleanup alone will not fix the false positives. So this plan starts with a screenshot-informed audit first, then separates shared visual correctness from actual Boxing behavior logic. Success means Derrick gets a more trustworthy Boxing proving surface and we have a clearer read on whether the remaining Boxing detection errors are fixture/runtime issues, detector-threshold issues, or real logic bugs.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Boxing screenshot showing current oddities | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/12/image-c64a0034.png` |
| `REF-02` | Boxing proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/boxing_proving.tscn` |
| `REF-03` | Shared proving harness | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-04` | Landmark drawer | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/landmark_drawer.gd` |
| `REF-05` | Hand trail drawer | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/hand_trail_drawer.gd` |
| `REF-06` | Boxing-specific proving harness layer | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-07` | Camera/preview view | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/camera_view.gd` |
| `REF-08` | Current clean-base plan that just passed source-level QA | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-12-mediapipe-start-stop-and-proving-ui-clean-base.md` |

---

## Tasks

### Task 1: Audit the Boxing screenshot oddities and map them to likely source surfaces

**Bead ID:** `oc-428s`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Inspect Derrick’s Boxing screenshot plus the current Boxing/shared proving source surfaces and identify the strongest likely causes for the three reported issues: raycast-like trails, skeleton/landmarks drawing outside the visible video feed, and incorrect repeated Boxing gesture firings / missed left punches on the prerecorded left-punch clip. Separate shared overlay/trail problems from actual Boxing detector/logic problems, and recommend the smallest truthful fix order.

**Folders Created/Deleted/Modified:**
- `.plans/`
- source paths only for reading unless a tiny truth note is required

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny truth-revealing note is required

**Status:** ✅ Complete

**Results:** Screenshot-backed audit completed and bead `oc-428s` closed. The screenshot shows semantic Boxing failure, not just cosmetic UI drift: on the left-punch prerecorded fixture the proving surface reported `last: Right Knee Strike`, flooded the event log with knee/leg-lift events, and showed Guard + Squat simultaneously while Derrick was in guard throwing left punches. Shared-problem read: the raycast-like trails most likely come from fallback hand synthesis / reseed behavior in `.testbed/scripts/proving_harness.gd`, not primarily `hand_trail_drawer.gd`; skeleton/landmarks outside the visible feed most likely come from `.testbed/scripts/landmark_drawer.gd`, which computed display bounds but still projected out-of-range normalized landmarks into surrounding UI space. Boxing-specific read: `src/detectors/pose_detector_substrate.gd` was the strongest likely source for the missed `punch_left` detections and unrelated gesture spam. Most important likely causes identified there were (1) punch-family detection being gated behind `if not guard`, which is hostile to a guard-start / guard-end straight-punch fixture, (2) lower-body detector paths lacking strong enough torso/foot confidence gating, and (3) baseline/height-state drift from continuing recalibration. Smallest truthful fix order established: first clip/hide out-of-feed landmarks in `landmark_drawer.gd`, second tighten trail point acceptance/reseed logic in `proving_harness.gd`, third remove or narrow guard suppression for straight punches on the fixture path, fourth add lower-body confidence gating before any deeper threshold retuning, and only then revisit baseline strategy if needed. One additional contract truth was recorded: the left-punch fixture sidecar explicitly forbids `hook_left`, `uppercut_left`, `knee_left`, and `knee_right`, so the current screenshot behavior is clearly wrong against the authored proving contract, not just noisy.

---

### Task 2: Fix overlay visibility so landmarks/trails outside the displayed feed are hidden or clipped correctly

**Bead ID:** `oc-amde`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-07`  
**Prompt:** Implement the smallest truthful fix so pose landmarks/skeleton/trails do not render outside the actually displayed video feed bounds in the proving scenes. Preserve aspect ratio and the new preview-fit behavior, and ensure out-of-feed points are hidden or clipped rather than drawing in surrounding UI space.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scripts/`
- `src/` only if shared camera-view geometry needs a small support change

**Files Created/Deleted/Modified:**
- exact overlay/drawer/preview files required by the fix

**Status:** ✅ Complete

**Results:** Completed and pushed in commit `95d97fc` (`Fix proving overlay out-of-bounds landmarks`). The fix stayed tight to `.testbed/scripts/landmark_drawer.gd`: normalized-bounds checks now reject any landmark point whose `x` or `y` falls outside `0.0..1.0`, so point circles/arcs no longer project into the surrounding UI outside the displayed feed, and skeleton segments now draw only when both connected landmarks are in normalized bounds. Preview-fit/layout math was left untouched. `hand_trail_drawer.gd` did not need changes for this bead because it already rejects out-of-bounds normalized trail points and breaks segments at those boundaries. Safe validation run: `godot --headless --path .testbed --quit`, which exited `0`; only the same pre-existing headless shutdown leak/resource warnings remained.

---

### Task 3: Fix remaining hand-trail raycast behavior in Boxing/shared proving surfaces

**Bead ID:** `oc-plxc`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Investigate and fix the remaining raycast-like hand trail behavior visible in Boxing. Keep scope tight to truthful trail history / continuity / drawing logic and preserve any already-landed cleanup that was meant to prevent stale straight-line bridges.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scripts/`
- tests only if a small targeted regression case is warranted

**Files Created/Deleted/Modified:**
- exact trail-related files required by the fix

**Status:** ✅ Complete

**Results:** Completed earlier and landed in commit `5706ae8` (`Fix trail fallback raycast continuity`). Source-level result: `proving_harness.gd` now rejects sketchy fallback hand synthesis rather than clamping/bridging toward edge points, and the existing `hand_trail_drawer.gd` break-marker behavior remains coherent with the intended “break honestly instead of raycasting to some synthetic point” model. Runtime truth pass still belongs to Derrick, but the previously identified shared fallback/reseed source of the raycast-look has now been addressed in source.

---

### Task 4: Investigate missed left-punch detection and repeated incorrect Boxing gesture firings on the prerecorded left-punch fixture

**Bead ID:** `oc-me05`  
**SubAgent:** `primary` (for `research` or `coder` workflow role depending on findings)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-06`  
**Prompt:** Analyze why the prerecorded left-punch clip in guard position does not produce left-punch detections while repeatedly firing unrelated gestures such as knee strike / leg lift. Determine whether the fault is most likely in Boxing detection logic, shared gesture routing, fixture interpretation, pose coordinate assumptions, or proving-scene state presentation. If a narrow source fix is obvious and safe, recommend it; otherwise produce the smallest truthful next implementation target.

**Folders Created/Deleted/Modified:**
- `.plans/`
- source paths only for reading unless a tiny truth note is required

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny truth-revealing note is required

**Status:** ✅ Complete

**Results:** Completed via cleanup pass and pushed in commit `a1c0594` (`Fix boxing guard-start punch fixture detection`). The kept coherent source changes in `src/detectors/pose_detector_substrate.gd` were explicitly checked against the authored left-punch fixture sidecar `.testbed/assets/fixtures/boxing/punch_left/boxing__punch_left__positive__guard_start_end__take_01.fixture.yaml`, which expects `punch_left` count `4` and forbids `hook_left`, `uppercut_left`, `knee_left`, and `knee_right`. The landed detector changes now let straight punches evaluate even while `guard` is active, add torso/foot confidence gating before squat/knee/leg-lift firing, and freeze baseline calibration once it succeeds instead of drifting through the clip. The cleanup pass also reverted a stray local `boxing_proving.tscn` debug-toggle drift (`startup_mode = 0`, `skip_sidecar_stop_on_close_debug = false`) that was not durable product work. Safe validation run used `godot --headless --path .testbed --quit`; scripts still parsed/loaded cleanly, with only pre-existing headless leak/resource warnings at shutdown. Runtime fixture truth still belongs to Derrick: source-level detector cleanup is landed, but this pass did not certify an actual proving run yielding exactly `punch_left = 4` with no forbidden events.

---

### Task 5: QA the Boxing oddities slice after the first fixes land

**Bead ID:** `oc-12bp`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Verify that the first Boxing oddities fixes improve the proving surface meaningfully. Explicitly separate source-proven overlay/trail fixes from anything that still needs Derrick’s direct runtime truth pass on the prerecorded left-punch clip.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / QA notes only unless a truthful docs correction is required

**Status:** ✅ Complete

**Results:** QA completed as a source/static-validation pass against the fixture-backed contract. Trail fix `5706ae8` checks out coherently in source: `proving_harness.gd` now rejects sketchy fallback hand synthesis instead of clamping/bridging toward feed edges, and `hand_trail_drawer.gd` already respects break markers, so the combined behavior matches the intended “break honestly, don’t raycast” model. Overlay clipping fix `95d97fc` checks out in source: `landmark_drawer.gd` now skips out-of-bounds landmarks for both points and skeleton segments, which truthfully matches the displayed-image-bounds projection model and should stop off-feed drawing in surrounding UI space. Detector fix `a1c0594` is aligned to the left-punch fixture contract at source level: straight punches now evaluate while `guard` is active, lower-body spam risk is reduced by torso/foot confidence gating, and baseline recalibration now freezes once calibrated. Fixture truth was rechecked during QA: expected `punch_left` count is `4`; forbidden events include `punch_right`, `hook_left`, `hook_right`, `uppercut_left`, `uppercut_right`, `knee_left`, and `knee_right`, with the screenshot/audit also highlighting bogus `leg_lift_*` / `squat` family noise as part of the observed failure family. Strongest safe validation run: `godot --headless --path .testbed --quit`. Exact remaining gap remains explicit: this QA pass proves source/static coherence only, not a real prerecorded proving run, so it does **not** certify that the fixture now emits exactly `punch_left = 4` and no forbidden events at runtime. One additional runtime caveat noted during QA: `boxing_proving.tscn` is currently `startup_mode = 2` (`GODOT_ONLY_DEBUG`), so Derrick’s next real fixture validation run will need the intended startup mode set before detector/runtime truth can be claimed.

---

### Task 6: Audit Boxing oddities slice readiness after source-level fixes and QA

**Bead ID:** `oc-fvc9`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-08`  
**Prompt:** Independently audit the landed Boxing oddities fixes and the QA claims. Decide whether the slice is truly ready for Derrick’s real prerecorded left-punch fixture truth pass and whether it is ready to be treated as settled enough for deeper Boxing work.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-12-boxing-oddities-audit-and-fixes.md`

**Status:** ✅ Complete

**Results:** Independent audit completed against the exact requested source files plus the left-punch fixture contract. The landed source fixes are real and coherent: `proving_harness.gd` now breaks/reseeds trails honestly instead of synthesizing long fallback bridges; `hand_trail_drawer.gd` respects those break markers; `landmark_drawer.gd` now suppresses out-of-bounds points and skeleton segments; and `pose_detector_substrate.gd` now allows straight-punch evaluation while `guard` is active and adds stronger lower-body confidence gating before squat/knee/leg-lift paths. However, two readiness gaps remain and matter for truthful handoff. First, `.testbed/scenes/boxing_proving.tscn` is still saved with `startup_mode = 2` (`GODOT_ONLY_DEBUG`) and `skip_sidecar_stop_on_close_debug = true`, so the authored Boxing proving scene is not currently saved in a state that can directly produce the real prerecorded detector truth pass without Derrick first flipping those debug toggles back to a runtime-capable mode. Second, the left-punch fixture’s observability contract still requires `gesture_debug.boxing.left.punch_distance`, `gesture_debug.boxing.left.punch_velocity`, and `gesture_debug.boxing.left.punch_extension`, but those fields do not exist in `pose_detector_substrate.gd` / proving-harness source today; only `gesture_debug.ready.punch_left` clearly exists. That means the detector slice is ready enough to justify Derrick’s next real runtime truth pass, but it is **not** fully fixture-contract-complete and should **not** yet be treated as fully proven / ready for deeper Boxing work without that runtime pass and, ideally, the missing observability follow-up.

---

### Task 6: Derrick manual Boxing input review and feedback pass

**Bead ID:** `oc-gfj1`  
**SubAgent:** `primary` (for `primary` workflow role)  
**Role:** `primary`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-06`  
**Prompt:** After the current source-level Boxing oddities fixes, Derrick will manually run the Boxing proving surface against the prerecorded left-punch fixture, review the visible input/detection behavior directly, and provide feedback on what still looks wrong or improved.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / review notes only unless a later fix slice requires more

**Status:** ⏳ Pending

**Results:** Pending tomorrow manual truth pass from Derrick.

---

### Task 7: Audit Boxing fixture expected fields for usefulness vs hallucination

**Bead ID:** `oc-hya2`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-03`, `REF-06`  
**Prompt:** Investigate whether the Boxing fixture contract’s expected observability fields such as `gesture_debug.boxing.left.punch_distance`, `gesture_debug.boxing.left.punch_velocity`, and `gesture_debug.boxing.left.punch_extension` are meaningful missing concepts we should actually implement, or whether they are effectively hallucinated / unhelpful expectations that should be removed or revised.

**Folders Created/Deleted/Modified:**
- `.plans/`
- fixture/docs/source paths only if needed for the audit

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny truth-revealing note is required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 8: Design fixture-listenable event validation path for Boxing and Flow harnesses

**Bead ID:** `oc-mqnk`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-02`, `REF-03`, `REF-06`, `REF-08`  
**Prompt:** Determine what the current fixture/proving system is missing so Boxing and Flow harness events can be emitted in a machine-checkable way — likely through or alongside input-core — so outside systems can listen for expected events within time ranges and verify prerecorded fixture runs automatically. The goal is to enable future QA subagents to know the system did what it claimed because both code checks and fixture-backed event expectations pass.

**Folders Created/Deleted/Modified:**
- `.plans/`
- research/design notes only unless a tiny truth note is needed

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny truth-revealing note is required

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:**
- Screenshot-backed triage for the Boxing oddities.
- Shared overlay clipping fix for out-of-feed landmarks/skeleton segments.
- Shared trail fallback/raycast continuity fix.
- Boxing detector cleanup aligned to the guard-start left-punch fixture contract at source level.
- Independent audit separating “ready for Derrick’s runtime truth pass” from “fully proven / ready to proceed deeper.”

**Reference Check:**
- `REF-01` to `REF-07`: satisfied only at source/static-validation level.
- Runtime proving truth against the prerecorded left-punch fixture is still pending Derrick’s direct run.
- Fixture observability parity is still incomplete because `gesture_debug.boxing.left.*` fields required by the fixture are not yet implemented in source.

**Commits:**
- `5706ae8` - `Fix trail fallback raycast continuity`
- `95d97fc` - `Fix proving overlay out-of-bounds landmarks`
- `a1c0594` - `Fix boxing guard-start punch fixture detection`

**Lessons Learned:**
- Boxing oddities were not just cosmetic; the screenshot exposed real semantic detector failures.
- Shared proving-surface bugs and Boxing-specific detector bugs have to stay separated or the diagnosis gets muddy.
- Fixture/YAML contract truth is essential for Boxing detector work; screenshot intuition alone is not enough.
- “Ready for runtime truth pass” is a narrower claim than “runtime truth already proven” or “fixture contract fully satisfied.”

---

*Created on 2026-05-12*