# AeroBeat MediaPipe Python — Start/Stop Audit and Proving UI Clean Base

**Date:** 2026-05-12  
**Status:** In Progress  
**Agent:** Pico 🐱‍🏍

---

## Goal

Audit and fix the sidecar lifecycle safety and the two proving-scene layout bugs so Derrick has a cleaner, safer base before tackling the deeper Boxing/Flow functionality issues.

---

## Overview

This slice intentionally avoids the broader gesture/trails/functionality bug family for now. The immediate objective is to make sure the MediaPipe sidecar lifecycle is safe and portable in principle, and that the proving scenes are visually stable enough that later behavior debugging is not muddied by obvious UI/layout failures.

The highest-risk engineering issue is the current sidecar start/stop implementation. Recent crash-hunt work proved that the Linux shutdown path has accumulated several repo-owned kill/cleanup branches, and Derrick correctly called out two concerns: the implementation should not silently remain Linux-only when the addon claims broader desktop support, and any forced-kill strategy must target **our** sidecar specifically rather than broad generic names like `main.py` that could affect unrelated processes on the host. That means this slice should first audit the current launcher/runtime/process naming and then land the smallest truthful source changes needed to make the process identity more explicit and the stop strategy less hazardous across Linux/macOS/Windows.

The second part of this slice is visual stability in the proving scenes. Derrick identified two current UI regressions that are interfering with clean testing: the Boxing top-left icon overlaps the scene title, and the camera/live preview surface can exceed its intended layout bounds and squash adjacent UI. Those should be fixed after the lifecycle audit so later validation of Boxing/Flow behavior happens in a stable, readable proving shell.

We will **not** mix in the broader trail/gesture/functionality bug family yet. Success for this plan means: (1) sidecar start/stop code is audited and tightened for platform coverage + safer process targeting, (2) the Boxing header overlap is gone, (3) camera/preview content fits its intended panel while preserving aspect ratio, and (4) Derrick confirms this clean base before we move into the larger functionality backlog.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Sidecar lifecycle manager | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/autostart_manager.gd` |
| `REF-02` | Sidecar launcher / process-group lifecycle | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/process/desktop_sidecar_launcher.gd` |
| `REF-03` | Shared camera/preview view | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/camera_view.gd` |
| `REF-04` | Boxing proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/boxing_proving.tscn` |
| `REF-05` | Flow proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/flow_proving.tscn` |
| `REF-06` | Shared proving harness | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-07` | Sidecar Python entrypoint / process identity | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/main.py` |
| `REF-08` | Current archived crash-hunt history for teardown context | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/archive/2026-05-08-cookie-boxing-ui-missing-and-close-crash.md` |

---

## Tasks

### Task 1: Audit current sidecar start/stop design for platform coverage and process-target safety

**Bead ID:** `oc-4ow0`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-07`, `REF-08`  
**Prompt:** Audit the current MediaPipe sidecar start/stop path across `src/autostart_manager.gd`, `src/process/desktop_sidecar_launcher.gd`, and the Python sidecar entrypoint. Identify exactly which parts are Linux-only today, what the current macOS/Windows behavior really is, and whether the current kill/cleanup targeting is too generic or potentially unsafe for unrelated host processes. Propose the smallest truthful fix direction that improves process identity and cross-platform correctness without inventing unvalidated platform claims.

**Folders Created/Deleted/Modified:**
- `.plans/`
- source paths only for reading unless a tiny truth note is required

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny truth-revealing note is required

**Status:** ✅ Complete

**Results:** Research completed and bead `oc-4ow0` should close. Exact current Linux behavior: runtime validation only accepts `linux-x64`/`macos-x64`/`windows-x64` keys, but on this repo/host the actually prepared runtime on disk is `linux-x64`, with only a scaffolded `windows-x64` folder and no `macos-x64` runtime root present. On Linux, launch is the only path that is clearly validated in source: `AutoStartManager` first does a broad prelaunch `pkill -f python_mediapipe/main.py`, then launches the sidecar through `DesktopSidecarLauncher.launch_detached()` using `/bin/bash` + `setsid nohup`, stores a process-group id from a pid file, starts heartbeat immediately, and later considers the server still alive if either the launcher says the process group is alive or the log contains `MediaPipe started`. On stop/close, Linux runs the heaviest and least safe ladder: launcher-managed process-group `TERM` then optional `KILL`, followed by repo-owned cleanup kills `pkill -9 -f python_mediapipe/main.py`, `pkill -9 -f main.py`, and `fuser -k -9 /dev/video0`.

Exact current macOS behavior: the runtime contract claims `macos-x64` support, but the launcher path is explicitly noted in source as unvalidated scaffolding. `launch_detached()` just calls `OS.create_process(command, args)` and records a direct pid (`macos-direct-pid`), with notes saying process-group isolation/teardown parity are scaffolded but not validated on this Linux host. Stop uses `/bin/kill -TERM <pid>` then optional `/bin/kill -KILL <pid>`, again with notes that macOS teardown remains unvalidated. There is no repo-side macOS cleanup equivalent to the Linux `pkill`/`fuser` path. Separately, `python_mediapipe/platform_utils.py` does contain real macOS-only runtime behavior (`caffeinate` App Nap suppression), but that is Python-process tuning, not proof that the addon launch/stop contract has been validated on macOS.

Exact current Windows behavior: the runtime contract claims `windows-x64` support and a `windows-x64` runtime folder exists, but `prepare_runtime.py` truthfully warns that foreign-platform preparation is scaffold-only unless run on that host, and the launcher path is again source-marked as unvalidated. `launch_detached()` uses `OS.create_process(command, args)` and records a direct pid (`windows-direct-pid`); liveness checks use `tasklist /FI "PID eq <pid>"`; stop uses `taskkill /PID <pid> /T` then optional `/F`. Notes in the launcher explicitly say Windows launch/teardown are scaffolded and not validated on this Linux host. `platform_utils.py` adds real Windows process-priority tuning, but that again is sidecar-process optimization, not evidence that the surrounding Godot lifecycle is proven on Windows.

Unsafe / overly broad process targeting found: (1) `src/autostart_manager.gd:_kill_existing_servers()` runs `pkill -f python_mediapipe/main.py` before every Linux start, which can hit unrelated repo checkouts or any other Python process launched from a matching path fragment. (2) `src/autostart_manager.gd:_run_linux_cleanup_patterns()` escalates further with `pkill -9 -f python_mediapipe/main.py` and then `pkill -9 -f main.py`; the plain `main.py` match is the worst offender and is broad enough to kill unrelated Python programs on the host. (3) the same cleanup kills every process using `/dev/video0` via `fuser -k -9 /dev/video0`, which is intentionally Linux-specific and not scoped to this sidecar at all. (4) Linux start fallback/liveness logic can report success from stale log text (`grep -c "MediaPipe started"`) even if the actual current process identity is gone, so process truth is partially decoupled from process identity.

Intentional scaffolding versus actually validated behavior: the desktop runtime contract is intentionally narrow to desktop only and x64 only (`SUPPORTED_DESKTOP_PLATFORM_KEYS = [linux-x64, macos-x64, windows-x64]`), so arm64/x86 desktop support is not truthfully implemented today. `prepare_runtime.py` is also truthful that foreign-platform prep is manifest/sentinel scaffolding only unless executed on the target host. However, the top-level addon lifecycle still reads as broader cross-platform support than has actually been proven: Linux process-group launch/stop is the only path with concrete repo-owned orchestration and crash-hunt history behind it; macOS and Windows are pid-only scaffolds with explicit unvalidated notes. Even on Linux, some cleanup behavior is historically practical but not process-safe.

Smallest truthful implementation direction: keep the current launcher-owned process identity as the primary stop surface and stop broad host scans from being the normal path. Concretely: (1) give the sidecar an explicit per-launch identity token or marker passed on the command line/env and recorded in `_launch_info`, so any fallback kill targets a unique AeroBeat-sidecar signature rather than `main.py`; (2) remove the generic Linux prelaunch/cleanup `pkill -f main.py` branch entirely and, if a Linux fallback is still needed, narrow it to that explicit identity token only; (3) treat launcher-targeted stop (`process_group_id` on Linux, direct pid on macOS/Windows) as the default truth path, with repo-level cleanup only as clearly-labeled last-resort debug recovery; and (4) make platform truth more explicit in logs/docs/UI by describing macOS/Windows as scaffolded pid-targeted lanes pending host validation rather than implying parity with the Linux path. No extra follow-up task was added because Task 2 already covers the implementation pass for this exact fix direction.

---

### Task 2: Implement safer sidecar identity and cross-platform lifecycle tightening

**Bead ID:** `oc-xkip`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-07`  
**Prompt:** Based on the audit, implement the smallest truthful source changes needed to improve the MediaPipe sidecar start/stop design. Priorities: avoid overly generic process targeting like broad `main.py` kills, make the sidecar’s process identity more explicit, and tighten platform-specific start/stop behavior so Linux/macOS/Windows lanes are handled intentionally rather than accidentally. Preserve current validated Linux behavior where necessary, but prefer safer and more specific cleanup semantics.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `src/`
- `python_mediapipe/`
- tests/docs only if directly needed for truthful validation

**Files Created/Deleted/Modified:**
- exact start/stop / sidecar identity files required by the implementation

**Status:** ✅ Complete

**Results:** Coder pass completed and will close bead `oc-xkip` after handoff. Scope stayed tight to the sidecar identity/lifecycle slice. In `src/process/desktop_sidecar_launcher.gd`, each detached launch now gets an explicit `sidecar_identity` token (`aerobeat-sidecar-<label>-<timestamp>-<rand>`) recorded in `_launch_info` and appended to argv as `--sidecar-identity=<token>` on Linux, macOS, and Windows. That keeps launcher-owned identity as the primary lifecycle surface while giving repo-owned fallback cleanup one explicit sidecar signature to target instead of broad filename matches. The macOS/Windows launcher notes were also tightened to say they are intentional direct-PID scaffolds with argv identity markers, not Linux-equivalent validated parity.

In `python_mediapipe/args.py` and `python_mediapipe/main.py`, the sidecar now accepts `--sidecar-identity` and logs it on startup so the launched process identity is explicit in both argv and logs. In `src/autostart_manager.gd`, the Linux prelaunch broad cleanup was removed entirely (`pkill -f python_mediapipe/main.py` no longer runs before start), the generic close-time `pkill -9 -f main.py` was removed entirely, and the Linux fallback cleanup now only runs `pkill -9 -f -- --sidecar-identity=<current token>` when the launcher-recorded identity exists. The previous `/dev/video0` `fuser -k -9` cleanup was also removed so repo-owned cleanup is no longer device-wide. Linux liveness was tightened by removing the stale log-text fallback (`grep` for `MediaPipe started`); `is_server_running()` now trusts only the current launcher-recorded process identity. `src/process/mediapipe_process.gd` logging was updated to surface the same explicit identity, and `.testbed/scripts/proving_harness.gd` stop-mode labels were adjusted so the Linux pkill debug label matches the new identity-scoped behavior while the legacy video0 toggle is labeled as a no-op.

Exact validation run:
- `/home/derrick/.local/bin/godot --headless --path . --script src/autostart_manager.gd --check-only`
- `/home/derrick/.local/bin/godot --headless --path . --script src/process/desktop_sidecar_launcher.gd --check-only`
- `/home/derrick/.local/bin/godot --headless --path . --script src/process/mediapipe_process.gd --check-only`
- `python3 -m py_compile python_mediapipe/args.py python_mediapipe/main.py`
- `git diff --check`

Commit/push status: pending at plan-update time; final commit hash will be added in handoff.

---

### Task 3: Fix Boxing proving header icon/title overlap

**Bead ID:** `oc-zy0e`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Fix the Boxing proving-scene header composition so the top-left Boxing icon no longer overlaps the scene title. Use the Flow scene and current proving-shell direction as the truth reference, and keep the scope tightly limited to the layout bug.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/` only if a shared header helper truly needs a small change

**Files Created/Deleted/Modified:**
- `.testbed/scenes/boxing_proving.tscn`
- `.testbed/scripts/proving_harness.gd`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/scripts/capture_fixture_proving.gd`

**Status:** ✅ Complete

**Results:** Reworked the Boxing header to follow the Flow shell direction: removed the root-positioned `HeaderIcon`, added `HeaderRow` under `Margin/VSplit/Header`, and placed both `HeaderIcon` and `TitleLabel` inside that horizontal row so the icon no longer sits on top of the title text (`REF-04`, `REF-05`). Kept the shared impact limited to node lookup resilience by switching title/icon lookups to `find_child(...)` where the new nested header structure required it (`REF-06`). Safe validation run: a focused Python assertion pass on `.testbed/scenes/boxing_proving.tscn` verified that `HeaderIcon` is no longer rooted at `.` and now lives under `Margin/VSplit/Header/HeaderRow`, plus `git diff --check` passed. Attempted headless Godot `--check-only` script validation, but this checkout resolves testbed preloads through an installed `res://addons/aerobeat-input-mediapipe-python/...` path that does not exist in the repo-only layout, so that parse path was not a truthful validation route for this slice.

---

### Task 4: Fix proving-scene camera/preview fit so video preserves aspect ratio without crushing adjacent UI

**Bead ID:** `oc-gzyy`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Fix the proving-scene camera/live-preview layout bug so the image/video texture respects the intended panel bounds, preserves aspect ratio, and does not expand in a way that squashes or pushes other UI elements offscreen. Scope should cover both live and prerecorded preview behavior in the Boxing/Flow proving scenes if they share the same root cause.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `src/`
- `.testbed/scenes/`
- `.testbed/scripts/` if layout glue needs a small shared fix

**Files Created/Deleted/Modified:**
- exact camera/preview/layout files required by the fix

**Status:** ✅ Complete

**Results:** Updated `.testbed/scripts/proving_harness.gd` so the runtime `MediaPipeCameraView` inherits the placeholder `CameraDisplay` layout contract (custom minimum size, layout mode, size flags, expand + stretch modes). This keeps live and prerecorded previews constrained to the intended panel bounds while preserving aspect ratio, preventing the TextureRect from expanding and squashing adjacent UI.

Exact validation run:
- `/home/derrick/.local/bin/godot --headless --path .testbed --script res://scripts/proving_harness.gd --check-only`
- `git diff --check`

---

### Task 5: QA the clean-base slice before deeper functionality work resumes

**Bead ID:** `oc-mkyr`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Independently verify that the clean-base slice is actually ready: sidecar lifecycle semantics are safer/clearer, platform handling is truthful, the Boxing header overlap is gone, and the preview surface fits without crushing neighboring UI. Explicitly call out what is source-proven versus what still needs Derrick’s direct runtime truth pass.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / QA notes only unless a truthful docs correction is required

**Status:** ✅ Complete

**Results:** QA completed. Overall verdict: this clean-base slice passes strongly enough at the **source / static-validation level** to unblock deeper functionality work, but it still needs Derrick’s **direct runtime truth pass** before anyone claims the live experience is fully proven.

Exact QA findings by scope:

1. **Sidecar lifecycle semantics are materially safer/clearer in source (`REF-01`, `REF-02`, `REF-07`).** `src/process/desktop_sidecar_launcher.gd` now generates and records an explicit per-launch `sidecar_identity`, appends it to argv on Linux/macOS/Windows, and keeps Linux process-group launch as the primary lifecycle surface. `src/autostart_manager.gd` no longer does the earlier broad Linux prelaunch kill sweep, no longer contains the dangerous generic `pkill -f main.py` cleanup, and no longer contains `/dev/video0` `fuser` cleanup. The remaining Linux fallback kill is explicitly narrowed to `pkill -9 -f -- --sidecar-identity=<token>`, which is materially safer because it targets this repo-owned launch identity instead of broad filenames/device users.

2. **Platform handling is now source-truthful instead of accidentally implying parity (`REF-01`, `REF-02`).** The launcher’s macOS and Windows notes explicitly describe those lanes as direct-PID scaffolding with identity markers and say they remain unvalidated on this Linux host. That is the right truth boundary for this slice: Linux is the only path with source evidence of richer launch/stop orchestration; macOS/Windows are intentionally scaffolded, not proven equivalent.

3. **Boxing header overlap is gone in scene structure (`REF-04`, `REF-06`).** `.testbed/scenes/boxing_proving.tscn` now places `HeaderIcon` and `TitleLabel` under `Margin/VSplit/Header/HeaderRow` instead of leaving the icon positioned independently at the root. Source-wise, that removes the earlier structural cause of the title/icon overlap.

4. **Preview surface fit is constrained in source/layout (`REF-03`, `REF-04`, `REF-06`).** The placeholder `CameraDisplay` in the Boxing scene still uses keep-aspect-centered stretch (`stretch_mode = 5`) with a bounded minimum size, and `.testbed/scripts/proving_harness.gd` now copies that placeholder layout contract onto the runtime `MediaPipeCameraView` (`custom_minimum_size`, layout mode, size flags, expand mode, stretch mode) before replacing the placeholder. Combined with `src/camera_view.gd`’s aspect-aware display math, this is strong source evidence that the preview should preserve aspect ratio inside the panel without crushing neighboring UI.

5. **Source-proven vs live-runtime truth line is clear.** Source/static proof is strong for the structural fixes above, but live runtime is still not claimed here. This QA pass did **not** prove on-host behavior for: real sidecar start/stop under Godot, heartbeat-only exit timing, Linux fallback cleanup only hitting the intended process under actual failure conditions, macOS/Windows lifecycle behavior on native hosts, or visual confirmation that the camera panel behaves correctly with live/prerecorded frames in a real rendered window. Those remain Derrick runtime checks.

Exact validation run during QA:
- `python3 -m py_compile python_mediapipe/args.py python_mediapipe/main.py`
- `/home/derrick/.local/bin/godot --headless --path .testbed --script res://scripts/proving_harness.gd --check-only`
- `git diff --check`
- focused Python scene assertion pass confirming `HeaderRow`, nested `HeaderIcon`/`TitleLabel`, keep-aspect camera display, and bounded camera minimum size in `.testbed/scenes/boxing_proving.tscn`
- focused Python source assertion pass confirming explicit `--sidecar-identity` plumbing/logging, removal of broad `main.py` cleanup, removal of `fuser`, and runtime camera-view layout inheritance

QA conclusion: **Pass for clean-base source readiness.** I would let deeper functionality work resume from this base, with the explicit caveat that Derrick should still do one direct runtime pass to confirm live start/stop behavior and rendered UI behavior before anyone overstates completion.

---

### Task 6: Audit the clean-base slice and decide whether it is ready for the larger functionality bug pass

**Bead ID:** `oc-xk27`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Audit the final diff, validation evidence, and QA findings for this clean-base slice. Confirm whether the sidecar lifecycle and proving-scene UI issues are resolved strongly enough that Derrick should move on to the larger trails/gesture/functionality backlog from a cleaner baseline.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / audit notes only

**Status:** ✅ Complete

**Results:** Auditor verdict: **Pass for clean-base readiness, with explicit live-runtime caveats.** I independently re-read the claimed source surfaces (`REF-01`, `REF-02`, `REF-04`, `REF-06`, `REF-07`), inspected the committed implementation chain (`59d795b`, `5ab0df9`, `8920cb4`), and reran the repo-level static checks that are truthful on this host: `python3 -m py_compile python_mediapipe/args.py python_mediapipe/main.py`, `/home/derrick/.local/bin/godot --headless --path .testbed --script res://scripts/proving_harness.gd --check-only`, and `git diff --check`.

What is now good enough to treat as a cleaner base for deeper functionality work:
1. **Sidecar lifecycle targeting is materially safer in source (`REF-01`, `REF-02`, `REF-07`).** The old broad Linux host sweeps are gone from the normal path: no prelaunch `pkill -f python_mediapipe/main.py`, no generic `pkill -9 -f main.py`, and no `/dev/video0` `fuser` kill. Each launch now carries an explicit `--sidecar-identity=<token>` marker, that identity is recorded in launcher state and logged by Python, and the remaining Linux fallback cleanup is narrowed to that explicit token instead of generic filenames.
2. **Platform truth is clearer and less misleading (`REF-01`, `REF-02`).** Linux remains the only source-proven rich lifecycle path; macOS/Windows are now described truthfully as direct-PID scaffold lanes with identity markers, not implied parity.
3. **The Boxing header overlap fix is structural, not cosmetic (`REF-04`, `REF-06`).** `HeaderIcon` is no longer a root-positioned overlay; it now lives beside `TitleLabel` inside `HeaderRow`, which removes the overlap cause at scene-structure level.
4. **Preview-fit/layout is structurally tightened (`REF-03`, `REF-04`, `REF-06`).** The runtime `MediaPipeCameraView` now inherits the placeholder `CameraDisplay` layout contract before replacement, so the intended panel bounds and keep-aspect behavior are preserved in source instead of relying on default TextureRect behavior.

What remains unverified and must still be treated as Derrick-only runtime truth:
1. **Actual live start/stop behavior on a rendered host session is not proven by this audit.** I did not witness a real sidecar launch, heartbeat timeout, graceful stop, or forced cleanup sequence under a live Godot window.
2. **The narrowed Linux fallback `pkill -f -- --sidecar-identity=...` is source-safe in intent but not live-proven here under failure conditions.** I am not claiming runtime proof that it always catches only the intended process in every host scenario.
3. **macOS and Windows lifecycle behavior remain unvalidated scaffold lanes.** The source wording is now honest, but there is still no native-host proof of launch/teardown parity.
4. **The visual fixes are structurally convincing, but not visually witnessed in a live rendered scene during this audit.** I am not claiming screenshot/window proof from this pass.

Bottom line: this slice is **clean enough to use as the base for the larger functionality bug pass** because the risky cleanup semantics and the obvious proving-shell layout defects have been reduced to a more truthful, source-sound baseline. It should **not** be oversold as fully runtime-validated completion.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** A cleaner MediaPipe proving baseline: safer sidecar identity/cleanup semantics, a structurally fixed Boxing header, and preview layout inheritance that should keep the runtime camera surface within its intended bounds while preserving aspect ratio.

**Reference Check:** `REF-01`, `REF-02`, `REF-04`, `REF-06`, and `REF-07` were re-audited directly against committed source. `REF-03` remains indirectly validated through the proving-harness layout handoff rather than a live rendered runtime pass. No deliberate deviations were found from the stated clean-base scope.

**Commits:**
- `59d795b` - Tighten mediapipe sidecar identity cleanup
- `5ab0df9` - Fix proving preview layout bounds
- `8920cb4` - Fix boxing proving header layout

**Lessons Learned:** For this repo, source-level cleanup safety and UI structure can be audited with good confidence, but lifecycle truth and rendered-layout truth still need an explicit live-host pass before anyone claims more than a clean base.

---

*Created on 2026-05-12*
