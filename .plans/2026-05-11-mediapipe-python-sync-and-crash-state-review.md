# AeroBeat MediaPipe Python — Sync and Crash State Review

**Date:** 2026-05-11  
**Status:** Complete  
**Agent:** Pico 🐱‍🏍

---

## Goal

Sync the local `aerobeat-input-mediapipe-python` repo to the latest `main`, then inspect the filled-in crash-test state file so we can choose the next crash-hunting move from current evidence instead of stale assumptions.

---

## Overview

We’re resuming from the active crash-hunting thread, where the strongest current truth is that the proving-scene close-path problem looks shared between Boxing and Flow and can destabilize the X11/GNOME session, while blank/control paths stay clean. Derrick has now filled out the local crash tracker JSON, which should give us a denser matrix of what combinations actually crash, what only produce `BadWindow`, and what stays safe.

This plan keeps the first pass narrow and low-risk: update the repo from origin if needed, read the current crash-state JSON exactly as filled in, summarize the real pattern, and then decide the next smallest implementation or test-isolation target. No guessing from memory when the tracker file now exists as the local source of truth.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Active long-running crash/UI coordination plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-08-cookie-boxing-ui-missing-and-close-crash.md` |
| `REF-02` | Prior handoff / crash-first resume instruction | `/home/derrick/.openclaw/workspace/memory/2026-05-11.md` |
| `REF-03` | Local crash-test state source of truth to inspect | `/home/derrick/Documents/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/.crash-test/.crash-test-state.json` |
| `REF-04` | Crash-test tracker page that defines the matrix fields | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/.crash-test/crash-test.html` |
| `REF-05` | Recent memory about proving-scene crash surface and clean/safe split | `memory search: 2026-05-06, 2026-05-08, 2026-05-09` |

---

## Tasks

### Task 1: Sync local repo with latest `origin/main`

**Bead ID:** `oc-hje4`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-03`  
**Prompt:** In `aerobeat-input-mediapipe-python`, verify remotes/status and fast-forward the repo to the latest `origin/main` if needed. Record exactly what changed and whether the crash-state file or crash-test assets moved.

**Folders Created/Deleted/Modified:**
- `.plans/`
- repo root as needed from upstream sync

**Files Created/Deleted/Modified:**
- repo files only if upstream changed them
- this plan file

**Status:** ✅ Complete

**Results:** Repo sync completed and bead `oc-hje4` was closed. The local repo fast-forwarded cleanly from `2f0acb2bfd0749bc6f0adbb8a258bcc0b05188c1` to upstream commit `ce6ee1a313d2b260f7cb5a0ff9a668e7a73d1646` (`added the crash-test-state.json file`). The upstream delta included `.testbed/.crash-test/.crash-test-state.json`, `.testbed/project.godot`, `.testbed/scenes/boxing_proving.tscn`, and `.testbed/scenes/flow_proving.tscn`. This confirms the crash-state file itself was part of the latest upstream change and is now present in the synced local source. Validation performed: remote verification, before/after branch status, fetch, HEAD vs `origin/main`, ahead/behind log, changed-file diff, `git merge --ff-only origin/main`, and final `git log -1 --stat`. The only remaining local change is this new plan file.

---

### Task 2: Inspect the filled crash-test state and summarize the real failure pattern

**Bead ID:** `oc-cw57`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Read the current `.crash-test-state.json` exactly as filled out by Derrick, map the tested combinations across scene/source/startup-mode/skip-sidecar-stop, and summarize what the matrix actually says about the crash surface. Call out clean-safe combinations, reproducible crash combinations, and any patterns that tighten or weaken the current shared-shutdown-path hypothesis.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/.crash-test/` (read-only unless a follow-up fix is explicitly chosen)

**Files Created/Deleted/Modified:**
- `.testbed/.crash-test/.crash-test-state.json` (read-only for this task)
- this plan file

**Status:** ✅ Complete

**Results:** Research completed and bead `oc-cw57` was closed. The crash matrix is fully populated at 24/24 tested combinations. Current state-file classification yields 16 clean-safe rows, 3 crash-flagged rows, 5 bad-window-only rows, and 0 untested rows. The strongest pattern is the close-path toggle: all 3 crash-flagged rows are on `normal_stop`, while `skip_sidecar_stop_on_close_debug` has 0 crashes. That materially strengthens the shared shutdown-path hypothesis for the true crash surface. But `skip_sidecar` still carries multiple BadWindow-only outcomes, which suggests a second lighter-weight window/X11 teardown issue can appear independently from the real crash path. Clustering by scene/source/startup mode is weaker: Flow is somewhat worse than Boxing for crash observations, live camera is somewhat worse than prerecorded video, TRACKING leans toward true crash observations, and GODOT_ONLY_DEBUG leans toward BadWindow-only noise. Important truth correction: the notes inside the state file weaken the word reproducible for the 3 crash rows, because those rows reportedly closed cleanly on later retries after restart. So the file currently proves crash-observed rows more strongly than deterministic crash-repro rows. The next most useful distinction is to split observed-once from reliably-reproduces, and keep BadWindow-only separate from true crash/session-collapse outcomes.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Synced the local `aerobeat-input-mediapipe-python` repo to the latest upstream `main`, then converted the filled crash-test matrix into a concrete crash-surface summary. The strongest current truth is that true crash observations cluster on the normal shared shutdown path, while `skip_sidecar_stop_on_close_debug` removes crash outcomes but does not remove all BadWindow/X11-noise outcomes.

**Reference Check:** `REF-03` and `REF-04` were used directly for the matrix interpretation, with `REF-05` used as prior-context comparison. Findings strengthen — but do not fully close — the shared shutdown-path hypothesis.

**Commits:**
- `ce6ee1a313d2b260f7cb5a0ff9a668e7a73d1646` - `added the crash-test-state.json file` (upstream fast-forwarded into local repo)

**Lessons Learned:** The matrix is complete enough to stop guessing, but its current booleans still conflate observed-once with reproducible-on-demand. The next crash-hunting pass should preserve the current matrix and add a stricter distinction between true repros and one-off observations, while continuing to keep BadWindow-only separate from actual session-collapse crashes.
