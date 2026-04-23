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

### Task 2: Implement Godot runtime resolution and fail-fast validation

**Bead ID:** `oc-49s`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-03`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Claim the bead on start. After Task 1 lands, update Godot-side runtime resolution so the sidecar resolves platform-keyed desktop runtimes instead of a generic `assets/venv`. Add explicit platform-key derivation, editor/export-aware runtime mode handling where appropriate, platform-correct Python executable resolution, manifest/runtime validation, and controlled fail-fast behavior when the runtime is missing or invalid. Keep mobile excluded from this runtime path. Commit and push by default before handoff.

**Folders Created/Deleted/Modified:**
- `src/`
- `python_mediapipe/`

**Files Created/Deleted/Modified:**
- `src/autostart_manager.gd`
- related startup/runtime validation surfaces as needed
- `python_mediapipe/runtime_paths.py` if follow-on edits are needed

**Status:** ⏳ Pending

**Results:** Reserved.

---

### Task 3: Refactor desktop sidecar process management for platform-aware runtime launching

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
- new helper modules if needed

**Status:** ⏳ Pending

**Results:** Reserved.

---

### Task 4: Update docs/build guidance to match the implemented runtime system

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

**What We Built:** Task 1 is complete: the repo now has a first runtime-contract layer for unified desktop runtimes under `python_mediapipe/assets/runtimes/<platform>/`, including Python-side platform-key helpers, manifest/sentinel definitions, runtime-validation utilities, preparation scaffolding, and ignore rules for generated runtime contents. Remaining phases still cover Godot runtime resolution, platform-aware process management, and README/build-doc updates.

**Reference Check:**
- `REF-01` and `REF-02` are reflected in the new platform-keyed runtime contract and generated runtime-root layout.
- `REF-05` now defines the minimum Python-side manifest/sentinel/runtime-path expectations for the new architecture.
- `REF-07` is honored honestly: this pass adds the contract foundation and scaffolding, not full Windows/macOS runtime validation.

**Commits:**
- `Add unified desktop runtime contract foundation`

**Lessons Learned:**
- The cleanest execution path is staged: runtime contract first, resolver second, process-management third, docs last.
- The foundation pass is most useful when it defines contract details and validation surfaces without overclaiming cross-platform runtime readiness.

---

*Started on 2026-04-23*
