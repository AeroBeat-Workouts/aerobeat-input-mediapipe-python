# AeroBeat MediaPipe Python — Normal Stop Shutdown Path Inspection

**Date:** 2026-05-11  
**Status:** Complete  
**Agent:** Pico 🐱‍🏍

---

## Goal

Inspect the normal proving-scene sidecar shutdown path against the heartbeat-only bypass path, identify the most likely race or hazardous cleanup step, and recommend the smallest next code change to test.

---

## Overview

Derrick clarified that the crash rows in the tracker are not deterministic repro rows; each crash was followed by a full PC restart, and later retries under the same settings often closed cleanly. That shifts the interpretation from “specific setting combo always crashes” toward “some setting combos increase exposure to a timing-sensitive close-path race.”

The strongest current product truth remains the same: no crash has been observed yet with `skip_sidecar_stop_on_close_debug` enabled, while crash-observed rows all sit on the normal stop path. So the right next slice is not broad scene/layout work — it is close-time shutdown mechanics. We want to compare exactly what the normal stop path does that the heartbeat-only path does not, and identify the narrowest candidate step to defer, soften, or remove for the next isolation pass.

In parallel, Derrick is running repeated manual close attempts with `skip_sidecar_stop_on_close_debug` enabled across Boxing/Flow using `TRACKING` and `PREVIEW_ONLY_DEBUG`. That manual pressure test will help determine whether the bypass is truly protective or whether crashes can still happen even when explicit close-time sidecar shutdown is skipped.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Prior crash-state sync/review plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-11-mediapipe-python-sync-and-crash-state-review.md` |
| `REF-02` | Active long-running crash/UI coordination plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-08-cookie-boxing-ui-missing-and-close-crash.md` |
| `REF-03` | Proving harness skip-sidecar toggle wiring | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-04` | AutoStartManager normal close path and heartbeat-only bypass | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/autostart_manager.gd` |
| `REF-05` | Python sidecar heartbeat timeout behavior | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/main.py` |
| `REF-06` | 2026-05-09 handoff that elevated shutdown-path comparison to top priority | `/home/derrick/.openclaw/workspace/memory/2026-05-09.md` |
| `REF-07` | Derrick’s manual clarification: crash-observed rows were followed by restart and later clean retries; current manual focus is repeated skip-sidecar attempts in Boxing/Flow TRACKING + PREVIEW_ONLY_DEBUG | current session |

---

## Tasks

### Task 1: Research the normal stop path vs heartbeat-only path and recommend the smallest next isolation change

**Bead ID:** `oc-mpk0`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Compare the proving harness close-path wiring, AutoStartManager shutdown code, and Python heartbeat shutdown behavior. Identify exactly what normal stop does that heartbeat-only bypass avoids, then recommend the smallest next code-level isolation change to test. Distinguish likely high-risk steps (sync terminate, pkill cleanup, device cleanup, stop timing, duplicate shutdown notifications, etc.) from lower-risk ones. Keep it focused on truth-finding, not speculative redesign.

**Folders Created/Deleted/Modified:**
- `.plans/`
- source tree read-only for this research task

**Files Created/Deleted/Modified:**
- this plan file only

**Status:** ✅ Complete

**Results:** Research completed and bead `oc-mpk0` was closed. The key conclusion is that heartbeat-only bypass avoids `AutoStartManager`’s synchronous sidecar termination block entirely, while the proving harness cleanup remains common to both paths. In the normal path, `AutoStartManager` close/teardown currently runs `_stop_sync()`, which performs `_stop_heartbeat()`, a blocking `OS.delay_msec(200)`, `_desktop_sidecar_launcher().terminate_sync(_launch_info)`, Linux `pkill -9 -f python_mediapipe/main.py`, and immediate `_cleanup_server_state()`. In skip-sidecar mode, that entire block is skipped and Python instead exits after heartbeat timeout (~3s) from its own side. The highest-suspicion operation is `terminate_sync(_launch_info)`, followed by the forceful Linux `pkill -9` cleanup. The smallest next isolation change recommended is to keep normal close-path shutdown enabled but add a debug path that skips only `terminate_sync(_launch_info)` while leaving the rest of `_stop_sync()` intact. If crashes disappear under that narrower change, the fault tightens around launcher-managed sync termination; if not, `pkill -9` becomes the next prime suspect. Duplicate close notifications exist in both the harness and `AutoStartManager`, but current guards suggest they are more likely noise than the core failure.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** A code-level comparison of the normal proving close path versus the heartbeat-only bypass path, with a concrete recommendation for the next smallest shutdown isolation change. The current best read is that the risky surface sits in `AutoStartManager`’s synchronous sidecar termination path, not in the shared proving-harness cleanup.

**Reference Check:** `REF-03`, `REF-04`, and `REF-05` were inspected directly; findings align with `REF-06` and Derrick’s current-session clarification in `REF-07`.

**Commits:**
- none (research-only pass)

**Lessons Learned:** The most valuable delta is not broad scene mode or detector behavior — it is whether `_stop_sync()` runs. Derrick then completed 24 additional manual close attempts with `skip_sidecar_stop_on_close_debug` enabled, limited to Flow across `TRACKING` and `PREVIEW_ONLY_DEBUG` with both live camera and prerecorded video, and observed 0 crashes plus 2 BadWindow-only events. That materially strengthens the read that the real session-collapse bug lives in the normal explicit sidecar stop path, while BadWindow can still occur as separate lower-grade X11/window noise. The next sharp experiment should isolate `terminate_sync(_launch_info)` before touching broader shutdown flow or redesigning the sidecar lifecycle.
