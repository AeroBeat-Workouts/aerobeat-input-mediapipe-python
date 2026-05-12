# AeroBeat MediaPipe Python — Crash-Test Tracker Shutdown Mode Expansion

**Date:** 2026-05-11  
**Status:** Complete  
**Agent:** Pico 🐱‍🏍

---

## Goal

Update the local crash-test tracker page and adjacent state schema so it truthfully tracks the new shutdown-isolation modes alongside the older broad skip-sidecar path.

---

## Overview

We just landed and audited the new shutdown-isolation toggles that split the suspicious normal stop path into finer-grained manual testing surfaces. The code truth is ready, but the local tracker page still only models the old binary axis: `normal_stop` versus `skip_sidecar`. That means Derrick now has a better manual test ladder than the tracker can actually represent.

This follow-up should keep scope tight and truth-first: expand the tracker model so it can capture the four meaningful shutdown surfaces now available in source, preserve existing local data as safely as possible, and make the page/manual-state format easy to use during repeated crash hunting. Because the tracker is a manual truth log, clarity matters more than cleverness. The page should make it obvious which shutdown mode was tested and should not silently collapse different modes into the same bucket.

We should also be careful about compatibility: the existing `.crash-test-state.json` already contains real hand-entered data. So the update should either migrate that state forward safely or preserve it in a clearly explainable way. And since this is UI/tracker work rather than crash repro work, QA and audit can stay source-only / offline-safe.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Completed shutdown-toggle implementation/audit plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-11-shutdown-isolation-debug-toggles.md` |
| `REF-02` | Tracker page that currently models only the old shutdown axis | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/.crash-test/crash-test.html` |
| `REF-03` | Current persisted tracker state that should be preserved or migrated carefully | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/.crash-test/.crash-test-state.json` |
| `REF-04` | Proving harness Inspector-facing shutdown toggles now available to manual testing | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-05` | AutoStartManager shutdown-mode truth that the tracker needs to represent | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/autostart_manager.gd` |
| `REF-06` | Current manual caveat: `boxing_proving.tscn` still defaults the broad bypass to true, so tracker copy should help avoid accidental wrong-mode logging | current session + prior audited plan |

---

## Tasks

### Task 1: Design the expanded tracker shutdown-mode matrix and migration approach

**Bead ID:** `oc-iqpy`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Inspect the current crash-test page/state format and the newly landed shutdown toggles, then propose the smallest truthful tracker expansion. Specify the shutdown-mode enum/labels, how old `normal_stop` / `skip_sidecar` rows should map forward, and any UI copy needed to avoid logging tests under the wrong mode.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/.crash-test/` (read-only for research)

**Files Created/Deleted/Modified:**
- this plan file only

**Status:** ✅ Complete

**Results:** Research completed and bead `oc-iqpy` was closed. The recommended smallest truthful expansion is to replace the old binary `skipSidecar` axis with a single `shutdownMode` enum while leaving the rest of the matrix shape intact. Recommended enum ids/labels: `normal_stop` (`Normal stop`), `heartbeat_only` (`Heartbeat-only (broad skip-sidecar)`), `normal_stop+skip_terminate_sync` (`Normal stop + skip terminate_sync`), `normal_stop+skip_linux_pkill_main_py` (`Normal stop + skip Linux pkill main.py`), and `normal_stop+skip_terminate_sync+skip_linux_pkill_main_py` (`Normal stop + skip terminate_sync + skip Linux pkill main.py`). This matches the source/log truth more closely than adding multiple tracker booleans and avoids collapsing the new narrow shutdown rungs together. Existing hand-entered data should migrate forward by remapping only the final shutdown-axis segment: old `skipSidecar: "normal_stop"` becomes `shutdownMode: "normal_stop"`, and old `skipSidecar: "skip_sidecar"` becomes `shutdownMode: "heartbeat_only"`, while preserving `tested`, `crashed`, `badWindowOnly`, and `notes` as-is. The page should also add explicit copy that broad skip-sidecar overrides the narrow toggles, and it should warn that Boxing currently bakes a misleading default for narrow-mode testing unless the root Inspector values are deliberately changed first.

---

### Task 2: Implement the tracker page/state expansion

**Bead ID:** `oc-45ic`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Update the crash-test tracker page and adjacent JSON/state handling to represent the expanded shutdown-mode matrix truthfully. Preserve existing data as safely as possible, keep the page offline-friendly, and do not introduce risky runtime behavior. Commit/push before handoff.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/.crash-test/`

**Files Created/Deleted/Modified:**
- `.testbed/.crash-test/crash-test.html`
- `.testbed/.crash-test/.crash-test-state.json`
- this plan file

**Status:** ✅ Complete

**Results:** Coder pass completed and bead `oc-45ic` was closed. The tracker page and adjacent state schema were expanded to replace the old binary `skipSidecar` axis with a truthful `shutdownMode` enum covering `normal_stop`, `heartbeat_only`, `normal_stop+skip_terminate_sync`, `normal_stop+skip_linux_pkill_main_py`, and `normal_stop+skip_terminate_sync+skip_linux_pkill_main_py`. The UI/table/exported payloads were updated to show shutdown mode explicitly, and warning copy was added to make two critical manual-testing truths visible: broad `skip_sidecar_stop_on_close_debug` overrides the narrow toggles, and `boxing_proving.tscn` currently bakes that broad override on, so narrow-mode testing is misleading unless the root Inspector values are changed first. Existing hand-entered data was preserved by migrating only the final shutdown-axis segment (`normal_stop` stays `normal_stop`, old `skip_sidecar` becomes `heartbeat_only`) while preserving `tested`, `crashed`, `badWindowOnly`, and `notes` exactly. Newly introduced narrow-mode rows were added as fresh empty/default entries. LocalStorage and file-import normalization were also updated so old v1 browser-local state and old JSON payloads normalize forward safely. Safe validation only: `git diff --check` against the tracker files plus offline Python validation confirming JSON version 2, 60 combos/rows total, all 24 legacy rows migrated correctly, and all 36 new narrow-mode rows initialized empty. No risky runtime repros or proving-scene execution were run. The change was committed and pushed as `0830980` (`Expand crash-test tracker shutdown modes`).

---

### Task 3: QA the tracker expansion without running risky runtime paths

**Bead ID:** `oc-aqmc`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Perform a source-only / offline-safe QA pass on the expanded crash-test tracker. Do not launch proving scenes or exercise any risky close-path behavior. Verify that the page/state model now truthfully distinguishes the new shutdown modes, and that existing data handling is reasonable and clearly explained.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- this plan file only

**Status:** ✅ Complete

**Results:** Source-only QA passed and bead `oc-aqmc` was closed. QA explicitly confirmed no risky runtime paths were run. The tracker page and exported JSON/state schema now truthfully model the five shutdown modes (`normal_stop`, `heartbeat_only`, `normal_stop+skip_terminate_sync`, `normal_stop+skip_linux_pkill_main_py`, and `normal_stop+skip_terminate_sync+skip_linux_pkill_main_py`) in a way that matches the actual proving-harness / `AutoStartManager` source truth. QA verified the matrix shape at 60 combos / 60 rows, confirmed the schema is now version 2 and uses `shutdownMode` instead of the old binary `skipSidecar` axis, and confirmed all 24 legacy rows forward-map correctly while preserving `tested`, `crashed`, `badWindowOnly`, and `notes` exactly. QA also judged the new warning copy adequate: it clearly explains that broad `skip_sidecar_stop_on_close_debug` overrides the narrow toggles and that `boxing_proving.tscn` currently bakes that broad override on by default, which would otherwise make narrow-mode logging misleading.

---

### Task 4: Audit the tracker expansion without running risky runtime paths

**Bead ID:** `oc-r7os`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Perform an independent source-only audit of the tracker update after coder and QA finish. Confirm that the tracker now represents the shutdown-mode truth accurately enough for Derrick’s manual crash hunting and call out any remaining mismatch between code reality and tracker UI/state.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- this plan file only

**Status:** ✅ Complete

**Results:** Independent source-only audit passed and bead `oc-r7os` was closed. The auditor verified directly from the tracker page/state plus shutdown-mode source truth that the tracker now accurately represents all five real shutdown surfaces and explicitly documents the broad-override rule: if `skip_sidecar_stop_on_close_debug` is on, the effective mode is `heartbeat_only` regardless of the narrow toggles. The committed state file is internally consistent at schema version 2 with 60 combos/rows, no leftover old `skip_sidecar` combo IDs, and fresh narrow-mode rows present. QA’s final conclusion was confirmed accurate. No risky runtime paths were run during audit. Remaining manual caveat: `boxing_proving.tscn` still bakes `skip_sidecar_stop_on_close_debug = true`, so Boxing narrow-mode testing must first turn that broad bypass back off at the root Inspector.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Expanded the local crash-test tracker so it now truthfully records the full shutdown-isolation ladder instead of collapsing everything into only `normal_stop` versus `skip_sidecar`. The tracker page, exported payloads, and adjacent state file now represent five shutdown modes and preserve the earlier hand-entered crash-hunt data through a safe forward migration.

**Reference Check:** `REF-02`, `REF-03`, `REF-04`, and `REF-05` are now reflected truthfully in the tracker schema/UI. `REF-06` was addressed with explicit warning copy so manual logging does not accidentally misclassify Boxing runs that still start with the broad bypass on.

**Commits:**
- `0830980` - `Expand crash-test tracker shutdown modes`

**Lessons Learned:** For manual crash hunting, tracker truth matters almost as much as code truth. A single `shutdownMode` enum was cleaner and safer than bolting extra booleans onto the old page, and the migration stayed understandable because it only remapped the final axis while preserving the user-entered result fields exactly.
