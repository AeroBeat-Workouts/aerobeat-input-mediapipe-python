# AeroBeat MediaPipe Python Synthetic-Probe Shutdown Warning Truth Pass

**Date:** 2026-04-24  
**Status:** In Progress  
**Agent:** Pico 🐱‍🏍

---

## Goal

Identify and fix the repo-local synthetic-probe shutdown warnings that still appear in `aerobeat-input-mediapipe-python` after the `MediaPipeServer` startup-order repair, without broadening scope beyond that warning path.

---

## Overview

The previous cleanup slice successfully removed the real addon-internal startup-order error (`Node not found: "MediaPipeServer"`) in both the repo-local and assembly-facing validation paths. However, the repo-local synthetic probe used to isolate provider startup still emitted generic shutdown warnings on exit: `ObjectDB instances leaked at exit` and `1 resources still in use at exit`.

Those warnings did not reproduce in the assembly-facing rerun, so they are not blocking product-level assembly integration. But they are still real signals in the repo-local validation surface, and if they come from our provider/server teardown path we should clean them up before moving on. This pass should stay narrow: reproduce the exact warning source, determine whether it belongs to the probe harness or to repo code, implement the smallest truthful fix, then re-verify the synthetic probe and confirm we have not regressed the now-clean assembly-facing path.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Completed startup-order cleanup plan and final audit | `.plans/mediapipe-python/2026-04-24-mediapipeserver-startup-order-and-mount-comment-cleanup.md` |
| `REF-02` | Current provider implementation | `src/providers/mediapipe_provider.gd` |
| `REF-03` | Current server implementation / teardown path | `src/server/mediapipe_server.gd` |
| `REF-04` | Repo-local validation surface that reproduced the shutdown warnings | `.testbed/`, `.testbed/addons.jsonc` |
| `REF-05` | Assembly-facing validation surface used as a non-regression check | `../aerobeat-assembly-community/` |

---

## Tasks

### Task 1: Reproduce and attribute the shutdown warnings truthfully

**Bead ID:** `oc-yn6`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Reproduce the repo-local synthetic-probe shutdown warnings exactly, determine whether they originate from the probe harness or the repo’s provider/server teardown behavior, and identify the smallest truthful fix. Do not implement yet.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`
- `.testbed/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-24-synthetic-probe-shutdown-warning-truth-pass.md`

**Status:** ✅ Complete

**Results:** Research pass completed against current `HEAD` with fresh repo-local `.testbed` runs and direct teardown inspection of `REF-02` / `REF-03`.

Exact reproduction attempts and findings:
- Fresh mounted-addon probe rerun: `cd .testbed && godotenv addons install`, then `~/.local/bin/godot --headless --path . --script <temp>/mediapipe_provider_startup_probe.gd --quit --verbose --log-file <temp>/repo_probe.log`. The disposable script loaded `res://addons/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd`, instantiated the provider, added it to the root, awaited one frame, printed `PROBE_SERVER_CHILD_PRESENT=true`, `PROBE_SERVER_CHILD_CLASS=Node`, called `provider.start()`, printed `PROBE_PROVIDER_START_RESULT=true`, and quit immediately. The resulting log showed `[MediaPipeServer] Starting UDP server on port 4242`, `[MediaPipeServer] UDP socket bound to 127.0.0.1:4242`, and `[MediaPipeProvider] EXIT_TREE - stopping server`, but **did not** emit `WARNING: ObjectDB instances leaked at exit` or `ERROR: 1 resources still in use at exit`.
- Teardown-isolation variant: a second disposable probe repeated the same startup, then `queue_free()`d the provider, awaited one more frame, and quit. That run also did **not** emit `ObjectDB` or `resources still in use` warnings. The only extra shutdown artifact was `StringName: 1 unclaimed string names at exit`, which came from the altered disposable harness shape and is not evidence of provider/server resource leakage.

Source inspection findings:
- `REF-02` (`src/providers/mediapipe_provider.gd`) creates the server lazily in `_ensure_server()`, wires signals once, and on `NOTIFICATION_EXIT_TREE` calls `stop()`. There is no custom resource ownership beyond the child `MediaPipeServer` node.
- `REF-03` (`src/server/mediapipe_server.gd`) holds one `PacketPeerUDP`, marks `_is_running = false`, calls `_udp.close()`, and emits `server_stopped()` in `stop()`. There is no thread/process/file handle teardown path here that would explain a persistent `ObjectDB` / `resources still in use` exit warning after the node tree exits.

Truthful attribution:
- I could **not** reproduce the previously documented repo-local `ObjectDB instances leaked at exit` / `1 resources still in use at exit` warnings on the current repo-local synthetic probe path.
- Current evidence points away from `MediaPipeProvider` / `MediaPipeServer` teardown as the source. The provider/server path starts and exits cleanly in the current synthetic probe, and an explicit-free variant stays clear of those warnings too.
- The smallest truthful fix is therefore **not** a provider/server code change in this pass. The correct next adjustment is to treat the earlier warning claim as stale or harness-specific unless someone can provide the exact warning-producing probe script/log again. If any follow-up fix is needed, it should target the probe harness / documentation claim first, not `src/providers/mediapipe_provider.gd` or `src/server/mediapipe_server.gd`. `REF-01` should be read as having an outdated caveat until re-proven.

---

### Task 2: Fix the shutdown-warning source and validate the narrow path

**Bead ID:** `oc-e9k`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Implement the smallest truthful fix for the synthetic-probe shutdown warnings, then re-run the repo-local probe and a light assembly-facing non-regression check. Keep scope tight, document exact evidence, and commit/push by default.

**Folders Created/Deleted/Modified:**
- `src/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- provider/server files as needed
- `.plans/mediapipe-python/2026-04-24-synthetic-probe-shutdown-warning-truth-pass.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: QA the warning fix and audit closure

**Bead ID:** `oc-rfv`  
**SubAgent:** `primary`  
**Role:** `qa` / `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Independently verify that the repo-local synthetic-probe shutdown warnings are either gone or truthfully explained as probe-only behavior, confirm the assembly-facing path did not regress, and close only if the evidence supports that conclusion.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-24-synthetic-probe-shutdown-warning-truth-pass.md`

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
