# AeroBeat MediaPipe Python Final Migration Pass

**Date:** 2026-04-20  
**Status:** Draft  
**Agent:** Pico 🐱‍🏍

---

## Goal

Complete the dedicated repo-specific migration pass for `aerobeat-input-mediapipe-python` so its GodotEnv/testbed/runtime/docs state is truthful, internally coherent, and ready for the normal coder → QA → auditor loop.

---

## Overview

Yesterday’s family-wide migration wave intentionally left `aerobeat-input-mediapipe-python` for a dedicated final pass because this repo is not just another straightforward Godot addon migration. It has mixed legacy testbed state, a Python sidecar runtime, repo-local install/docs expectations, and a direct relationship with `aerobeat-assembly-community` that makes “just apply the same pattern everywhere” too risky. The plan here is to treat this repo as first-class direct work and resolve the remaining migration truthfully rather than force parity where the repo shape does not actually match the rest of the family.

The execution should start with a repo-specific audit that distinguishes pre-existing local dirt from migration-required work, then move through implementation, QA, and independent audit. The implementation pass should preserve honest documentation about what is and is not currently specified, especially around the Python runtime and installation flow. If the work reveals assembly-community follow-on requirements, those should be captured explicitly rather than silently folded into this repo’s scope.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Prior integration/source-of-truth architecture notes for this repo family | `.plans/INTEGRATION-ARCHITECTURE.md` |
| `REF-02` | Current repo README and user-facing install/runtime guidance | `README.md` |
| `REF-03` | Prior narrow cleanup plan in this repo | `.plans/2026-04-16-fix-testbed-stale-openclaw-path.md` |
| `REF-04` | Session handoff describing why this repo was deferred for dedicated treatment | `memory/2026-04-19.md` |
| `REF-05` | Current repo working tree / file layout | `.` |

Use these references to keep the migration honest. Exact parity with other repos is not required where this repo’s Python sidecar/runtime shape differs, but any deliberate deviations must be documented explicitly.

---

## Tasks

### Task 1: Audit the repo-specific migration gap

**Bead ID:** `oc-0ho`  
**SubAgent:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-05`  
**Prompt:** Audit `aerobeat-input-mediapipe-python` as a dedicated migration target. Identify the remaining migration gap between the current repo state and the intended GodotEnv-era conventions, explicitly separating (a) required repo-local migration work, (b) pre-existing unrelated local dirt, and (c) follow-on issues that belong in another repo such as `aerobeat-assembly-community`. Return a concise action list with evidence, and do not edit files yet.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-04-20-mediapipe-python-final-migration-pass.md`

**Status:** ✅ Complete

**Results:** The research audit found five repo-local migration gaps that belong to this repo: (1) the addon entrypoint promised by the architecture docs is missing because `input_provider.gd` is absent and `plugin.cfg` does not declare a `script="input_provider.gd"` entry; (2) `src/providers/mediapipe_provider.gd` still extends `Node` and its lifecycle/signature surface does not match the intended `AeroInputProvider` contract, so implementation must either complete that migration or explicitly document a narrower supported stance; (3) `README.md` contains stale install/runtime guidance, including a missing `./install_deps.sh`, an incorrect root-level `requirements.txt` reference, and repo-root test-video examples that do not exist; (4) the tracked `.testbed` layout is not self-consistent on this machine because committed symlinks point at dead absolute `/home/derrick/Documents/GitHub/AeroBeat/...` paths; and (5) `.testbed/project.godot` references `res://icon.svg` but `.testbed/icon.svg` is missing. The audit also separated unrelated local dirt from migration-owned work: deleted `.gd.uid` files, deleted tracked `.testbed/videos/*`, untracked `.testbed/assets/videos/*`, and an untracked install-progress UID. Assembly-side provider registration and consumer wiring remain follow-on work owned by `aerobeat-assembly-community`, not something to hide inside this repo bead. Recommended action list: add/restore the addon entrypoint, resolve the provider-contract stance truthfully, fix README/install commands to match reality, replace absolute `.testbed` symlinks with a portable repo-local layout, resolve the missing testbed icon/reference issue, and decide whether `.testbed/videos` or `.testbed/assets/videos` is the canonical tracked test fixture location before normalizing references.

---

### Task 2: Implement the final repo-specific migration pass

**Bead ID:** `oc-pzu`  
**SubAgent:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-05`  
**Prompt:** Implement the repo-local changes required to complete the dedicated final migration pass for `aerobeat-input-mediapipe-python`. Keep the repo honest about the Python sidecar/runtime/install state, update GodotEnv/testbed/docs/config/layout as needed, avoid masking unresolved external issues, run all relevant repo-local validation available, then commit and push by default before handoff.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `.testbed/addons/`
- `.testbed/assets/`
- `python_mediapipe/`
- `src/`

**Files Created/Deleted/Modified:**
- `input_provider.gd`
- `plugin.cfg`
- `README.md`
- `.testbed/addons/aerobeat-core`
- `.testbed/python_mediapipe`
- `.testbed/src`
- `.testbed/icon.svg`
- `.testbed/assets/videos/boxing.mp4`
- `.testbed/assets/videos/female_boxer.mp4`
- `.testbed/assets/videos/group_dance.mp4`
- `.testbed/assets/videos/hiphop_dance.mp4`
- `.testbed/assets/videos/punching_bag.mp4`
- `.testbed/assets/videos/shadow_boxing.mp4`
- `.testbed/assets/videos/test_videos.py`
- `python_mediapipe/args.py`
- `python_mediapipe/main.py`
- `python_mediapipe/test_runner.py`
- `src/autostart_manager.gd`
- `src/process/mediapipe_process.gd`

**Status:** ✅ Complete

**Results:** Initial implementation landed in commit `a898033` (`Finish MediaPipe Python migration cleanup`) and was pushed to `main`, then QA found a real adapter-load blocker and the coder completed a targeted retry in commit `774117a` (`Fix addon-mounted MediaPipe adapter loading`), also pushed to `main`. Across those two passes, the coder restored the repo’s addon entrypoint by creating root `input_provider.gd` and wiring `plugin.cfg` to `script="input_provider.gd"`; rewrote the README so install/runtime instructions match the actual repo shape; made the testbed portable with relative repo-local links and `.testbed/icon.svg`; canonicalized test fixtures under `.testbed/assets/videos/`; and updated stale install/help text in Python/Godot-side messages to point at the real requirements path. To resolve the QA blocker without overclaiming parity, the retry made the root adapter and its dependency chain load from script-local paths so the addon now works when mounted under `res://addons/aerobeat-input-mediapipe-python/` in a consuming project, while preserving repo-local testbed use. The retry also tightened `.testbed/test/test_scene.gd` manual recovery guidance so it now mentions the repo-root `pose_landmarker_full.task` prerequisite and using `.testbed/venv/bin/python` or an equivalent environment with `python_mediapipe/requirements.txt` installed. Validation across the implementation passes reported: `python3 -m py_compile python_mediapipe/*.py` passed; `git diff --check --cached` / `git diff --check` passed; headless Godot testbed startup reached the repo’s truthful current blocker of a missing repo-root `pose_landmarker_full.task`; the system-Python filter test failed with `ModuleNotFoundError: numpy`, which honestly reflects the host environment; the repo-local `.testbed/venv/bin/python python_mediapipe/test_filter.py` passed; and the coder explicitly verified that a consuming-project-style addon mount could load and instantiate `res://addons/aerobeat-input-mediapipe-python/input_provider.gd`. Orchestrator spot-checks confirmed the retry commit exists on `main`, the adapter now uses script-local loading, and the worktree remains clean aside from the intentionally uncommitted active plan file.

---

### Task 3: Verify the migrated repo end-to-end

**Bead ID:** `oc-sap`  
**SubAgent:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-05`  
**Prompt:** Independently verify the final repo-specific migration outcome for `aerobeat-input-mediapipe-python`. Confirm the repo’s docs/config/testbed/runtime guidance are internally coherent, the claimed validation actually ran and makes sense, and any unresolved assembly-community follow-on items are documented rather than hidden.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-04-20-mediapipe-python-final-migration-pass.md`

**Status:** ✅ Complete

**Results:** QA initially failed on a real addon-load blocker, then passed after the targeted retry landed in commit `774117a`. The retry fixed the assembly-load issue by making the root adapter resolve dependencies from its own script directory instead of hardcoded repo-root `res://src/...` paths, and the testbed recovery text was tightened to mention the repo-root `pose_landmarker_full.task` prerequisite plus the expected `.testbed/venv/bin/python` or equivalent environment with `python_mediapipe/requirements.txt` installed. QA re-verified the corrected state and confirmed: `plugin.cfg` points at root `input_provider.gd`; the adapter now uses script-local dependency loading; README/runtime/testbed guidance is internally coherent with current repo reality, including canonical `.testbed/assets/videos/`, `.task` expectations, and assembly-community follow-on ownership; and the portable `.testbed` links remain correct. QA reran validation and confirmed `python3 -m py_compile python_mediapipe/*.py` passes, system Python still fails `python3 python_mediapipe/test_filter.py` with `ModuleNotFoundError: numpy` in a way that matches the documented host-environment limitation, the repo-local `.testbed/venv/bin/python python_mediapipe/test_filter.py` passes, and `godot --headless --path .testbed --quit` reaches the truthful blocker `Missing MediaPipe model asset: pose_landmarker_full.task`. QA also verified the consuming-project case directly: a temporary headless Godot project mounting both `addons/aerobeat-input-mediapipe-python` and `addons/aerobeat-core` successfully loaded and instantiated `res://addons/aerobeat-input-mediapipe-python/input_provider.gd`. The only remaining note was non-blocking startup noise from the provider’s `_server` child lookup before fallback creation, which does not block addon loading or migration completion.

---

### Task 4: Independent completion audit

**Bead ID:** `oc-5x8`  
**SubAgent:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-05`  
**Prompt:** Audit the final state of `aerobeat-input-mediapipe-python` after implementation and QA. Truth-check the repo against the plan, the actual diff, and the validation evidence. Confirm whether this repo’s migration pass is actually complete, and if not, identify the remaining gap precisely. Close the bead only if the work is truly done.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-04-20-mediapipe-python-final-migration-pass.md`

**Status:** ✅ Complete

**Results:** The auditor truth-checked the final repo state against the plan, the two implementation commits (`a898033` and `774117a`), the current file layout, and the validation evidence, then closed the audit bead as complete. Audit confirmed that the root addon entrypoint exists and is wired correctly through `plugin.cfg`, that `input_provider.gd` can actually load and instantiate in a consuming-project addon mount alongside `aerobeat-core`, that the README/install/runtime guidance is materially truthful, that the `.testbed` layout is now portable/coherent, and that canonical test fixtures under `.testbed/assets/videos/` are consistent with the repo’s tracked references. The auditor also confirmed that unresolved items are documented instead of hidden: missing repo-root `pose_landmarker_full.task` remains an honest local prerequisite, missing system-Python packages remain an honest host-environment prerequisite, and assembly-community registration/wiring remains explicit follow-on work owned elsewhere. The only remaining issue noted was non-blocking Godot startup noise from the provider probing for a missing `MediaPipeServer` child before fallback creation; the auditor judged that as cleanup-worthy later, but not a closure blocker for this migration pass.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Completed the dedicated final migration pass for `aerobeat-input-mediapipe-python` by restoring a truthful root addon entrypoint, making that entrypoint actually loadable in a consuming-project addon mount, rewriting docs/install/runtime guidance to match reality, converting the `.testbed` layout to portable repo-local links, adding the missing testbed icon, and normalizing canonical test fixtures under `.testbed/assets/videos/`. The repo now honestly presents itself as partially migrated: lifecycle/polling adapter support is in place, but full contract parity and assembly-consumer wiring remain separate future work rather than hidden assumptions.

**Reference Check:** `REF-01` is now satisfied at the repo-entrypoint level with a real root addon entrypoint and clearer contract stance, while still documenting the intentionally narrow scope instead of pretending full parity. `REF-02` now matches the real repo layout and runtime/install expectations, including the actual `python_mediapipe/requirements.txt` path and manual `.task` prerequisite. `REF-03` remains consistent with the earlier stale-path cleanup and is extended by more truthful testbed recovery guidance. `REF-05` now reflects a portable `.testbed` layout and current canonical asset locations. Deliberate deviations from ideal family parity are explicitly documented rather than hidden.

**Commits:**
- `a898033` - Finish MediaPipe Python migration cleanup
- `774117a` - Fix addon-mounted MediaPipe adapter loading
- `Pending local commit` - Add completed final migration pass plan

**Lessons Learned:** This repo needed direct treatment because the Python sidecar/testbed shape made blind family-wide migration rules too coarse. The coder → QA → retry → re-QA → audit loop paid off: QA caught a real consuming-project addon-path bug that a repo-root-only pass would have missed. Also, truthful prerequisites such as local `.task` assets or host Python dependencies should be documented as prerequisites, not mislabeled as unfinished migration work.

---

*Completed on 2026-04-20*
