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
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-04-24-synthetic-probe-shutdown-warning-truth-pass.md`

**Status:** ✅ Complete

**Results:** No durable provider/server repo code change was made, because the fresh evidence for this task shows the shutdown warning belongs to the disposable harness shape rather than `REF-02` / `REF-03` production teardown.

Exact validation run in the repo-local mounted-addon surface (`REF-04`):
- Reinstalled the workbench addon payload with `cd .testbed && godotenv addons install`.
- Old disposable harness shape (kept a loaded provider script reference and instantiated provider alive until quit, without explicit teardown): `~/.local/bin/godot --headless --path . --script <temp>/leak_probe.gd --quit --verbose --log-file <temp>/leak_probe.log`. That harness used `ResourceLoader.load("res://addons/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd", "", ResourceLoader.CACHE_MODE_IGNORE)`, `provider_script.new()`, printed `PROBE_PROVIDER_CLASS=Node`, then quit while both references were still live. The resulting log reproduced the generic shutdown warnings exactly: `WARNING: ObjectDB instances leaked at exit`, `Leaked instance: GDScriptNativeClass`, `Leaked instance: Node`, `Leaked instance: GDScript`, `ERROR: 1 resources still in use at exit`, and `Resource still in use: res://addons/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd (GDScript)`.
- Safer disposable harness teardown: `~/.local/bin/godot --headless --path . --script <temp>/safe_probe.gd --quit --verbose --log-file <temp>/safe_probe.log`. This variant used the same `ResourceLoader.load(..., CACHE_MODE_IGNORE)` / `provider_script.new()` setup, but then called `provider.free()`, set `provider = null`, set `provider_script = null`, awaited one frame, and only then quit. That rerun logged `PROBE_PROVIDER_CLASS=Node` and **did not** emit `ObjectDB instances leaked at exit`, `resources still in use at exit`, `Leaked instance: GDScriptNativeClass`, or `Resource still in use: res://addons/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd (GDScript)`.

Truthful fix decision:
- The smallest truthful fix for this slice is documentation/plan correction only: record that the warning source is harness-only and that the safe disposable-probe teardown pattern is to free/null the temporary provider + loaded script references before quit.
- Because the warning disappears without changing `REF-02` / `REF-03`, there is no evidence in this pass that the repo’s provider/server teardown still owns the leak signal.

Assembly-facing non-regression check (`REF-05`):
- From `../aerobeat-assembly-community`, reran `godotenv addons install`, then executed `~/.local/bin/godot --headless --path . --quit-after 2 --verbose --log-file <temp>/assembly_runtime.log`.
- Exit status was `0`. The log shows `AeroBeat Assembly started`, `Loading resource: res://addons/aerobeat-input-mediapipe/src/providers/mediapipe_provider.gd`, two successful `[MediaPipeServer] Starting UDP server on port 4242` / `UDP socket bound to 127.0.0.1:4242` pairs, `Tracking started`, and `Registered MediaPipe addon adapter`.
- Exact scan found no `Node not found: "MediaPipeServer"`, no `ObjectDB instances leaked at exit`, and no `resources still in use at exit` in this light assembly-facing rerun.

Files changed in this task: this plan file only.

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

**Status:** ✅ Complete

**Results:** Independent QA/audit pass completed against live `main`, the plan history in `REF-01`, and the cited documentation-only commits `83d0ae0` and `90df651`.

Exact audit reruns:
- Commit inspection: `git show --stat 83d0ae0` and `git show --stat 90df651` confirm this slice is documentation-only. `83d0ae0` records the initial research note; `90df651` adds the harness-only explanation and assembly non-regression evidence. There is no hidden provider/server production diff in this slice.
- Repo-local old disposable probe shape (`REF-04`): after `cd .testbed && godotenv addons install`, I ran `~/.local/bin/godot --headless --path . --script /tmp/tmp.eWuD96WXRm/leak_probe.gd --quit --verbose --log-file /tmp/tmp.eWuD96WXRm/leak_probe.log`. That harness used `ResourceLoader.load("res://addons/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd", "", ResourceLoader.CACHE_MODE_IGNORE)`, kept both `provider_script` and `provider = provider_script.new()` alive, printed `PROBE_PROVIDER_CLASS=Node`, and quit without releasing them. The resulting log reproduced the warning family exactly: `WARNING: ObjectDB instances leaked at exit`, `Leaked instance: GDScriptNativeClass`, `Leaked instance: Node`, `Leaked instance: GDScript`, `ERROR: 1 resources still in use at exit`, and `Resource still in use: res://addons/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd (GDScript)`.
- Repo-local safe disposable teardown (`REF-04`): I then ran `~/.local/bin/godot --headless --path . --script /tmp/tmp.eWuD96WXRm/safe_probe.gd --quit --verbose --log-file /tmp/tmp.eWuD96WXRm/safe_probe.log`. This used the same load/new pattern, then `provider.free()`, `provider = null`, `provider_script = null`, awaited one frame, and quit. The log still showed `PROBE_PROVIDER_CLASS=Node` but did **not** contain `ObjectDB instances leaked at exit`, `resources still in use at exit`, any `Leaked instance:` lines, or `Resource still in use: res://addons/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd (GDScript)`.
- Assembly-facing non-regression rerun (`REF-05`): from `../aerobeat-assembly-community`, after `godotenv addons install`, I ran `~/.local/bin/godot --headless --path . --quit-after 2 --verbose --log-file /tmp/tmp.eWuD96WXRm/assembly_runtime.log`. Exit status was `0`. The log shows `AeroBeat Assembly started`, `Loading resource: res://addons/aerobeat-input-mediapipe/src/providers/mediapipe_provider.gd`, two successful `[MediaPipeServer] Starting UDP server on port 4242` / `UDP socket bound to 127.0.0.1:4242` pairs, `Tracking started`, and `Registered MediaPipe addon adapter`. Exact grep found no `Node not found: "MediaPipeServer"`, no `ObjectDB instances leaked at exit`, and no `resources still in use at exit`.
- Screenshot/user-report truth check: the earlier generic warning report is consistent with the disposable harness shape, not a production provider regression, because (1) the warning family reproduces on demand only when the harness keeps the loaded script/object refs alive until process exit, (2) the same harness goes clean when those refs are released before quit, and (3) the broader runtime surfaces already recorded in `REF-01` and the fresh assembly rerun here stay free of these warnings. That combination supports a truthful harness-shape attribution rather than a provider/server production bug claim.

Audit verdict: pass. The evidence supports closure of `oc-rfv` and supports the existing decision not to add a production-code diff in `REF-02` / `REF-03` for this slice.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** A truthful closure record for the synthetic-probe shutdown-warning slice: the repo-local `ObjectDB` / resource-exit warnings are reproducible as a disposable-harness artifact when script/object refs are intentionally left alive until quit, they disappear when the harness frees/nulls those refs first, and the assembly-facing mounted-addon path remains clean.

**Reference Check:** `REF-01` is now clarified rather than contradicted: the earlier startup-order pass should no longer be read as evidence of a production provider leak, because this audit shows the warning family belongs to a disposable probe shape. `REF-02` and `REF-03` remain satisfied without further code changes: no new evidence points to provider/server teardown as the source. `REF-04` is satisfied by the two independent repo-local probe reruns at `/tmp/tmp.eWuD96WXRm/leak_probe.log` and `/tmp/tmp.eWuD96WXRm/safe_probe.log`. `REF-05` is satisfied by the fresh assembly rerun at `/tmp/tmp.eWuD96WXRm/assembly_runtime.log`, which showed the mounted provider starting normally with no startup-order or ObjectDB/resource regression.

**Commits:**
- `83d0ae0` - Document synthetic probe shutdown warning research
- `90df651` - Document synthetic probe warning as harness-only
- Audit plan update committed after this verification pass

**Lessons Learned:** Generic Godot shutdown warnings are only useful if the harness lifecycle is truthful. For disposable script probes that use `ResourceLoader.load(..., CACHE_MODE_IGNORE)`, keeping the loaded script and instantiated node alive until process exit can manufacture `ObjectDB` / resource-exit noise that does not represent product behavior. For this addon, consumer-facing runtime checks in the mounted repo-local and assembly surfaces are the better truth source than minimal disposable harnesses unless the harness explicitly releases temporary refs before quitting.

---

*Completed on 2026-04-24*
