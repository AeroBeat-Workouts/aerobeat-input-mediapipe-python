# AeroBeat MediaPipe Python GodotEnv Testbed Conversion

**Date:** 2026-04-20  
**Status:** Draft  
**Agent:** Pico 🐱‍🏍

---

## Goal

Replace the manually committed `.testbed` symlink wiring in `aerobeat-input-mediapipe-python` with the intended GodotEnv-managed dependency/linking system.

---

## Overview

Right now this repo’s `.testbed` still relies on committed symlinks for `src`, `python_mediapipe`, and `addons/aerobeat-core`. That does not match the intended AeroBeat GodotEnv direction. The follow-up here is to convert this repo’s testbed to the GodotEnv flow cleanly: remove the hand-maintained symlinks, add the correct GodotEnv configuration, verify the install/link behavior, and update docs so the repo truthfully describes the managed setup.

This needs a careful audit first so the repo lands on the *correct* GodotEnv shape, but Derrick has now made the architectural rule explicit: `aerobeat-core`, `src`, and `python_mediapipe` are all real dependencies of the Godot project under `.testbed`, and this repo should use **only GodotEnv** to handle dependency linking. Manual symlink solutions are not allowed. The goal is a truthful managed setup, not just “delete symlinks and hope.”

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Derrick’s instruction to replace manual symlinks with GodotEnv | current session notes (2026-04-20 09:34 EDT) |
| `REF-02` | AeroBeat GodotEnv direction recorded in memory | `memory/2026-04-17.md` |
| `REF-03` | Current repo layout and `.testbed` symlink state | `.` |
| `REF-04` | Current architecture/integration doc | `.plans/INTEGRATION-ARCHITECTURE.md` |
| `REF-05` | Current README/runtime docs | `README.md` |

---

## Tasks

### Task 1: Audit the correct GodotEnv shape for this repo’s testbed

**Bead ID:** `oc-2bn`  
**SubAgent:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Audit how `aerobeat-input-mediapipe-python` should use GodotEnv for its `.testbed` wiring. Determine the correct managed configuration for replacing the current committed `.testbed` symlinks to `src`, `python_mediapipe`, and `addons/aerobeat-core`. Derrick has clarified that all three are real dependencies of the `.testbed` Godot project and that this repo should ONLY use GodotEnv to handle linking in AeroBeat — never custom/manual symlink solutions. Identify the exact GodotEnv config/install workflow, path/layout implications, and docs updates needed. Do not edit files yet; return a concise action map with evidence.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-20-godotenv-testbed-conversion.md`

**Status:** ✅ Complete

**Results:** The audit concluded that the clean GodotEnv shape is not three separate hand-wired local links, but one GodotEnv-managed self-package entry for this repo root plus explicit managed entries for `aerobeat-core` and GUT. In concrete terms, `.testbed/addons.jsonc` should install `aerobeat-input-mediapipe-python` from `url: ".."`, `source: "symlink"`, `subfolder: "/"`; install `aerobeat-core` from `url: "../../aerobeat-core"`, `source: "symlink"`, `subfolder: "/"`; and install GUT from its standard remote Git source under `subfolder: "/addons/gut"`. This lets GodotEnv manage all three actual `.testbed` dependencies without inventing fake standalone packages for `src/` or `python_mediapipe/`, because those already belong to the repo-root package payload. The required repo conversion work is therefore: add `.testbed/addons.jsonc`; remove the tracked manual links `.testbed/src`, `.testbed/python_mediapipe`, and `.testbed/addons/aerobeat-core`; rewrite `.testbed` code/resources that currently rely on `res://src/...` or `res://python_mediapipe/...` to instead use `res://addons/aerobeat-input-mediapipe-python/src/...` and `.../python_mediapipe/...`; update `.gitignore` to the standard GodotEnv workbench shape for managed addons; update `README.md` to document `cd .testbed && godotenv addons install`; and update CI to the matching GodotEnv restore/import/GUT flow instead of assuming the manual symlinked state. The audit also confirmed what should not be done here: no assembly-root `addons.jsonc` changes, no custom bootstrap script, and no custom replacement symlink logic. Biggest implementation implication: proving that `.testbed` still imports and resolves its runtime paths after the manual symlinks are deleted, because this is not just a manifest addition but a path-rewrite conversion to managed package consumption.

---

### Task 2: Implement the GodotEnv conversion

**Bead ID:** `oc-65l`  
**SubAgent:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Convert `aerobeat-input-mediapipe-python` from the current manually committed `.testbed` symlink wiring to the correct GodotEnv-managed setup. `aerobeat-core`, `src`, and `python_mediapipe` must all be handled as GodotEnv-managed dependencies for the `.testbed` project, and manual/custom symlink solutions should be removed entirely. Remove the manual symlinks only after the replacement config/workflow is in place. Update config/docs/runtime guidance so the repo truthfully reflects the managed setup, preserve the working testbed behavior, and run relevant validation. Commit and push by default.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `.github/workflows/`
- `src/`

**Files Created/Deleted/Modified:**
- `.testbed/addons.jsonc`
- `.gitignore`
- `README.md`
- `.github/workflows/gut_ci.yml`
- `src/autostart_manager.gd`
- `src/mediapipe_input_with_camera.gd`
- `.testbed/scenes/test_scene.tscn`
- `.testbed/scenes/test_scene.gd`
- removed tracked manual links `.testbed/src`, `.testbed/python_mediapipe`, `.testbed/addons/aerobeat-core`

**Status:** ✅ Complete

**Results:** The coder completed the GodotEnv conversion in commit `a02116b` (`Convert testbed to GodotEnv-managed addons`) and pushed it to `main`. The repo now has a committed `.testbed/addons.jsonc` that manages the testbed through GodotEnv using a self-package entry for `aerobeat-input-mediapipe-python` from `..` with `source: "symlink"`, a sibling-repo `aerobeat-core` entry from `../../aerobeat-core` with `source: "symlink"`, and a GUT entry from its upstream Git source. The old tracked manual links `.testbed/src`, `.testbed/python_mediapipe`, and `.testbed/addons/aerobeat-core` were removed from the repo, and `.testbed` path references were rewritten away from `res://src/...` / `res://python_mediapipe/...` to the installed package form under `res://addons/aerobeat-input-mediapipe-python/...`. The coder also updated runtime code (`src/autostart_manager.gd`, `src/mediapipe_input_with_camera.gd`), `.gitignore`, `README.md`, and `.github/workflows/gut_ci.yml` so the repo now truthfully documents GodotEnv as the only linkage mechanism and CI restores dependencies through `godotenv addons install`. Validation reported by the coder: `cd .testbed && godotenv addons install` succeeded and recreated managed addon links under `.testbed/addons/`; `python3 -m py_compile python_mediapipe/*.py` passed; `.testbed/venv/bin/python python_mediapipe/test_filter.py` passed; `godot --headless --path .testbed --import` completed; and `godot --headless --path .testbed --quit` reached the same truthful blocker of missing `pose_landmarker_full.task`. The coder also noted that a full GUT run still fails for pre-existing repo-local test-suite reasons unrelated to the linkage conversion: several scripts under `.testbed/tests/unit/` do not extend `GutTest` or rely on unavailable assertion helpers, so collection/parsing fails. Orchestrator spot-checks confirmed the pushed commit exists, `.testbed/addons.jsonc` is present, the old tracked manual links are gone from git, and the generated `.testbed/addons/` links now reflect GodotEnv-managed install output rather than committed repo-owned symlink wiring.

---

### Task 3: Verify the GodotEnv-managed testbed state

**Bead ID:** `oc-nga`  
**SubAgent:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Independently verify that the repo no longer relies on the old manual `.testbed` symlinks and now uses the intended GodotEnv-managed setup. Confirm the config is correct, docs are truthful, and the testbed/install behavior still makes sense. Re-run the critical validations and report any exact gap.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-20-godotenv-testbed-conversion.md`

**Status:** ✅ Complete

**Results:** QA verified that the GodotEnv conversion is real and that the repo no longer depends on the old manual `.testbed` symlink contract. `.testbed/addons.jsonc` was confirmed to match the intended shape: `aerobeat-input-mediapipe-python` from `..` via `source: "symlink"` and `subfolder: "/"`, `aerobeat-core` from `../../aerobeat-core` via `source: "symlink"` and `subfolder: "/"`, and `gut` from upstream Git under `/addons/gut`. QA also confirmed the old repo-owned wiring is gone: `.testbed/src` is missing and untracked, `.testbed/python_mediapipe` is missing and untracked, and `.testbed/addons/aerobeat-core` is no longer tracked as repo-owned wiring. The strongest proof was an install reproducibility check: QA deliberately deleted the generated `.testbed/addons/aerobeat-core` and `.testbed/addons/aerobeat-input-mediapipe-python` symlinks, reran `cd .testbed && godotenv addons install`, and confirmed that GodotEnv recreated them successfully. That verifies the current symlinks under `.testbed/addons/` are now GodotEnv install output, not prohibited custom repo wiring. QA also checked that `.testbed` files now resolve this package through `res://addons/aerobeat-input-mediapipe-python/...` in the active scene/test files. Validation reruns were sound: `python3 -m py_compile python_mediapipe/*.py` passed, `.testbed/venv/bin/python python_mediapipe/test_filter.py` passed, `godot --headless --path .testbed --import` passed, and `godot --headless --path .testbed --quit` reached the same truthful blocker of missing `pose_landmarker_full.task`. GUT still fails to run meaningful tests, but QA judged that to be pre-existing suite trouble rather than a GodotEnv conversion issue. The only new dirt seen was untracked Godot import/editor artifacts, which QA treated as repo-hygiene noise rather than evidence of old linkage.

---

### Task 4: Independent completion audit

**Bead ID:** `oc-e9j`  
**SubAgent:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Audit the final GodotEnv-managed state of `aerobeat-input-mediapipe-python` after implementation and QA. Truth-check whether the old manual symlink approach is actually gone, the new managed setup is real, and the repo’s docs/config/behavior all line up. Close only if the conversion is truly complete; otherwise report the exact remaining gap.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-20-godotenv-testbed-conversion.md`

**Status:** ✅ Complete

**Results:** The auditor independently confirmed that the GodotEnv testbed conversion is real and complete. `.testbed/addons.jsonc` has the intended managed shape: `aerobeat-input-mediapipe-python` from `..` with `source: "symlink"` and `subfolder: "/"`, `aerobeat-core` from `../../aerobeat-core` with `source: "symlink"` and `subfolder: "/"`, and `gut` from upstream Git under `/addons/gut`. Old repo-owned wiring is gone from git: there is no tracked `.testbed/src`, `.testbed/python_mediapipe`, or `.testbed/addons/aerobeat-core`. The auditor also repeated the strongest proof of managed behavior by deleting the generated `.testbed/addons/aerobeat-core` and `.testbed/addons/aerobeat-input-mediapipe-python` links, rerunning `cd .testbed && godotenv addons install`, and confirming GodotEnv recreated both links correctly. Active `.testbed` scene/test paths now resolve through `res://addons/aerobeat-input-mediapipe-python/...`, while README, `.gitignore`, and CI all line up with the GodotEnv-only workflow. Validation reruns remained sound: `python3 -m py_compile python_mediapipe/*.py` passed, `.testbed/venv/bin/python python_mediapipe/test_filter.py` passed, `godot --headless --path .testbed --import` passed, and headless testbed startup reached the same truthful expected blocker of missing `pose_landmarker_full.task`. The auditor explicitly judged the remaining issues to be non-blockers for this conversion: the missing `.task` model prerequisite, pre-existing broken GUT suite behavior, and Godot import/editor noise.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Converted `aerobeat-input-mediapipe-python` from the old manual `.testbed` symlink contract to a GodotEnv-managed dependency setup. The testbed now installs the current repo as a self package, installs `aerobeat-core` as a managed sibling dependency, installs GUT through GodotEnv, and resolves its active scene/test/runtime paths through installed package locations under `res://addons/...` instead of relying on hand-maintained `.testbed/src` / `.testbed/python_mediapipe` / `.testbed/addons/aerobeat-core` links.

**Reference Check:** `REF-01` is satisfied: the manual symlink approach was replaced with GodotEnv-managed dependency linking for the `.testbed` project. `REF-02` aligns with the earlier AeroBeat GodotEnv direction of package-oriented dependency management. `REF-03` now reflects a repo with no tracked manual `.testbed` dependency links. `REF-04` remains consistent with the repo’s package/integration architecture while now using `.testbed/addons.jsonc` as the workbench dependency manifest. `REF-05` now truthfully documents `cd .testbed && godotenv addons install` as the linkage mechanism.

**Commits:**
- `a02116b` - Convert testbed to GodotEnv-managed addons
- `Pending local commit` - Add GodotEnv testbed conversion plan

**Lessons Learned:** The clean GodotEnv shape for this repo was a managed self-package plus managed sibling dependencies, not fake standalone packages for internal folders. The strongest verification pattern was destructive/reinstall testing: deleting generated addon links and proving `godotenv addons install` recreates them. Also, it was important to separate real conversion failures from unrelated existing issues such as missing `.task` assets and broken legacy GUT tests.

---

*Completed on 2026-04-20*
