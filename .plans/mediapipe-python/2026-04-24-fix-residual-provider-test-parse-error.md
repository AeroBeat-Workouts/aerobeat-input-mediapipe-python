# AeroBeat MediaPipe Python Residual Provider Test Parse Error

**Date:** 2026-04-24  
**Status:** Draft  
**Agent:** Pico 🐱‍🏍

---

## Goal

Fix the residual `.testbed` editor parse error in `res://tests/unit/test_mediapipe_provider.gd` and re-verify that the Godot testbed opens without the reported console errors.

---

## Overview

Derrick reopened the `.testbed` Godot project and immediately reproduced a residual editor parse error that slipped past the prior coder → QA → auditor loop. The visible console error points at `res://tests/unit/test_mediapipe_provider.gd:90` with `Builtin type cannot be used as a name on its own` and `Identifier "Vector2" not declared in the current scope`, which means the earlier “clean” validation missed at least one real editor path.

This pass is intentionally narrow and corrective: reproduce the exact failure from the repo state Derrick is seeing, repair the test script so it parses under the current GUT/testbed setup, then independently re-check the editor open/import path to make sure the reported console errors are actually gone. The plan also needs to record that the prior verification was incomplete so the final result is truthful.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Derrick’s reported console error screenshot and text | current session, 2026-04-24 09:27 EDT |
| `REF-02` | Residual failing test script | `.testbed/tests/unit/test_mediapipe_provider.gd` |
| `REF-03` | Prior repair/verification plan that missed this path | `.plans/mediapipe-python/2026-04-24-testbed-godotenv-verification-and-repair.md` |
| `REF-04` | Current `.testbed` addon wiring | `.testbed/addons.jsonc` |

---

## Tasks

### Task 1: Reproduce and pinpoint the residual provider test parse error

**Bead ID:** `oc-8fr`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Reproduce the residual editor parse error Derrick reported in `res://tests/unit/test_mediapipe_provider.gd`, confirm the exact failing line and language/runtime reason, and identify the smallest truthful fix. Do not implement yet. Claim the bead on start, gather exact evidence, and update this plan with the findings.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`
- `.testbed/tests/unit/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-24-fix-residual-provider-test-parse-error.md`
- `.testbed/tests/unit/test_mediapipe_provider.gd`

**Status:** ✅ Complete

**Results:** Reproduced with Godot 4.6.2 from the repo root using `~/.local/bin/godot --headless --path .testbed --import --verbose`, which emitted the same three editor-load errors Derrick reported: two parse errors at `res://tests/unit/test_mediapipe_provider.gd:90` (`Builtin type cannot be used as a name on its own`, `Identifier "Vector2" not declared in the current scope`) followed by `Failed to load script "res://tests/unit/test_mediapipe_provider.gd" with error "Parse error"`. The failing source line is `assert_is(pos, Vector2)`. GUT’s `assert_is(object, a_class, text='')` helper is for Object-derived classes (it checks `TYPE_OBJECT` and then `is_instance_of(...)`), but `Vector2` is a built-in Variant type, not a class object value that can be passed bare as the second argument. Under this Godot/GUT setup, `Vector2` is valid in `is` checks and constructors like `Vector2(...)`, but not as a standalone class-reference expression here. Smallest truthful fix: replace line 90 with a built-in-type-safe assertion, preferably `assert_typeof(pos, TYPE_VECTOR2)`; `assert_true(pos is Vector2)` would also parse, but `assert_typeof` matches GUT’s intended API for built-ins most directly. Validated against `REF-01`, `REF-02`, and `REF-04`. 

---

### Task 2: Fix the provider test parse error and rerun targeted validation

**Bead ID:** `oc-ws9`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Implement the smallest correct fix for the residual parse error in `.testbed/tests/unit/test_mediapipe_provider.gd`, then rerun the relevant Godot import/editor validation to prove the reported console errors are gone. Update the plan with exact results, commit and push by default, and keep the scope narrow unless reproduction shows a second directly-related issue.

**Folders Created/Deleted/Modified:**
- `.testbed/tests/unit/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.testbed/tests/unit/test_mediapipe_provider.gd`
- `.plans/mediapipe-python/2026-04-24-fix-residual-provider-test-parse-error.md`

**Status:** ✅ Complete

**Results:** Replaced the invalid built-in type assertion at `REF-02` line 90 from `assert_is(pos, Vector2)` to `assert_typeof(pos, TYPE_VECTOR2)`, which is the narrow GUT-compatible fix identified in Task 1. Targeted script parsing now succeeds with `~/.local/bin/godot --headless --path .testbed --script tests/unit/test_mediapipe_provider.gd --check-only --log-file /tmp/oc_ws9_script_check.log` returning exit status 0 and no matches for the prior parse-error strings. The editor/import path also now loads `res://tests/unit/test_mediapipe_provider.gd` cleanly via `~/.local/bin/godot --headless --path .testbed --import --verbose --quit --log-file /tmp/oc_ws9_godot_import.log`; grepping that log shows the script load entry but no occurrences of `Builtin type cannot be used as a name on its own`, `Identifier "Vector2" not declared in the current scope`, or `Failed to load script ... test_mediapipe_provider`. Files changed in this task: `.testbed/tests/unit/test_mediapipe_provider.gd` and this plan file. Commit IDs: `ac0eb0e` (to be pushed on `main`).

---

### Task 3: Independently QA the editor open path for the reported error

**Bead ID:** `oc-cm4`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-04`  
**Prompt:** Independently verify that opening the `.testbed` Godot project no longer produces Derrick’s reported provider-test parse errors. Reproduce the open/import/editor path yourself and confirm the console is free of that exact failure. Update the plan and close the bead only if the evidence supports it.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-24-fix-residual-provider-test-parse-error.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Audit closure and record the verification gap truthfully

**Bead ID:** `oc-5r0`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Audit whether the residual provider-test parse error is actually fixed and whether the targeted QA is sufficient. Record the result truthfully, including that the previous broader verification missed this editor path if that remains true. Close only if the reported issue is genuinely resolved.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-24-fix-residual-provider-test-parse-error.md`

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
