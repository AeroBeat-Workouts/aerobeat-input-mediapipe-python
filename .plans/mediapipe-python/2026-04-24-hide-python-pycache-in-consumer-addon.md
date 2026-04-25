# AeroBeat MediaPipe Python Hide __pycache__ in Consumer Addon

**Date:** 2026-04-24  
**Status:** In Progress  
**Agent:** Pico 🐱‍🏍

---

## Goal

Hide `python_mediapipe/__pycache__/` from consumer/editor indexing while keeping `python_mediapipe/` visible and preserving the runtime-prep/dev-mode flow from `aerobeat-assembly-community`.

---

## Overview

The previous selective visibility pass intentionally made `python_mediapipe/` visible in consumer repos because Derrick wants the installed addon to support local runtime preparation from the assembly repo. One non-essential folder remained visible: `python_mediapipe/__pycache__/`. That folder is Python bytecode cache, not source-of-truth runtime content.

This pass stayed tiny and surgical. The fix does not re-hide `python_mediapipe/` itself and does not touch the runtime-prep flow. It only makes the localized `python_mediapipe/__pycache__/.gdignore` ship with the addon so Godot can keep indexing `python_mediapipe/` while skipping the bytecode cache folder.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current selective visibility plan and outcome | `.plans/mediapipe-python/2026-04-24-addon-visibility-layout-for-assembly-consumers.md` |
| `REF-02` | Current Python addon subtree | `python_mediapipe/` |
| `REF-03` | Current assembly consumer install path | `../aerobeat-assembly-community/addons/aerobeat-input-mediapipe/` |

---

## Tasks

### Task 1: Implement localized __pycache__ hide and refresh consumer install

**Bead ID:** `oc-hfp`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Implement the smallest truthful fix to hide `python_mediapipe/__pycache__/` from consumer/editor indexing while preserving visibility of `python_mediapipe/` itself. Refresh the assembly consumer install, verify `__pycache__/` is no longer indexed, and verify `prepare_runtime.py` still works from the installed addon path. Commit/push by default.

**Folders Created/Deleted/Modified:**
- `python_mediapipe/__pycache__/`
- `.plans/mediapipe-python/`
- `../aerobeat-assembly-community/addons/`

**Files Created/Deleted/Modified:**
- `.gitignore`
- `python_mediapipe/__pycache__/.gdignore`
- `.plans/mediapipe-python/2026-04-24-hide-python-pycache-in-consumer-addon.md`

**Status:** ✅ Complete

**Results:** Implemented the smallest truthful owner-repo fix in commit `0eec2f8` (`Hide python_mediapipe pycache from consumers`) and pushed it to `origin/main`. Exact code change: kept the existing localized hide marker file at `python_mediapipe/__pycache__/.gdignore`, but made it shippable by carving out a narrow `.gitignore` exception for `python_mediapipe/__pycache__/` and then tracking only `python_mediapipe/__pycache__/.gdignore`. No broader visibility rules changed, so `python_mediapipe/` itself remains visible.

Exact baseline proof before the push: after refreshing `../aerobeat-assembly-community` against the prior remote `main`, running `python3 addons/aerobeat-input-mediapipe/python_mediapipe/prepare_runtime.py --platform linux-x64 --mode dev --create-venv --force --validate --json`, and rebuilding Godot caches, `.godot/editor/filesystem_cache10` still contained `res://addons/aerobeat-input-mediapipe/python_mediapipe/__pycache__/`, which proved the problem was real and that the consumer install did not yet carry the local `.gdignore`.

Exact refreshed consumer-install evidence after the push: from `../aerobeat-assembly-community`, removed the stale installed/cache copies at `addons/aerobeat-input-mediapipe` and `.addons/aerobeat-input-mediapipe`, cleared the relevant `.godot/editor/filesystem_cache*` and `.godot/global_script_class_cache.cfg`, and reran `godotenv addons install`. The install log resolved `aerobeat-input-mediapipe` from `git@github.com:AeroBeat-Workouts/aerobeat-input-mediapipe-python.git` on branch `main`. The refreshed addon tree then contained `addons/aerobeat-input-mediapipe/python_mediapipe/__pycache__/.gdignore` with content `# Hide Python bytecode cache from Godot consumers.`

Exact runtime-prep evidence from the installed addon path (`REF-03`): ran `python3 addons/aerobeat-input-mediapipe/python_mediapipe/prepare_runtime.py --platform linux-x64 --mode dev --create-venv --force --validate --json`. It exited `0` and returned `"validation_status": "venv_created"`, `"validation_errors": []`, and `"runtime_root": "/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/addons/aerobeat-input-mediapipe/python_mediapipe/assets/runtimes/linux-x64"`. The installed runtime tree contains `runtime-manifest.json`, `.runtime-ready`, and `venv/` under `python_mediapipe/assets/runtimes/linux-x64/`.

Exact indexing evidence after the refreshed install plus runtime prep: `addons/aerobeat-input-mediapipe/python_mediapipe/__pycache__/` existed on disk and contained both `.gdignore` and `runtime_paths.cpython-312.pyc`, but a direct grep across `.godot/editor/filesystem_cache*` and `.godot/global_script_class_cache.cfg` returned `PYCACHE_INDEXED=NO` for `res://addons/aerobeat-input-mediapipe/python_mediapipe/__pycache__/`. At the same time, `.godot/editor/filesystem_cache10` still contained `res://addons/aerobeat-input-mediapipe/python_mediapipe/`, `.../python_mediapipe/assets/`, and `.../python_mediapipe/assets/models/`, proving `python_mediapipe/` stayed visible while only `__pycache__/` dropped out of editor indexing.

---

### Task 2: QA/audit the hidden __pycache__ state in the assembly consumer

**Bead ID:** `oc-d0m`  
**SubAgent:** `primary`  
**Role:** `qa` / `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Independently verify that `python_mediapipe/__pycache__/` is no longer indexed/visible in the refreshed assembly consumer state while `python_mediapipe/` stays visible and `prepare_runtime.py` still works. Close only if the evidence supports it.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-24-hide-python-pycache-in-consumer-addon.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Landed the tiny owner-repo fix needed to ship a localized hide marker for `python_mediapipe/__pycache__/`, refreshed the assembly consumer install, and revalidated that the installed addon still supports runtime preparation while no longer indexing the bytecode cache folder.

**Reference Check:** `REF-01` remains consistent with the previous selective-visibility outcome and narrows it one level deeper for `__pycache__/`. `REF-02` satisfied: only `.gitignore` handling for `python_mediapipe/__pycache__/` changed, and `python_mediapipe/` itself stayed visible. `REF-03` satisfied for coder validation: the refreshed consumer install in `../aerobeat-assembly-community/addons/aerobeat-input-mediapipe/` now carries `python_mediapipe/__pycache__/.gdignore`, does not index `__pycache__/`, and still passes the installed `prepare_runtime.py` validation path.

**Commits:**
- `0eec2f8` - Hide python_mediapipe pycache from consumers

**Lessons Learned:** A localized `.gdignore` is only effective for consumer installs if the file is actually shippable. With a blanket `__pycache__/` ignore in Git, the fix needed to be not a new visibility rule, but a narrow allowlist that tracks exactly one hide marker file inside the otherwise-ignored cache directory.

---

*Completed on Pending*
