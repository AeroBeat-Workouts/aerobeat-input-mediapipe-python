# AeroBeat MediaPipe Python Sidecar Cleanup Follow-ups

**Date:** 2026-04-23  
**Status:** In Progress  
**Agent:** Pico 🐱‍🏍

---

## Goal

Land the two post-migration cleanup beads for Linux sidecar shutdown noise without changing the already-validated runtime contract.

---

## Overview

The main unified desktop runtime migration is complete. QA and audit both confirmed two remaining cleanup issues that do not block the migration itself: a false-positive Linux teardown warning and duplicate shutdown / `AUTO_STOPPED` noisiness. This follow-up plan isolates those fixes so the repo can preserve the honest Linux-validated/runtime-scaffolded story while tightening shutdown behavior.

Work will proceed bead-by-bead through the usual coder → QA → auditor loop. The expectation is narrow cleanup only: no hidden scope expansion into broader runtime or cross-platform changes.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Completed unified runtime implementation plan | `.plans/mediapipe-python/2026-04-23-unified-unfrozen-platform-runtimes-implementation.md` |
| `REF-02` | Shared runtime validation helper | `src/runtime/desktop_sidecar_runtime.gd` |
| `REF-03` | Platform-aware sidecar launcher | `src/process/desktop_sidecar_launcher.gd` |
| `REF-04` | Direct sidecar process path | `src/process/mediapipe_process.gd` |
| `REF-05` | Autostart path | `src/autostart_manager.gd` |
| `REF-06` | Current repo contract / docs | `README.md` |

---

## Tasks

### Task 1: Fix false-positive Linux sidecar teardown warning

**Bead ID:** `oc-b24`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Claim the bead on start. Tighten Linux teardown confirmation logic so `desktop_sidecar_launcher.gd` only warns when shutdown actually failed. Preserve current validated Linux behavior and do not expand into unrelated runtime changes. If shutdown confirmation must use better PID/PGID/process-state checks, implement the minimal truthful fix. Update this plan with actual results, run relevant repo-local validation, commit/push, and close the bead if coder scope is complete.

**Folders Created/Deleted/Modified:**
- `src/process/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `src/process/desktop_sidecar_launcher.gd`
- related smoke/support files if needed
- this plan file

**Status:** ✅ Complete

**Results:** Completed with a narrow Linux-only launcher fix in `src/process/desktop_sidecar_launcher.gd`. The false-positive teardown warning was caused by Linux process-group liveness confirmation treating lingering zombie/stale group state as evidence that shutdown failed. The launcher now confirms Linux group liveness with `ps -o stat= -g <pgid>` and only reports the group as alive when at least one non-zombie member remains. Validated on this Linux host with the existing repo-local sidecar smoke paths: `python3 -m py_compile python_mediapipe/*.py`; `godot --headless --path .testbed -s /tmp/mediapipe_process_smoke.gd`; and `godot --headless --path .testbed -s /tmp/autostart_manager_smoke.gd`. In the validated `MediaPipeProcess` smoke path, the teardown warning no longer appears and post-run checks showed no lingering `python_mediapipe/main.py` process. Commit: `64ced48`. 

---

### Task 2: Deduplicate sidecar shutdown / `AUTO_STOPPED` noise

**Bead ID:** `oc-q4j`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Claim the bead on start. Clean up duplicate shutdown / `AUTO_STOPPED` noisiness in the MediaPipe sidecar paths while preserving validated Linux behavior. Keep the change narrow and truthful. Update this plan with actual results, run relevant repo-local validation, commit/push, and close the bead if coder scope is complete.

**Folders Created/Deleted/Modified:**
- `src/process/`
- `src/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `src/process/mediapipe_process.gd`
- `src/autostart_manager.gd`
- any small related helper updates if needed
- this plan file

**Status:** ✅ Complete

**Results:** Initial cleanup landed in `7f6b7ff`, but QA correctly caught one remaining false-positive Linux teardown warning resurfacing in both validated shutdown paths even though no lingering `python_mediapipe/main.py` process remained. The retry stayed narrow: `src/process/desktop_sidecar_launcher.gd` now gives the Linux post-`SIGKILL` process-group confirmation loop a slightly longer settle window before warning, preserving the already-validated idempotency/dedup behavior from `src/autostart_manager.gd` and `src/process/mediapipe_process.gd` without reopening broader lifecycle logic. Revalidated on this Linux host with focused repo-local shutdown checks: `python3 -m py_compile python_mediapipe/*.py`; `godot --headless --path .testbed -s /tmp/qa_mediapipe_process_smoke.gd`; `godot --headless --path .testbed -s /tmp/qa_autostart_manager_smoke.gd`; and `ps -eo pid,args | grep '[p]ython_mediapipe/main.py' || true` after each smoke run. In the retry validation, the direct `MediaPipeProcess` path emitted a single `PROCESS_STOPPED`, stayed free of extra `EXIT_TREE` / `PREDELETE` chatter, no longer logged `Linux process-group teardown could not confirm termination after SIGKILL.`, and left no lingering `python_mediapipe/main.py` process. The `AutoStartManager` path emitted `AUTO_STOPPED` once, stayed free of extra shutdown chatter, no longer logged the Linux teardown warning, and likewise left no lingering `python_mediapipe/main.py` process. Retry commit: `20f5678`. Initial idempotency commit: `7f6b7ff`. 

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Landed both scoped post-migration sidecar cleanup fixes: (1) truthful Linux teardown confirmation for process-group shutdown, plus a retry that keeps the post-`SIGKILL` confirmation window honest to real Linux settle time, and (2) idempotent stop-path cleanup that removes duplicate shutdown signaling/logging in the validated MediaPipe sidecar paths.

**Reference Check:** `REF-01`, `REF-03`, `REF-04`, and `REF-05` satisfied. The launcher/runtime structure from the completed migration plan remains intact; Linux behavior was tightened without broadening into unvalidated cross-platform parity claims.

**Commits:**
- `64ced48` - Fix Linux sidecar teardown confirmation
- `7f6b7ff` - Deduplicate sidecar shutdown teardown noise
- `20f5678` - Allow extra Linux sidecar teardown settle time

**Lessons Learned:** The remaining shutdown noise was mostly lifecycle re-entry plus Linux kill-confirmation timing, not a deeper runtime failure. Small active-state/idempotency guards on explicit stop and notification cleanup paths were necessary, and the final warning cleanup needed the launcher to allow the killed process group a little more time to disappear before claiming teardown failed.

---

*Started on 2026-04-23*
