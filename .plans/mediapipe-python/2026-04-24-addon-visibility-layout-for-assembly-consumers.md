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

That means the fix should likely move from a single root ignore to a selective ignore layout owned by `aerobeat-input-mediapipe-python` itself. After that, we need to refresh the assembly install and verify that the editor shows the desired folders and still hides the repo-internal ones.

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
**Prompt:** Implement the smallest truthful fix in `aerobeat-input-mediapipe-python` so consumer repos show `src/` and `python_mediapipe/` under the addon while hiding repo-only folders. Refresh the assembly consumer install and record exact validation evidence. Commit/push by default.

**Folders Created/Deleted/Modified:**
- `src/`
- `python_mediapipe/`
- `.plans/mediapipe-python/`
- `../aerobeat-assembly-community/addons/`

**Files Created/Deleted/Modified:**
- ignore/layout files as needed
- `.plans/mediapipe-python/2026-04-24-addon-visibility-layout-for-assembly-consumers.md`
- `../aerobeat-assembly-community/.plans/2026-04-24-mediapipe-addon-editor-visibility-indexing-pass.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: QA/audit the consumer-visible addon tree in assembly

**Bead ID:** `oc-6b0`  
**SubAgent:** `primary`  
**Role:** `qa` / `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Independently verify that the refreshed assembly consumer install now shows `src/` and `python_mediapipe/` under the MediaPipe addon while keeping `.beads/`, `.git/`, `.github/`, `.plans/`, and `.testbed/` hidden. Close only if the evidence supports it.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-24-addon-visibility-layout-for-assembly-consumers.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending.

**Lessons Learned:** Pending.

---

*Completed on Pending*
