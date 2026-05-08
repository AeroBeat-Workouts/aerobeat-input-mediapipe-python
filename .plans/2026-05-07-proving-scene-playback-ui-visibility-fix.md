# AeroBeat MediaPipe Proving Scene Playback UI Visibility Fix

**Date:** 2026-05-07  
**Status:** In Progress  
**Agent:** Pico 🐱‍🏍

---

## Goal

Fix the proving-scene playback UI so the Boxing and Flow state panels render visibly and usefully during scene playback in the Godot editor, then sync the confirmed fix to Cookie for renewed human testing.

---

## Overview

Derrick confirmed an important truth gap in the current human-verification pass: the proving scenes now open and run, but the right-side observability UI is not usable during playback. The panel is visible in the editor layout, yet during play most of the status/message content is missing or clipped from the final rendered view. That means the earlier observability work is not actually available to the human tester in the environment that matters.

This slice stays tightly scoped to `aerobeat-input-mediapipe-python`. First we need to reproduce the issue locally, inspect the Control tree/layout behavior during editor playback, and land the smallest truthful fix that restores the intended visible panel behavior for both `boxing_proving.tscn` and `flow_proving.tscn`. After implementation, QA must verify the fix in real Godot editor playback with screenshots or other direct evidence, and an independent audit must confirm we are not merely making the panel exist in the editor while still broken in play mode.

Only after local coder → QA → auditor confirmation will we touch Cookie. Once the local repo is pushed, we will update Cookie’s checkout over SSH, refresh any required local setup, and tell Derrick when the machine is ready for another test pass.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current human verification plan with pending live-testing bead | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-05-mediapipe-human-verification-and-video-fixtures.md` |
| `REF-02` | Boxing proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/boxing_proving.tscn` |
| `REF-03` | Flow proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/flow_proving.tscn` |
| `REF-04` | Shared proving harness script | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/proving_harness.gd` |
| `REF-05` | Derrick’s live report that playback UI content is missing/cut off | current session |

---

## Tasks

### Task 1: Reproduce and fix proving-scene playback UI visibility

**Bead ID:** `oc-3bt`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Reproduce the proving-scene playback UI visibility/layout bug locally in `aerobeat-input-mediapipe-python`, inspect the relevant Control tree/layout logic, and implement the smallest truthful fix so the Boxing and Flow observability panels render visibly during play mode in the Godot editor. Use direct Godot/editor evidence where possible, keep edits in the owning repo, run relevant validation, commit/push before handoff, and close the bead only if the local implementation slice is genuinely done.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/proving_harness.gd`
- `.testbed/scenes/boxing_proving.tscn`
- `.testbed/scenes/flow_proving.tscn`

**Status:** ✅ Complete

**Results:** Reproduced the bug via scene/script inspection and runtime layout probing. Root cause was truthful layout overflow: the right-side observability stack exceeded normal play-window height in both proving scenes and had no outer scroll container, so playback clipped the lower content. Landed the smallest fix by wrapping the existing right column in `RightPanelScroll` (`ScrollContainer`) in both scenes and updating the harness node bindings accordingly. Structural/runtime validation passed and the implementation was committed and pushed as `20c7ab3` (`Fix proving harness right panel clipping`).

---

### Task 2: QA the playback UI fix in actual editor play mode

**Bead ID:** `oc-8z2`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Independently verify the proving-scene playback UI fix in actual Godot editor play mode. Confirm the right-side panel content is visible and usable during playback for both Boxing and Flow scenes, capture direct evidence, and distinguish editor-static visibility from in-play visibility. Close the bead only if the QA proof is genuinely sufficient.

**Folders Created/Deleted/Modified:**
- same owning repo / `.testbed` scene paths

**Files Created/Deleted/Modified:**
- temporary QA probe script/evidence only

**Status:** ✅ Complete

**Results:** QA passed and `oc-8z2` was closed. No Godot plugin/editor session was available, so QA used the highest-fidelity truthful fallback: actual headless Godot runtime execution with a temporary probe that instantiated each proving scene, let layout run, inspected the live `ScrollContainer`, and programmatically scrolled it. At 1280x720-equivalent root size, Boxing initially showed `EventsPanel` partially visible (`242/260`) and then fully visible after scroll (`260/260`); Flow initially showed `71/180` visible and then fully visible after scroll (`180/180`). This certifies runtime-layout reachability for both scenes, while explicitly not claiming human-visible editor-window proof.

---

### Task 3: Audit the final UI-playback truth

**Bead ID:** `oc-d2g`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Perform an independent audit of the local playback UI fix. Verify that the intended panel content is truly available during scene playback, that both scenes are covered, and that any remaining limitations are stated honestly. Close the bead only if the fix really resolves Derrick’s reported testing blocker.

**Folders Created/Deleted/Modified:**
- same owning repo / `.testbed` scene paths

**Files Created/Deleted/Modified:**
- plan updates and audit notes only unless truth fixes are required

**Status:** ✅ Complete

**Results:** Audit passed and `oc-d2g` was closed. The auditor independently inspected commit `20c7ab3`, confirmed the functional change is the right-side swap to `RightPanelScroll` in both proving scenes plus harness path updates, and re-ran a disposable headless Godot runtime probe. Certified now: the specific runtime clipping blocker is resolved because the right-side observability UI is reachable via scrolling for both scenes at play-window-sized layout. Not certified now: direct human-visible editor-window ergonomics or screenshot/video proof. Audit conclusion: the fix is truthful and good enough to proceed to Cookie retest, with Derrick’s next run serving as the first real human-visible confirmation.

---

### Task 4: Update Cookie and re-stage the human test pass

**Bead ID:** `oc-2ot`  
**SubAgent:** `primary` (for `qa` / `research` workflow roles)  
**Role:** `qa` then `research`  
**References:** `REF-01`, `REF-05`  
**Prompt:** After local coder, QA, and audit confirmation, update Cookie’s checkout to the approved commit, restore any required local testbed/runtime setup there, and confirm whether Derrick can reopen the project for another human verification pass. Record exact remote commands, commit under test, and any remaining machine-specific caveats.

**Folders Created/Deleted/Modified:**
- Cookie repo checkout for `aerobeat-input-mediapipe-python`

**Files Created/Deleted/Modified:**
- none expected unless a truthful machine-local handoff artifact is useful

**Status:** ⏳ Pending

**Results:** Pending

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending

**Reference Check:** Pending

**Commits:**
- Pending

**Lessons Learned:** Pending

---

*Completed on Pending*
