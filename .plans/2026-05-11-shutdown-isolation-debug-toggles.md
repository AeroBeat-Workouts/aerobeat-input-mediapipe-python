# AeroBeat MediaPipe Python — Shutdown Isolation Debug Toggles

**Date:** 2026-05-11  
**Status:** Complete  
**Agent:** Pico 🐱‍🏍

---

## Goal

Add narrow debug toggles that let us isolate the suspicious normal sidecar shutdown steps independently, starting with `terminate_sync(_launch_info)` and the Linux `pkill -9` cleanup, without requiring the broad heartbeat-only bypass.

---

## Overview

The current crash-hunt evidence is now strong enough to justify a precise code experiment. Derrick’s filled crash matrix showed all crash-observed rows on the normal stop path and zero crash rows under `skip_sidecar_stop_on_close_debug`. Then Derrick completed 24 additional manual Flow close attempts with `skip_sidecar_stop_on_close_debug` enabled across `TRACKING` and `PREVIEW_ONLY_DEBUG`, using both live camera and prerecorded video, and saw zero crashes plus only two BadWindow events. That makes the normal explicit sidecar stop path the clear favorite.

The code inspection narrowed the most suspicious operations inside that normal path to `terminate_sync(_launch_info)` first and Linux `pkill -9 -f python_mediapipe/main.py` second. The right next move is to expose those as separate debug toggles so manual Cookie testing can isolate them independently, without using the broader “skip the whole stop path” bypass.

Because crash reproduction can destabilize the environment, this execution pass will keep QA and audit source-only. No subagent in this loop should run the proving scenes or intentionally exercise risky close-path behavior. The product change is to create sharper knobs; Derrick’s manual testing remains the truth source for risky repros.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Shutdown-path inspection plan and conclusion | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-11-normal-stop-shutdown-path-inspection.md` |
| `REF-02` | Proving harness skip-sidecar toggle wiring | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-03` | AutoStartManager shutdown code to split into narrower toggles | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/autostart_manager.gd` |
| `REF-04` | Derrick’s latest manual result: 24 Flow close attempts with skip-sidecar enabled produced zero crashes and two BadWindow-only events | current session |
| `REF-05` | Crash-state review plan showing normal-stop vs skip-sidecar pattern | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-11-mediapipe-python-sync-and-crash-state-review.md` |

---

## Tasks

### Task 1: Implement narrow shutdown-isolation debug toggles

**Bead ID:** `oc-vhzh`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Implement narrow debug toggles that allow isolating `terminate_sync(_launch_info)` and Linux `pkill -9 -f python_mediapipe/main.py` independently inside the normal stop path. Keep the existing broad `skip_sidecar_stop_on_close_debug` behavior intact. Wire any new toggles cleanly through the proving harness into `AutoStartManager`, keep names explicit enough for Inspector/manual testing, update any relevant debug logging/status copy, and commit/push before handoff. Do not run risky proving-scene close-path tests.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scripts/`
- `src/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/proving_harness.gd`
- `src/autostart_manager.gd`
- any adjacent docs/comments only if directly useful for manual testing
- this plan file

**Status:** ✅ Complete

**Results:** Coder pass completed and bead `oc-vhzh` was closed. Two new Inspector-facing debug toggles were added and wired through the proving harness into `AutoStartManager`: `skip_sidecar_terminate_sync_on_close_debug` and `skip_linux_pkill_main_py_on_close_debug`. The existing broad bypass `skip_sidecar_stop_on_close_debug` was preserved unchanged. In `src/autostart_manager.gd`, the first new toggle skips only `_desktop_sidecar_launcher().terminate_sync(_launch_info)`, and the second skips only the Linux `pkill -9 -f python_mediapipe/main.py` cleanup. Shutdown logging was also tightened so the effective stop mode is explicit during manual testing (for example `heartbeat_only`, `normal_stop+skip_terminate_sync`, `normal_stop+skip_linux_pkill_main_py`, or both narrow skips combined). Safe validation only: headless Godot `--check-only` passes were run against the proving harness and `autostart_manager.gd`, plus `git diff --check`. No risky proving-scene close-path repros were run. The change was committed and pushed as `2f40d25` (`Add narrow shutdown isolation toggles`).

---

### Task 2: QA the shutdown-isolation toggles without running the code

**Bead ID:** `oc-jimf`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Perform a source-only QA pass on the new shutdown-isolation toggles. Do not launch Godot, do not run proving scenes, and do not execute any runtime path that could trigger the crash. Verify naming clarity, wiring correctness from proving harness to `AutoStartManager`, shutdown-path branching correctness, and whether the resulting manual test matrix will let Derrick isolate `terminate_sync` separately from `pkill -9`.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- this plan file only

**Status:** ❌ Failed

**Results:** QA completed source-only and correctly rejected the current change as not yet fully truthful. The broad bypass and the narrow `terminate_sync` isolation are wired correctly, and QA explicitly confirmed no risky runtime paths were run. But the new `skip_linux_pkill_main_py_on_close_debug` toggle does not yet create a real single-step isolation, because `src/autostart_manager.gd` still runs a broader `pkill -9 -f main.py` path that is likely to catch the same sidecar process anyway. That means Derrick cannot truthfully isolate “skip only Linux pkill” yet, and the current toggle name overpromises what the code actually isolates. QA also noted that the local crash-matrix page still only models the old broad on/off skip-sidecar axis, so it does not yet represent the new narrow knobs. Net QA verdict: partly usable, but not ready for audit or manual-certification as-is.

---

### Task 3: Fix the Linux pkill isolation gap that QA found

**Bead ID:** `oc-115c`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Fix the QA-reported Linux pkill isolation gap so `skip_linux_pkill_main_py_on_close_debug` truthfully skips the sidecar force-kill path instead of still letting a broader fallback `pkill -9 -f main.py` catch the same process. Keep the change narrow, preserve the broad skip-sidecar and narrow terminate-sync behaviors, and do not run risky runtime repros. Commit/push before handoff.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `src/`

**Files Created/Deleted/Modified:**
- `src/autostart_manager.gd`
- this plan file

**Status:** ✅ Complete

**Results:** Follow-up coder pass completed and bead `oc-115c` was closed. The Linux pkill isolation toggle is now truthful in `src/autostart_manager.gd`: before this fix, `skip_linux_pkill_main_py_on_close_debug` skipped `pkill -9 -f python_mediapipe/main.py` but still always ran the broader `pkill -9 -f main.py`, which likely matched the same sidecar process and collapsed the intended distinction. After the fix, both sidecar-targeting pkill patterns now sit under the same gated branch, so enabling `skip_linux_pkill_main_py_on_close_debug` skips both `pkill -9 -f python_mediapipe/main.py` and `pkill -9 -f main.py` while still preserving the rest of the shutdown path, including `fuser -k -9 /dev/video0`. The broad skip-sidecar toggle and the narrow terminate-sync toggle remain unchanged. Safe validation only: `git diff --check`, source-level sanity review, and diff inspection. No risky runtime repro or live proving launch was run. The fix was committed and pushed as `fb037e7` (`Fix Linux pkill isolation toggle`).

---

### Task 4: Re-QA the toggles after the Linux pkill fix, without running the code

**Bead ID:** `oc-ogid`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Perform a second source-only QA pass after the Linux pkill isolation fix. Do not launch Godot, do not run proving scenes, and do not execute any runtime path that could trigger the crash. Verify that the manual isolation matrix is now truthful for broad bypass, skip only terminate_sync, skip only Linux pkill, and skip both suspicious normal-stop substeps.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- this plan file only

**Status:** ✅ Complete

**Results:** Re-QA completed source-only and bead `oc-ogid` was closed. QA explicitly confirmed no risky runtime paths were run. After commit `fb037e7`, the toggle matrix is now source-truthful: the broad heartbeat-only bypass still skips `_stop_sync()` entirely, the narrow terminate toggle skips only `DesktopSidecarLauncher.terminate_sync(_launch_info)`, the Linux pkill toggle now truthfully skips both sidecar-targeting pkill patterns while preserving the rest of normal stop, and enabling both narrow toggles keeps `_stop_sync()` active while skipping both suspicious substeps. The remaining gap is now auxiliary rather than code-truth: `.testbed/.crash-test/crash-test.html` and its adjacent JSON still model only the old `normal_stop` vs `skip_sidecar` axis and do not yet represent the new narrower modes. QA also noted that `boxing_proving.tscn` still has `skip_sidecar_stop_on_close_debug = true` baked on the scene root, so manual testing of the new narrower modes must start by deliberately setting that broad bypass back to false.

---

### Task 5: Audit the toggle implementation and QA claims without running the code

**Bead ID:** `oc-bvvf`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Perform an independent source-only audit of the shutdown-isolation toggle implementation and the QA conclusions once the Linux pkill isolation gap has been fixed and QA has rechecked it. Do not run the code. Confirm the change actually creates the intended narrower isolation knobs, preserves the broad skip-sidecar behavior, and gives Derrick a truthful next manual testing surface.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- this plan file only

**Status:** ✅ Complete

**Results:** Independent source-only audit passed and bead `oc-bvvf` was closed. The auditor verified directly from commits `2f40d25` and `fb037e7` that the implementation now truthfully exposes all four intended manual isolation surfaces: broad heartbeat-only bypass; skip only `terminate_sync`; skip only Linux sidecar-targeting pkill patterns; and skip both suspicious normal-stop substeps while keeping the rest of `_stop_sync()` active. The auditor also confirmed QA’s latest conclusions are accurate and that QA’s earlier rejection was correct before the pkill fix landed. No risky runtime paths were run during audit. Remaining manual-testing caveats are auxiliary rather than code-truth blockers: the local crash-matrix page and adjacent state JSON still model only the old broad axis, and `boxing_proving.tscn` still has `skip_sidecar_stop_on_close_debug = true` baked on the scene root, so narrow-mode testing must first set that broad bypass back to false.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Added narrow shutdown-isolation debug toggles that let manual testing separate the broad heartbeat-only bypass from the two highest-suspicion normal-stop substeps. The repo now supports four truthful source-level manual surfaces: broad heartbeat-only bypass; skip only `terminate_sync`; skip only Linux sidecar-targeting pkill patterns; and skip both suspicious normal-stop substeps while keeping the rest of `_stop_sync()` active.

**Reference Check:** `REF-01`, `REF-02`, and `REF-03` were satisfied directly in source. `REF-04` and `REF-05` were reflected in the chosen isolation shape and QA/audit interpretation. One auxiliary surface still lags the source truth: the local crash-matrix tracker page and JSON do not yet model the new narrow modes.

**Commits:**
- `2f40d25` - `Add narrow shutdown isolation toggles`
- `fb037e7` - `Fix Linux pkill isolation toggle`

**Lessons Learned:** The QA loop was necessary here: the first implementation looked plausible but was not yet truthful for Linux pkill isolation until the broader fallback kill pattern was also gated. The clean split now is that code truth is ready for manual testing, while the tracker UI/schema and some scene defaults still need follow-up if we want the local checklist page to represent the finer-grained shutdown matrix exactly.
