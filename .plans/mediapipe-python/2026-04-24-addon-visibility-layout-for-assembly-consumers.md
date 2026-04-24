# AeroBeat MediaPipe Python Addon Visibility Layout for Assembly Consumers

**Date:** 2026-04-24  
**Status:** In Progress  
**Agent:** Pico 🐱‍🏍

---

## Goal

Make the shipped `aerobeat-input-mediapipe-python` addon appear correctly inside consumer repos like `aerobeat-assembly-community`: `src/` and `python_mediapipe/` should be visible under `addons/aerobeat-input-mediapipe/`, while repo-only folders like `.beads/`, `.git/`, `.github/`, `.plans/`, and `.testbed/` should stay hidden.

---

## Overview

The current investigation showed that the installed addon exists on disk but is hidden from the Godot editor because a root-level `.gdignore` is too broad. Derrick clarified the intended layout more precisely: this is not about hiding everything except runtime loadable scripts. The consumer-visible addon should expose `src/` and `python_mediapipe/` in the editor, while hiding repo-internal management folders and other non-consumer surfaces.

Derrick also clarified an important runtime expectation for assembly-community dev mode: the installed `python_mediapipe/prepare_runtime.py` script should be runnable from the consumer repo so it can regenerate the large, platform-specific, non-committed runtime files locally (for our case, Linux dev/testing from `aerobeat-assembly-community`). That means the fix is not just selective visibility. We also need to make sure the shipped addon layout supports that local runtime-prep workflow cleanly, without exposing repo-only junk like `.git` in the consumer addon tree.

So the fix should move from a single root ignore to a selective ignore/layout strategy owned by `aerobeat-input-mediapipe-python`, and then verify both outcomes in the assembly consumer: (1) the editor shows the desired folders while hiding repo-only ones, and (2) the installed `python_mediapipe/prepare_runtime.py` flow works for Linux dev-mode runtime preparation.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Derrick’s desired visible vs hidden addon layout | current session, 2026-04-24 19:18 EDT |
| `REF-02` | Current addon visibility investigation | `../aerobeat-assembly-community/.plans/2026-04-24-mediapipe-addon-editor-visibility-indexing-pass.md` |
| `REF-03` | Current addon root contents and ignore behavior | `.gdignore`, `src/`, `python_mediapipe/`, `.beads/`, `.git/`, `.github/`, `.plans/`, `.testbed/` |
| `REF-04` | Current assembly consumer install path | `../aerobeat-assembly-community/addons/aerobeat-input-mediapipe/` |

---

## Tasks

### Task 1: Audit current shipped layout and define the smallest selective ignore strategy

**Bead ID:** `oc-uzl`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Audit the current shipped addon layout for `aerobeat-input-mediapipe-python` and determine the smallest truthful ignore/layout strategy that will make `src/` and `python_mediapipe/` visible in consumer editors while hiding repo-only folders like `.beads/`, `.git/`, `.github/`, `.plans/`, and `.testbed/`. Do not implement yet.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-24-addon-visibility-layout-for-assembly-consumers.md`

**Status:** ✅ Complete

**Results:** Audited both the source repo root and the current installed consumer payload at `../aerobeat-assembly-community/addons/aerobeat-input-mediapipe/`. Exact evidence: both trees currently ship the same top-level layout — `plugin.cfg`, `README.md`, `src/`, `python_mediapipe/`, plus repo-only folders `.beads/`, `.git/`, `.github/`, `.plans/`, and `.testbed/`.

The current hide/show behavior is broader than intended because there is a root-level `.gdignore` in the addon root and a second `.gdignore` at `python_mediapipe/.gdignore`. For Godot, the presence of `.gdignore` on a directory boundary is the important fact; the file contents do not selectively filter child names. That means the root `.gdignore` suppresses scanner/class-cache visibility for the whole addon tree in the consumer install (matching `REF-02`), and `python_mediapipe/.gdignore` would keep the full `python_mediapipe/` subtree hidden even after the root ignore is removed.

`src/` should remain visible: `plugin.cfg` points directly to `script="src/input_provider.gd"`, and the repo README documents `src/` as the assembly-facing Godot implementation. `python_mediapipe/` should also remain visible: the README explicitly documents it as the Python sidecar/runtime-prep payload, and the shipped tree contains meaningful consumer-relevant content there (`main.py`, `prepare_runtime.py`, `requirements.txt`, `runtime_paths.py`, `assets/models/*.task`).

Inside `python_mediapipe/`, the only clearly already-localized ignore boundary is `python_mediapipe/assets/runtimes/.gdignore`, which is the right place to keep generated desktop runtime roots hidden. Caveat: the folder also currently contains a shipped `__pycache__/` tree with `.pyc` files. That cache directory is not covered by any localized `.gdignore`; if `python_mediapipe/.gdignore` is removed so the folder becomes visible, `__pycache__/` would likely become visible too unless the install step stops copying it or a localized ignore is added just for `python_mediapipe/__pycache__/`.

Recommended smallest truthful fix: remove the addon-root `.gdignore`, remove `python_mediapipe/.gdignore`, keep `python_mediapipe/assets/runtimes/.gdignore`, and move ignore boundaries down onto the repo-only folders that are actually meant to stay hidden in consumer editors (`.beads/`, `.github/`, `.plans/`, `.testbed/`; `.git/` should ideally stop being copied into the consumer payload at all, but if it continues to be shipped, it also needs its own localized hide/exclude treatment). This is the smallest layout change that preserves visibility for `src/` and `python_mediapipe/` without re-hiding the whole addon.

---

### Task 2: Implement the selective ignore/layout fix and refresh the assembly install

**Bead ID:** `oc-7z6`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Implement the smallest truthful fix in `aerobeat-input-mediapipe-python` so consumer repos show `src/` and `python_mediapipe/` under the addon while hiding repo-only folders such as `.beads`, `.git`, `.github`, `.plans`, and `.testbed`. Refresh the assembly consumer install, verify the visible/hidden layout, and also verify that `python_mediapipe/prepare_runtime.py` can be run from the installed addon in `aerobeat-assembly-community` to regenerate Linux dev-mode runtime files as intended. Record exact validation evidence and commit/push by default.

**Folders Created/Deleted/Modified:**
- `src/`
- `python_mediapipe/`
- `.plans/mediapipe-python/`
- `../aerobeat-assembly-community/addons/`

**Files Created/Deleted/Modified:**
- ignore/layout files as needed
- `.plans/mediapipe-python/2026-04-24-addon-visibility-layout-for-assembly-consumers.md`
- `../aerobeat-assembly-community/.plans/2026-04-24-mediapipe-addon-editor-visibility-indexing-pass.md`

**Status:** ✅ Complete

**Results:** Implemented the smallest truthful owner-repo visibility fix in commit `ea26670` (`Fix addon selective visibility layout`) and pushed it to `origin/main`. Exact layout change: removed the addon-root `.gdignore` and `python_mediapipe/.gdignore`, kept the existing localized runtime ignore at `python_mediapipe/assets/runtimes/.gdignore`, and added localized `.gdignore` markers only on repo-only directories that should stay out of consumer editor scans (`.beads/.gdignore`, `.github/.gdignore`, `.plans/.gdignore`, `.testbed/.gdignore`).

Assembly refresh evidence (`REF-04`): from `../aerobeat-assembly-community`, I removed the stale installed/cache copies at `addons/aerobeat-input-mediapipe` and `.addons/aerobeat-input-mediapipe`, ran `godotenv addons install`, and confirmed the refreshed top-level tree now contains visible consumer payload folders `src/` and `python_mediapipe/` with no addon-root `.gdignore` and no `python_mediapipe/.gdignore`. The refreshed payload also contains localized hide markers at `addons/aerobeat-input-mediapipe/.beads/.gdignore`, `.github/.gdignore`, `.plans/.gdignore`, and `.testbed/.gdignore`; `python_mediapipe/assets/runtimes/.gdignore` remained in place. The install still includes a `.git/` directory on disk because GodotEnv materializes a Git checkout for the installed payload, and the owning repo cannot ship tracked files inside `.git/`; however, subsequent Godot scan/cache checks showed no `res://addons/aerobeat-input-mediapipe/.git/` entries, so `.git` did not become editor-visible in the validated consumer state.

Godot visibility/indexing evidence: after clearing the relevant assembly `.godot` scan/class-cache files and running `~/.local/bin/godot --headless --path ../aerobeat-assembly-community --import --quit-after 1000`, `.godot/editor/filesystem_cache*` gained `res://addons/aerobeat-input-mediapipe/`, `.../python_mediapipe/`, `.../python_mediapipe/assets/`, `.../python_mediapipe/assets/models/`, and the expected `src/` subdirectories. `.godot/global_script_class_cache.cfg` now contains MediaPipe addon classes again, including `MediaPipeCameraView`, `MediaPipeConfig`, and `MediaPipeProvider`, with paths under `res://addons/aerobeat-input-mediapipe/src/...`. A direct hidden-dir cache scan found no entries for `res://addons/aerobeat-input-mediapipe/.beads/`, `.github/`, `.plans/`, `.testbed/`, or `.git/`, which is the strongest local evidence that the whole addon is no longer hidden while the repo-only folders remain out of Godot’s scanned/indexed tree.

Installed runtime-prep evidence: from `../aerobeat-assembly-community/addons/aerobeat-input-mediapipe`, ran `python3 python_mediapipe/prepare_runtime.py --platform linux-x64 --mode dev --create-venv --force --validate --json`. The command exited `0` and returned `"validation_status": "venv_created"`, `"validation_errors": []`, and `"runtime_root": "/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/addons/aerobeat-input-mediapipe/python_mediapipe/assets/runtimes/linux-x64"`, proving the installed consumer payload can regenerate the Linux dev-mode runtime in place as intended. The resulting installed runtime tree contains `runtime-manifest.json`, `.runtime-ready`, and `venv/` under `python_mediapipe/assets/runtimes/linux-x64/`.

---

### Task 3: QA/audit the consumer-visible addon tree in assembly

**Bead ID:** `oc-6b0`  
**SubAgent:** `primary`  
**Role:** `qa` / `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Independently verify that the refreshed assembly consumer install now shows `src/` and `python_mediapipe/` under the MediaPipe addon while keeping `.beads/`, `.git/`, `.github/`, `.plans/`, and `.testbed/` hidden, and verify that the installed `python_mediapipe/prepare_runtime.py` flow works from `aerobeat-assembly-community` for Linux dev-mode runtime preparation. Close only if the evidence supports it.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-24-addon-visibility-layout-for-assembly-consumers.md`

**Status:** ✅ Complete

**Results:** Independent QA/audit passed against the refreshed consumer install at `../aerobeat-assembly-community/addons/aerobeat-input-mediapipe/`. Exact on-disk verification: `addons/aerobeat-input-mediapipe/.gdignore` is absent and `addons/aerobeat-input-mediapipe/python_mediapipe/.gdignore` is absent, while localized hide markers are present at `.beads/.gdignore`, `.github/.gdignore`, `.plans/.gdignore`, `.testbed/.gdignore`, and `python_mediapipe/assets/runtimes/.gdignore`.

Independent Godot scan evidence: after deleting the relevant assembly `.godot/editor/filesystem_cache*` and `.godot/global_script_class_cache.cfg` files and rerunning `~/.local/bin/godot --headless --path . --import --quit-after 1000` from `../aerobeat-assembly-community`, `.godot/editor/filesystem_cache10` contained `res://addons/aerobeat-input-mediapipe/python_mediapipe/`, `.../python_mediapipe/assets/`, `.../python_mediapipe/assets/models/`, `res://addons/aerobeat-input-mediapipe/src/`, and the expected `src/config`, `src/process`, `src/providers`, `src/runtime`, `src/server`, and `src/strategies` subdirectories. `.godot/global_script_class_cache.cfg` also contained addon script-class paths under `res://addons/aerobeat-input-mediapipe/src/...`, including `src/camera_view.gd`, `src/config/mediapipe_config.gd`, and `src/providers/mediapipe_provider.gd`. A direct grep of those same cache files found no entries for `res://addons/aerobeat-input-mediapipe/.beads/`, `.git/`, `.github/`, `.plans/`, or `.testbed/`, so the requested repo-only folders remained out of Godot/editor indexing even though `.git/` still physically exists on disk in the installed checkout.

Runtime-prep verification also passed independently: from `../aerobeat-assembly-community`, I ran `python3 addons/aerobeat-input-mediapipe/python_mediapipe/prepare_runtime.py --platform linux-x64 --mode dev --create-venv --force --validate --json`. It exited `0` and returned `"validation_status": "venv_created"`, `"validation_errors": []`, and `"runtime_root": "/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/addons/aerobeat-input-mediapipe/python_mediapipe/assets/runtimes/linux-x64"`. The installed runtime tree now contains `runtime-manifest.json`, `.runtime-ready`, and `venv/` under `python_mediapipe/assets/runtimes/linux-x64/`, which confirms Linux dev-mode runtime preparation works from the installed consumer addon path.

Audit judgment: the physical installed `.git/` directory is a tooling caveat from GodotEnv materializing a Git checkout, not a blocker for this slice, because the requested acceptance condition was editor/index visibility and the independent cache check showed no `.git/` scan/index entries. Minor caveat: `python_mediapipe/__pycache__/` is visible in the filesystem cache, so if consumer tree tidiness beyond the requested hidden set matters later, that cache directory should be excluded or cleaned separately.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Replaced the over-broad addon-level hide with localized repo-only hide boundaries so assembly consumers now get a scanned/indexed MediaPipe addon tree where `src/` and `python_mediapipe/` are visible, repo-only folders stay out of the scanned editor tree, and the installed `python_mediapipe/prepare_runtime.py` helper can regenerate the Linux dev runtime directly from the consumer addon path.

**Reference Check:** `REF-01` satisfied: the validated consumer-visible payload exposes `src/` and `python_mediapipe/` while keeping repo-only folders out of Godot’s scanned/indexed tree. `REF-02` satisfied via the refreshed assembly investigation evidence showing the former whole-tree invisibility is gone after the owner-repo fix. `REF-03` satisfied via direct source-repo layout changes: root `.gdignore` removed, `python_mediapipe/.gdignore` removed, localized `.gdignore` markers added only under repo-only folders, and `python_mediapipe/assets/runtimes/.gdignore` retained. `REF-04` satisfied by fresh reinstall plus cache/runtime validation from `../aerobeat-assembly-community/addons/aerobeat-input-mediapipe/`.

**Commits:**
- `ea26670` - Fix addon selective visibility layout
- `4064bb9` - Record addon visibility validation

**Lessons Learned:** In Godot, `.gdignore` must live on the exact directories that should be hidden; using it at the addon root or at `python_mediapipe/` hides far more than intended. Also, consumer install tools can still leave `.git/` on disk even when Godot itself no longer scans/indexes that folder, so on-disk payload cleanliness and editor visibility are related but not identical concerns. Separate from the requested hidden set, installed Python cache folders like `python_mediapipe/__pycache__/` can still surface in Godot’s filesystem cache unless they are explicitly excluded or scrubbed during install.

---

*Completed on 2026-04-24*
