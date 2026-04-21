# AeroBeat MediaPipe Python

**Date:** 2026-04-21  
**Status:** Complete  
**Agent:** Pico 🐱‍🏍

---

## Goal

Audit the current MediaPipe Python sidecar package after the AeroBeat repo refactor, repair the sidecar’s repo-owned capabilities from a Python-first baseline, and prepare a clean second phase for Godot/workbench validation.

---

## Overview

This repo is now truthfully positioned as a mixed package: a Python MediaPipe sidecar plus a Godot-facing addon/testbed shell. The immediate risk is that recent repo-shape and GodotEnv refactors may have left the Python runtime, repo docs, and repo-local validation surfaces out of sync even if the repo shape itself is cleaner. The right first move is to treat the Python sidecar as the source system under test and verify it independently from Godot: dependency boot, model-asset expectations, CLI/runtime behavior, UDP output contract, camera/video input handling, heartbeat shutdown, and any Python-only tests or benchmarks.

The repo scan already shows a few concrete red flags worth auditing early. The README still documents `aerobeat-core` paths in the GodotEnv manifest even though the workspace moved to `aerobeat-input-core`; `.testbed/tests/test_mediapipe_logic.gd` still loads `src/driver.gd`, which does not exist in the current repo; and there is no tracked `pose_landmarker_*.task` file in the repo root, so a full runtime pass will require either an existing local model asset or a deliberate prerequisite note. That makes this a good candidate for a strict coder → qa → auditor loop focused on separating true code regressions from missing prerequisites or stale documentation.

The execution strategy is phased. Phase 1 repairs and validates the sidecar independently from Godot. Phase 2 re-enters the hidden `.testbed/` Godot workbench only after the Python side is trustworthy. Any downstream assembly-community or broader Godot consumer wiring discovered during that work is explicitly out-of-scope for this repo and should be recorded as follow-on beads in the owning consuming repo instead of being silently absorbed here.

Session decisions captured for execution:
- move MediaPipe model assets from package root to `python_mediapipe/assets/models/`
- stop treating `.task` model files as external-only ignore artifacts; commit the required model assets into the repo unless size/testing proves that impractical
- move the repo-managed local Python environment location away from repo root / `.testbed/venv` and into `python_mediapipe/assets/venv/` or an equivalent sidecar-owned path
- remove docs/runtime assumptions that the user manually manages a separate Python environment
- important caveat to validate during implementation: a committed virtual environment is usually not portable across machines, so “sidecar owns its env” should likely mean repo-managed install location rather than a git-tracked venv blob unless cross-machine proof says otherwise

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Last-session handoff pointing at repo-first repair from current baseline | `memory/2026-04-20.md` |
| `REF-02` | Current repo contract / truthful runtime claims | `README.md` |
| `REF-03` | Python sidecar runtime entrypoint and protocol behavior | `python_mediapipe/main.py` |
| `REF-04` | Godot auto-start / dependency / model prerequisite behavior | `src/autostart_manager.gd` |
| `REF-05` | Godot UDP receive path and packet parsing expectations | `src/server/mediapipe_server.gd` |
| `REF-06` | Current workbench dependency manifest (watch for stale core-path naming) | `.testbed/addons.jsonc` |
| `REF-07` | Repo-local Godot test surface with stale script reference (`src/driver.gd`) | `.testbed/tests/test_mediapipe_logic.gd` |

---

## Tasks

### Task 1: Baseline repo audit and evidence capture

**Bead ID:** `oc-ydn`  
**SubAgent:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Audit `aerobeat-input-mediapipe-python` from the repo root and produce a concise evidence-based baseline report. Claim the bead on start. Verify current tracked layout, documented runtime contract, Python entrypoints, model prerequisites, repo-local tests, GodotEnv manifest paths, and any obviously stale or broken references introduced by recent refactors. Do not repair yet. Separate findings into: confirmed code bugs, stale docs/tests, missing local prerequisites, and likely out-of-scope downstream issues. Leave exact file paths and commands for follow-up. Do not close the bead until the report is complete.

**Folders Created/Deleted/Modified:**
- `/.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-21-sidecar-audit-and-repair.md`

**Status:** ✅ Complete

**Results:** Completed evidence-only audit. Confirmed stale `aerobeat-core` references in `.testbed/addons.jsonc` and `README.md`; confirmed broken test reference to `src/driver.gd` in `.testbed/tests/test_mediapipe_logic.gd`; confirmed no tracked `.task` assets exist; confirmed current runtime still anchors model lookup to bare/root paths; confirmed autostart currently relies on `.testbed/venv/` and hardcodes a Python 3.12 site-packages path. No repo changes were made during the audit.

---

### Task 2: Python-first sidecar validation matrix

**Bead ID:** `oc-coi`  
**SubAgent:** `coder`  
**References:** `REF-02`, `REF-03`  
**Prompt:** Starting from the current repo root, claim the bead and validate the MediaPipe sidecar independently from Godot. Exercise dependency/import checks, CLI help/arg parsing, Python-only tests, video-file execution path, optional camera path if available, UDP output format expectations, MJPEG stream behavior if owned by the sidecar, and heartbeat-driven shutdown. Record exact commands, pass/fail results, and whether failures are caused by code regressions, environment gaps, or missing model assets. Repair repo-owned Python/runtime issues discovered during this task, keeping docs/runtime truthful. Commit and push by default before handoff unless blocked by a missing prerequisite.

**Folders Created/Deleted/Modified:**
- `python_mediapipe/`

**Files Created/Deleted/Modified:**
- `python_mediapipe/main.py`
- `python_mediapipe/test_runner.py`
- `python_mediapipe/runtime_paths.py`
- `python_mediapipe/assets/models/pose_landmarker_lite.task`
- `python_mediapipe/assets/models/pose_landmarker_full.task`
- `python_mediapipe/assets/models/pose_landmarker_heavy.task`
- `python_mediapipe/assets/venv/.gdignore`
- `src/autostart_manager.gd`
- `src/process/mediapipe_process.gd`
- `.testbed/scenes/test_scene.gd`
- `README.md`
- `.gitignore`

**Status:** ✅ Complete

**Results:** Completed the runtime-contract repair in commit `6f81fc7` (`Repair MediaPipe sidecar runtime contract`). Model lookup moved to `python_mediapipe/assets/models/`; all three `.task` assets were committed there; repo-managed env ownership moved to `python_mediapipe/assets/venv/` without committing a machine-specific venv blob; docs/runtime assumptions about `.testbed/venv` and ad hoc user-managed envs were removed; and the previously misleading optimization flags (`--preprocess-size`, `--udp-batch-size`, `--use-roi`, `--roi-size`, `--roi-padding`) were wired into real runtime behavior. Validation covered Python compile/import checks, sidecar-owned venv install, direct video-based sidecar runs, test-runner passes, and headless workbench import/startup checks.

---

### Task 3: Repo-local validation surface repair

**Bead ID:** `oc-8ne`  
**SubAgent:** `coder`  
**References:** `REF-02`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Claim the bead and repair repo-local validation surfaces that no longer match the current repo shape. Focus on stale test/script references, truthful manifest paths, README instructions, and any workbench assumptions that are supposed to remain accurate even before downstream assembly integration. Do not broaden into assembly-community wiring. If a surface is intentionally partial, make it explicit rather than pretending it works.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `src/`

**Files Created/Deleted/Modified:**
- `.testbed/tests/test_mediapipe_logic.gd`
- `.testbed/addons.jsonc`
- `README.md`
- `.testbed/scenes/mediapipe_provider_test.gd`

**Status:** ✅ Complete

**Results:** Completed local manifest/doc/test repair across commits `11483dc` (`Repair local validation and docs surfaces`) and `2eebe52` (`Fix testbed MediaPipe provider script loading`). Updated `.testbed/addons.jsonc` to point at sibling repo `../../aerobeat-input-core` while preserving compatibility mount key `aerobeat-core`; updated `README.md` to describe the new sibling naming and compatibility path truthfully; repaired `.testbed/tests/test_mediapipe_logic.gd` to assert against `src/input_provider.gd` instead of stale `src/driver.gd`; and fixed `.testbed/scenes/mediapipe_provider_test.gd` by preloading `MediaPipeConfig` and `MediaPipeServer` explicitly and removing the unnecessary `class_name` collision. Validation showed GodotEnv restore/import succeeded and the workbench got past the prior provider parse blocker into actual local hookup.

---

### Task 4: Repo-local Godot workbench verification (Phase 2)

**Bead ID:** `oc-01y`  
**SubAgent:** `qa`  
**References:** `REF-02`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** After the Python-first repairs are in, claim the bead and verify the hidden `.testbed/` Godot workbench against the truthful repo contract. Restore addons, confirm the package mounts correctly from the repo root, verify dependency auto-install behavior, verify clear failure behavior when the `.task` asset is missing, and if the model prerequisite is satisfied verify local sidecar start + UDP receive + landmark flow in the workbench. Explicitly note what was validated without Godot, what was validated in Godot, and what still belongs to consuming repos.

**Folders Created/Deleted/Modified:**
- `.testbed/`

**Files Created/Deleted/Modified:**
- validation artifacts only if needed

**Status:** ✅ Complete

**Results:** QA rerun passed after fixing `.testbed/scenes/mediapipe_provider_test.gd`. Verified that the workbench no longer depends on `.testbed/venv`, that model/env resolution now points at `python_mediapipe/assets/{models,venv}`, and that headless workbench startup progresses into real local hookup: AutoStartManager passes dependency/model checks, sidecar launches, `MediaPipeServer` binds UDP, and `CameraView` starts streaming. Validation remains headless/timed rather than a long interactive session, but it is sufficient to pass the repo forward to audit.

---

### Task 5: Independent truth-check and closure

**Bead ID:** `oc-bwo`  
**SubAgent:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Claim the bead and independently truth-check the completed work against the repo contract and the evidence produced by coder/QA. Confirm the repaired sidecar can be described honestly in the README, that repo-local tests/instructions point at real files, that Godot phase claims are supported by evidence, and that any unresolved gaps are correctly scoped as prerequisites or downstream work instead of hidden defects. Close the bead only if the repo’s claims and actual behavior now match.

**Folders Created/Deleted/Modified:**
- none required

**Files Created/Deleted/Modified:**
- plan updates only if needed

**Status:** ✅ Complete

**Results:** Independent audit passed. Verified that stale local references were repaired truthfully, model assets moved to `python_mediapipe/assets/models/`, `.task` assets are committed in git, sidecar env ownership moved to `python_mediapipe/assets/venv/` without committing a machine-specific venv blob, docs no longer rely on `.testbed/venv` or ad hoc user-managed envs, optimization flags reflect actual runtime behavior, and the `.testbed` workbench now gets past the prior provider parse blocker into local hookup. Remaining caveat is fidelity only: verification is headless/timed rather than a long interactive gameplay session.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Repaired the AeroBeat MediaPipe Python sidecar repo so its runtime contract is truthful and repo-owned again. The repo now stores committed MediaPipe model assets under `python_mediapipe/assets/models/`, uses a sidecar-owned generated env location under `python_mediapipe/assets/venv/`, no longer depends on `.testbed/venv` as part of the contract, has truthful local docs/manifests/tests after the repo-family rename, and gets through headless workbench startup into real local hookup with the sidecar, UDP server, and camera stream.

**Reference Check:**
- `REF-01` handoff was satisfied: the repo was reopened from the new baseline and audited/repaired from repo-first truth.
- `REF-02` README/runtime contract now matches observed repo behavior.
- `REF-03` Python sidecar entrypoint now resolves committed model assets and uses the advertised optimization flags in real runtime paths.
- `REF-04` autostart now resolves the sidecar-owned env/model paths and no longer anchors to `.testbed/venv` / repo-root model assumptions.
- `REF-05` UDP receive path remained compatible and was validated through workbench startup/local hookup.
- `REF-06` workbench manifest now points truthfully at sibling `aerobeat-input-core` while preserving the compatibility mount key required by current runtime references.
- `REF-07` stale local test reference to `src/driver.gd` was removed in favor of real current files.

**Commits:**
- `11483dc` - Repair local validation and docs surfaces
- `6f81fc7` - Repair MediaPipe sidecar runtime contract
- `2eebe52` - Fix testbed MediaPipe provider script loading

**Lessons Learned:**
- The right split was: commit durable model assets, but do not commit a machine-specific venv blob.
- Repo-shape cleanup had left both stale documentation and a real workbench parse blocker; the coder → QA → auditor loop caught both.
- Headless/timed Godot verification is strong enough to prove startup/local hookup truth, but still not the same as a long interactive gameplay session.
- If Derrick wants fully bundled portable Python inside shipped builds, that should be treated as a separate packaging/distribution phase beyond the current repo-owned env cleanup.

---

*Completed on 2026-04-21*
