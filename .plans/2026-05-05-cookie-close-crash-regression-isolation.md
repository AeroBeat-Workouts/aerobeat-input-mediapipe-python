# AeroBeat Cookie Close-Crash Regression Isolation

**Date:** 2026-05-05  
**Status:** Partial  
**Agent:** Pico 🐱‍🏍

---

## Goal

Reproduce and isolate the Cookie-side Zorin GUI crash that occurs when running the MediaPipe `.testbed` scene in Godot and then closing the running project from the editor, so we can determine whether this is a sidecar/autostart/camera teardown bug, a Godot editor/runtime close-path bug, or a lower-level desktop/driver/session interaction.

---

## Overview

Derrick confirmed that after unblocking the `.testbed` addon/runtime setup, the older Zorin GUI crash bug reappeared on Cookie when running the test scene and then closing the running project in the editor. That means the current blocker is no longer scene loadability; it is a close-path stability issue during real interactive use.

We already have useful prior evidence from earlier work: the old Python `os._exit(0)` shutdown path was real but not sufficient to explain the desktop reset by itself, and previous A/B work suggested the broader close path mattered more than that single suspect. Source: `memory/2026-04-28.md#L47-L63`, `memory/2026-04-28-zorin-gui-crash.md#L125-L169`. But this new reproduction is slightly different in an important way: it is happening from the Godot editor/testbed path rather than just the exported proof path, so we need fresh isolation instead of assuming the older conclusion maps 1:1.

This plan should move in narrow slices: first reproduce and capture the exact current close-path failure in the `.testbed` flow, then isolate whether the crash requires the MediaPipe runtime/sidecar/autostart path, and only then implement fixes. Because Derrick is actively syncing on Cookie, every landed change should be committed and pushed immediately for retest.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Prior close-crash memory summary | `/home/derrick/.openclaw/workspace/memory/2026-04-28.md` |
| `REF-02` | Prior detailed close-crash notes | `/home/derrick/.openclaw/workspace/memory/2026-04-28-zorin-gui-crash.md` |
| `REF-03` | Current runtime-regression fix plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-05-proving-scene-runtime-regression-fix.md` |
| `REF-04` | Desktop-control skill | `/home/derrick/.openclaw/workspace/skills/desktop-control/SKILL.md` |
| `REF-05` | MediaPipe test scene path(s) in `.testbed` | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/` |

---

## Tasks

### Task 1: Reproduce and capture the current Cookie close-crash path

**Bead ID:** `oc-kji`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-04`, `REF-05`  
**Prompt:** Reproduce the current Cookie-side close-crash path from the Godot editor/testbed flow as faithfully as possible. Capture exactly what scene was run, what close action was taken, what logs/state changes occurred, and whether the failure still looks like a full desktop/session crash, an editor crash, a GPU/X11 path, or something narrower. Use desktop-control-assisted validation if it provides truthful evidence. Claim the bead at start and close it only when the reproduction evidence is concrete.

**Folders Created/Deleted/Modified:**
- plan/notes only unless capture artifacts need a documented home

**Files Created/Deleted/Modified:**
- plan updates / notes only in this slice

**Status:** ✅ Complete

**Results:** Local bounded reproduction completed, but it did not reproduce the crash on this machine. Using the absolute engine path `/home/derrick/.local/share/openclaw/godot/current/godot` (which resolved to Godot 4.6.2 stable), both a runtime pass on `test_scene.tscn` and an editor pass on `.testbed` closed cleanly with exit code `0` under an X11-path forensic harness. The repro directories under `.temp/oc-kji-local-repro/` captured Godot logs, screenshots, journal output, app exit state, and sidecar logs. Useful caveat: the close was exercised via `wmctrl -ic`, which produced Mutter warnings about synthetic close requests, so it is a strong bounded probe but not perfect titlebar-click parity. Most important result: the suspected version delta collapsed because this local clean run was already on Godot 4.6.2; the major obvious remaining environment difference is Cookie’s NVIDIA/Zorin stack.

---

### Task 2: Isolate the triggering teardown path

**Bead ID:** `oc-g1w`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-04`, `REF-05`  
**Prompt:** Design and execute the narrowest truthful A/B isolation for the current editor/testbed close path. Determine whether the crash requires the MediaPipe sidecar/runtime/autostart path, the camera preview path, or merely running/closing a Godot test scene in the editor. Reuse prior evidence, but do not assume the old exported-build result is sufficient for this new testbed/editor reproduction.

**Folders Created/Deleted/Modified:**
- same owning repo paths as needed for isolation notes or small temporary test helpers

**Files Created/Deleted/Modified:**
- only the minimal files needed for truthful isolation

**Status:** ⏳ Pending

**Results:** Pending

---

### Task 3: Implement the smallest fix supported by the isolation evidence

**Bead ID:** `oc-tf1`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-05`  
**Prompt:** Once the triggering teardown path is isolated, implement the smallest fix that matches the evidence. Do not paper over the issue with broad refactors. Validate, commit, and push before handoff.

**Folders Created/Deleted/Modified:**
- exact code paths implicated by the isolation result

**Files Created/Deleted/Modified:**
- to be filled once the root cause is known

**Status:** ⏳ Pending

**Results:** Pending

---

### Task 4: QA and audit the close-path fix

**Bead ID:** `oc-e10`  
**SubAgent:** `primary` (for `qa` then `auditor` workflow roles)  
**Role:** `qa` then `auditor`  
**References:** `REF-01`, `REF-02`, `REF-04`, `REF-05`  
**Prompt:** Independently verify the close-path fix and certify only what was actually proven. Distinguish editor-path proof from exported-build proof, and distinguish “no longer obviously crashes” from “root cause actually isolated.”

**Folders Created/Deleted/Modified:**
- same owning repo paths as implementation

**Files Created/Deleted/Modified:**
- plan/notes only unless a truth fix is required

**Status:** ⏳ Pending

**Results:** Pending

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** We established a clean local baseline for the close path and narrowed the environment deltas. The `.testbed` runtime/editor close path did not reproduce the crash locally, and that local repro was already running on Godot 4.6.2 stable. This materially shifts suspicion away from a simple version mismatch and toward Cookie-specific environment factors, with the NVIDIA/Zorin stack now the strongest obvious remaining delta.

**Reference Check:** `REF-01` and `REF-02` were used as prior truth only, not blindly inherited. The new editor/testbed-path local repro did not support claiming a universal repo bug. Deliberate gap: the actual triggering teardown path on Cookie remains unisolated, so the plan stays open for a future Cookie-side A/B run.

**Commits:**
- none yet in this slice; work stayed at reproduction/forensics stage

**Lessons Learned:** A clean local non-repro on the same Godot major/minor version is meaningful. Before chasing invasive code fixes, we need higher-fidelity Cookie-side isolation with compositor/titlebar-equivalent close behavior and stronger environment-delta evidence.

---

*Completed on 2026-05-05 (partial; Cookie-side isolation still pending)*
