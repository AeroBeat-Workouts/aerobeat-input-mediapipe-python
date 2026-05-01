# aerobeat-input-mediapipe-python

**Date:** 2026-05-01  
**Status:** In Progress  
**Agent:** Chip 🐱‍💻

---

## Goal

Align `aerobeat-input-mediapipe-python` with the locked AeroBeat v1 downscope and keep it truthful as the official current PC-first camera gameplay input path.

---

## Overview

This repo is part of the AeroBeat input/platform downscope wave following the completed shell pass. The work here went beyond a light wording cleanup because the repo-local testbed still depended on stale external symlinks and transition-era `aerobeat-core` assumptions. The pass therefore covered repo truth surfaces plus enough runtime/testbed cleanup to keep the current path usable.

The target truth stayed narrow: **camera-only official gameplay input**, **Boxing + Flow official gameplay features**, and **PC community first**. Architecture can still remain modular and future-friendly, but the repo should not market non-camera parity, revive `aerobeat-core` as a hard dependency, or depend on dead machine-local paths.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Parent input/platform coordination plan | `/home/derrick/.openclaw/workspace/projects/openclaw-chip/.plans/2026-05-01-aerobeat-input-platform-downscope-pass.md` |
| `REF-02` | Downscoped docs source of truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-docs` |
| `REF-03` | Owning repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python` |

---

## Tasks

### Task 1: Audit and align repo truth

**Bead ID:** `aerobeat-input-mediapipe-python-2x0`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Claim the assigned bead, audit the repo against the downscoped AeroBeat docs truth, implement the required alignment changes, run relevant validation, commit/push to `main`, and leave concise QA handoff notes.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/`
- `python_mediapipe/`
- `src/`
- `tests/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-01-input-mediapipe-python-downscope-alignment.md`
- `.testbed/project.godot`
- `.testbed/src` (retargeted to repo-local relative symlink)
- `.testbed/python_mediapipe` (retargeted to repo-local relative symlink)
- `.testbed/addons/aerobeat-core` (removed stale external symlink)
- `.testbed/test/mediapipe_provider_test.gd`
- `README.md`
- `plugin.cfg`
- `python_mediapipe/main.py`
- `python_mediapipe/test_runner.py`
- `src/autostart_manager.gd`
- `src/process/mediapipe_process.gd`
- `src/providers/mediapipe_provider.gd`
- `tests/mediapipe_provider_test.gd`
- `tests/test_mediapipe_logic.gd`
- `tests/unit/test_mediapipe_process.gd`
- `tests/unit/test_mediapipe_provider.gd`
- `tests/unit/test_mediapipe_server.gd`

**Status:** ✅ Complete

**Results:**
- Updated repo messaging in `README.md` and `plugin.cfg` so this repo reads as the official current **PC-first camera gameplay input** path for AeroBeat v1, aligned with `REF-02` downscope truth.
- Removed stale hard dependency wording around `aerobeat-core` from runtime/test comments and testbed surfaces.
- Fixed the repo-local `.testbed/` to stop depending on dead external absolute symlinks and an obsolete `aerobeat-core` addon entry.
- Tightened `src/autostart_manager.gd` so venv and requirements resolution work from either the repo root runtime or the repo-local `.testbed` project, and removed the hardcoded Python 3.12 site-packages assumption.
- Corrected install/help messages to point at `python_mediapipe/requirements.txt`.
- Fixed stale test references (`src/driver.gd`) and packet-shape expectations in the standalone server test.
- Added minimal assertion stubs so the legacy GUT-shaped scripts parse without GUT present, while preserving them as future harness-facing tests rather than claiming they are the primary current validation path.
- Commit: `a43ff04` (`Align MediaPipe Python repo to PC camera v1 truth`)

---

## Final Results

**Status:** ✅ Complete

**What We Built:**
A truthful, repo-localized current-path pass for `aerobeat-input-mediapipe-python`: docs and metadata now describe the repo as the official current AeroBeat v1 PC camera input path; the testbed resolves local repo assets instead of stale machine-specific paths; and the runtime no longer assumes a hard `aerobeat-core` dependency or a hardcoded Python 3.12 venv layout.

**Reference Check:**
- `REF-01`: satisfied; repo treated as a keep-active/current-path repo, not a light pass.
- `REF-02`: satisfied; wording now matches the downscoped truth of **camera-only official gameplay**, **Boxing + Flow**, **PC community first**.
- `REF-03`: satisfied; changes stayed scoped to the owning repo and its local testbed/runtime surfaces.

**Validation:**
- ✅ `python3 -m venv venv && . venv/bin/activate && pip install -r python_mediapipe/requirements.txt`
- ✅ `. venv/bin/activate && python -m py_compile python_mediapipe/*.py`
- ✅ `. venv/bin/activate && python python_mediapipe/test_filter.py`
- ✅ `~/.local/bin/godot --headless --path .testbed --quit-after 2`
- ✅ `~/.local/bin/godot --headless --path .testbed --quit-after 5`
- ⚠️ Legacy standalone scripts under `tests/` and `tests/unit/` remain GUT-shaped / non-MainLoop scripts and are not the authoritative direct-run validation path yet; this pass made them parse more cleanly but did not redesign the harness architecture.

**Commits:**
- `a43ff04` - `Align MediaPipe Python repo to PC camera v1 truth`

**Lessons Learned:**
- The most dangerous drift in this repo was operational, not just textual: dead absolute symlinks and hardcoded venv paths made the “current path” look healthier than it really was.
- Repo-local testbeds need repo-local path resolution first; otherwise documentation truth and runtime truth diverge quickly.

**QA Handoff Notes:**
- Verify the repo-local `.testbed/` still behaves correctly in the editor, especially AutoStartManager startup/cleanup around real camera access.
- Treat `tests/` and `tests/unit/` as legacy harness work in need of a proper Godot/GUT entrypoint rather than proof of current end-to-end coverage.
- Smoke-check that README + plugin wording still matches the locked docs truth in `aerobeat-docs` for future downscope passes.

---

*Completed on 2026-05-01*
