# AeroBeat MediaPipe Python Architecture Alignment Follow-up

**Date:** 2026-04-20  
**Status:** Draft  
**Agent:** Pico 🐱‍🏍

---

## Goal

Align `aerobeat-input-mediapipe-python` with the intended repo architecture by moving root tests into the testbed, moving the addon entrypoint implementation out of repo root code placement, and renaming the testbed scene folder from `test/` to `scenes/`.

---

## Overview

The just-finished migration pass got the repo into a truthful, working state, but Derrick noted three structure mismatches that still violate the intended package layout. Those notes are architectural, not cosmetic: repo root should stay free of raw code/scripts, testbed-owned content should live under `.testbed/`, and scene folders inside the testbed should use `scenes/` rather than `test/`.

This follow-up should be treated as a narrow repo-structure alignment pass, not a new behavior rewrite. The work needs to preserve the newly verified addon-loading behavior, keep docs and paths coherent after any moves, and re-verify that both the standalone testbed and addon-mounted consumer path still work after the refactor.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Derrick’s architecture notes for this follow-up | current session notes (2026-04-20 08:45 EDT) |
| `REF-02` | Final migration pass plan and current known-good state | `.plans/2026-04-20-mediapipe-python-final-migration-pass.md` |
| `REF-03` | Current repo layout | `.` |
| `REF-04` | Current root addon entrypoint and plugin wiring | `input_provider.gd`, `plugin.cfg` |
| `REF-05` | Current testbed scene layout and recovery guidance | `.testbed/test/`, `.testbed/project.godot` |

---

## Tasks

### Task 1: Audit exact path impacts for the requested architecture changes

**Bead ID:** `oc-c9v`  
**SubAgent:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Audit the exact path and wiring impacts of Derrick’s requested architecture changes for `aerobeat-input-mediapipe-python`: move root `/tests` content under `/.testbed/`, move the root addon entrypoint implementation under `/src/` so repo root no longer contains raw code/scripts, and rename `/.testbed/test/` to `/.testbed/scenes/`. Identify every file/path/reference that must change to preserve addon loading, testbed startup, docs, and validation. Do not edit yet; return a concise action map.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-20-architecture-alignment-followup.md`

**Status:** ✅ Complete

**Results:** The audit mapped the requested structure changes precisely. For the addon entrypoint move, `input_provider.gd` should move from repo root to `src/input_provider.gd`, `plugin.cfg` must update its `script=` path accordingly, and README layout/docs must stop describing a root-level addon entrypoint. Plugin-based consumers should continue working if they honor `plugin.cfg`, but any consuming-project code or validation that directly loads `res://addons/aerobeat-input-mediapipe-python/input_provider.gd` will need to update to the new `src/` path. For the `.testbed/test/` → `.testbed/scenes/` rename, the critical startup wires that must move together are: `.testbed/project.godot` main scene path, `.testbed/scenes/test_scene.tscn` ext_resource references, and the runtime load inside the scene script that currently targets `res://test/mediapipe_provider_test.gd`. For moving root `tests/` under `.testbed/`, the clean architecture split is `.testbed/scenes/` for manual scene/testbed content and `.testbed/tests/` for the automated/root test files. The audit also found that similarly named files under root `tests/` and `.testbed/test/` are not interchangeable duplicates, so implementation must not merge them blindly. Docs/path coherence updates are required in `README.md`, and likely in `.plans/INTEGRATION-ARCHITECTURE.md` if that document is still meant to reflect current architecture. Validation-path impact also includes `.github/workflows/gut_ci.yml`, which currently points at `res://test/unit` and likely needs both test-directory and project-path updates once tests move under `.testbed/`. Biggest external risk identified: consumers or validations that explicitly load the old root addon script path instead of relying on `plugin.cfg`.

---

### Task 2: Implement the architecture alignment changes

**Bead ID:** `oc-148`  
**SubAgent:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Implement Derrick’s requested architecture alignment for `aerobeat-input-mediapipe-python`: move root tests into the testbed, move the addon entrypoint implementation out of repo root raw-code placement into `/src/`, and rename `/.testbed/test/` to `/.testbed/scenes/`. Update all dependent paths/docs/config so the repo stays truthful and working. Preserve the verified consuming-project addon load behavior and the testbed startup behavior. Run relevant repo-local validation, then commit/push by default.

**Folders Created/Deleted/Modified:**
- `src/`
- `.testbed/scenes/`
- `.testbed/tests/`
- `.github/workflows/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `src/input_provider.gd`
- `plugin.cfg`
- `README.md`
- `.testbed/project.godot`
- `.testbed/scenes/test_scene.tscn`
- `.testbed/scenes/test_scene.gd`
- `.github/workflows/gut_ci.yml`
- `.plans/INTEGRATION-ARCHITECTURE.md`
- moved root `tests/**` into `.testbed/tests/**`
- renamed `.testbed/test/**` into `.testbed/scenes/**`

**Status:** ✅ Complete

**Results:** The coder first completed the structure-alignment pass in commit `7057f2e` (`Align MediaPipe Python addon architecture`) and pushed it to `main`, then the auditor found a mounted-addon regression caused by moving the entrypoint under `src/`. A targeted retry fixed that exact path issue in commit `3b27fd1` (`Fix mounted addon local script paths`), also pushed to `main`. Across those two passes, the repo-root addon entrypoint implementation was moved into `src/input_provider.gd`, `plugin.cfg` was updated to `script="src/input_provider.gd"`, root `tests/` content was moved under `.testbed/tests/`, and the old `.testbed/test/` manual scene content was renamed to `.testbed/scenes/` without blindly merging similarly named files that serve different roles. The coder updated the critical startup and path wiring to match: `.testbed/project.godot`, `.testbed/scenes/test_scene.tscn`, `.testbed/scenes/test_scene.gd`, README layout/docs, `.plans/INTEGRATION-ARCHITECTURE.md`, and `.github/workflows/gut_ci.yml` now reflect the new structure. The retry kept Derrick’s requested `src/` architecture intact while fixing `src/input_provider.gd` so its script-local loader resolves `providers/mediapipe_provider.gd` and `config/mediapipe_config.gd` relative to the new `src/` location instead of incorrectly producing `src/src/...` in mounted-addon use. Validation across the implementation passes reported: `git diff --check` passed, `python3 -m py_compile python_mediapipe/*.py` passed, `.testbed/venv/bin/python python_mediapipe/test_filter.py` passed, headless `.testbed` startup still reached the same truthful runtime blocker of missing `pose_landmarker_full.task`, and both the consuming-project mounted-addon path and the repo-local testbed path resolved the provider script correctly after the retry. The coder also noted that stale `.testbed/.godot` cache entries still referenced the old `res://test/...` paths until the cache was cleared during validation; after clearing cache, startup reflected the new `res://scenes/...` layout correctly. Orchestrator spot-checks confirmed both pushed commits exist, `plugin.cfg` points at `src/input_provider.gd`, `src/input_provider.gd` now resolves local dependencies correctly from within `src/`, the repo now has `.testbed/scenes/` and `.testbed/tests/`, and the CI workflow targets `.testbed` with `res://tests/unit` coverage output under `.testbed/coverage.json`.

---

### Task 3: Verify the architecture-aligned repo state

**Bead ID:** `oc-v5r`  
**SubAgent:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Independently verify that the requested architecture alignment landed correctly. Confirm root no longer carries the disallowed raw code/test structure, testbed-owned content moved under `.testbed/`, the scene folder is now `scenes/`, and addon/testbed/docs behavior still works. Re-run the critical validations and report any exact gap.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-20-architecture-alignment-followup.md`

**Status:** ✅ Complete

**Results:** QA initially passed the structure move, then the auditor found a real mounted-addon regression caused by moving the entrypoint under `src/` without fully adjusting its script-local dependency paths. After the targeted retry landed in commit `3b27fd1`, QA re-verified the corrected state and passed. The final QA verdict is that the requested architecture alignment now holds: there is no root `input_provider.gd`, no root `tests/`, no `.testbed/test/`, `src/`, `.testbed/scenes/`, and `.testbed/tests/` are all present, `plugin.cfg` points to `script="src/input_provider.gd"`, and `.testbed/project.godot` uses `res://scenes/test_scene.tscn`. QA confirmed that `src/input_provider.gd` now resolves local dependencies as `providers/mediapipe_provider.gd` and `config/mediapipe_config.gd`, and explicitly verified that the mounted-addon case resolves those to `res://addons/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd` and `res://addons/aerobeat-input-mediapipe-python/src/config/mediapipe_config.gd` without any lingering `src/src/...` regression. The mounted-addon smoke test successfully loaded and instantiated `res://addons/aerobeat-input-mediapipe-python/src/input_provider.gd` and created the internal `MediaPipeProvider` child. Validation reruns remained clean or truthfully blocked in the expected way: `python3 -m py_compile python_mediapipe/*.py` passed, `.testbed/venv/bin/python python_mediapipe/test_filter.py` passed, and headless `.testbed` startup still reached the truthful blocker of missing `pose_landmarker_full.task`. The remaining observed warnings were non-blocking UID fallback and cleanup noise, not architecture/path failures.

---

### Task 4: Independent completion audit

**Bead ID:** `oc-1yz`  
**SubAgent:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Audit the final architecture-aligned state of `aerobeat-input-mediapipe-python`. Truth-check the repo against Derrick’s notes, the plan, the actual file layout, and the validation evidence. Confirm whether the requested structure changes are truly complete or identify the precise remaining gap.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-20-architecture-alignment-followup.md`

**Status:** ✅ Complete

**Results:** The audit initially failed on a real mounted-addon regression after the entrypoint moved under `src/`, then passed after the targeted retry in commit `3b27fd1` fixed the local dependency paths. The final audit confirmed that Derrick’s requested structure alignment is real on disk: no root `input_provider.gd`, no root `tests/`, no `.testbed/test/`, and `src/`, `.testbed/scenes/`, and `.testbed/tests/` are all present with `plugin.cfg` pointing at `script="src/input_provider.gd"` and `.testbed/project.godot` pointing at `res://scenes/test_scene.tscn`. The auditor independently verified that the mounted-addon `src/src/...` regression is actually fixed: `src/input_provider.gd` now resolves `providers/mediapipe_provider.gd` and `config/mediapipe_config.gd` relative to its own `src/` directory, a headless mounted-addon audit successfully loaded and instantiated `res://addons/aerobeat-input-mediapipe-python/src/input_provider.gd`, and the instantiated addon created its internal `MediaPipeProvider` child while resolving dependencies to the expected `res://addons/aerobeat-input-mediapipe-python/src/providers/...` and `.../src/config/...` paths. Validation reruns also remained sound: `python3 -m py_compile python_mediapipe/*.py` passed, `.testbed/venv/bin/python python_mediapipe/test_filter.py` passed, and headless `.testbed` startup reached the same truthful expected blocker of missing `pose_landmarker_full.task`. Remaining warnings were judged non-blocking: UID fallback warnings after cache rebuild and the pre-existing `Node not found: "MediaPipeServer"` message before provider fallback creation.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Completed the requested architecture-alignment follow-up for `aerobeat-input-mediapipe-python`. The repo no longer keeps raw addon code or tests at repo root, the addon entrypoint now lives under `src/`, automated tests now live under `.testbed/tests/`, manual testbed scene content now lives under `.testbed/scenes/`, and the docs/config/CI/testbed wiring were updated to match. After a targeted retry, the new `src/` entrypoint also works correctly in the consuming-project mounted-addon case without regressing back to root-level raw-code placement.

**Reference Check:** `REF-01` is satisfied: root `/tests` moved under `/.testbed/`, the addon entrypoint implementation moved under `/src/`, and `/.testbed/test/` was renamed to `/.testbed/scenes/`. `REF-02` remains consistent with the prior migration pass while now documenting the stricter architecture layout. `REF-03` now reflects the aligned repo structure on disk. `REF-04` is satisfied by moving the entrypoint implementation under `src/` and updating `plugin.cfg` accordingly. `REF-05` is satisfied by renaming the testbed scene folder to `scenes/` and updating testbed wiring to match. The one regression introduced during the move was found by audit and fixed before closure.

**Commits:**
- `7057f2e` - Align MediaPipe Python addon architecture
- `3b27fd1` - Fix mounted addon local script paths
- `Pending local commit` - Add completed architecture alignment follow-up plan

**Lessons Learned:** Architecture-only cleanup can still break runtime behavior if script-local path resolution quietly depends on the old file location. The retry loop was worth it here: the structure move looked right on disk and even passed an initial QA pass, but the independent audit still caught the mounted-addon `src/src/...` regression. Also, stale `.godot` cache state and UID metadata noise can confuse validation after folder renames, so those warnings need to be separated from true path regressions.

---

*Completed on 2026-04-20*
