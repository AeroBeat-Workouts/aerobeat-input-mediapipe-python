# AeroBeat MediaPipe Python

**Date:** 2026-04-23  
**Status:** Complete  
**Agent:** Pico 🐱‍🏍

---

## Goal

Document and lock a unified desktop runtime architecture for the MediaPipe Python sidecar that replaces the old generic `assets/venv` idea with generated, gitignored, platform-specific unfrozen runtimes under `python_mediapipe/assets/runtimes/<platform>/`.

---

## Overview

Earlier cleanup already removed the stale local `.testbed/venv` and confirmed that `python_mediapipe/assets/venv/` had become the truthful local desktop-side runtime location. That fixed the immediate repo confusion, but it was still only an intermediate architecture. A single `assets/venv` path is not a durable cross-platform design because Python environments, native wheels, executable layouts, and process-management behavior differ across Linux, macOS, and Windows.

This planning pass locks a cleaner target architecture: one **desktop-only runtime family** rooted at `python_mediapipe/assets/runtimes/`, with platform keys such as `linux-x64`, `macos-x64`, and `windows-x64`. These runtimes are generated, unfrozen, platform-specific, and gitignored. Development and exported desktop builds should use the same path family and the same conceptual runtime contract; they should differ by preparation mode, manifest validation, and startup behavior rather than by separate top-level path families.

This plan is intentionally honest about the current codebase: runtime/process behavior is still Linux-specific today. The work completed in this bead is documentation and planning only. No cross-platform runtime code was implemented here, and nothing in this plan claims that Windows/macOS support is already working.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Prior sidecar distribution decision draft | `.plans/mediapipe-python/2026-04-21-desktop-sidecar-distribution-decision.md` |
| `REF-02` | Prior repair plan that rejected treating a machine-specific venv as the portability answer | `.plans/mediapipe-python/2026-04-21-sidecar-audit-and-repair.md` |
| `REF-03` | Current repo contract / runtime docs still describing `assets/venv` as the truthful local state | `README.md` |
| `REF-04` | Current Godot auto-start runtime path resolution and Linux-oriented process logic | `src/autostart_manager.gd` |
| `REF-05` | Current Godot process wrapper with Linux-specific process-group handling | `src/process/mediapipe_process.gd` |
| `REF-06` | Current Python sidecar runtime path helpers | `python_mediapipe/runtime_paths.py` |
| `REF-07` | Architecture decision created in this bead | `.plans/mediapipe-python/2026-04-23-unified-unfrozen-platform-runtimes-decision.md` |

---

## Tasks

### Task 1: Draft the architecture decision for unified unfrozen platform runtimes

**Bead ID:** `oc-lt3`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Claim the bead on start. Draft a repo-local architecture decision doc that replaces the old generic `assets/venv` direction with a unified desktop runtime family under `python_mediapipe/assets/runtimes/<platform>/`. Cover why one universal venv will not work, why a separate `assets/venv` concept is no longer preferred, what “unfrozen platform-specific runtime” means, how dev vs release should differ by mode/manifest instead of top-level path family, how Godot should resolve runtimes, why mobile stays excluded, how fail-fast behavior should work, and the tradeoffs relative to a frozen sidecar. Be explicit that current code is still Linux-centric and that no cross-platform implementation is being claimed.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-23-unified-unfrozen-platform-runtimes-decision.md`

**Status:** ✅ Complete

**Results:** Created `REF-07`, an accepted architecture-decision record for the new unified desktop runtime system. The decision locks these key points: desktop runtimes live under `python_mediapipe/assets/runtimes/{windows-x64,macos-x64,linux-x64}/`; those runtime roots are generated, gitignored, unfrozen, and platform-specific; one generic shared venv is not the portability unit; `assets/venv` was only an intermediate cleanup step and is not the preferred long-term contract; dev and release should share the same path family while differing by preparation mode and manifest behavior; mobile remains on the native path; and runtime startup must fail fast if the expected platform runtime is missing or malformed. The decision also documents the current Linux-only assumptions in `src/autostart_manager.gd` and `src/process/mediapipe_process.gd` instead of pretending cross-platform support already exists.

---

### Task 2: Rewrite the implementation plan around the unified runtime family

**Bead ID:** `oc-lt3`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Update the active implementation plan so it no longer frames the work as `assets/venv` for dev versus some separate release layout. Replace that with a concrete phased plan for the unified `assets/runtimes/<platform>/` architecture. Include likely files to edit, expected runtime-manifest fields, `.gitignore` changes, platform-specific autostart/process-management work for Linux/macOS/Windows, and build/export integration expectations. Update the task/results/final-results sections truthfully for the documentation/planning work performed in this bead.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-23-sidecar-runtime-path-and-cross-platform-unfrozen-plan.md`

**Status:** ✅ Complete

**Results:** Rewrote this plan to match the new architecture. The plan now treats `python_mediapipe/assets/runtimes/<platform>/` as the single desktop runtime family and frames follow-on work as phased implementation rather than ambiguous exploration. Concrete next-step scope is captured below in the implementation outline: runtime path helper changes (`python_mediapipe/runtime_paths.py`), Godot runtime resolution and fail-fast behavior (`src/autostart_manager.gd`), process-launch abstraction and platform-specific stop/start logic (`src/process/mediapipe_process.gd` and related runtime launch code), README/doc updates, and `.gitignore` migration away from `assets/venv` assumptions toward generated `assets/runtimes/*` contents.

---

## Concrete Implementation Outline

### Phase 1: Runtime contract and manifest design

Likely files to edit:

- `python_mediapipe/runtime_paths.py`
- `src/autostart_manager.gd`
- `README.md`
- `.gitignore`
- new runtime-preparation script(s), likely under `python_mediapipe/` or `scripts/`

Define runtime keys and directory shape:

- `python_mediapipe/assets/runtimes/linux-x64/`
- `python_mediapipe/assets/runtimes/macos-x64/`
- `python_mediapipe/assets/runtimes/windows-x64/`

Expected manifest fields (minimum starting set):

- `schema_version`
- `mode` (`dev` or `release`)
- `platform_key`
- `os_family`
- `arch`
- `python_version`
- `requirements_hash`
- `prepared_at`
- `prepared_by` or `prepared_on`
- `entrypoint`
- `python_executable`
- `model_assets_version` or model-file inventory
- `packages` (selected pinned package versions)
- `validation_status`
- `notes` or `preparation_warnings`

Desired outcome:

- Godot and Python helper code can resolve a runtime root and validate that it matches the current desktop platform before launch.

### Phase 2: Runtime preparation tooling

Likely files to add/edit:

- new prep script(s), e.g. `python_mediapipe/prepare_runtime.py` or shell/PowerShell wrappers
- `python_mediapipe/runtime_paths.py`
- `.gitignore`
- `README.md`

Responsibilities:

- prepare a target platform runtime root
- create the platform-local env inside that runtime root
- install requirements
- verify committed `.task` model assets exist
- emit manifest and sentinel files
- support `dev` vs `release` preparation modes
- avoid implying that one prepared runtime can be copied cross-platform

`.gitignore` expectations:

- remove the special-case long-term emphasis on `python_mediapipe/assets/venv/`
- ignore generated contents under `python_mediapipe/assets/runtimes/*`
- if needed, keep allow-rules only for intentionally retained placeholders such as `.gdignore` or template marker files

### Phase 3: Godot runtime resolution and fail-fast startup

Likely files to edit:

- `src/autostart_manager.gd`
- possibly `src/input_provider.gd` or related startup surfaces if they own user-facing failure states
- `README.md`

Required behavior:

- detect desktop vs mobile first
- detect editor/dev vs exported desktop runtime
- derive platform key (`linux-x64`, `macos-x64`, `windows-x64`)
- resolve runtime root from `python_mediapipe/assets/runtimes/<platform>/`
- resolve platform-correct Python path (`bin/python` vs `Scripts/python.exe`)
- validate manifest and required files before launch
- emit clear errors and stop safely when runtime is missing/bad
- avoid ambiguous fallback to unrelated host Python in release mode

### Phase 4: Platform-specific process management

Likely files to edit:

- `src/autostart_manager.gd`
- `src/process/mediapipe_process.gd`
- possibly new helper modules for platform-specific launch/termination behavior

Current honest baseline:

- Linux logic relies on `/bin/bash`, `setsid`, `/bin/kill`, `pkill`, `fuser`, `/tmp`, `which`, `grep`, `DISPLAY`, and `xdpyinfo`

Required changes by platform:

- **Linux:** preserve or cleanly encapsulate current process-group strategy and display detection
- **macOS:** replace Linux shell/process assumptions with macOS-safe launch and termination behavior; verify camera/display/runtime permissions implications separately
- **Windows:** replace bash/process-group assumptions with Windows-native process creation and teardown strategy; resolve `Scripts/python.exe`; define how child-process cleanup and heartbeat shutdown are enforced

Goal:

- one abstract desktop sidecar lifecycle contract with platform-specific implementations underneath it

### Phase 5: Build/export integration

Likely files to edit:

- export/build docs in this repo
- possibly CI/build scripts in this repo or the owning export pipeline repo once identified
- `README.md`

Expectations to lock during implementation:

- exported desktop builds should know exactly how the correct platform runtime arrives
- release prep should validate manifest/platform before packaging
- the export pipeline should not silently package the wrong runtime root
- release mode should prefer pre-prepared/bundled runtimes over ad hoc first-run mutation unless that is later chosen deliberately

Open product-level question to preserve for later implementation:

- whether release artifacts bundle the prepared runtime directly or stage it through a broader build/export pipeline remains an implementation detail after this architecture, not a reason to split dev and release into separate top-level path families again

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Documentation only: an architecture decision plus a rewritten implementation plan for a unified desktop runtime system based on generated platform-specific runtimes under `python_mediapipe/assets/runtimes/<platform>/`.

**Reference Check:**
- `REF-01` and `REF-02` were carried forward honestly: prior cleanup proved that a stale `.testbed/venv` should go away and that a machine-specific venv blob is not the portability answer.
- `REF-03` through `REF-06` were used to keep the new decision grounded in the repo’s current state instead of inventing a finished cross-platform implementation.
- `REF-07` records the final architecture choice for this bead.

**Commits:**
- `458f031` - Document unified desktop sidecar runtimes

**Lessons Learned:**
- `python_mediapipe/assets/venv/` was a useful cleanup waypoint, but it is not the clean long-term portability contract.
- The right abstraction is a platform-keyed desktop runtime family, not a generic venv plus a separate release-only runtime tree.
- Cross-platform path design is the easy part; process management and fail-fast runtime validation are the real implementation work.

---

*Completed on 2026-04-23*