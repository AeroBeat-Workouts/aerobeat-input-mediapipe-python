# AeroBeat MediaPipe Proving Scene Runtime Regression Fix

**Date:** 2026-05-05  
**Status:** Partial  
**Agent:** Pico 🐱‍🏍

---

## Goal

Fix the proving-scene runtime regression blocking `boxing_proving.tscn` / `flow_proving.tscn` from opening after Cookie-side runtime preparation, verify the scenes load again, and keep the repo committed/pushed after each feedback-driven fix.

---

## Overview

Derrick reported a real runtime regression after running `prepare_runtime.py` and opening the `.testbed` Godot project on Cookie. The current visible failure is a missing dependency for `res://addons/aerobeat-input-mediapipe-python/src/autostart_manager.gd`, referenced by `res://scenes/boxing_proving.tscn`. That strongly suggests a pathing/install-shape mismatch between the repo-local proving scenes and the installed addon/runtime layout rather than a detector-behavior issue.

This plan stays tightly scoped to restoring scene loadability first. We need to diagnose whether the correct fix belongs in the proving scenes, the addon install shape, `prepare_runtime.py`, or supporting runtime docs/scripts. Once the load regression is fixed, we should verify both proving scenes load again and only then continue the broader human verification/testing workflow. Because Derrick is actively testing on Cookie, every implementation retry should be committed and pushed promptly so Cookie can sync and re-test cleanly.

The user explicitly asked that testing may use the desktop-control skill. That means we should prefer a truthful local GUI validation path when available, but we should not fake certainty if the environment only supports structural/headless proof. If desktop control helps confirm Godot/editor/runtime behavior, use it; otherwise document the limit clearly.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Reported runtime error screenshot | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/05/image-651b8948.png` |
| `REF-02` | Active human verification / fixtures plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-05-mediapipe-human-verification-and-video-fixtures.md` |
| `REF-03` | Boxing proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/boxing_proving.tscn` |
| `REF-04` | Flow proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/flow_proving.tscn` |
| `REF-05` | Runtime/addon path likely involved | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/autostart_manager.gd` |
| `REF-06` | Desktop-control skill guidance | `/home/derrick/.openclaw/workspace/skills/desktop-control/SKILL.md` |

---

## Tasks

### Task 1: Diagnose the proving-scene dependency regression

**Bead ID:** `oc-xf3`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Diagnose why the proving scenes now reference a missing `res://addons/aerobeat-input-mediapipe-python/src/autostart_manager.gd` dependency after runtime preparation. Inspect scene references, addon install shape, runtime scripts, and any path assumptions introduced by recent work. Separate repo-structure truth from Cookie/runtime-shape truth. If helpful, use desktop-control-supported local GUI validation honestly. Claim the bead at start and close it only when the root cause and recommended fix path are clear.

**Folders Created/Deleted/Modified:**
- repo-local plan / docs / .testbed / runtime-related paths as needed for diagnosis notes

**Files Created/Deleted/Modified:**
- notes/plan updates only unless an obvious small truth fix is required

**Status:** ✅ Complete

**Results:** Diagnosis complete. The missing `res://addons/aerobeat-input-mediapipe-python/src/autostart_manager.gd` error was traced to absent GodotEnv-managed mounts under `.testbed/addons/`, especially `.testbed/addons/aerobeat-input-mediapipe-python`, not to a bad scene path or missing source file. Both `boxing_proving.tscn` and `flow_proving.tscn` intentionally depend on the mounted addon path, and `python_mediapipe/prepare_runtime.py` only prepares Python runtime assets, not addon mounts. Positive/negative controls confirmed that scenes load when the mount exists and fail with the same missing-dependency family when `addons/` is absent. Immediate Cookie unblock: `cd .testbed && godotenv addons install`.

---

### Task 2: Implement the runtime regression fix

**Bead ID:** `oc-7pc`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Implement the minimal truthful fix for the proving-scene runtime regression so `boxing_proving.tscn` and `flow_proving.tscn` can load after the normal runtime/addon preparation flow. Update scenes, runtime prep, or addon pathing as required, but do not over-broaden scope. Validate, commit, and push before handoff.

**Folders Created/Deleted/Modified:**
- runtime / scene / docs paths depending on diagnosis

**Files Created/Deleted/Modified:**
- exact runtime-fix files discovered during Task 1

**Status:** ✅ Complete

**Results:** Implemented the minimal truthful workflow fix without changing the intentional scene references. `README.md` now explicitly distinguishes Python runtime prep from GodotEnv addon restore and calls out the proving-scene dependency on `res://addons/aerobeat-input-mediapipe-python/...`. `python_mediapipe/prepare_runtime.py` now emits a developer-facing warning when `.testbed/` exists but the self addon mount is missing, instructing the user to run `cd .testbed && godotenv addons install`. `docs/proving-scene-human-verification-checklist.md` now lists launch prerequisites in the correct order: restore addon mounts first, prepare Python runtime second, then open `.testbed`. Validation included direct script runs in both good and simulated-missing-mount states plus doc spot-checks. Commit: `ede587d` (`Clarify testbed addon restore for proving scenes`).

---

### Task 3: QA the load fix

**Bead ID:** `oc-grl`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-06`  
**Prompt:** Independently verify that the load regression is actually fixed. Prefer the highest-fidelity available validation path, including desktop-control-assisted GUI confirmation if feasible, and otherwise use headless/runtime proof plus explicit caveats. Confirm both proving scenes load and note any remaining runtime warnings/errors.

**Folders Created/Deleted/Modified:**
- same owning repo paths as implementation

**Files Created/Deleted/Modified:**
- none expected beyond notes/plan updates if verification is clean

**Status:** ⏳ Pending

**Results:** Pending

---

### Task 4: Audit and close the regression slice

**Bead ID:** `oc-3i9`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check the regression fix, the validation evidence, and the final repo claims. Certify only what was actually proven. If Cookie still needs a follow-up sync/retest note, say so explicitly. Close the bead only if the regression slice is genuinely done.

**Folders Created/Deleted/Modified:**
- same owning repo paths as implementation

**Files Created/Deleted/Modified:**
- plan updates/audit notes only unless a truth fix is required

**Status:** ⏳ Pending

**Results:** Pending

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** We fixed the workflow regression that made the proving scenes look broken after Cookie-side runtime prep. The core issue was missing GodotEnv addon mounts under `.testbed/addons/`, not broken scene references. The repo now explains that `prepare_runtime.py` prepares only Python runtime assets, while `.testbed` addon mounts must be restored separately with `godotenv addons install`, and the runtime helper now warns when that prerequisite is missing.

**Reference Check:** `REF-03` through `REF-05` remain truthful: the proving scenes intentionally reference mounted addon scripts, the source `autostart_manager.gd` still exists, and the fix path is workflow/documentation/preflight rather than scene surgery. Deliberate caveat: this plan did not independently finish the Cookie-side QA + audit retest loop before session end.

**Commits:**
- `ede587d` - Clarify testbed addon restore for proving scenes

**Lessons Learned:** In this repo, Python runtime prep and GodotEnv addon restore are separate setup surfaces. The failure looked like a scene/code regression, but the real issue was an install-shape prerequisite that had become easy to forget in a fresh test loop.

---

*Completed on 2026-05-05 (partial; QA/audit follow-through still pending)*
