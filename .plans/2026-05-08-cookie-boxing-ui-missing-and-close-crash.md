# AeroBeat MediaPipe Python — Cookie Boxing UI Missing and Close Crash

**Date:** 2026-05-08  
**Status:** Draft  
**Agent:** Pico 🐱‍🏍

---

## Goal

Truthfully isolate why Cookie still hides the right-side proving UI during Boxing playback and why stopping playback now consistently crashes Cookie’s Zorin GUI.

---

## Overview

Today’s in-person Cookie retest produced two high-value truths. First, the Boxing proving scene still does not visibly show the expected right-side debug/observability panels during actual playback; Derrick only sees the camera feed plus some left-side text. That means the earlier layout/observability fixes improved source structure and some local validation evidence, but they did **not** yet solve the real human-visible Boxing playback problem on Cookie.

Second, Cookie’s Zorin GUI now crashes consistently when stopping playback of the project. Derrick reproduced that twice. That is stronger evidence than the earlier non-blocking `BadWindow` caveat and means the close-path investigation is back in the critical path. We need to separate whether the visible-UI failure and the GUI crash share one runtime cause or merely happen in the same retest path.

This plan keeps the two issues explicitly split but coordinated: (1) re-truth the Boxing visible UI failure using current scene/runtime structure and real window evidence, and (2) capture a clean close-crash forensic pass on Cookie so we can compare today’s stronger failure shape against the older export/editor isolation history. No approximate claims: visible UI must be visible, and close behavior must be measured against the actual Cookie desktop outcome.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Prior active Cookie coordination plan and retest ladder | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/.plans/2026-05-06-cookie-exported-app-close-control-check.md` |
| `REF-02` | Current proving-scene human verification context | `/home/derrick/.openclaw/workspace/memory/2026-05-07.md` |
| `REF-03` | Prior handoff that left in-person Cookie truthing as the remaining step | `/home/derrick/.openclaw/workspace/memory/2026-05-06.md` |
| `REF-04` | Boxing proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/boxing_proving.tscn` |
| `REF-05` | Flow proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/flow_proving.tscn` |
| `REF-06` | Shared proving harness | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-07` | Docs-backed design-size/stretch correction plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-07-godot-doc-backed-proving-ui-structure-correction.md` |
| `REF-08` | Earlier close-crash evidence showing sidecar forced-exit fix was not root cause | `/home/derrick/.openclaw/workspace/memory/2026-04-28.md` |
| `REF-09` | Earlier close-crash session transcript / forensic checkpoint | `/home/derrick/.openclaw/workspace/memory/2026-04-28-zorin-gui-crash.md` |
| `REF-10` | Today’s direct human report: right-side UI still missing and Zorin GUI crashes consistently on stop | current session |

---

## Tasks

### Task 1: Re-truth the Boxing visible UI failure on Cookie using real playback evidence

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-02`, `REF-04`, `REF-06`, `REF-07`, `REF-10`  
**Prompt:** Read the current Boxing proving scene, harness, and recent layout-fix history, then compare that to Derrick’s current Cookie report that the right-side UI is still missing during real playback. Identify the most likely failure surface before code changes: scene layout collapse, runtime replacement/layout loss, project stretch/content-scale behavior, or scene/run-path mismatch. Use real visible-window evidence requirements in your reasoning and prepare the narrowest next implementation target.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/`

**Files Created/Deleted/Modified:**
- This plan file unless deeper implementation is explicitly required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 2: Fix the real right-side Boxing UI visibility bug at the owning source

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-10`  
**Prompt:** After the research pass identifies the real failure surface, implement the smallest truthful fix in the owning `aerobeat-input-mediapipe-python` source so the right-side proving UI is visibly present during actual Boxing playback on Cookie. Do not certify based on headless geometry alone. Commit/push before handoff and leave exact validation notes.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/`

**Files Created/Deleted/Modified:**
- `/.testbed/scenes/boxing_proving.tscn`
- `/.testbed/scenes/flow_proving.tscn` (if shared fix is needed)
- `/.testbed/scripts/proving_harness.gd`
- any directly owning project display/layout config if required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: QA the visible Boxing/Flow UI on the real Cookie playback path

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-10`  
**Prompt:** Independently verify on the highest-fidelity available Cookie playback path that the right-side observability UI is actually visible and legible during Boxing and Flow scene playback. Distinguish visible-window truth from headless or structural-only checks.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Capture today’s Cookie stop-playback GUI crash with a clean forensic pass

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-08`, `REF-09`, `REF-10`  
**Prompt:** Reconstruct the strongest current close-crash evidence path for Cookie now that Derrick reports consistent Zorin GUI crashes on stop-playback. Use the prior forensic history to avoid repeating disproven theories, and set up the narrowest clean evidence capture for today’s playback-stop crash so we can compare it against the older sidecar/export/editor boundaries.

**Folders Created/Deleted/Modified:**
- `.plans/`
- forensic/log capture folders as needed

**Files Created/Deleted/Modified:**
- plan updates and any forensic notes/scripts only as required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 5: Audit whether the stop-playback crash belongs to the current proving-scene path or a broader Cookie desktop failure

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-08`, `REF-09`, `REF-10`  
**Prompt:** Independently audit the latest close-crash evidence and decide what is actually proven: whether today’s failure is the same family as the earlier Cookie desktop reset, whether it is stronger than the prior non-blocking `BadWindow` note, and what exact next isolation branch should follow.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates and audit notes only

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending

**Lessons Learned:** Pending.

---

*Completed on Pending*
