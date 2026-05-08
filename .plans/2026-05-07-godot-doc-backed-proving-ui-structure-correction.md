# AeroBeat Godot Doc-Backed Proving UI Structure Correction

**Date:** 2026-05-07  
**Status:** In Progress  
**Agent:** Pico 🐱‍🏍

---

## Goal

Compare the proving scenes against current Godot 4 UI/2D documentation, then correct the scene structure so the webcam/2D content and the on-screen proving UI are composed using the intended Godot layering/layout model during playback.

---

## Overview

Derrick explicitly redirected this debugging slice away from guesswork and toward current Godot documentation. That correction matters. The proving scenes have been debugged as if the issue were only container sizing, but Derrick’s reading is that the scene is missing necessary runtime setup for rendering a proper on-screen GUI during playback — the kind of separation Godot typically uses between world/canvas content and HUD/UI content.

Current repo inspection shows the proving scenes are rooted at a full-screen `Control` with everything — webcam surface, overlays, and right-side observability panels — living inside a single container tree. There is no `CanvasLayer`, no `Camera2D`, and no project-level stretch/content-scale configuration visible in `.testbed/project.godot`. Current Godot docs indicate that `Control` + containers are the standard way to build UI, `CanvasLayer` is used to draw UI/HUD independently of the default 2D canvas, and `Camera2D` controls scrolling of the 2D world canvas rather than the UI itself. This suggests we should compare the proving scene against the docs-backed pattern for “world/canvas content plus HUD” instead of continuing to treat everything as one container layout.

This slice will document the comparison explicitly, then use a coder → QA → auditor loop to implement the smallest truthful scene correction that aligns with the intended Godot model and proves visible playback behavior on desktop.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Godot 4.6 Multiple resolutions docs | `https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html` |
| `REF-02` | Godot 4.6 Control docs | `https://docs.godotengine.org/en/stable/classes/class_control.html` |
| `REF-03` | Godot 4.6 Using Containers docs | `https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html` |
| `REF-04` | Godot 4.6 CanvasLayer docs | `https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html` |
| `REF-05` | Godot 4.6 Camera2D docs | `https://docs.godotengine.org/en/stable/classes/class_camera2d.html` |
| `REF-06` | Boxing proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/boxing_proving.tscn` |
| `REF-07` | Flow proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/flow_proving.tscn` |
| `REF-08` | Shared proving harness | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-09` | Testbed project config | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/project.godot` |
| `REF-10` | Derrick’s explicit direction that missing Camera2D/CanvasLayer/etc. should be evaluated against docs | current session |

---

## Tasks

### Task 1: Compare docs-backed Godot structure to current proving scenes and implement correction

**Bead ID:** `oc-3rs`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`, `REF-10`  
**Prompt:** Read the current Godot 4 docs for Control/containers, CanvasLayer, Camera2D, and multiple resolutions; compare those docs to the current proving scenes and project config; then implement the smallest truthful correction needed so the proving UI is composed using the intended Godot structure during playback. Be explicit about what docs say, what current repo structure is doing, and what you changed. Use visible desktop evidence for validation, commit/push to main before handoff, and close the bead only if the implementation slice is genuinely done.

**Status:** ✅ Complete

**Results:** Docs-backed implementation landed in commit `fb0d3db` (`Set testbed proving UI design size`). The coder concluded that these proving scenes were already correctly shaped as `Control`/container UI, that `CanvasLayer` and `Camera2D` were not the missing fix for this scene architecture, and that the meaningful missing setup was project-level display/content-scale policy. The only file changed was `.testbed/project.godot`, adding a 1280x720 design size plus `window/stretch/mode="canvas_items"` and `window/stretch/aspect="expand"`.

---

### Task 2: QA visible playback against the docs-backed correction

**Bead ID:** `oc-3rs.1`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** Independently verify the docs-backed proving-scene structure correction in actual visible playback. Confirm that the UI is visibly present during playback and that the resulting structure matches the intended Godot pattern claimed by the coder.

**Status:** ✅ Complete

**Results:** QA passed using visible-window screenshots and repo-state verification. Both Boxing and Flow were confirmed materially more usable during playback after `fb0d3db`; the left camera/tracking view remained visible and the right-side observability UI was visibly present and readable. QA also agreed that the docs-backed conclusion held up: project display/stretch settings were the meaningful missing setup, not missing `Camera2D` / `CanvasLayer`.

---

### Task 3: Audit the docs-backed final truth

**Bead ID:** `oc-3bt.2`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`, `REF-10`  
**Prompt:** Independently audit whether the final proving-scene structure now matches the claimed Godot docs-backed model and resolves the visible playback UI blocker truthfully.

**Status:** ✅ Complete

**Results:** Audit passed for the claimed scope: visible UI/layout usability. The auditor confirmed the scene tree was already `Control`/container-based, `CanvasLayer` and `Camera2D` were not the missing fix for this architecture, and the before/after evidence matched a project-level design-size/stretch correction rather than a missing scene-structure rewrite. Audit recommended updating Cookie to `fb0d3db` for retest.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Landed a docs-backed proving UI correction in `fb0d3db` by setting the testbed project design size/stretch policy instead of restructuring the scenes around `Camera2D` or `CanvasLayer`. The local coder → QA → auditor loop agreed that these proving scenes were already correctly built as `Control`/container UI and that the meaningful missing setup was project-level display/content-scale behavior in `.testbed/project.godot`.

**Reference Check:** `REF-01` through `REF-10` support the conclusion that `Camera2D`/`CanvasLayer` were not the missing fix for this scene shape. The correction truthfully improves visible UI/layout usability, but does not certify detector behavior or motion truthing.

**Commits:**
- `fb0d3db` - Set testbed proving UI design size

**Lessons Learned:** For Godot 4 UI-layout issues, check current docs and project display/stretch settings before assuming a Unity-style camera/canvas fix. Visible-window evidence also matters more than headless geometry for certifying human-usable layout.

---

*Completed on Pending*
