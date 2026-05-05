# AeroBeat MediaPipe Proving Scene Human Verification and Tuning

**Date:** 2026-05-05  
**Status:** Complete  
**Agent:** Pico 🐱‍🏍

---

## Goal

Audit the Boxing and Flow proving scenes in `aerobeat-input-mediapipe-python` to make sure they visibly test and report the status of each gameplay feature plus gesture/input state, then tune any gaps in detector/debug coverage without mixing in unrelated performance investigation.

---

## Overview

Yesterday’s implementation stack landed cleanly across docs, content, input-core, and the MediaPipe provider. The current repo already contains the first-pass detector substrate, Boxing detectors, Flow detectors, and dedicated proving scenes. That means today should start from real behavior verification rather than more speculative architecture work.

The immediate audit question is not just whether the detectors fire, but whether each proving scene makes the current gameplay/debug truth legible: every supported feature should either have a visible test/status surface or be explicitly called out as missing. That includes one-shot gestures, hold/state transitions, continuity-oriented Flow signals, and the lower-level gesture/input/body-state diagnostics Derrick needs for human tuning.

This plan keeps the work tightly scoped to `aerobeat-input-mediapipe-python`, because the highest-value next step is to exercise the provider in its own `.testbed` and tune the detector truth at the source. If we discover genuine contract issues during testing, we will create explicit follow-up beads instead of quietly broadening scope across other repos. Performance remains isolated: unless detector behavior is unusably blocked by runtime speed/latency, the previously parked perf investigation bead `oc-nua` stays out of this pass.

Because this phase depends on observed camera behavior, we should expect an iterative loop: baseline launch/proof, Boxing tuning, Flow tuning, then QA and independent audit. If Derrick needs to perform the physical movement pass, that interaction should be recorded clearly in the plan/results so the final state distinguishes automated verification from human-in-the-loop truthing.

Two explicit follow-up tracks are now part of the expected roadmap after the current observability pass: (1) substantial human verification / movement truthing across all supported features, and (2) creation of reusable feature-specific video fixtures that can later support more automated detector/proving-scene testing. The current audit should record whether those belong as new beads after this slice rather than pretending the work is fully finished today.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Completed cross-repo implementation plan from yesterday | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-docs/.plans/2026-05-04-mediapipe-input-alignment-and-feature-mapping.md` |
| `REF-02` | Yesterday handoff / next-session notes | `/home/derrick/.openclaw/workspace/memory/2026-05-04.md` |
| `REF-03` | MediaPipe provider repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python` |
| `REF-04` | Boxing proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/boxing_proving.tscn` |
| `REF-05` | Flow proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/flow_proving.tscn` |
| `REF-06` | Future isolated perf bead | `oc-nua` |

---

## Tasks

### Task 1: Audit proving-scene coverage and establish test baseline

**Bead ID:** `oc-wfw`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** In `aerobeat-input-mediapipe-python`, create/claim the repo-local bead for today’s proving-scene audit/tuning pass, inspect the current Boxing and Flow proving scenes plus their detector entrypoints, and verify whether each gameplay feature and each gesture/input/body-state status is visibly tested or displayed. Launch the highest-fidelity repo-local validation path available, document the exact baseline coverage and any blind spots before tuning, and separate detector-truth blockers from performance-only concerns. Claim the bead on start with `bd update <id> --status in_progress --json`, leave precise notes, and do not close the parent effort unless the baseline coverage audit is genuinely established.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.beads/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/`

**Files Created/Deleted/Modified:**
- plan updates only unless baseline fixes are required

**Status:** ✅ Complete

**Results:** Baseline audit completed. The current Boxing and Flow scenes both launch headlessly and the substrate unit slice passed (`test_pose_detector_substrate.gd`: 9/9). Runtime/editor truthing was only partial because no live Godot plugin editor session was available for in-editor screenshots or human-visible gesture verification. Audit outcome: both scenes already provide solid live camera/landmark visibility plus rolling event feeds, but they are still missing the persistent observability Derrick asked for. Shared gaps include no persistent per-signal status board, no counters/last-fired timestamps, no visible ready/reset gate state, and no proof matrix showing which supported features are currently visible/exercised. Boxing specifically needs persistent per-move status for punch/hook/uppercut/knee families plus clearer guard/suppression/reset visibility. Flow specifically needs deeper diagnostic visibility for the actual swing/trail decision inputs (`duration`, `arc length`, `net distance`, `directional consistency`, `lane spread`, `avg confidence`, candidate `placement`, candidate `direction`) plus ready/reset state and a more explicit coverage grid. Likely next edit surface: `.testbed/scenes/proving_harness.gd`, with scene layout adjustments in `boxing_proving.tscn` and `flow_proving.tscn` if more UI room is needed.

---

### Task 2: Tune Boxing proving-scene coverage and detector behavior

**Bead ID:** `oc-7ya`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-06`  
**Prompt:** Using the established baseline in `aerobeat-input-mediapipe-python`, tune the Boxing proving scene so it clearly tests and shows the status of each supported Boxing gameplay feature and underlying gesture/input/body-state signal. Focus on punch family thresholds, guard state transitions, squat/lean/sidestep behavior, knee/leg-lift reset behavior, and whether the scene UI/debug output makes those states legible during human verification. Keep all canonical detector logic in `src/` rather than scene scripts, but add honest proving-scene instrumentation where needed. If specific movement classes prove ambiguous, document the ambiguity precisely instead of papering over it. Claim the bead at start, run relevant validation, commit/push repo changes before handoff, and close the bead with an explicit reason only if the Boxing tuning slice is actually done.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/`

**Files Created/Deleted/Modified:**
- `.testbed/scenes/proving_harness.gd`
- `.testbed/scenes/boxing_proving.tscn`
- `.testbed/scenes/flow_proving.tscn`
- `src/detectors/pose_detector_substrate.gd`

**Status:** ✅ Complete

**Results:** Added a persistent Boxing signal board so the proving harness now shows durable per-signal status instead of relying mostly on a rolling event feed. The new board includes rows for `punch_left/right`, `hook_left/right`, `uppercut_left/right`, `knee_left/right`, `guard`, `squat`, `lean_left/right`, `sidestep_left/right`, and `leg_lift_left/right`, with a mix of active state, ready/reset state, guard suppression state for attack families, fire count, last-seen/transition age, and last power value where relevant. Quick stats now also expose whether guard is active and how many Boxing attack gates are currently armed. To support truthful readiness display, `src/detectors/pose_detector_substrate.gd` now exposes `gesture_debug.ready` through detector state, and both proving scenes gained panel layout support for the shared harness UI. Validation passed: full unit slice `39/39` green plus headless smoke launches for both proving scenes. Changes were committed and pushed on `main` as `16b7274` (`Improve boxing proving-scene observability`). Remaining known limitation: this was an observability pass, not live threshold/perf retuning, so human movement truthing is still needed; Flow-specific deep diagnostics remain for Task 3.

---

### Task 3: Tune Flow proving-scene coverage and detector behavior

**Bead ID:** `oc-hxd`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Using the established baseline in `aerobeat-input-mediapipe-python`, tune the Flow proving scene so it clearly tests and shows the status of each supported Flow gameplay feature and underlying gesture/input/body-state signal. Focus on `placement` vs `direction` truth, swing/trail continuity windows, mirrored-hand path sanity, and the payload/debug output needed to verify authored semantics without moving the logic out of `src/`. Claim the bead at start, run relevant validation, commit/push repo changes before handoff, and close the bead with an explicit reason only if the Flow tuning slice is actually done.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/`

**Files Created/Deleted/Modified:**
- `.testbed/scenes/flow_proving.tscn`
- `.testbed/scenes/proving_harness.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `src/detectors/pose_detector_substrate.gd`

**Status:** ✅ Complete

**Results:** Added a deeper persistent Flow observability layer. The detector now exposes richer truthful Flow debug data under `gesture_debug.flow.left/right`, including placement/direction candidates, history window information, latest hand position/confidence, center offset, and current swing/trail analysis metadata. The proving harness now shows persistent rows for `swing_left`, `swing_right`, `trail_left`, and `trail_right`, with durable status (`READY` / `RESET` / `ACTIVE` / `IDLE`), counts, last-seen timing, last emitted placement/direction, current candidate placement/direction, and live metrics such as duration, arc length, net distance, directional consistency, lane spread, and average confidence. It also adds mirrored-hand path sanity readouts and a deeper per-hand metrics panel so Derrick can distinguish placement-vs-direction truth and understand near-miss behavior. Validation passed: `git diff --check`, `python3 -m py_compile python_mediapipe/*.py`, full GUT suite `45/45`, and headless smoke boots for both proving scenes. Changes were committed and pushed on `main` as `5ce52d5` (`Improve flow proving-scene observability`). Remaining limitation: this improves observability, not detector threshold tuning; live human movement truthing is still needed.

---

### Task 4: QA the tuned proving behavior

**Bead ID:** `oc-6dm`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Independently verify the tuned Boxing and Flow proving behavior in `aerobeat-input-mediapipe-python`. Use the highest-fidelity available validation path, distinguish automated checks from human-performed movement truthing, and report exact false positives/false negatives or stability concerns. Claim the bead on start and only close it if the QA pass is genuinely complete.

**Folders Created/Deleted/Modified:**
- same owning repo / proving scene paths as implementation

**Files Created/Deleted/Modified:**
- none expected beyond notes/plan updates if verification is clean

**Status:** ❌ Failed

**Results:** Automated/structural QA passed for both scenes, but the bead remains open because end-to-end human-visible runtime truthing was not possible in this pass. Verified cleanly: `git diff --check`, `python3 -m py_compile python_mediapipe/*.py`, headless `.testbed` import, full GUT suite `45/45`, and structural smoke checks for both proving scenes. QA also confirmed that the Boxing scene now has persistent coverage rows for punches/hooks/uppercuts/knees plus guard/squat/lean/sidestep/leg-lift state visibility, and that the Flow scene now has persistent rows for `swing_*` / `trail_*` with emitted-vs-candidate placement/direction plus continuity/metric readouts. Remaining blocker: there was no live Godot plugin/editor session and therefore no human movement truthing, no runtime screenshots, and no direct ergonomics/readability check during real motion. Pre-existing headless warning `ObjectDB instances leaked at exit` remains visible but does not currently appear to block proving-scene observability work. Recommendation from QA: proceed only to a limited audit that certifies implemented observability surfaces and automated evidence, or pause for live human verification before final closure.

---

### Task 5: Audit tuned truth and decide follow-up beads

**Bead ID:** `oc-ibh`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Perform an independent truth audit of the final tuned state in `aerobeat-input-mediapipe-python`. For this pass, allow a limited audit scope if live human movement verification is still outstanding: certify only what the proving scenes, detector logic, and automated validation evidence actually prove, and call out what remains unverified. Verify any claims in docs/README still match reality. If work remains, leave exact retry guidance and create or recommend explicit follow-up beads instead of allowing scope drift. Keep perf concerns isolated to `oc-nua` unless they are proven blockers. Explicitly address the two expected future tracks: substantial human verification/movement truthing and creation of reusable feature-specific video fixtures for automated testing.

**Folders Created/Deleted/Modified:**
- same owning repo / proving scene paths as implementation

**Files Created/Deleted/Modified:**
- plan updates and audit notes only unless a truthful docs fix is required

**Status:** ✅ Complete

**Results:** Limited audit passed. The auditor independently re-ran structural validation (`git diff --check`, Python compile, headless `.testbed` import, targeted substrate tests `10/10`, full GUT suite `45/45`, and headless proving-scene instantiation/probe checks) and confirmed the new observability surfaces are genuinely implemented. Certified for current scope: richer detector debug state now feeds the proving harness truthfully; Boxing has persistent rows for attack/state families with readiness/count/timing visibility; Flow has persistent `swing_*` / `trail_*` rows with candidate-vs-emitted placement/direction plus live decision metrics; README remains materially aligned and does not overclaim human-tested or 3D-validated behavior. Not certified: anything that requires live human motion, including real-world threshold correctness, live UI ergonomics during movement, false-positive/false-negative behavior, and robustness across repeated reps/camera occlusion. Audit conclusion: implementation beads are done for observability/automation scope only, and follow-up work should explicitly cover (1) human verification/tuning and (2) reusable feature-specific video fixtures for more automated proving.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Completed the proving-scene observability phase for `aerobeat-input-mediapipe-python`. Boxing and Flow proving scenes now expose persistent status boards instead of depending mainly on transient event logs, and the detector substrate now exports richer truthful debug state so the harness can surface readiness, emitted-vs-candidate state, and per-feature diagnostics. This gives Derrick much better tooling for the next real testing phase.

**Reference Check:** `REF-03` through `REF-05` are aligned for observability scope. The proving scenes and shared harness now truthfully expose the implemented Boxing and Flow detector/debug surfaces. Deliberate gap: this plan does **not** certify live human movement truth, threshold correctness under real reps, or camera-occlusion robustness; those belong to the next follow-up workload.

**Commits:**
- `16b7274` - Improve boxing proving-scene observability
- `5ce52d5` - Improve flow proving-scene observability

**Lessons Learned:** Independent QA/audit helped keep us honest about the difference between structural/automated proof and real human-motion proof. The proving scenes are now useful dashboards, but they still need a dedicated human verification phase and a separate prerecorded-fixture strategy rather than pretending either one alone is enough.

---

*Completed on 2026-05-05*
