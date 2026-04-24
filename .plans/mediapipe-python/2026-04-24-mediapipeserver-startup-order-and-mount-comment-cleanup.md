# AeroBeat MediaPipe Python Startup-Order and Mount-Path Cleanup

**Date:** 2026-04-24  
**Status:** Draft  
**Agent:** Pico 🐱‍🏍

---

## Goal

Fix the remaining addon-internal `MediaPipeServer` startup-order error in `aerobeat-input-mediapipe-python` and correct the stale adapter mount-path comment so the assembly integration path is both truthful and cleaner.

---

## Overview

The previous Linux assembly truth pass for `aerobeat-assembly-community` is complete, but it exposed one real addon-internal caveat that belongs back in this repo: `addons/aerobeat-input-mediapipe/src/providers/mediapipe_provider.gd` logs `Node not found: "MediaPipeServer"` during startup before recovering and continuing normally. The assembly-side audit confirmed this is not a remaining assembly integration mismatch; it is an ordering bug inside the MediaPipe addon provider itself.

This pass should stay narrow. We are not reopening provider contract design, broader assembly integration, or gameplay semantics here. The work is to remove the startup-order error cleanly, verify runtime still behaves correctly in the local `.testbed` and in the assembly-facing path as appropriate, and fix the stale adapter comment/documentation that still mentions the old `res://addons/aerobeat-input-mediapipe-python/` mount path instead of the live assembly mount key.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Assembly truth-pass findings that identified the remaining addon caveat | `../aerobeat-assembly-community/.plans/2026-04-24-mediapipe-linux-import-truth-pass.md` |
| `REF-02` | Current provider implementation with startup-order issue | `src/providers/mediapipe_provider.gd` |
| `REF-03` | Current public adapter entrypoint and stale mount-path comment | `src/input_provider.gd` |
| `REF-04` | Current repo-local testbed/runtime validation surface | `.testbed/`, `.testbed/addons.jsonc`, `README.md` |
| `REF-05` | Current assembly-facing integration reality | `../aerobeat-assembly-community/addons.jsonc`, `../aerobeat-assembly-community/src/main.gd` |

---

## Tasks

### Task 1: Fix the provider startup-order bug and stale mount-path comment

**Bead ID:** `oc-1wg`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Fix the remaining addon-internal `MediaPipeServer` startup-order issue in `src/providers/mediapipe_provider.gd` so the provider no longer logs the `Node not found: "MediaPipeServer"` error during startup, while preserving current runtime behavior. Also correct the stale mount-path comment/documentation in `src/input_provider.gd` so it matches the live assembly mount reality. Keep scope tight, run relevant validation in the local `.testbed` and the best truthful assembly-facing check available, update this plan with exact results, and commit/push by default.

**Folders Created/Deleted/Modified:**
- `src/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `src/providers/mediapipe_provider.gd`
- `src/input_provider.gd`
- `.plans/mediapipe-python/2026-04-24-mediapipeserver-startup-order-and-mount-comment-cleanup.md`

**Status:** ✅ Complete

**Results:** Fixed the addon-internal startup-order bug in `REF-02` by replacing the eager `@onready var _server = $MediaPipeServer` lookup with lazy `_ensure_server()` creation/lookup so `_ready()` and `start()` can attach or reuse the child without emitting the missing-node error first. This preserves current runtime behavior: the provider still creates/uses a local `MediaPipeServer`, configures it, connects the same signals, and starts/stops normally. Also corrected the stale adapter comment in `REF-03` so it now names the live assembly mount alias `res://addons/aerobeat-input-mediapipe/` instead of the old repo-name path.

Validation evidence:
- Repo-local `.testbed` startup probe against the mounted addon path: `~/.local/bin/godot --headless --path .testbed --script /tmp/mediapipe_provider_startup_probe.gd --log-file /tmp/mediapipe_provider_startup_probe.log` exited `0`, printed `PROBE_SERVER_CHILD_PRESENT=true`, then `[MediaPipeServer] Starting UDP server on port 4242`, `[MediaPipeServer] UDP socket bound to 127.0.0.1:4242`, and `PROBE_PROVIDER_START_RESULT=true`. Explicit grep of that log found **no** `Node not found: "MediaPipeServer"` occurrence.
- Additional repo-local `.testbed` script parse check: `~/.local/bin/godot --headless --path .testbed --script addons/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd --check-only --quit --log-file /tmp/mediapipe_provider_check_only.log` exited `0` with no parse/load failures.
- Best truthful assembly-facing path from sibling `aerobeat-assembly-community`: after publishing this repo update and rerunning `godotenv addons install` there, `~/.local/bin/godot --headless --path . --quit-after 2 --verbose --log-file /tmp/mediapipe_assembly_runtime_after_push.log` exited `0`, logged `AeroBeat Assembly started`, loaded `res://addons/aerobeat-input-mediapipe/src/providers/mediapipe_provider.gd`, bound UDP successfully twice on `127.0.0.1:4242`, logged `Tracking started`, and `Registered MediaPipe addon adapter`. Explicit grep of that log found **no** `Node not found: "MediaPipeServer"` occurrence. Direct file spot-check in the installed addon also confirmed the new payload is present: `addons/aerobeat-input-mediapipe/src/providers/mediapipe_provider.gd` now contains `var _server = null`, and `addons/aerobeat-input-mediapipe/src/input_provider.gd` contains the updated live assembly alias comment.

Files changed in this task: `src/providers/mediapipe_provider.gd`, `src/input_provider.gd`, and this plan file. Implementation commit: `cad9ae5` (`Fix MediaPipeServer startup ordering`), pushed to `origin/main`.

---

### Task 2: QA the startup-order fix in repo-local and assembly-facing validation paths

**Bead ID:** `oc-oaz`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Independently verify that the `MediaPipeServer` startup-order error is gone and that the stale mount-path wording is corrected. Re-run the best truthful repo-local `.testbed` validation path plus an assembly-facing validation path that exercises the mounted addon, then report exact evidence and any remaining caveat.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-24-mediapipeserver-startup-order-and-mount-comment-cleanup.md`

**Status:** ✅ Complete

**Results:** Independently QA-verified the coder’s claims against commits `cad9ae5` (`Fix MediaPipeServer startup ordering`) and `17208c6` (`Record MediaPipeServer startup fix validation`) instead of trusting the prior summary. Direct source inspection confirmed `REF-02` now uses lazy server lookup/creation (`var _server = null` plus `_ensure_server()`) and `REF-03` now documents the live assembly mount alias `res://addons/aerobeat-input-mediapipe/`.

Validation evidence:
- Repo-local `.testbed` path: reinstalled the workbench mounts with `cd .testbed && godotenv addons install`, then ran a fresh headless startup probe against the mounted addon provider using `~/.local/bin/godot --headless --path . --script /tmp/tmp.ebdKc7rPzF/mediapipe_provider_startup_probe.gd --quit --log-file /tmp/tmp.ebdKc7rPzF/repo_probe.log`. The probe loaded `res://addons/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd`, instantiated it, and logged `PROBE_SERVER_CHILD_PRESENT=true`, `PROBE_SERVER_CHILD_CLASS=Node`, `[MediaPipeServer] Starting UDP server on port 4242`, `[MediaPipeServer] UDP socket bound to 127.0.0.1:4242`, and `PROBE_PROVIDER_START_RESULT=true`; command exit status was `0`. Exact log scan `grep -F -c 'Node not found: "MediaPipeServer"' /tmp/tmp.ebdKc7rPzF/repo_probe.log` returned `0`, so the former startup-order error did not recur in the best truthful repo-local provider-start path.
- Assembly-facing mounted-addon path: from `../aerobeat-assembly-community`, reran `godotenv addons install` and then `~/.local/bin/godot --headless --path . --quit-after 2 --verbose --log-file /tmp/tmp.ebdKc7rPzF/assembly_runtime.log`. Exit status was `0`. The log shows `AeroBeat Assembly started`, `Loading resource: res://addons/aerobeat-input-mediapipe/src/providers/mediapipe_provider.gd`, `[MediaPipeServer] Starting UDP server on port 4242`, `[MediaPipeServer] UDP socket bound to 127.0.0.1:4242` (twice during the current assembly startup flow), `Tracking started`, and `Registered MediaPipe addon adapter`. Exact log scan `grep -F -c 'Node not found: "MediaPipeServer"' /tmp/tmp.ebdKc7rPzF/assembly_runtime.log` returned `0`, so the mounted assembly path also no longer emits the target error.
- Mounted payload wording check: direct spot-checks of both installed addon payloads confirmed the stale wording is corrected where consumers actually load it. `sed -n '1,16p' .testbed/addons/aerobeat-input-mediapipe-python/src/input_provider.gd` and `sed -n '1,16p' ../aerobeat-assembly-community/addons/aerobeat-input-mediapipe/src/input_provider.gd` both show the updated comment naming the live assembly alias `res://addons/aerobeat-input-mediapipe/`. Corresponding payload checks `grep -n 'var _server = null\|@onready var _server' .testbed/addons/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd` and `grep -n 'var _server = null\|@onready var _server' ../aerobeat-assembly-community/addons/aerobeat-input-mediapipe/src/providers/mediapipe_provider.gd` both report `var _server = null`, matching the fix actually installed into consumer-facing paths.

Files changed in this task: this plan file only. QA verdict: pass for the targeted scope. Remaining exact caveat for audit: while neither validation log contained `Node not found: "MediaPipeServer"`, the assembly headless run still ended with the generic pre-existing warnings `ObjectDB instances leaked at exit` and `1 resources still in use at exit`; those warnings are outside the narrow startup-order / comment-cleanup goal but did appear in this QA pass and should not be mistaken for evidence of the old `MediaPipeServer` lookup failure.

---

### Task 3: Audit closure for the cleanup slice

**Bead ID:** `oc-ij4`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Audit whether this narrow cleanup slice is actually complete: the provider should no longer emit the `MediaPipeServer` startup-order error in the validated paths, the mount-path wording should be truthful, and no broader contract claims should have been smuggled in. Verify independently and close only if the evidence supports it.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-24-mediapipeserver-startup-order-and-mount-comment-cleanup.md`

**Status:** ✅ Complete

**Results:** Independent audit pass completed against the live repo state plus the cited history in commits `cad9ae5` (`Fix MediaPipeServer startup ordering`), `17208c6` (`Record MediaPipeServer startup fix validation`), and `9316acc` (`Record QA for MediaPipeServer startup fix`). The implementation scope remains narrow: `cad9ae5` changes only `REF-02`, `REF-03`, and this plan file, so no broader adapter/provider contract claims were introduced beyond removing the eager `MediaPipeServer` lookup and correcting the mount-alias wording.

Audit evidence re-run from scratch:
- Repo-local `.testbed` mounted-addon path (`REF-04`): reran `cd .testbed && godotenv addons install`, then executed a fresh headless startup probe with `~/.local/bin/godot --headless --path . --script /tmp/tmp.VSckCxuBZ9/mediapipe_provider_startup_probe.gd --quit --log-file /tmp/tmp.VSckCxuBZ9/repo_probe.log`. The log shows `PROBE_SERVER_CHILD_PRESENT=true`, `PROBE_SERVER_CHILD_CLASS=Node`, `[MediaPipeServer] Starting UDP server on port 4242`, `[MediaPipeServer] UDP socket bound to 127.0.0.1:4242`, and `PROBE_PROVIDER_START_RESULT=true`. Exact truth check on that log reported `node_not_found=0`, so `Node not found: "MediaPipeServer"` does not appear in the validated repo-local mounted path.
- Assembly-facing mounted-addon path (`REF-05`): reran `godotenv addons install` in `../aerobeat-assembly-community`, then executed `~/.local/bin/godot --headless --path . --quit-after 2 --verbose --log-file /tmp/tmp.VSckCxuBZ9/assembly_runtime.log`. The log shows `AeroBeat Assembly started`, `Loading resource: res://addons/aerobeat-input-mediapipe/src/providers/mediapipe_provider.gd`, two successful `[MediaPipeServer] Starting UDP server on port 4242` / `UDP socket bound to 127.0.0.1:4242` pairs in the current startup flow, `Tracking started`, and `Registered MediaPipe addon adapter`. Exact truth check on that log also reported `node_not_found=0`, so `Node not found: "MediaPipeServer"` does not appear in the mounted assembly path either.
- Mount-path wording verification (`REF-03`, `REF-05`): direct spot-checks of `.testbed/addons/aerobeat-input-mediapipe-python/src/input_provider.gd` and `../aerobeat-assembly-community/addons/aerobeat-input-mediapipe/src/input_provider.gd` both show the updated truthful comment naming the live assembly mount alias `res://addons/aerobeat-input-mediapipe/`.
- Installed payload verification (`REF-02`, `REF-04`, `REF-05`): direct grep of both mounted provider copies reports `var _server = null` and no `@onready var _server`, matching the lazy `_ensure_server()` startup-order fix actually consumed by both validation surfaces.

Generic exit-warning decision: the repo-local synthetic probe still emits `WARNING: ObjectDB instances leaked at exit` and `ERROR: 1 resources still in use at exit`, but the assembly-facing validation did not reproduce those warnings in this audit rerun. For this bead’s narrow scope, those repo-probe shutdown warnings are caveats rather than blockers because the target startup-order failure is absent in both validated consumer paths, the mounted wording is truthful, and there is no evidence they are the old `MediaPipeServer` lookup bug resurfacing.

Audit verdict: pass. This cleanup slice is complete for its stated scope, so bead `oc-ij4` can be closed.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Removed the addon-internal `MediaPipeServer` startup-order error from the validated repo-local and assembly-facing mounted paths, and corrected the adapter comment so it truthfully names the live assembly mount alias `res://addons/aerobeat-input-mediapipe/`.

**Reference Check:** `REF-01` satisfied as the remaining caveat was correctly traced back to addon-internal startup ordering rather than assembly mismatch. `REF-02` satisfied: provider now uses lazy server acquisition and the validated mounted payloads both contain `var _server = null` instead of eager `@onready` lookup. `REF-03` satisfied: source and mounted payloads both use the truthful mount-alias wording. `REF-04` satisfied: repo-local `.testbed` validation rerun showed `PROBE_SERVER_CHILD_PRESENT=true`, successful UDP bind/start, and `node_not_found=0` for `Node not found: "MediaPipeServer"`. `REF-05` satisfied: assembly-facing mounted-addon validation rerun loaded the mounted provider, started tracking, registered the addon adapter, and also reported `node_not_found=0`.

**Commits:**
- `cad9ae5` - Fix MediaPipeServer startup ordering
- `17208c6` - Record MediaPipeServer startup fix validation
- `9316acc` - Record QA for MediaPipeServer startup fix
- Audit plan update committed after this verification pass

**Lessons Learned:** For addon packages consumed through mounted aliases, truth-check the installed payloads in both the repo-local harness and the downstream assembly rather than relying on source-only inspection. Also separate target-bug evidence from generic shutdown noise: the absence of `Node not found: "MediaPipeServer"` in both consumer paths is the blocker-clearing signal for this slice, while synthetic probe teardown warnings should be tracked separately if they matter later.

---

*Completed on 2026-04-24*
