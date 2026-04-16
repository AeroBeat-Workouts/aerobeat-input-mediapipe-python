# AeroBeat Input MediaPipe Python

**Date:** 2026-04-16  
**Status:** In Progress  
**Agent:** Pico 🐱‍🏍

---

## Goal

Inspect the stale OpenClaw-local path reference in the MediaPipe Python testbed scene and fix it so the file no longer points at an invalid or misleading workspace path.

---

## Overview

The rescan found one remaining active stale reference in `aerobeat-input-mediapipe-python/.testbed/test/test_scene.gd`, where the file still points at an old OpenClaw-local path under `/home/derrick/.openclaw/workspace/addons/...`. Based on Derrick's note, this likely reflects an older preproduction habit where agents dumped files into the workspace root instead of keeping them inside project repos.

The work here is intentionally narrow: inspect the file in context, determine whether the path should be corrected to a repo-owned location or replaced with an explicit invalid-path/TODO note, then validate that the resulting guidance is accurate and not misleading. The change should be repo-local, documented in the plan, and verified before handoff.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Target testbed file with stale path reference | `.testbed/test/test_scene.gd` |
| `REF-02` | Repo README and local setup context | `README.md` |
| `REF-03` | Current repo structure for MediaPipe Python | `.` |

---

## Tasks

### Task 1: Inspect the stale testbed path in context

**Bead ID:** `oc-6mn`  
**SubAgent:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Inspect `.testbed/test/test_scene.gd` and the surrounding repo structure to determine what the stale OpenClaw-local path was trying to reference, whether there is a correct repo-owned path it should point to now, and whether the right fix is replacement or an explicit TODO/invalidation note. Do not edit yet; return a concise recommendation.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-04-16-fix-testbed-stale-openclaw-path.md`

**Status:** ✅ Complete

**Results:** Inspection confirmed that the stale path in `.testbed/test/test_scene.gd` was old manual-recovery guidance intended to point users at the MediaPipe Python repo checkout so they could manually launch the Python sidecar after auto-start failure. There is a clear modern repo-owned replacement, so the recommended fix is replacement rather than a TODO/invalidation note: remove the stale absolute OpenClaw path and instead instruct the user to run `python3 python_mediapipe/main.py --camera 0 --show-window` from the `aerobeat-input-mediapipe-python` repo root. The inspection also noted broader local-path fragility inside `.testbed/` via absolute symlinks into another clone, but that is separate from this specific user-facing stale-path fix. Finally, the repo-root `CLAUDE.md` and `.claude/` created during bead/tool initialization were confirmed to be accidental fallout and should be removed during implementation.

---

### Task 2: Fix the stale path reference in the testbed file

**Bead ID:** `oc-kyy`  
**SubAgent:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Update `.testbed/test/test_scene.gd` to replace the stale OpenClaw-local path reference with the correct repo-owned path if one exists, or otherwise add a clear comment/TODO noting that the old path is invalid and needs cleanup. Keep the change minimal, validate the file remains coherent, and commit/push by default.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.testbed/test/test_scene.gd`
- `CLAUDE.md`
- `.claude/settings.json`
- `.plans/2026-04-16-fix-testbed-stale-openclaw-path.md`

**Status:** ✅ Complete

**Results:** Replaced the stale manual-recovery guidance in `.testbed/test/test_scene.gd` so it no longer points at an invalid OpenClaw workspace path. The file now instructs the user to open a terminal in the `aerobeat-input-mediapipe-python` repo root and run `python3 python_mediapipe/main.py --camera 0 --show-window`, which matches the repo-owned layout without baking in a machine-specific absolute path. During the same pass, the accidental tool-init fallout introduced during bead setup was removed by deleting the newly generated repo-root `CLAUDE.md` and `.claude/settings.json`. Validation confirmed the changed `_on_server_failed()` guidance block is coherent, the stale absolute path no longer appears in the active testbed file, and the accidental Claude integration artifacts are gone. The change was committed and pushed as `54ef9c3` (`Fix stale testbed recovery path guidance`).

---

### Task 3: QA the updated testbed guidance

**Bead ID:** `oc-r8t`  
**SubAgent:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Independently verify that the stale path reference was corrected appropriately and no misleading OpenClaw-local path remains in the active testbed file. Confirm the new wording is accurate for the repo's current layout.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-04-16-fix-testbed-stale-openclaw-path.md`

**Status:** ✅ Complete

**Results:** QA independently verified that `.testbed/test/test_scene.gd` no longer contains the stale absolute OpenClaw workspace path and now correctly instructs the user to open a terminal in the `aerobeat-input-mediapipe-python` repo root, run `python3 python_mediapipe/main.py --camera 0 --show-window`, and then press F5 in Godot to restart the scene. QA also confirmed that the accidental tool-init fallout is gone again: both the repo-root `CLAUDE.md` file and the `.claude/` directory are absent. No residual issues were found in this QA pass.

---

### Task 4: Audit completion

**Bead ID:** `oc-4hq`  
**SubAgent:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Audit the final fix. Confirm the stale path reference is no longer misleading, the repo now reflects current path expectations, and the change is appropriately scoped.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-04-16-fix-testbed-stale-openclaw-path.md`

**Status:** ✅ Complete

**Results:** Audit confirmed that the stale hardcoded OpenClaw workspace path was fully removed from the active testbed file and replaced with guidance that is appropriate for the repo's current layout: open a terminal in the `aerobeat-input-mediapipe-python` repo root and run `python3 python_mediapipe/main.py --camera 0 --show-window`. The auditor also confirmed that the accidental Claude integration artifacts created during bead setup were correctly removed, and that commit `54ef9c3` is present on `main` and pushed. The only remaining repo-local caveat is that this plan file itself was still untracked prior to handoff, which is being resolved by committing the plan now.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Fixed the stale manual-recovery guidance in `.testbed/test/test_scene.gd` so it no longer points at an invalid OpenClaw workspace path, and removed accidental `CLAUDE.md` / `.claude/` tool-init fallout from the repo.

**Reference Check:** `REF-01` now reflects repo-root-based recovery guidance rather than a machine-specific stale path; `REF-02` and `REF-03` support the conclusion that repo-root guidance is the correct modern expectation for this repo.

**Commits:**
- `54ef9c3` - Fix stale testbed recovery path guidance
- `Pending local commit` - Add completed plan for stale testbed path fix

**Lessons Learned:** Early AeroBeat preproduction left behind a few workspace-root assumptions that need targeted cleanup, but at this point the remaining active stale agentic/OpenClaw surface is very small. Also, Beads/Claude integration side effects can reintroduce repo-root `CLAUDE.md` / `.claude/` files during setup, so those need to be treated as accidental fallout under the current policy.

---

*Completed on 2026-04-16*
