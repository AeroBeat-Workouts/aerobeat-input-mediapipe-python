# AeroBeat MediaPipe Python

**Date:** 2026-04-23  
**Status:** In Progress  
**Agent:** Pico 🐱‍🏍

---

## Goal

Move the development/runtime-owned Python environment out of `.testbed/venv` into a sidecar-owned location under `python_mediapipe/`, then lock what would be required for an **unfrozen** Python sidecar to run across 64-bit Linux, macOS, and Windows.

---

## Overview

We already made the architectural decision that the Python runtime should be a **sidecar-owned asset** rather than a hidden testbed-owned detail. The repo contract and code were updated earlier to point at `python_mediapipe/assets/venv/`, but the working tree still contained a large stale `.testbed/venv` (~533 MB). In this coder pass, the canonical path was kept at `python_mediapipe/assets/venv/` per the current task constraints, and the goal was narrowed to removing the stale local `.testbed/venv` so there is one truthful source of runtime ownership on disk and in active repo guidance.

Separately, we need to answer the distribution/portability question for the **unfrozen** sidecar. A venv copied from one machine is not the cross-platform solution; an unfrozen sidecar that works on Linux/macOS/Windows means the repo must own Python code, dependency manifests, model assets, bootstrap/install logic, runtime path resolution, and platform-specific launch/process-management behavior — while each target machine builds or hydrates its own local environment for that platform. The output should be a concrete requirement list and recommendation, not hand-wavy “just ship the venv.”

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Prior sidecar distribution decision draft | `.plans/mediapipe-python/2026-04-21-desktop-sidecar-distribution-decision.md` |
| `REF-02` | Prior repair plan that explicitly rejected committing/copying a machine-specific venv blob as the portable solution | `.plans/mediapipe-python/2026-04-21-sidecar-audit-and-repair.md` |
| `REF-03` | Current repo contract / runtime docs | `README.md` |
| `REF-04` | Current Godot auto-start runtime path resolution | `src/autostart_manager.gd` |
| `REF-05` | Current Python sidecar source tree | `python_mediapipe/` |
| `REF-06` | Current stale legacy env location still present in working tree | `.testbed/venv/` |
| `REF-07` | Current sidecar-owned env location already present in working tree | `python_mediapipe/assets/venv/` |

---

## Tasks

### Task 1: Confirm and implement the canonical sidecar runtime path

**Bead ID:** `oc-azf`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Claim the bead on start. Audit the current runtime-path reality in `aerobeat-input-mediapipe-python`: verify whether `.testbed/venv` is stale, whether `python_mediapipe/assets/venv` is the actively used path, and whether any active tracked docs/code still incorrectly point at `.testbed/venv`. Keep `python_mediapipe/assets/venv` as the canonical local sidecar env path, remove the stale local `.testbed/venv` if safe, update any active tracked references only if they are still wrong, and do not commit a machine-specific venv to git.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `python_mediapipe/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-23-sidecar-runtime-path-and-cross-platform-unfrozen-plan.md`

**Status:** ✅ Complete

**Results:** Audited tracked references with `git grep`. Active code/docs already use `python_mediapipe/assets/venv` truthfully (`README.md`, `src/autostart_manager.gd`, `src/process/mediapipe_process.gd`, and `.testbed/scenes/test_scene.gd`). Remaining `.testbed/venv` hits were limited to `.gitignore` and historical plan/archive files, so no active code/doc path corrections were needed. Verified the canonical sidecar env exists at `python_mediapipe/assets/venv/` and that `python_mediapipe/assets/venv/bin/python` resolves successfully in a lightweight runtime check. Removed the stale local `.testbed/venv` directory from disk without changing the canonical path. This task required local-state cleanup plus this plan update; it did **not** require tracked code/runtime-path edits outside the plan.

---

### Task 2: Validate local dev/runtime behavior after the path change

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Claim the bead on start. Validate that the repo still works truthfully after the runtime-path change: direct Python sidecar launch, dependency detection/auto-install behavior, model resolution, and Godot workbench startup far enough to prove the new path is authoritative. Explicitly state whether the env was moved, recreated, or symlinked locally, and note any platform-specific assumptions that are still Linux-only.

**Folders Created/Deleted/Modified:**
- `python_mediapipe/`
- `.testbed/`

**Files Created/Deleted/Modified:**
- validation artifacts only if needed

**Status:** ⏳ Pending

**Results:** Reserved.

---

### Task 3: Lock the unfrozen cross-platform sidecar requirements

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Claim the bead on start. Produce an evidence-based architecture note for what it takes to support an unfrozen Python sidecar across 64-bit Linux, macOS, and Windows. Cover: Python version policy, per-platform wheel availability for `mediapipe`/OpenCV/Numpy and any transitive native deps, bootstrap strategy (venv creation + pip install on target machine), platform-specific launch path resolution, subprocess behavior differences, camera backend differences, path separator/shell differences, code locations that are currently Linux-specific, packaging/export handoff expectations, and the recommended division between dev-mode runtime and shipped-build runtime. Conclude whether unfrozen cross-platform support is a good product path or just a dev/debug path.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- this plan file
- optional research note if needed

**Status:** ⏳ Pending

**Results:** Reserved.

---

### Task 4: Independent audit of the final recommendation

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Claim the bead on start. Independently truth-check both the runtime-path change and the unfrozen cross-platform recommendation. Verify that the repo’s docs match the real runtime path, that we did not quietly rely on a copied machine-specific venv as a portability answer, and that the final cross-platform guidance honestly separates what is proven today from what would require new engineering. Close the bead only if the recommendation is evidence-based and non-hand-wavy.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`
- `python_mediapipe/`
- `.testbed/`

**Files Created/Deleted/Modified:**
- plan updates only if needed

**Status:** ⏳ Pending

**Results:** Reserved.

---

## Final Results

**Status:** ⚠️ Draft / Awaiting execution approval

**What We Built:** A plan to (1) reconcile the actual Python sidecar env location with the desired sidecar-owned path under `python_mediapipe/`, and (2) produce an honest cross-platform requirement/risk assessment for an unfrozen Python sidecar on Linux/macOS/Windows.

**Reference Check:**
- `REF-01` keeps this session tied to the unresolved distribution-decision thread.
- `REF-02` preserves the earlier important constraint: a machine-specific venv blob is not the portability strategy.
- `REF-03` through `REF-07` anchor this plan to the current real repo/runtime state, including the stale `.testbed/venv` and active sidecar-owned env path.

**Commits:**
- None yet

**Lessons Learned:**
- The repo contract already moved away from `.testbed/venv`, but the working tree still has enough leftover runtime state to create confusion.
- “Unfrozen and cross-platform” is mostly a bootstrap/install/process-management problem, not a “copy one venv around” problem.

---

*Drafted on 2026-04-23*
