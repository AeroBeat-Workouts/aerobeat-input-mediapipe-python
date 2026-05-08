# AeroBeat MediaPipe Visible-Window Proving UI Layout Regression

**Date:** 2026-05-07  
**Status:** In Progress  
**Agent:** Pico 🐱‍🏍

---

## Goal

Fix the proving-scene UI so the observability/status panels are actually visible inside the real editor play window, not merely reachable in headless runtime layout math.

---

## Overview

The prior fix addressed a real vertical clipping problem by adding outer scrolling, but Derrick’s live screenshot proves that it did not solve the actual human-visible blocker. In the visible play window, the camera view still dominates the canvas and the observability UI is effectively pushed off or cut off horizontally. That means the prior QA/audit scope was incomplete because it relied on headless runtime geometry rather than visible desktop playback.

This retry slice must be stricter. Implementation needs to reproduce the problem against a real visible play window and fix the layout so both the camera/tracking surface and the right-side status UI coexist within the window Derrick is actually using. QA and audit must require visible-window evidence via desktop control and/or direct desktop screenshots, not just scene-tree inference.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Derrick screenshot showing visible-window failure | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/07/image-0211fb55.png` |
| `REF-02` | Boxing proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/boxing_proving.tscn` |
| `REF-03` | Flow proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/flow_proving.tscn` |
| `REF-04` | Shared proving harness script | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-05` | Prior partial fix commit | `20c7ab3` |

---

## Tasks

### Task 1: Reproduce and fix the visible-window UI layout regression

**Bead ID:** `oc-8gx`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Reproduce the proving-scene layout failure shown in Derrick’s screenshot using real visible playback evidence if possible, or the strongest truthful fallback plus screenshot-based reasoning if not. Fix the layout so the observability/status UI is actually visible in the play window alongside the camera/tracking view for both Boxing and Flow scenes. Use the smallest truthful fix, validate it, commit/push before handoff, and close the bead only if the implementation slice is genuinely done.

**Status:** ⏳ Pending

**Results:** Pending

---

### Task 2: QA the visible-window fix with desktop-visible evidence

**Bead ID:** `oc-eey`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Independently verify the fix using visible-window evidence. Prefer desktop control + screenshots or an actual Godot plugin/editor session. Do not certify success from headless geometry alone. Confirm that the status UI is visibly present and usable during playback for both scenes.

**Status:** ⏳ Pending

**Results:** Pending

---

### Task 3: Audit the final visible-window truth

**Bead ID:** `oc-aso`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Independently audit whether the revised fix actually resolves Derrick’s visible-window blocker. Keep the evidence bar honest: visible-window proof beats headless inference.

**Status:** ⏳ Pending

**Results:** Pending

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending

**Reference Check:** Pending

**Commits:**
- Pending

**Lessons Learned:** Pending

---

*Completed on Pending*
