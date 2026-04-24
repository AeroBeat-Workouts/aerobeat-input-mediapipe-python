# AeroBeat MediaPipe Python Testbed GodotEnv Verification and Repair

**Date:** 2026-04-24  
**Status:** Draft  
**Agent:** Pico 🐱‍🏍

---

## Goal

Verify that the `.testbed` Godot project in `aerobeat-input-mediapipe-python` still works correctly after the GodotEnv and sidecar/runtime refactors, then repair any breakage so the test scenes open and play without new errors or warnings.

---

## Overview

This pass is no longer about replacing absolute symlinks or introducing GodotEnv — that conversion already happened. The real task now is to truth-check whether the current `.testbed` Godot project still consumes the repo through GodotEnv the way we intend after the recent MediaPipe Python runtime and launcher refactors, especially with the repo package itself, the Python sidecar payload, and the `aerobeat-input-core` contract package all mounted into the workbench project.

The work needs to validate the actual developer flow, not just static file layout. That means restoring the `.testbed` dependencies through GodotEnv, importing/opening the testbed, exercising the active scenes, checking whether they play cleanly, and then fixing any regressions discovered in scene paths, addon layout assumptions, sidecar startup, runtime validation, or contract wiring. After implementation, the repo needs an independent QA pass and audit so we know the workbench is genuinely healthy rather than just patched until one command stops complaining.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current `.testbed` addon dependency manifest | `.testbed/addons.jsonc` |
| `REF-02` | Current repo testbed/runtime guidance | `README.md` |
| `REF-03` | Previous GodotEnv testbed conversion plan | `.plans/mediapipe-python/2026-04-20-godotenv-testbed-conversion.md` |
| `REF-04` | Recent runtime migration/cleanup handoff state | `memory/2026-04-23.md` |
| `REF-05` | Active `.testbed` scenes and scripts | `.testbed/scenes/` |
| `REF-06` | Current package runtime/autostart implementation | `src/`, `python_mediapipe/` |

---

## Tasks

### Task 1: Audit current `.testbed` GodotEnv behavior and reproduce any scene/runtime failures

**Bead ID:** `oc-8e6`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Audit the current `.testbed` Godot project in `aerobeat-input-mediapipe-python` after the recent GodotEnv conversion and MediaPipe Python runtime refactors. Restore `.testbed` dependencies via GodotEnv, inspect how the repo package, the Python sidecar payload, and `aerobeat-input-core` are mounted into the workbench, then reproduce the current state of opening/importing/running the test scenes. Identify any errors or warnings that prevent the scenes from opening or playing cleanly, and map each failure back to the exact path/layout/runtime assumption causing it. Do not implement fixes yet. Claim the bead on start and return a concise evidence-backed repair plan.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`
- `.testbed/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-24-testbed-godotenv-verification-and-repair.md`

**Status:** ✅ Complete

**Results:** Audit complete. I restored the workbench with `cd .testbed && godotenv addons install`, verified the intended mounts, and reproduced the project in both headless and live-editor flows. Evidence: `.testbed/addons/aerobeat-input-mediapipe-python` resolves to this repo root, `.testbed/addons/aerobeat-core` resolves to the sibling `../../aerobeat-input-core` repo under the compatibility addon key/path, and `.testbed/addons/gut` installs from upstream as expected (`REF-01`, `REF-02`). Live editor open succeeded and the active main scene `res://scenes/test_scene.tscn` ran successfully in GUI mode with pose tracking visible, confirming the GodotEnv conversion itself is functional (`REF-05`, `REF-06`).

The audit also found real remaining issues: (1) editor import/open logs contain parse errors from `.testbed/tests/*.gd` because those scripts call GUT assertion helpers without extending a GUT base class, so the parser still flags undefined methods even though the scripts try to guard them at runtime; (2) `.testbed/scenes/install_progress.gd` fails to parse because it type-annotates `$AutoStartManager` as `AutoStartManager`, but that global type is not being resolved during editor parse, creating import noise even though the active main scene still loads; (3) runtime play of the main scene works, but the run log is flooded by `Image format RGB8 not supported by hardware, converting to RGBA8` warnings from `src/camera_view.gd:_update_texture()`, so the scene does not play warning-free yet; (4) the spawned Python sidecar itself starts successfully from the repo-owned runtime and model asset paths, proving the current runtime/launcher path assumptions still work under the GodotEnv symlinked package mount on this host (`python_mediapipe/assets/runtimes/linux-x64/venv/bin/python`, `python_mediapipe/assets/models/pose_landmarker_full.task`).

---

### Task 2: Repair `.testbed` scene/runtime issues so the workbench opens and plays cleanly

**Bead ID:** `oc-gc9`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Implement the fixes required to make the `.testbed` Godot project in `aerobeat-input-mediapipe-python` work correctly with the current GodotEnv-managed addon layout and the refactored Python sidecar/runtime contract. Preserve the intended package structure: the repo package and Python sidecar content should be consumed from the installed addon payload, and `aerobeat-input-core` should remain a GodotEnv-managed dependency. Fix scene/script/resource/runtime issues until the active test scenes open and play without unexpected errors or warnings. Run the relevant validation commands, commit and push by default, and document any remaining truthful prerequisite if something external still blocks a fully clean run.

**Folders Created/Deleted/Modified:**
- `.testbed/scenes/`
- `.testbed/tests/`
- `.testbed/tests/unit/`
- `src/`

**Files Created/Deleted/Modified:**
- `.testbed/scenes/install_progress.gd`
- `.testbed/scenes/test_scene.gd`
- `.testbed/tests/test_mediapipe_logic.gd`
- `.testbed/tests/unit/test_mediapipe_process.gd`
- `.testbed/tests/unit/test_mediapipe_provider.gd`
- `.testbed/tests/unit/test_mediapipe_server.gd`
- `src/autostart_manager.gd`
- `src/camera_view.gd`

**Status:** ✅ Complete

**Results:** Implemented the audit-driven repair set and validated it against the real GodotEnv-managed workbench on this host. The `.testbed/tests/*.gd` scripts that call GUT assertion helpers now inherit from the concrete GUT base script (`res://addons/gut/test.gd`), which removes the editor parse/load failures without changing the tests' existing standalone guard logic. `.testbed/scenes/install_progress.gd` no longer hard-types `$AutoStartManager` as `AutoStartManager`; it now resolves the node safely as `Node`, checks for null in `_ready()`, and therefore stops producing the global-type parse failure during import/open. `src/camera_view.gd` now initializes and updates its texture path in `RGBA8`, converts decoded JPEG frames to `RGBA8` before upload, and reuses a persistent `ImageTexture` via `update(frame)`, which removes the runtime spam `Image format RGB8 not supported by hardware, converting to RGBA8` while preserving the current MJPEG stream behavior (`REF-05`, `REF-06`). I also repaired two teardown issues surfaced by live runtime validation: `.testbed/scenes/test_scene.gd` now frees the placeholder `TextureRect` after `replace_by()` and queues cleanup for dynamically created runtime nodes, while `src/autostart_manager.gd` now uses synchronous shutdown in `_exit_tree()` so scene teardown no longer leaks a `GDScriptFunctionState` warning on exit.

Validation evidence: `cd .testbed && godotenv addons install` succeeded and restored the expected addon mounts (`REF-01`); `godot --headless --path .testbed --import --quit-after 1000` completed without parse errors; `godot --headless --path .testbed --editor --quit-after 1000` completed without parse errors; `godot --path .testbed --quit-after 900` exercised the real main scene, started the repo-owned sidecar runtime, connected the camera stream, and exited cleanly with no RGB8 conversion spam or ObjectDB leak warnings; a live Wayland desktop screenshot taken during that runtime run (`/tmp/aerobeat-testbed-check/runtime.png`) shows the active test scene rendering with camera feed and 33 detected landmarks. Implementation commit: `abbfb4e` (`Fix testbed parse errors and camera runtime warnings`).

---

### Task 3: QA the repaired `.testbed` by re-importing and exercising the scenes

**Bead ID:** `oc-577`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-05`, `REF-06`  
**Prompt:** Independently QA the repaired `.testbed` Godot project in `aerobeat-input-mediapipe-python`. Reinstall addons via GodotEnv as needed, re-import the project, open/run the active test scenes, and verify whether they now load and play cleanly. Confirm there is no hidden dependence on stale paths or legacy sidecar layout assumptions. Report exact validation evidence plus any remaining warnings, errors, or prerequisites.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`
- `.testbed/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-24-testbed-godotenv-verification-and-repair.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Audit completion against the requested outcome

**Bead ID:** `oc-e28`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Audit whether `aerobeat-input-mediapipe-python` now truly has a healthy `.testbed` Godot project under the GodotEnv setup. Truth-check that the repo package, Python sidecar content, and `aerobeat-input-core` contract package are wired correctly for the workbench; that the active test scenes open and play without unexpected errors or warnings; and that any remaining blocker is explicitly documented and genuinely external. Close only if the evidence supports that outcome.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-24-testbed-godotenv-verification-and-repair.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending

**Lessons Learned:** Pending.

---

*Completed on Pending*
