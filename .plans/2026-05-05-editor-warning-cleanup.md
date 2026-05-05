# AeroBeat MediaPipe Editor Warning Cleanup

**Date:** 2026-05-05  
**Status:** Partial  
**Agent:** Pico 🐱‍🏍

---

## Goal

Remove the current Godot editor warnings visible after running/closing the `.testbed` scenes, while keeping scope narrow and separate from the larger Cookie close-crash isolation.

---

## Overview

During direct interactive testing, Derrick observed warnings in the Godot editor after closing the Boxing test scene. The screenshot shows one likely environment/XIM warning plus two likely repo-owned GDScript reload warnings caused by naming collisions around `MediaPipeConfig` and `MediaPipeServer`. Those collisions are likely cleanup-worthy regardless of whether they are tied to the larger Cookie crash.

The close-crash investigation remains a separate active slice. This plan only targets the warning cleanup path: identify which warnings are actionable in repo code, implement the smallest truthful fix, and verify that the relevant editor warnings are gone or explicitly bounded if they are environment-specific.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Warning screenshot from Derrick | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/05/image-06780d78.png` |
| `REF-02` | Testbed scene directory | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/` |
| `REF-03` | MediaPipe config class source | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/config/mediapipe_config.gd` |
| `REF-04` | MediaPipe server class source | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/server/mediapipe_server.gd` |
| `REF-05` | Close-crash isolation plan (separate scope) | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-05-cookie-close-crash-regression-isolation.md` |

---

## Tasks

### Task 1: Diagnose actionable editor warnings

**Bead ID:** `oc-b75`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Diagnose the current editor warnings shown after running/closing the `.testbed` scenes. Separate repo-owned/actionable warnings from environment-specific noise. In particular, determine whether the `MediaPipeConfig` / `MediaPipeServer` warnings are caused by local constant names colliding with global `class_name` declarations and identify the narrowest fix path.

**Folders Created/Deleted/Modified:**
- plan/notes only unless a tiny truth fix is needed to complete diagnosis

**Files Created/Deleted/Modified:**
- plan updates only

**Status:** ✅ Complete

**Results:** Diagnosis complete. The `_create_xic...` warning from the screenshot looks like environment/XIM noise rather than repo-owned project logic. The actionable warnings are the two `GDScript::reload` messages about `MediaPipeConfig` and `MediaPipeServer`; those were traced to local preload constant names in `.testbed/scenes/mediapipe_provider_test.gd` colliding with the global `class_name MediaPipeConfig` and `class_name MediaPipeServer` declarations in the addon source. The narrowest truthful fix path is a local alias rename in that single scene script.

---

### Task 2: Implement narrow warning cleanup

**Bead ID:** `oc-tbi`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Implement the smallest truthful repo-side fix for the actionable editor warnings. Avoid broad refactors. If the XIM warning is environment-specific and not realistically owned by repo code, document that clearly instead of pretending to fix it.

**Folders Created/Deleted/Modified:**
- exact files implicated by diagnosis

**Files Created/Deleted/Modified:**
- exact warning-cleanup files

**Status:** ✅ Complete

**Results:** Implemented the narrow repo-side warning cleanup in `.testbed/scenes/mediapipe_provider_test.gd` only. The colliding preload constants were renamed from `MediaPipeConfig` / `MediaPipeServer` to `MediaPipeConfigScript` / `MediaPipeServerScript`, and local typed declarations plus `.new()` callsites were updated to match. Validation included a direct script parse check and a brief headless `test_scene.tscn` smoke startup. Commit: `ed0bd92` (`Fix MediaPipe testbed preload name collisions`). The `_create_xic` warning remains intentionally out of scope as environment/editor noise.

---

### Task 3: QA and audit warning cleanup

**Bead ID:** `oc-895`  
**SubAgent:** `primary` (for `qa` then `auditor` workflow roles)  
**Role:** `qa` then `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Verify the warning cleanup and certify only what was actually fixed. Distinguish repo-side warning removal from remaining environment-specific/editor-platform caveats.

**Folders Created/Deleted/Modified:**
- same owning repo paths as implementation

**Files Created/Deleted/Modified:**
- plan/notes only unless a truth fix is required

**Status:** ⏳ Pending

**Results:** Pending

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** We cleaned up the narrow repo-owned editor warning path that Derrick hit after closing the Boxing test scene. The actionable `GDScript::reload` warnings came from preload alias collisions in `.testbed/scenes/mediapipe_provider_test.gd`, and those aliases are now renamed to avoid colliding with the addon’s global `class_name` declarations.

**Reference Check:** `REF-03` and `REF-04` remain truthful global class sources. The repo-side fix addressed the exact local collision path seen in `REF-02`. Deliberate caveat: broader same-pattern cleanup in other files was intentionally left untouched, and the environment/XIM warning from `REF-01` remains out of scope.

**Commits:**
- `ed0bd92` - Fix MediaPipe testbed preload name collisions

**Lessons Learned:** Not every editor warning deserves the same treatment. The valuable split here was separating environment noise from a small real repo-owned cleanup issue, then fixing only the file that actually drove the observed warning path.

---

*Completed on 2026-05-05 (partial; broader warning hygiene/QA audit still pending)*
