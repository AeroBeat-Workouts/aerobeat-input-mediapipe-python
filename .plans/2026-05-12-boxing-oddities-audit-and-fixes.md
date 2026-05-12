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

**Results:** Screenshot-informed audit completed against `REF-01` through `REF-07`.

- **What looks wrong in the screenshot (`REF-01`):** the proving surface is semantically wrong, not just visually noisy. The clip is a left-punch fixture, but the UI shows `last: Right Knee Strike`, the event feed is dominated by knee-strike / leg-lift events, and both `Guard` and `Squat` are active at once while Derrick appears to be in a normal guard stance rather than a squat. That makes the Boxing state readout untrustworthy even before deeper runtime checks.
- **Issue 1 — raycast-like trails is primarily a shared proving/trail continuity problem (`REF-03`, `REF-05`):** `hand_trail_drawer.gd` now respects break markers, so the drawer itself is no longer the strongest suspect. The higher-confidence source surface is `proving_harness.gd` trail sampling and reseed behavior: `_resolve_trail_hand_point()` can synthesize a hand point from index/pinky/thumb fallbacks, `_synthesize_trail_hand_point()` clamps near-out-of-bounds candidates back into 0..1 space, and `_append_trail_point()` immediately seeds a new segment after a break. That combination can still produce long straight hand-to-fallback segments that read like raycasts even without the older stale-bridge bug.
- **Issue 2 — landmarks/skeleton outside the visible feed is a shared overlay projection bug (`REF-04`, `REF-07`):** `landmark_drawer.gd` correctly computes displayed image bounds, but it never rejects or clips normalized points outside 0..1 before drawing circles/lines. `_landmark_to_screen()` will project any out-of-range landmark into UI space around the video panel. `camera_view.gd` is not the main problem here; it already computes displayed image size/offset similarly. The missing guard lives in the drawer.
- **Issue 3 — missed left punches + unrelated gesture spam is Boxing detector/routing, not overlay:**
  - Punch-family detection is explicitly suppressed whenever `guard` is active. In `PoseDetectorSubstrate._detect_intent_events()`, `_process_straight_punch()`, `_process_hook()`, and `_process_uppercut()` only run inside `if not _get_state("guard"):`. For a guard-start / guard-end left-punch fixture, that means punch detection is gated off during the exact posture the clip naturally uses.
  - The screenshot’s simultaneous `Guard` + `Squat` and repeated knee/leg-lift spam points at over-eager lower-body classification, not merely UI mislabeling.
  - Lower-body detectors (`_process_squat`, `_process_knee`, `_process_leg_lift`) do not gate on lower-body landmark confidence, while `_build_metrics()` still computes knee/ankle-derived measurements from whatever smoothed landmarks exist. Weak or stale leg landmarks can therefore still drive Boxing events.
  - `_update_baseline()` continuously re-averages baseline from all tracking frames instead of a neutral stance window, so a boxing-stance clip can drift the baseline and help keep `height_state` / squat logic wrong.
  - The left-punch fixture sidecar forbids `hook_left`, `uppercut_left`, `knee_left`, and `knee_right`, so the current behavior is source-level wrong against the intended proving contract.
- **Shared vs Boxing-specific separation:**
  - **Shared proving surfaces:** `landmark_drawer.gd` out-of-bounds rendering; `proving_harness.gd` trail point synthesis / reseed continuity; `hand_trail_drawer.gd` is secondary now.
  - **Boxing-specific detector surfaces:** guard gating of punch family, permissive squat/knee/leg-lift triggers on low-confidence or stale lower-body landmarks, and drifting baseline logic inside `PoseDetectorSubstrate`.
- **Smallest truthful fix order:**
  1. Fix `landmark_drawer.gd` bounds rejection/clipping first so overlays stop lying outside the displayed feed.
  2. Tighten shared trail point acceptance / reseed logic in `proving_harness.gd` so fallback hand points do not read as raycasts.
  3. In Boxing detector logic, stop guard from blanket-suppressing punch detection on this punch fixture path, then add confidence gates for lower-body detectors before retuning thresholds.
  4. Only after that, revisit baseline strategy / threshold tuning if squat+knee spam still remains.
- **Follow-up tasks:** no new task required yet; existing Tasks 2–4 already cover the truthful next slices.

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

**Status:** ⏳ Pending

**Results:** Pending.

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
- `.plans/2026-05-12-boxing-oddities-audit-and-fixes.md`
- `.testbed/scripts/proving_harness.gd`

**Status:** ✅ Complete

**Results:** Implemented a tight shared trail-truth fix in `REF-03` only.

- Removed the near-bounds fallback acceptance path for trail synthesis; fallback hand candidates now must already be truthfully inside normalized 0..1 bounds before they can influence a trail point.
- Stopped using the partially invalid wrist itself as a synthesis candidate once the direct wrist sample fails the usable test.
- Removed edge clamping from synthesized fallback points, so the harness no longer invents edge-snapped hand positions that can draw straight raycast-like segments toward the frame border.
- Required at least two in-bounds fallback finger landmarks and rejected synthesis when those fallback candidates are too far apart (`MAX_TRAIL_FALLBACK_SPREAD = 0.18`), forcing a clean trail break instead of connecting to a dubious synthetic hand location.
- Net behavior change: when wrist tracking degrades or falls out of bounds, the trail now breaks and waits for a truthful clustered fallback / wrist recovery instead of drawing long straight continuity lines from stale or clamped fallback positions.
- Safe validation run: `godot --headless --path .testbed --quit` from the repo root. Result: project loaded, the edited harness parsed successfully, and shutdown reached normal exit with the pre-existing headless leak/resource warnings only.

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

**Status:** ⏳ Pending

**Results:** Pending.

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

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⏳ Draft

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending

**Lessons Learned:** Pending.

---

*Created on 2026-05-12*