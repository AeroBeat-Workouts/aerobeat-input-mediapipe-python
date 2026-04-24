# AeroBeat MediaPipe Python

**Date:** 2026-04-23  
**Status:** In Progress  
**Agent:** Pico 🐱‍🏍

---

## Goal

Implement the first shipping-quality foundation for the unified desktop runtime architecture: generated, gitignored, unfrozen platform runtimes under `python_mediapipe/assets/runtimes/<platform>/`, with Godot resolving the correct runtime path explicitly instead of relying on a generic `assets/venv` assumption.

---

## Overview

The architecture decision is already locked in `.plans/mediapipe-python/2026-04-23-unified-unfrozen-platform-runtimes-decision.md`. The next step is implementation, but this needs to happen in a staged way because the current codebase still mixes runtime-path concerns, Linux-specific process behavior, and legacy documentation assumptions. The right first execution wave is to build the runtime contract and resolver foundation before we tackle deeper cross-platform process-management parity.

This plan keeps the work honest. Phase 1 establishes the runtime directory contract, manifest expectations, and `.gitignore` behavior. Phase 2 teaches Godot how to resolve the new runtime family and fail fast when the expected runtime is missing or malformed. Phase 3 tackles desktop process-management abstraction and the current Linux-specific lifecycle code. Phase 4 updates the repo docs/build guidance to match the implemented behavior. The repo should only claim the level of cross-platform support actually validated at each step.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Architecture decision for unified unfrozen platform runtimes | `.plans/mediapipe-python/2026-04-23-unified-unfrozen-platform-runtimes-decision.md` |
| `REF-02` | Prior planning doc rewritten around the unified runtime family | `.plans/mediapipe-python/2026-04-23-sidecar-runtime-path-and-cross-platform-unfrozen-plan.md` |
| `REF-03` | Current Godot auto-start/runtime resolution and Linux-specific lifecycle behavior | `src/autostart_manager.gd` |
| `REF-04` | Current process wrapper / sidecar lifecycle code | `src/process/mediapipe_process.gd` |
| `REF-05` | Current Python runtime path helper logic | `python_mediapipe/runtime_paths.py` |
| `REF-06` | Current repo contract / docs | `README.md` |
| `REF-07` | Current ignore rules for generated local runtime artifacts | `.gitignore` |

---

## Tasks

### Task 1: Implement the unified desktop runtime contract

**Bead ID:** `oc-3kc`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-05`, `REF-07`  
**Prompt:** Claim the bead on start. Implement the first runtime-contract layer for the unified desktop runtime system. Replace long-term `assets/venv` assumptions with platform-keyed runtime helpers rooted at `python_mediapipe/assets/runtimes/<platform>/`, define the minimum manifest/sentinel expectations in code and/or helper utilities, add or update runtime-preparation scaffolding as appropriate, and update `.gitignore` so generated desktop runtime contents are ignored. Keep the implementation truthful: do not pretend Windows/macOS runtime preparation is fully validated if it is not. Commit and push by default before handoff.

**Folders Created/Deleted/Modified:**
- `python_mediapipe/`
- `python_mediapipe/assets/`

**Files Created/Deleted/Modified:**
- `python_mediapipe/runtime_paths.py`
- `python_mediapipe/prepare_runtime.py`
- `python_mediapipe/assets/runtimes/.gdignore`
- `.gitignore`

**Status:** ✅ Complete

**Results:** Implemented the runtime-contract foundation in `python_mediapipe/runtime_paths.py` and new helper script `python_mediapipe/prepare_runtime.py`. The Python-side contract now defines supported desktop platform keys (`linux-x64`, `macos-x64`, `windows-x64`), canonical runtime roots under `python_mediapipe/assets/runtimes/<platform>/`, runtime-manifest and sentinel filenames, platform-correct Python executable resolution, requirements hashing, model-asset inventory capture, and a validation helper for the minimum manifest/sentinel expectations. Added `python_mediapipe/assets/runtimes/.gdignore` plus `.gitignore` rules so generated runtime contents are ignored while keeping the runtime root itself available. This pass kept the repo honest: the preparation helper supports contract scaffolding for all declared platform keys, but only host-platform venv creation is allowed, and no Windows/macOS runtime parity is claimed from this change. Validation for this phase was helper/path-level only: Python compilation, current-platform helper inspection, scaffold generation, and contract validation on a generated Linux runtime root. The work was committed before handoff in `Add unified desktop runtime contract foundation`.

---

### Task 2: Prepare the local linux-x64 dev runtime and retire the legacy `assets/venv`

**Bead ID:** `oc-02o`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Claim the bead on start. Using the new unified runtime tooling, prepare the local `python_mediapipe/assets/runtimes/linux-x64/` runtime in `dev` mode so the current Linux host has a real development runtime under the new contract. Then retire the legacy `python_mediapipe/assets/venv/` local environment now that it is no longer the preferred path. Keep the implementation truthful: only remove the legacy env after confirming the new linux runtime is present and validates; do not claim cross-platform runtime prep beyond the current host. Update docs/plan notes if active repo guidance still treats `assets/venv` as canonical local state. Commit and push by default before handoff.

**Folders Created/Deleted/Modified:**
- `python_mediapipe/assets/runtimes/linux-x64/`
- `python_mediapipe/assets/venv/` (removed locally after validation)
- `.testbed/scenes/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-23-unified-unfrozen-platform-runtimes-implementation.md`
- `README.md`
- `.testbed/scenes/test_scene.gd`
- `python_mediapipe/assets/venv/.gdignore` (deleted with the retired legacy local runtime)

**Status:** ✅ Complete

**Results:** Prepared the current host's real dev runtime under `python_mediapipe/assets/runtimes/linux-x64/` with `python_mediapipe/prepare_runtime.py --platform linux-x64 --mode dev --create-venv --validate`, installed `python_mediapipe/requirements.txt` into that runtime-local venv, and re-ran the contract validator so the linux runtime now exists with a live Python environment plus manifest/sentinel files under the new unified runtime contract. Validation stayed honest and Linux-only: the runtime-contract helper reported no validation errors, the new runtime Python successfully imported `mediapipe`, `cv2`, and `numpy`, and `python_mediapipe/test_filter.py` passed from the new runtime. After that confirmation, the legacy local `python_mediapipe/assets/venv/` directory was removed. Active tracked guidance that still treated `assets/venv` as canonical was updated for truthfulness in `README.md` and `.testbed/scenes/test_scene.gd`; those updates explicitly note that direct/manual local usage should now point at `assets/runtimes/linux-x64/` while Godot-side autostart/runtime resolution still needs its follow-on migration in Task 3. Commit/push details recorded below after handoff.

---

### Task 3: Implement Godot runtime resolution and fail-fast validation

**Bead ID:** `oc-49s`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-03`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Claim the bead on start. After the local linux-x64 dev runtime exists and the legacy `assets/venv` is retired, update Godot-side runtime resolution so the sidecar resolves platform-keyed desktop runtimes instead of a generic `assets/venv`. Add explicit platform-key derivation, editor/export-aware runtime mode handling where appropriate, platform-correct Python executable resolution, manifest/runtime validation, and controlled fail-fast behavior when the runtime is missing or invalid. Keep mobile excluded from this runtime path. Commit and push by default before handoff.

**Folders Created/Deleted/Modified:**
- `src/`
- `python_mediapipe/`

**Files Created/Deleted/Modified:**
- `src/autostart_manager.gd`
- related startup/runtime validation surfaces as needed
- `python_mediapipe/runtime_paths.py` if follow-on edits are needed

**Status:** ✅ Complete

**Results:** Completed in commit `cd85355` (`Resolve platform-keyed desktop sidecar runtimes`). `src/autostart_manager.gd` now derives an explicit desktop platform key, resolves `python_mediapipe/assets/runtimes/<platform>/`, picks the platform-correct Python executable (`venv/bin/python` vs `venv/Scripts/python.exe`), distinguishes dev/source-checkout runs from exported-template release mode, validates the runtime manifest/sentinel/model inventory before launch, and fails fast with clear preparation guidance instead of falling back to a random system Python or auto-creating a legacy venv. Mobile remains excluded from this desktop runtime path. As a related runtime consumer cleanup, `src/process/mediapipe_process.gd` now resolves the same platform-keyed runtime family and its dependency error messages no longer point at `assets/venv`. `README.md` was updated to match the new truthful startup/runtime behavior. Validation run for this coder pass: `python3 -m py_compile python_mediapipe/*.py`; `python3 python_mediapipe/prepare_runtime.py --platform linux-x64 --mode dev --validate`; `python_mediapipe/assets/runtimes/linux-x64/venv/bin/python python_mediapipe/test_filter.py`; `godot --headless --path .testbed --import`; and `godot --headless --path .testbed --quit`. Limitation: validation was performed on the local Linux dev runtime only; Windows/macOS path handling is scaffolded in code but not runtime-verified in this pass.

---

### Task 4: Refactor desktop sidecar process management for platform-aware runtime launching

**Bead ID:** `oc-7hq`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Claim the bead on start. After Task 2 lands, refactor the sidecar lifecycle/process code so runtime launch/stop behavior is explicitly platform-aware instead of Linux-only by assumption. Preserve Linux behavior where already proven, but isolate Linux-specific shell/process-group logic and introduce the structure needed for Windows/macOS-safe runtime launching and teardown. Be honest about what is scaffolded versus validated. Commit and push by default before handoff.

**Folders Created/Deleted/Modified:**
- `src/`

**Files Created/Deleted/Modified:**
- `src/process/mediapipe_process.gd`
- `src/autostart_manager.gd`
- `src/process/desktop_sidecar_launcher.gd`
- `src/runtime/desktop_sidecar_runtime.gd`
- `README.md`

**Status:** ✅ Complete

**Results:** Completed in commit `1a3950e` (`Refactor sidecar launchers for platform-aware runtimes`). Added shared Godot-side runtime resolution/validation in `src/runtime/desktop_sidecar_runtime.gd` so both `AutoStartManager` and direct `MediaPipeProcess` launches now enforce the same manifest/sentinel/platform/python/model contract before start. Added `src/process/desktop_sidecar_launcher.gd` to isolate the proven Linux detached shell + process-group launcher/teardown path from explicit macOS and Windows direct-PID scaffolding. `src/process/mediapipe_process.gd` now uses the shared runtime validator, resolves the sidecar entrypoint truthfully from the repo/addon package root, and launches through the platform-aware launcher instead of assuming Linux shell behavior everywhere. `src/autostart_manager.gd` now reuses the same shared runtime contract and launcher structure while keeping Linux-only cleanup patterns explicit. `README.md` was updated to document that direct `MediaPipeProcess` now shares runtime-contract validation and that macOS/Windows lifecycle branches are scaffolded, not host-validated. Validation run for this coder pass: `python3 -m py_compile python_mediapipe/*.py`; `python3 python_mediapipe/prepare_runtime.py --platform linux-x64 --mode dev --validate`; `python_mediapipe/assets/runtimes/linux-x64/venv/bin/python python_mediapipe/test_filter.py`; `godot --headless --path .testbed --import && godot --headless --path .testbed --quit`; `godot --headless --path .testbed -s /tmp/mediapipe_process_smoke.gd`; and `godot --headless --path .testbed -s /tmp/autostart_manager_smoke.gd`. Linux start/stop behavior was exercised successfully on this host for both direct `MediaPipeProcess` and `AutoStartManager`; macOS/Windows launch/teardown branches remain code-structured only and unverified here. One remaining nuance for QA: Linux teardown still logs an occasional "could not confirm termination after SIGKILL" warning even though follow-up `ps` checks on this host showed no lingering `python_mediapipe/main.py` processes after the smoke runs.

---

### Task 5: Update docs/build guidance to match the implemented runtime system

**Bead ID:** `oc-1sn`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-06`, `REF-07`  
**Prompt:** Claim the bead on start. After the runtime contract, resolver, and process-management changes land, update README and any relevant repo-local docs so they truthfully describe the unified desktop runtime system, generated runtime locations, preparation expectations, and current platform-validation status. Do not overclaim unsupported desktop parity. Commit and push by default before handoff.

**Folders Created/Deleted/Modified:**
- repo root
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `README.md`
- plan updates if needed

**Status:** ⏳ Pending

**Results:** Reserved.

---

## Final Results

**Status:** ⚠️ In Progress

**What We Built:** Tasks 1 through 4 are complete. The repo now has a unified desktop runtime-contract layer under `python_mediapipe/assets/runtimes/<platform>/`, a prepared `python_mediapipe/assets/runtimes/linux-x64/` dev runtime on this host, Godot-side fail-fast runtime resolution, and shared platform-aware launcher/runtime-validation helpers that keep Linux process-group behavior explicit while scaffolding macOS/Windows-safe launch and teardown paths. The legacy local `python_mediapipe/assets/venv/` directory has been retired. Remaining work is the final broader docs/build guidance pass in Task 5.

**Reference Check:**
- `REF-01` and `REF-02` are reflected in the new platform-keyed runtime contract and the prepared `linux-x64` runtime root.
- `REF-05` defines the runtime-manifest/sentinel/runtime-path expectations that were used to validate the prepared Linux runtime.
- `REF-06` was updated where active guidance still treated `assets/venv` as canonical for local/manual use.
- `REF-07` remains honored honestly: only the current host `linux-x64` runtime was prepared and validated in this pass; no Windows/macOS runtime parity is claimed.

**Commits:**
- `438a3aa` - Add unified desktop runtime contract foundation
- `68f0d22` - Prepare linux-x64 runtime and retire legacy sidecar venv
- `cd85355` - Resolve platform-keyed desktop sidecar runtimes
- `1a3950e` - Refactor sidecar launchers for platform-aware runtimes

**Lessons Learned:**
- The cleanest execution path is still staged: runtime contract first, live host runtime second, resolver third, process-management fourth, broader docs last.
- Retiring the legacy `assets/venv` before the Godot resolver migration is workable only if the tracked guidance explicitly says direct/manual Linux usage has moved to `assets/runtimes/linux-x64/` while autostart follow-on work is still pending.
- Immediate next session priority is Task 3 (`oc-49s`): migrate Godot-side autostart/runtime resolution to the new `assets/runtimes/<platform>/` contract and add controlled fail-fast validation before any deeper process-management refactor.

---

*Started on 2026-04-23*
