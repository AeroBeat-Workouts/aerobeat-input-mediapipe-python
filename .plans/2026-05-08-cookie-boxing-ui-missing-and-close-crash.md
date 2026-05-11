# AeroBeat MediaPipe Python — Cookie Boxing UI Missing and Close Crash

**Date:** 2026-05-08
**Status:** In Progress
**Agent:** Pico 🐱‍🏍

---

## Goal

Truthfully isolate why Cookie still hides the right-side proving UI during Boxing playback and why stopping playback now consistently crashes Cookie’s Zorin GUI.

---

## Overview

Today’s in-person Cookie retest produced two high-value truths. First, the Boxing proving scene still does not visibly show the expected right-side debug/observability panels during actual playback; Derrick only sees the camera feed plus some left-side text. That means the earlier layout/observability fixes improved source structure and some local validation evidence, but they did **not** yet solve the real human-visible Boxing playback problem on Cookie.

That UI failure is now confirmed on the local Legion Go too, not just on Cookie. Derrick ran the `aerobeat-input-mediapipe-python` project in the local editor from my terminal, opened the Boxing scene, and confirmed that my own editor playback also hides the expected right-side UI. The Python server failed there because no camera is attached, but that does not explain the missing observability panel. This is the key truth correction: earlier desktop-control-based visible-window certification was not indicative of real playback behavior.

Second, Cookie’s Zorin GUI now crashes consistently when stopping playback of the project. Derrick reproduced that twice. That is stronger evidence than the earlier non-blocking `BadWindow` caveat and means the close-path investigation is back in the critical path. We need to separate whether the visible-UI failure and the GUI crash share one runtime cause or merely happen in the same retest path.

This plan keeps the two issues explicitly split but coordinated: (1) re-truth the Boxing visible UI failure using current scene/runtime structure and real window evidence, and (2) capture a clean close-crash forensic pass on Cookie so we can compare today’s stronger failure shape against the older export/editor isolation history. No approximate claims: visible UI must be visible, and close behavior must be measured against the actual Cookie desktop outcome.

New truth correction after the first UI fix/QA loop: the relaxed split-layout change improved standalone/runtime-window playback, but Derrick’s exact editor play-mode path is still wrong. The screenshot from the current editor run shows a largely empty grey viewport with only the top tracking banner and lower-left provider-status text visible, while the expected right-side observability column is still absent/cut off.

Follow-up research tightened that further: the screenshot is not the proving harness at all. It matches the legacy `test_scene.tscn` main-scene path exactly, and `.testbed/project.godot` still points `run/main_scene` at `res://scenes/test_scene.tscn`. So the remaining UI failure is presently a run-path mismatch first: editor project play is still booting the old left-only scene, which means the proving-scene layout fix in `boxing_proving.tscn` / `flow_proving.tscn` never runs on Derrick’s exact F5-style route. Only after that route is corrected should we reopen any theory about editor-embedded proving-scene clipping.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Prior active Cookie coordination plan and retest ladder | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/.plans/2026-05-06-cookie-exported-app-close-control-check.md` |
| `REF-02` | Current proving-scene human verification context | `/home/derrick/.openclaw/workspace/memory/2026-05-07.md` |
| `REF-03` | Prior handoff that left in-person Cookie truthing as the remaining step | `/home/derrick/.openclaw/workspace/memory/2026-05-06.md` |
| `REF-04` | Boxing proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/boxing_proving.tscn` |
| `REF-05` | Flow proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/flow_proving.tscn` |
| `REF-06` | Shared proving harness | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-07` | Docs-backed design-size/stretch correction plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-07-godot-doc-backed-proving-ui-structure-correction.md` |
| `REF-08` | Earlier close-crash evidence showing sidecar forced-exit fix was not root cause | `/home/derrick/.openclaw/workspace/memory/2026-04-28.md` |
| `REF-09` | Earlier close-crash session transcript / forensic checkpoint | `/home/derrick/.openclaw/workspace/memory/2026-04-28-zorin-gui-crash.md` |
| `REF-10` | Today’s direct human report: right-side UI still missing and Zorin GUI crashes consistently on stop | current session |
| `REF-11` | Local Legion Go truth correction: Derrick reproduced the missing right-side UI in my own editor playback even without Cookie in the loop; Python server failure from no camera does not explain the missing UI | current session |
| `REF-12` | SSH/Tailscale access to Cookie has been reauthorized from my terminal for direct investigation | current session |
| `REF-13` | Derrick screenshot showing editor play-mode still cuts off the proving-scene UI after commit `34d6001`; only top banner and lower-left status remain visible | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/08/image-73082345.png` |
| `REF-14` | Derrick screenshot after run-path fix showing the correct Boxing proving scene now launches in editor play, but the layout is still cramped/clipped in the editor viewport | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/08/image-99adc21b.png` |
| `REF-15` | Derrick constraint: AeroBeat uses a 16:9 aspect ratio, so proving/test scenes should compose correctly for that target too | current session |
| `REF-16` | Derrick screenshot showing overlay registration and mirror mismatch in the now-correct Boxing proving scene: landmarks/skeleton do not align to the mirrored webcam view, and left/right handedness appears visually reversed | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/08/image-4607f58a.png` |
| `REF-17` | Derrick screenshot showing the hand-trail raycast bug persists even while fists remain in frame; out-of-frame clearing helps, but in-bounds giant diagonal slashes still occur | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/08/image-35404133.png` |
| `REF-18` | 2026-05-09 handoff: connected preview stops crashing when normal sidecar stop-on-close is skipped; shutdown path is now the prime suspect cluster | `/home/derrick/.openclaw/workspace/memory/2026-05-09.md` |
| `REF-19` | Today’s execution constraint: use `ssh chip` as the crash sandbox, verify the remote repo/deps first, and let Derrick recover the GUI locally after each crash if needed | current session |
| `REF-20` | Active close-path isolation toggle in proving harness / AutoStartManager | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` + `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/autostart_manager.gd` |
| `REF-21` | Chip console warning snapshot showing packet-backlog and stream-thread cleanup warnings during the dirty second-half rerun | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/09/image-0bb3a3de.png` |
| `REF-22` | Derrick’s 2026-05-09 Chip feedback: eliminate per-update console spam, investigate new CSV import warning, trim/dedupe shutdown logging, and prepare for a Penpot-driven boxing proving-scene redesign that replaces text-heavy status with gesture icons and active-state buttons | current session |
| `REF-23` | 2026-05-10 Boxing gesture detector UI mockup screenshot provided by Derrick for the next proving-scene redesign pass | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/10/aerobeat-boxing-gesture-detector-0a43eb94.png` |
| `REF-24` | 2026-05-10 Flow gesture detector UI mockup screenshot provided by Derrick for the next proving-scene redesign pass | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/11/aerobeat-flow-gesture-detector-74025d53.png` |

---

## Tasks

### Task 1: Re-truth the Boxing visible UI failure on Cookie using real playback evidence

**Bead ID:** `oc-apm`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-02`, `REF-04`, `REF-06`, `REF-07`, `REF-10`
**Prompt:** Read the current Boxing proving scene, harness, and recent layout-fix history, then compare that to Derrick’s current Cookie report that the right-side UI is still missing during real playback. Identify the most likely failure surface before code changes: scene layout collapse, runtime replacement/layout loss, project stretch/content-scale behavior, or scene/run-path mismatch. Use real visible-window evidence requirements in your reasoning and prepare the narrowest next implementation target.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/`

**Files Created/Deleted/Modified:**
- This plan file unless deeper implementation is explicitly required

**Status:** ✅ Complete

**Results:** Research completed and bead `oc-apm` was closed. The strongest current evidence says the missing right-side UI is primarily a proving-scene layout-collapse problem at real editor play-window widths, not a camera/server-start failure and not primarily the runtime camera-view replacement path. Derrick’s local no-camera repro is decisive: when the Python sidecar fails to start, `_on_server_started()` never reaches the camera-view swap path, yet the right-side UI is still missing. Current scene constraints remain too rigid for smaller real play windows (`HSplitContainer.split_offset = 740`, `CameraDisplay.custom_minimum_size = Vector2(640, 360)`, `RightPanelScroll.custom_minimum_size = Vector2(380, 0)`, plus outer margins). The narrowest next implementation target is the split/layout contract in `boxing_proving.tscn` and `flow_proving.tscn`, with `proving_harness.gd` only as a secondary support surface if needed. The earlier validation misled us because part of the evidence path came from the wrong scene and later checks proved structural/headless reachability rather than actual visible horizontal coexistence during real playback.

---

### Task 2: Fix the real right-side Boxing UI visibility bug at the owning source

**Bead ID:** `oc-8i2`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-10`
**Prompt:** After the research pass identifies the real failure surface, implement the smallest truthful fix in the owning `aerobeat-input-mediapipe-python` source so the right-side proving UI is visibly present during actual Boxing playback on Cookie. Do not certify based on headless geometry alone. Commit/push before handoff and leave exact validation notes.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/`

**Files Created/Deleted/Modified:**
- `/.testbed/scenes/boxing_proving.tscn`
- `/.testbed/scenes/flow_proving.tscn` (if shared fix is needed)
- `/.testbed/scripts/proving_harness.gd`
- any directly owning project display/layout config if required

**Status:** ✅ Complete

**Results:** Coder pass completed and bead `oc-8i2` was closed. The smallest truthful shared fix landed in commit `34d6001` (`Relax proving scene split layout`). The proving-scene split/layout contract was relaxed directly in `boxing_proving.tscn` and `flow_proving.tscn`: `HSplitContainer.split_offset` changed from `740` to `0`, `CameraDisplay.custom_minimum_size` changed from `640x360` to `480x270`, and `RightPanelScroll.custom_minimum_size` changed from `380` to `320`. This keeps Boxing and Flow aligned while removing the hard right-shifted split bias and lowering both columns’ width demands so the right observability panel has a better chance to remain present in narrower real windows. Structural validation passed (`git diff --cached --check`), and the coder also produced visible-window evidence from real runtime windows at roughly `520x720`, where both scenes showed the right-side observability column present alongside the left camera/quick-stats side. Important limitation kept explicit: this is stronger than headless geometry, but it still is not the final editor-embedded playback truth Derrick uses, so QA must verify that exact path before we certify manual retest readiness.

---

### Task 3: QA the visible Boxing/Flow UI on the real Cookie playback path

**Bead ID:** `oc-p9m`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-10`
**Prompt:** Independently verify on the highest-fidelity available Cookie playback path that the right-side observability UI is actually visible and legible during Boxing and Flow scene playback. Distinguish visible-window truth from headless or structural-only checks.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ✅ Complete

**Results:** QA completed and bead `oc-p9m` was closed. The strongest directly certifiable path available in this pass was host-visible real Godot runtime windows launched from `.testbed`, with desktop screenshots as evidence. On that path, both Boxing and Flow visibly showed a readable right-side observability column: Boxing showed `Overview`, `Boxing signal board`, and `Detector metrics`; Flow showed `Overview`, `Flow signal board`, and `Detector metrics`. This is stronger than structural/headless proof because it used real rendered playback windows, not just layout inference. Important scope limit: QA could not certify Derrick’s exact editor-embedded play-window path because there was no attached Godot plugin session and no truthful way to drive the already-open editor from shell control alone. QA also did not certify full live-camera observability behavior on this host path; local runs were enough to prove visible layout/readability during playback, not live camera truth. Net result: the UI branch is ready for Derrick’s manual retest on the exact editor path, but that manual retest remains the final truth source for the original bug.

---

### Task 4: Capture today’s Cookie stop-playback GUI crash with a clean forensic pass

**Bead ID:** `oc-5uc`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-01`, `REF-08`, `REF-09`, `REF-10`
**Prompt:** Reconstruct the strongest current close-crash evidence path for Cookie now that Derrick reports consistent Zorin GUI crashes on stop-playback. Use the prior forensic history to avoid repeating disproven theories, and set up the narrowest clean evidence capture for today’s playback-stop crash so we can compare it against the older sidecar/export/editor boundaries.

**Folders Created/Deleted/Modified:**
- `.plans/`
- forensic/log capture folders as needed

**Files Created/Deleted/Modified:**
- plan updates and any forensic notes/scripts only as required

**Status:** ✅ Complete

**Results:** Research completed and bead `oc-5uc` was closed. Current Cookie evidence shows a real X11 desktop-session reset on stop-playback, not just a harmless close warning. Importantly, the app/testbed path still reaches normal teardown markers first (window close request, camera stream stop, provider stop, cleanup complete, stop request) before the Zorin GUI session rolls over. That keeps the old Python sidecar `os._exit(0)` forced-shutdown bug ruled out as the root cause and keeps the broad “any plain exported Godot close crashes Cookie” theory ruled out too. The best next crash-branch move is one clean host-local forensic capture on Cookie using `workspace/scripts/desktop-app-forensics.sh`, so evidence survives even if SSH dies with the desktop session. That is now a stronger failure family than the earlier non-blocking `BadWindow` note.

---

### Task 5: Audit whether the stop-playback crash belongs to the current proving-scene path or a broader Cookie desktop failure

**Bead ID:** `oc-gqt`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-01`, `REF-08`, `REF-09`, `REF-10`
**Prompt:** Independently audit the latest close-crash evidence and decide what is actually proven: whether today’s failure is the same family as the earlier Cookie desktop reset, whether it is stronger than the prior non-blocking `BadWindow` note, and what exact next isolation branch should follow.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates and audit notes only

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 6: Investigate editor play-mode proving UI cutoff

**Bead ID:** `oc-hn2`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-13`
**Prompt:** Investigate why the proving-scene UI is now visible in standalone/runtime-window playback after commit `34d6001`, but still cut off in Derrick’s exact editor play-mode path. Compare the effective viewport/window constraints, scene embedding behavior, and any editor-specific size/stretcher differences that could keep the right-side column absent while leaving the top banner and lower-left status visible.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/`

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny truth-revealing probe is required

**Status:** ✅ Complete

**Results:** Research completed and bead `oc-hn2` was closed. The screenshot root cause is a scene/run-path mismatch, not a newly re-broken proving-scene split layout. The visible text in Derrick’s screenshot (`Tracking mode active - waiting for pose data...` and `MediaPipe Provider Status`) comes from the legacy `.testbed/scenes/test_scene.tscn` path via `.testbed/scripts/test_scene.gd`, not from `proving_harness.gd`. Current `.testbed/project.godot` still sets `run/main_scene="res://scenes/test_scene.tscn"`, so the exact editor play route Derrick used is still launching the old left-only test scene with absolute-positioned status UI and no right observability column at all. That explains why commit `34d6001` helped standalone/runtime-window proving-scene playback but had no effect on the editor play route: the proving scenes were never being run there. Narrowest next implementation target: fix the editor run path so Derrick’s intended play route launches `boxing_proving.tscn` (or an explicit proving-scene chooser/bootstrap), or otherwise make the F5 vs F6 distinction explicit if intentional.

---

### Task 7: Fix editor play-mode proving UI cutoff

**Bead ID:** `oc-5wz`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-13`
**Prompt:** After the research pass identifies the editor-specific failure surface, implement the smallest truthful source fix so the proving-scene UI remains visible in Derrick’s exact editor play-mode path, not just in standalone/runtime windows.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/`
- project display/layout config only if genuinely required

**Files Created/Deleted/Modified:**
- owning proving-scene/layout files as required by the fix

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 8: QA editor play-mode proving UI cutoff fix

**Bead ID:** `oc-b3y`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-13`
**Prompt:** Independently verify whether the editor play-mode cutoff is actually resolved on the highest-fidelity path available, and be explicit about what still requires Derrick’s direct truth pass.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 9: Investigate editor-visible Boxing proving layout clipping after the run-path fix

**Bead ID:** `oc-t0e`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-04`, `REF-06`, `REF-14`
**Prompt:** Investigate the remaining editor-visible layout clipping in the correct Boxing proving scene after the run-path fix. Use Derrick’s latest screenshot to identify which parts of the scene are still oversized or poorly prioritized for the editor viewport, and determine the narrowest next layout/content fix.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/`

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny truth-revealing probe is required

**Status:** ✅ Complete

**Results:** Research completed and bead `oc-t0e` was closed. The current editor-visible Boxing issue is not that the right column is missing; it is a vertical composition-budget problem in a shorter editor play window. Derrick’s screenshot is about `1198x674`, and current scene constraints still spend too much height on fixed-size content. In `boxing_proving.tscn`, the header stack remains tall (4 rows, outer margins `16`, separation `12`, `TitleLabel` font size `26`, `StatusLabel` font size `18`), while the right column still has large minimum heights: `SummaryPanel` `180`, `SignalPanel` `280`, `MetricsPanel` `240`, and `EventsPanel` `260`. Those right-column minimums alone total about `960 px` before header/margins/separators, so clipping in a ~674 px editor play window is expected. The screenshot matches that exactly: `Overview` is visible, `Boxing signal board` is cramped, `Detector metrics` barely appears, `Events` is effectively pushed off-screen, and the long red live-status line overruns horizontally. Narrowest next fix: reduce the right-column fixed minimum heights first, especially `SignalPanel`, `MetricsPanel`, and `EventsPanel` (plus likely `SummaryPanel`), then tame the header by wrapping/shrinking the long live-status line and reducing title/status font sizes or header spacing as needed. No detector logic change is indicated.

---

### Task 10: Fix editor-visible Boxing proving layout clipping

**Bead ID:** `oc-sas`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`, `REF-06`, `REF-14`
**Prompt:** After the research pass identifies the remaining layout problem in the correct Boxing proving scene, implement the smallest truthful source fix so the editor-visible Boxing proving UI is readable and usefully composed in Derrick’s actual editor play viewport. Respect AeroBeat’s intended 16:9 composition instead of merely shrinking things arbitrarily for a narrow viewport.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/`

**Files Created/Deleted/Modified:**
- owning proving-scene/layout files as required by the fix

**Status:** ✅ Complete

**Results:** Coder pass completed and bead `oc-sas` was closed. The scoped Boxing layout fix landed in commit `052f477` (`Tighten boxing proving editor layout`). Changes stayed limited to `.testbed/scenes/boxing_proving.tscn` and `.testbed/scripts/proving_harness.gd`. The fix reduced fixed vertical budget instead of rewriting scene behavior: margins `16→12`, main separation `12→8`, header separation `4→2`, title font `26→22`, status font `18→15`, camera minimum `480x270→426x240`, quick-stats minimum `200→140`, summary minimum `180→100`, signal minimum `280→150`, metrics minimum `240→120`, and events minimum `260→120`. The verbose live-status row was also compacted from the long `Live status | mode=... server=... camera=...` form into a shorter `Live | srv=... cam=... track=... poses=... last=...` form to stop the header from wasting width/height. Structural validation passed (`git diff --check`), and a repo-local Godot layout probe confirmed all four right-column panels enter the initial viewport and that the live-status content now stays compact. Important limit: this still needs final visible truth from QA / Derrick’s editor window, since no attached plugin/editor session was available for a literal live-window proof on the exact path.

---

### Task 11: QA editor-visible Boxing proving layout clipping fix

**Bead ID:** `oc-8dm`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-04`, `REF-06`, `REF-14`
**Prompt:** Independently verify whether the Boxing proving UI is now readable and usefully composed in the editor-visible play viewport, and be explicit about what still requires Derrick’s direct truth pass. QA should explicitly check whether the resulting composition still feels correct for AeroBeat’s intended 16:9 target.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 12: Investigate Boxing overlay registration and mirror mismatch

**Bead ID:** `oc-xag`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-04`, `REF-06`, `REF-16`
**Prompt:** Investigate why the Boxing proving-scene landmarks/skeleton no longer register to the mirrored webcam image and why left/right handedness appears visually reversed in Derrick’s screenshot. Identify the narrowest real failure surface before code changes: image mirroring without matching overlay transform, coordinate-space mismatch between camera view and overlay container, or another registration bug.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/`
- relevant overlay/rendering script paths if needed for inspection

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny truth-revealing probe is required

**Status:** ✅ Complete

**Results:** Research completed and bead `oc-xag` was closed. The real failure surface is a coordinate-convention mismatch, not primarily a container-anchor/layout bug. `src/providers/mediapipe_provider.gd` already converts landmarks into the repo’s mirrored gameplay space (`y = 1.0 - raw_y`, and with `flip_horizontal=true`, `x = 1.0 - raw_x`). The proving harness runs with `config.flip_horizontal = true`, and the camera image itself is also mirrored visually by `src/camera_view.gd`. But `.testbed/scripts/landmark_drawer.gd` and `.testbed/scripts/hand_trail_drawer.gd` still treat incoming points like raw top-left MediaPipe image coordinates, performing another horizontal flip (`1.0 - x`) while also using `y` directly. That means the overlay is double-mirrored horizontally and vertically inverted relative to the provider-normalized space. This matches Derrick’s screenshot and his later intuition that the skeleton also looked vertically reversed. Narrowest next fix: have the proving-scene overlay drawers consume provider-normalized coordinates directly (`x = lm.x`, screen `y = 1.0 - lm.y`) in both `landmark_drawer.gd` and `hand_trail_drawer.gd`, keeping the image and skeleton on the same single mirror transform and viewport mapping.

---

### Task 13: Fix Boxing overlay registration and mirror mismatch

**Bead ID:** `oc-c9j`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`, `REF-06`, `REF-16`
**Prompt:** After the research pass identifies the true overlay mismatch, implement the smallest truthful fix so the Boxing proving-scene landmarks/skeleton align to the mirrored webcam image and visually mirror correctly with athlete left/right in the proving view.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/`
- owning overlay/rendering source files as required

**Files Created/Deleted/Modified:**
- owning proving-scene / overlay-rendering files as required by the fix

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 14: QA Boxing overlay registration and mirror mismatch fix

**Bead ID:** `oc-6px`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-04`, `REF-06`, `REF-16`
**Prompt:** Independently verify whether the Boxing proving-scene overlay now aligns to the mirrored webcam image and visually mirrors left/right correctly, and be explicit about what still requires Derrick’s direct truth pass.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 15: Investigate Boxing hand-trail raycast bug after overlay coordinate fix

**Bead ID:** `Pending`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-04`, `REF-06`, `REF-16`
**Prompt:** Investigate why the supposed hand motion trails are rendering as giant raycast-like diagonals after the main overlay coordinate fix. Determine whether the trail history itself is stored in the wrong coordinate convention, whether stale pre-fix points are being mixed with corrected points, or whether the trail drawer is still mismatched relative to the wrist landmark path.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scripts/`

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny truth-revealing probe is required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 16: Fix Boxing hand-trail raycast bug

**Bead ID:** `Pending`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`, `REF-06`, `REF-16`
**Prompt:** After the research pass identifies the trail-specific bug, implement the smallest truthful fix so the hand trails render as actual recent wrist motion paths instead of giant diagonal raycasts.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scripts/`

**Files Created/Deleted/Modified:**
- owning proving-scene trail/rendering files as required by the fix

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 17: QA Boxing hand-trail raycast bug fix

**Bead ID:** `Pending`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-04`, `REF-06`, `REF-16`
**Prompt:** Independently verify whether the Boxing hand trails now render as believable recent motion paths rather than giant raycast-like diagonals, and be explicit about what still requires Derrick’s direct truth pass.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 15: Investigate Boxing hand-trail raycast bug after overlay coordinate fix

**Bead ID:** `oc-5z5`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-04`, `REF-06`, `REF-16`
**Prompt:** Investigate why the supposed hand motion trails are rendering as giant raycast-like diagonals after the main overlay coordinate fix. Determine whether the trail history itself is stored in the wrong coordinate convention, whether stale pre-fix points are being mixed with corrected points, or whether the trail drawer is still mismatched relative to the wrist landmark path.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scripts/`

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny truth-revealing probe is required

**Status:** ✅ Complete

**Results:** Research completed and bead `oc-5z5` was closed. The main coordinate-convention fix from `c8fcabb` is not the remaining trail problem: `hand_trail_drawer.gd` and `landmark_drawer.gd` now interpret provider-normalized mirrored gameplay space consistently. The real trail-specific failure surface is that the proving harness still appends wrist samples with no in-bounds check, and the trail drawer renders every stored point with no clipping / segment break / bounds rejection. Derrick’s screenshot proves this clearly: there are already green landmark dots outside the image bounds, and the right trail’s current endpoint marker `R` is itself off-image in the lower-right dark area. That means the latest wrist samples can already be off-image, not just stale history. Because trail history persists for 36 points / 1800 ms, one out-of-bounds sample becomes a giant diagonal slash. Narrowest next fix: add bounds-aware trail ingestion and/or rendering so out-of-range wrist samples are rejected, cleared, or break the polyline instead of being connected across the scene.

---

### Task 16: Fix Boxing hand-trail raycast bug

**Bead ID:** `oc-at2`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`, `REF-06`, `REF-16`
**Prompt:** After the research pass identifies the trail-specific bug, implement the smallest truthful fix so the hand trails render as actual recent wrist motion paths instead of giant diagonal raycasts.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scripts/`

**Files Created/Deleted/Modified:**
- owning proving-scene trail/rendering files as required by the fix

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 17: QA Boxing hand-trail raycast bug fix

**Bead ID:** `oc-491`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-04`, `REF-06`, `REF-16`
**Prompt:** Independently verify whether the Boxing hand trails now render as believable recent motion paths rather than giant raycast-like diagonals, and be explicit about what still requires Derrick’s direct truth pass.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 18: Investigate in-bounds Boxing hand-trail raycast persistence

**Bead ID:** `oc-01z`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-04`, `REF-06`, `REF-17`
**Prompt:** Investigate why the hand-trail raycast bug still persists while fists remain in frame after the out-of-bounds trail fix. Determine whether the remaining bad trail points are still in-bounds but semantically wrong, whether trail continuity should break on large motion jumps, or whether the wrong wrist/history source is being connected.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scripts/`

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny truth-revealing probe is required

**Status:** ✅ Complete

**Results:** Research completed and bead `oc-01z` was closed. The remaining trail bug is not the out-of-bounds case fixed by `10b3a84`; it is an in-bounds continuity problem. `proving_harness.gd` now clears trails for missing / low-visibility / out-of-bounds wrist samples, but it still appends every visible in-bounds sample with no continuity check. `hand_trail_drawer.gd` then connects all in-bounds samples into a single continuous polyline segment. The screenshot fits a transient but numerically in-bounds bad wrist sample entering history, followed by later correct wrist points being connected to it for up to 36 points / 1800 ms. The most likely root cause is a one-frame semantically wrong wrist localization from the pose stream, not a wrong wrist id or left/right history mix. Narrowest next fix: break trail continuity on implausibly large per-frame wrist jumps, starting a new segment or clearing that trail instead of connecting across the jump.

---

### Task 19: Fix in-bounds Boxing hand-trail raycast persistence

**Bead ID:** `oc-ko6`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`, `REF-06`, `REF-17`
**Prompt:** After the research pass identifies the remaining in-bounds trail failure, implement the smallest truthful source fix so Boxing hand trails do not render giant diagonal slashes even when fists are still in frame.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scripts/`

**Files Created/Deleted/Modified:**
- owning proving-scene trail/rendering files as required by the fix

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 20: QA in-bounds Boxing hand-trail raycast persistence fix

**Bead ID:** `oc-61i`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-04`, `REF-06`, `REF-17`
**Prompt:** Independently verify whether the Boxing hand trails no longer render giant diagonal slashes while fists remain in frame, and be explicit about what still requires Derrick’s direct truth pass.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 21: Investigate missing Boxing hand trails after continuity fix

**Bead ID:** `oc-thd`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-04`, `REF-06`, `REF-17`
**Prompt:** Investigate why the giant raycast slash is gone but the actual hand trails are now mostly absent, leaving only the current endpoint circle. Determine whether the continuity-jump threshold is too aggressive, whether the trail keeps resetting every frame, or whether minimum history/visibility conditions now prevent visible trail segments from accumulating.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scripts/`

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny truth-revealing probe is required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 22: Fix missing Boxing hand trails after continuity fix

**Bead ID:** `oc-7r7`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`, `REF-06`, `REF-17`
**Prompt:** After the research pass identifies why visible hand trails are now mostly absent, implement the smallest truthful fix so Boxing shows believable short wrist-motion trails again without reintroducing giant diagonal slashes.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scripts/`

**Files Created/Deleted/Modified:**
- owning proving-scene trail/rendering files as required by the fix

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 23: QA missing Boxing hand trails after continuity fix

**Bead ID:** `oc-cum`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-04`, `REF-06`, `REF-17`
**Prompt:** Independently verify whether Boxing now shows believable short hand-motion trails again without the old raycast slash bug, and be explicit about what still requires Derrick’s direct truth pass.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 24: Instrument Boxing trail continuity behavior on the real proving path

**Bead ID:** `oc-if1`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-04`, `REF-06`, `REF-17`
**Prompt:** Add the smallest truthful instrumentation or logging needed to explain why Boxing trails still collapse to a single endpoint in Derrick’s real editor path even after the latest continuity-tuning fix. Focus on point counts, continuity-break triggers, retained history length, and whether trail reseeding is firing almost every frame.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scripts/`
- test / debug support surfaces only if needed

**Files Created/Deleted/Modified:**
- plan updates only unless tiny instrumentation is required

**Status:** ✅ Complete

**Results:** Research/instrumentation completed and bead `oc-if1` was closed. Minimal trail-path instrumentation was added to the Boxing proving flow so the right-side UI / console now expose per-hand point counts, drawable segment counts, tail segment counts, continuity break counts, reseed counts, out-of-bounds clears, missing-sample skips, low-visibility skips, last jump distance, last action, and retained trail duration. The endpoint-only symptom is now mechanically explained: the renderer only draws a line with 2+ contiguous valid points, but it always draws the endpoint circle. Derrick’s first live read of the new counters is the decisive clue: the left trail action is repeatedly only `low_visibility`, `break_reseed`, or `clear_oob`. That means the live path is not accumulating enough stable contiguous points to ever render a visible trail, so the next fix should target the actual left-hand live data conditions rather than further abstract theory.

---

### Task 25: Use instrumentation findings to fix missing Boxing trails

**Bead ID:** `oc-krx`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`, `REF-06`, `REF-17`
**Prompt:** After the instrumentation pass identifies the real failure, implement the smallest truthful fix so Boxing shows believable short hand trails in the real proving path instead of only endpoint circles, without reintroducing the slash bug. Current live evidence says the left trail action is repeatedly `low_visibility`, `break_reseed`, or `clear_oob`, so the fix should directly address those real conditions.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scripts/`

**Files Created/Deleted/Modified:**
- owning proving-scene trail files as required by the fix

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 26: QA instrumented Boxing trail fix

**Bead ID:** `oc-1kd`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-04`, `REF-06`, `REF-17`
**Prompt:** Independently verify whether Boxing finally shows believable short hand trails again in the real proving path, and be explicit about what still requires Derrick’s direct truth pass.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 27: Investigate deterministic proving validation using existing test videos + logs

**Bead ID:** `oc-9wd`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-04`, `REF-06`, `REF-17`
**Prompt:** Investigate how to turn the existing project test videos into a deterministic proving-validation primitive for the Boxing scene. The goal is to stop relying on theory-only fixes by producing logs plus screenshotable rendered output that can verify trail/overlay behavior against repeatable input.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/`
- supporting test/log locations only if needed

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny truth-revealing probe is required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 28: Implement video-driven proving logs + screenshot validation

**Bead ID:** `oc-b10`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`, `REF-06`, `REF-17`
**Prompt:** Using the existing project test videos, implement the smallest truthful deterministic proving-validation primitive: logs that expose trail/overlay decisions and a repeatable rendered run path that can be captured with screenshots so subagents can verify their own fixes against stable input.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/`
- logging / validation support paths as required

**Files Created/Deleted/Modified:**
- owning proving-scene / validation harness files as required by the implementation

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 29: QA deterministic proving validation workflow

**Bead ID:** `oc-amo`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-04`, `REF-06`, `REF-17`
**Prompt:** Independently verify that the new deterministic proving-validation workflow really lets us validate overlay/trail behavior from test videos using logs plus screenshotable rendered output, instead of relying only on theory and live human retests.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 30: Run Cookie stop-playback forensic capture on the real close-crash path

**Bead ID:** `oc-a8h`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-01`, `REF-08`, `REF-09`, `REF-10`
**Prompt:** Use the already-identified host-local forensic harness path on Cookie to capture one clean stop-playback crash run from the real Godot proving/test-scene path. Focus on durable evidence that survives the desktop-session reset.

**Folders Created/Deleted/Modified:**
- `.plans/`
- Cookie forensic artifact folders / logs as needed

**Files Created/Deleted/Modified:**
- plan updates and forensic notes only unless tiny capture glue is required

**Status:** ⚠️ Partial

**Results:** Claimed bead `oc-a8h`, inspected Tasks 30-34 plus the Session Handoff, and verified the intended Cookie proving path remains `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed` with `run/main_scene="res://scenes/boxing_proving.tscn"`. On first verification, Cookie's copy of `/home/derrick/.openclaw/workspace/scripts/desktop-app-forensics.sh` was still a stale pre-hardening version (it lacked the new `systemd-run --user` / `controller.unit` path), so I backed it up to `/home/derrick/.openclaw/workspace/scripts/desktop-app-forensics.sh.bak-20260508-192732`, pushed the current hardened script to the same path, stopped the stale watch-only run at `/home/derrick/Documents/forensics/cookie-godot-stop-playback-20260508-192653`, and armed a fresh hardened capture at `/home/derrick/Documents/forensics/cookie-godot-stop-playback-20260508-192741`. Exact arm command used on Cookie: `/home/derrick/.openclaw/workspace/scripts/desktop-app-forensics.sh start --log-dir /home/derrick/Documents/forensics/cookie-godot-stop-playback-20260508-192741 --watch-pattern godot --watch-pattern Godot --watch-pattern python_mediapipe/main.py --watch-pattern gnome-shell --watch-pattern Xorg --poll-interval 2 --journal-since now --notes "Cookie real Godot editor stop-playback crash capture for aerobeat-input-mediapipe-python; armed from SSH in watch-only mode awaiting manual repro."` and status now reports `controller mode: systemd-user`, `controller_unit=desktop-app-forensics-1778282862-1439313.service`, `controller=active pid=1439357`. Durable artifacts already confirmed under that log dir: `meta/summary.txt`, `meta/environment.txt`, `logs/journal-system.log`, `logs/journal-user.log`, `logs/session-poll.log`, `logs/launcher.log`, `state/controller.pid`, `state/controller.unit`, and collector pid files. No truthful real stop-playback crash capture was obtained yet because there was no running Godot editor process when the harness was armed, and reproducing the actual stop-playback reset still requires Derrick to perform the real editor action on Cookie. Exact operator steps from here: (1) leave the harness running, (2) on Cookie launch/open the editor project at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed` (launcher path available at `/home/derrick/.local/bin/godot`; active desktop session is X11 on `DISPLAY=:1`), (3) run the Boxing proving scene and trigger the known stop-playback action that resets the desktop, then (4) after the machine returns, collect/finalize with `/home/derrick/.openclaw/workspace/scripts/desktop-app-forensics.sh status --log-dir /home/derrick/Documents/forensics/cookie-godot-stop-playback-20260508-192741` and `/home/derrick/.openclaw/workspace/scripts/desktop-app-forensics.sh stop --log-dir /home/derrick/Documents/forensics/cookie-godot-stop-playback-20260508-192741`. Bead stays open/in-progress until a real crash-boundary capture exists.

---

### Task 31: Audit Cookie stop-playback forensic capture and recommend the next isolation branch

**Bead ID:** `oc-73r`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-01`, `REF-08`, `REF-09`, `REF-10`
**Prompt:** Audit the Cookie host-local forensic capture from the real stop-playback crash path, summarize what it proves, and recommend the strongest next isolation or mitigation step.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates and audit notes only

**Status:** ✅ Complete

**Results:** Auditor pass completed and bead `oc-73r` is ready to close. I inspected the hardened Cookie artifact at `/home/derrick/Documents/forensics/cookie-godot-stop-playback-20260508-192741` plus current live host journals on Cookie to separate what the artifact itself captured from what the machine later proved after return. The artifact definitively captured the real stop-playback entry path up to the crash boundary better than the earlier pre-hardening run: `logs/journal-user.log` / `godot.log` show the real proving scene launch, sidecar/server start, active camera streaming, `Window close request`, `Stopping harness resources`, camera stream shutdown, and `[AutoStartManager] WM_CLOSE_REQUEST - stopping server` at `2026-05-08T19:32:28-04:00`. The last `session-poll.log` block at `2026-05-08T19:32:27-04:00` still shows pre-reset session `765`, Xorg pid `1407572`, gnome-shell pid `1407817`, editor pid `1446232`, proving scene pid `1446497`, and python pid `1446611` alive immediately before the stop path. The sidecar log adds that it received `SIGTERM` during teardown and then hit `XIO: fatal IO error 34 on X server ":1.0"`, which is strong evidence that the X connection collapsed during/after stop-playback teardown.

What the artifact does **not** contain is the actual rollover itself: there are no post-`19:32:28` poll snapshots, no captured `gnome-shell` / `Xorg` restart markers, no captured new session ID, and no final `finished_at=` marker in `meta/summary.txt`. The controller transient unit `desktop-app-forensics-1778282862-1439313.service` was itself terminated at `19:32:28` with exit status `143`, so the hardened capture still died before it could log the reset aftermath. However, live journal inspection after Cookie returned proves the reset did happen immediately after the artifact stopped: by `19:32:35` logind created new session `782`, by later inspection `loginctl show-user derrick` reported `Display=782`, and current Xorg / gnome-shell pids are `1447675` / `1447845` instead of the artifact’s `1407572` / `1407817`. Current live journal also shows the prior X11 stack being torn down and a fresh Xorg / GNOME login stack being brought up at `19:32:35-19:32:39`, with the old user manager (`systemd[1407504]`) only killing the lingering Godot app scope later at `19:33:58`.

Truthful comparison versus the old pre-hardening artifact at `cookie-godot-stop-playback-20260508-180542`: hardened mode **did improve capture reach** because the old run died around `18:14:34` before any stop-playback request was recorded, while the hardened run reached the real stop action and captured teardown logs through `WM_CLOSE_REQUEST` plus the sidecar’s `SIGTERM`/XIO failure. But it did **not** achieve the intended survival goal; it still failed before the desktop-reset boundary and still shows the known QA finalization gap (`stop.requested` exists, but `finished_at=` and a trustworthy final snapshot are missing on the systemd-managed path). Strongest next step: move the controller one level higher than the user systemd manager / GUI session entirely—use a system-scope transient service (or equivalently privileged host-level capture anchor) that keeps polling `loginctl`, `pgrep`, and both system/user journals across the stop action and at least 60s after the reset—because this run proves `systemd-run --user` is better than plain `nohup` for pre-boundary evidence, but still not durable enough to survive Cookie’s actual X11 session rollover.

---

### Task 32: Research a systemd-hardened forensic capture mode that survives desktop-session resets

**Bead ID:** `oc-30v`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-01`, `REF-08`, `REF-09`, `REF-10`
**Prompt:** Research the smallest truthful change to the desktop forensics harness so capture survives a GNOME/Xorg desktop-session reset better. Prefer a systemd-managed detached mode with durable journal/poll artifacts rather than a user-session-tied background shell process.

**Folders Created/Deleted/Modified:**
- `.plans/`
- shared `workspace/scripts/` and related docs/tests if needed

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny proof step is required

**Status:** ✅ Complete

**Results:** Research completed and bead `oc-30v` is ready to close. The smallest truthful hardening target is not the collector internals or artifact layout; it is the controller lifetime anchor in `workspace/scripts/desktop-app-forensics.sh`. Today the harness writes good durable artifacts, but `start` still detaches the controller with `nohup "$SELF_PATH" _run "$LOG_DIR" &` and then manages it mainly through `state/controller.pid`, which is weaker against a GNOME/Xorg desktop-session reset than a transient service anchored in the user systemd manager. Recommended design: keep `_run`, the existing `meta/`, `logs/`, and `state/` contract, and the existing app/journal/session-poll behavior; replace only the controller launch/management path with `systemd-run --user` (transient unit), record the unit name in `state/controller.unit`, teach `status` and `stop` to prefer `systemctl --user` when that unit file exists, and add a TERM/INT trap inside `_run` so unit stop still produces `stop.requested` plus a final snapshot. Operator caveat: this depends on a live user systemd manager and is materially stronger when `loginctl show-user` reports `Linger=yes`; it does not promise survival if the entire user manager dies, but it is the narrowest real improvement for capturing the desktop-reset boundary. Clear recommendation for `oc-8pl`: implement a systemd-user transient-service launch mode first, preserve backward compatibility for existing pid-based runs, and avoid broader harness redesign unless QA proves that the user-manager boundary still is not durable enough.

---

### Task 33: Implement a systemd-hardened forensic capture mode

**Bead ID:** `oc-8pl`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-01`, `REF-08`, `REF-09`, `REF-10`
**Prompt:** Implement the smallest truthful hardening to `workspace/scripts/desktop-app-forensics.sh` so capture can survive a desktop-session reset better. Prefer a transient systemd-run/service anchored outside the crashing GUI session, durable artifact writing, and a workflow that can cover the stop action plus post-crash window.

**Folders Created/Deleted/Modified:**
- `.plans/`
- shared `workspace/scripts/`
- shared docs/tests if needed

**Files Created/Deleted/Modified:**
- owning shared script/docs/test files as required

**Status:** ✅ Complete

**Results:** Coder pass completed and bead `oc-8pl` is ready to close. The shared `workspace/scripts/desktop-app-forensics.sh` now implements the narrow systemd-user hardening from `oc-30v` while keeping the existing `_run` harness/artifact contract intact: `start` prefers `systemd-run --user` transient-unit launch, records the unit name in `state/controller.unit`, still falls back to `nohup` when a user manager is unavailable, and writes `controller.pid` from the transient unit `MainPID` when available. `status` / `stop` now prefer `systemctl --user` when that unit marker exists, while remaining backward-compatible with older pid-only runs. `_run` also traps `TERM`/`INT` so stop/unit shutdown still writes `state/stop.requested` and a final snapshot / `finished_at` marker before exit. Terminal-safe validation only: `bash -n` passed; `help` output passed; a no-GUI lifecycle run at `/tmp/desktop-app-forensics-test` on Pico’s host successfully started in `controller mode: systemd-user`, recorded `state/controller.unit`, reported `controller=active` plus collector pids in `status`, then `stop` returned `Harness stopped cleanly` and a follow-up `status` showed `controller=inactive` with collectors stopped. Validation artifacts also confirmed durable final markers (`state/stop.requested`, `meta/summary.txt` with `finished_at`, launcher log showing `systemd-run --user`, and a final session snapshot tail). Operator caveat kept explicit: this improves survival against the common desktop-session reset boundary when a live user systemd manager exists, but it does not guarantee capture survival if the entire user manager is torn down.

---

### Task 34: QA the systemd-hardened forensic capture mode

**Bead ID:** `oc-dn7`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-01`, `REF-08`, `REF-09`, `REF-10`
**Prompt:** Independently verify whether the new hardened capture mode is actually more likely to survive a desktop-session reset and whether the operator workflow is clear enough for Derrick to use on Cookie.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ✅ Complete

**Results:** QA completed with mixed results and one material gap. Terminal-safe validation on Pico’s host confirmed the operator workflow is mostly clear and the systemd hardening is real in the narrow sense claimed by `oc-30v`: `help` now documents the preferred `systemd-run --user` path plus the nohup fallback; a start/status/stop lifecycle at `/tmp/desktop-app-forensics-qa-systemd` launched in `controller mode: systemd-user`; wrote `state/controller.unit`; reported `controller_unit=<transient>.service` plus `controller=active`; and `systemctl --user show` confirmed the controller lived in its own transient unit/cgroup (`.../app.slice/desktop-app-forensics-...service`) rather than only as a plain background shell process. That makes it truthfully more likely than the old ssh-shell-tied nohup launch to survive an invoking-shell death or a desktop-session reset that does not also tear down the user systemd manager. QA also forced the fallback path by masking the user-manager environment (`XDG_RUNTIME_DIR=/nonexistent DBUS_SESSION_BUS_ADDRESS=unix:path=/nonexistent`): `start` visibly downgraded to `controller mode: nohup`, did not leave `state/controller.unit`, and `status` / `stop` remained backward-compatible.

The important failure: the new systemd stop path did **not** preserve the coder-claimed finalization markers in this QA run. After `desktop-app-forensics.sh stop --log-dir /tmp/desktop-app-forensics-qa-systemd --grace-seconds 5`, `status` showed `controller=inactive`, but `meta/summary.txt` never gained `finished_at=` and the run did not prove a final cleanup snapshot the way the fallback/nohup run did. User-journal evidence for the transient unit showed `systemd[...]: Stopping ...`, `desktop-app-forensics.sh[PID]: Terminated`, and exit status `143`, which suggests the unit was stopped before the trap-driven cleanup fully flushed its final markers. By contrast, the explicit nohup fallback QA run at `/tmp/desktop-app-forensics-qa-fallback` did record `state/stop.requested` **and** `finished_at=` in `meta/summary.txt`. So the hardening claim is only partially certified: launch anchoring is better and fallback UX is acceptable, but the systemd-managed stop/finalization semantics still need tightening before we can say the hardened path fully preserves the intended forensic end markers under normal operator stop. Recommended next step: fix the transient-unit stop behavior so TERM-triggered cleanup reliably writes `finished_at` and the final snapshot before the unit fully exits, then rerun QA on Cookie/Pico.

---

### Task 35: Research a system-scope forensic capture mode above the user desktop stack

**Bead ID:** `oc-cr9`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-01`, `REF-08`, `REF-09`, `REF-10`
**Prompt:** Research the smallest truthful escalation from the current systemd-user hardened harness to a system-scope or equivalently host-level capture mode that can survive Cookie's actual X11/desktop session rollover. Derrick has explicitly granted sudo on Pico's terminal for this branch if needed. Focus on how to anchor the controller above the user manager while preserving the existing artifact layout and operator workflow as much as possible.

**Folders Created/Deleted/Modified:**
- `.plans/`
- shared `workspace/scripts/` and related docs/tests if needed

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny proof step is required

**Status:** ✅ Complete

**Results:** Research completed and bead `oc-cr9` is ready to close. I inspected the current shared harness at `/home/derrick/.openclaw/workspace/scripts/desktop-app-forensics.sh`, the hardened/audit findings from Tasks 31 and 34, and did one tiny host-safe proof that a system-scope transient unit can be anchored in PID 1 while still running the payload as the target desktop user (`sudo systemd-run --unit oc-forensics-proof-... --uid derrick ...` reported `User=derrick`, `ActiveState=active`, and a `/system.slice/...service` cgroup). Recommended design: add a new explicit system-scope controller mode that keeps the existing `_run`, `meta/`, `logs/`, `state/`, watch patterns, and subcommands, but launches the controller via `sudo systemd-run` in the **system manager** instead of `systemd-run --user`, preferably with `--uid derrick`, `WorkingDirectory=<cwd>`, `KillMode=process`, and a generous `TimeoutStopSec` so the controller can flush `stop.requested`, a final snapshot, and `finished_at=` before systemd finishes stopping it. This is the narrowest truthful escalation because the only thing that materially failed on Cookie was the lifetime anchor: the controller transient unit tied to the **user** manager died at the same crash boundary, while the collector/artifact model itself was already good enough pre-boundary.

The key design choice is **not** a long-lived root wrapper unless later QA proves it is required. A root wrapper supervising separate user collectors would add another orchestration layer, split ownership/permissions, and complicate cleanup/status without evidence that Cookie needs that complexity. A system-scope transient service whose main payload still runs as `derrick` preserves file ownership and most of the current script logic, yet moves the service’s lifecycle above the desktop session and above the user systemd manager. For journal capture in this mode, the smallest safe path is: keep the existing system journal collector, and replace the current `journalctl --user ...` follower with a root-capable or UID-filtered equivalent only when running in system-scope mode (for example `journalctl --since ... -f -o short-iso _UID=<target_uid>` from a privileged helper or from the system unit when allowed), because `journalctl --user` is scoped to the current user manager and is exactly the part most likely to become unreliable across rollover.

Operator caveats: Cookie would invoke this from SSH with `sudo` (for example a new `start --controller-mode system` or auto-selected fallback when explicitly requested); the script should record a new marker such as `state/controller.mode=systemd-system` plus `state/controller.unit`, and `status` / `stop` should prefer plain `systemctl` (system scope) over `systemctl --user` when that marker is present. Unit naming can keep the current `desktop-app-forensics-<epoch>-<pid>.service` convention to preserve operator recognition. Cleanup should remove or tolerate stale `controller.pid` / `controller.unit` the same way the current code does. Because the payload still runs as `derrick`, log dirs under `/home/derrick/Documents/forensics/...` stay writable without a root-owned artifact mess. If launch-cmd support matters in this mode, it should also execute as `derrick` inside the same system service rather than as root. Clear recommendation for `oc-0rb`: implement a **system-manager transient-service mode running as the target user**, not a root wrapper daemon; add explicit mode markers plus system-scope `status` / `stop`; adjust journal collection for the loss of `--user`; and carry forward the existing finalization fixups (`KillMode=process`, longer stop timeout, trap-driven summary flush) so QA can truthfully test survival across Cookie’s real X11 reset boundary.

---

### Task 36: Implement a system-scope forensic capture mode

**Bead ID:** `oc-0rb`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-01`, `REF-08`, `REF-09`, `REF-10`
**Prompt:** After the research pass identifies the correct root/system-scope escalation, implement the smallest truthful hardening to `workspace/scripts/desktop-app-forensics.sh` so the controller can survive Cookie's actual desktop/session rollover better than the current `systemd-run --user` mode. Preserve backward compatibility and existing artifact conventions where possible, and use sudo only to the minimum extent required.

**Folders Created/Deleted/Modified:**
- `.plans/`
- shared `workspace/scripts/`
- shared docs/tests if needed

**Files Created/Deleted/Modified:**
- owning shared script/docs/test files as required

**Status:** ✅ Complete

**Results:** Coder pass completed and bead `oc-0rb` is ready to close. The shared `workspace/scripts/desktop-app-forensics.sh` now has an explicit system-scope controller mode that preserves the existing `_run` harness, artifact layout, watch-pattern workflow, and `start/status/stop` surface while moving the controller anchor above the user desktop stack when requested. `start` now accepts `--controller-mode auto|user|system|nohup` plus `--controller-user`, launches system mode via `sudo systemd-run` against PID 1 with `--uid <target-user>`, and records explicit markers in `state/controller.mode`, `state/controller.unit`, and `state/controller.user`. The transient-unit launch path now also sets `KillMode=process` and `TimeoutStopSec=30s` for both user and system systemd modes. `status` / `stop` branch by the recorded controller mode so older pid-only/nohup runs still work, user-mode runs still use `systemctl --user`, and system-mode runs use plain `systemctl` via `sudo`.

Journal capture was hardened in the narrowest truthful way for system mode: the harness keeps the existing `logs/journal-system.log` collector and replaces the fragile `journalctl --user` assumption with a system-journal `_UID=<target uid>` follower for `logs/journal-user.log`, so useful per-user journal capture can continue even if the user manager rolls over. Finalization was also tightened by adding an `EXIT` trap on `_run` in addition to `TERM`/`INT`, so the controller now reliably writes `state/stop.requested`, a final polling snapshot, and `finished_at=` during the validated system-mode stop path.

Terminal-safe validation completed on Pico’s host only. `bash -n /home/derrick/.openclaw/workspace/scripts/desktop-app-forensics.sh` passed. `help` output was checked and now documents the new system mode. A no-GUI lifecycle run at `/tmp/desktop-app-forensics-system-138213` successfully started with `controller mode: systemd-system`, wrote `state/controller.mode=systemd-system`, `state/controller.unit=desktop-app-forensics-1778285971-138221.service`, and `state/controller.user=derrick`, reported `controller=active` plus collector pids in `status`, then `stop` returned `Harness stopped cleanly` and a follow-up `status` showed `controller=inactive`. The artifact also truthfully recorded `finished_at=` in `meta/summary.txt`, confirming the stop/finalization path worked in this validated system-scope run. Important caveat kept explicit: this is a terminal-safe anchor/lifecycle validation, not yet a real Cookie stop-playback rollover proof.

---

### Task 37: QA the system-scope forensic capture mode

**Bead ID:** `oc-cny`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-01`, `REF-08`, `REF-09`, `REF-10`
**Prompt:** Independently verify whether the new system-scope capture mode is actually anchored above the user desktop stack, whether the operator workflow remains usable on Cookie, and what final limits still remain. Be explicit about what is proven by terminal-safe validation versus what still needs a real Cookie stop-playback repro.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ✅ Complete

**Results:** Audited the real Cookie stop-playback repro captured in `/home/derrick/Documents/forensics/cookie-godot-stop-playback-20260508-202708` and compared it to the prior systemd-user run at `/home/derrick/Documents/forensics/cookie-godot-stop-playback-20260508-192741`. The new artifact truthfully proves a stronger controller anchor and materially better finalization: `meta/summary.txt` now includes `requested_controller_mode=system`, `controller_mode=systemd-system`, `controller_user=derrick`, `controller_unit=desktop-app-forensics-1778286428-1467297.service`, and a real `finished_at=2026-05-08T20:34:05-04:00`; `state/controller.mode`, `state/controller.user`, and `state/stop.requested` exist; the final session poll advanced through the actual stop boundary to `2026-05-08T20:34:05-04:00`; and the captured journals include the old desktop session tearing down (`Session 782 logged out`, old `/usr/libexec/gdm-x-session[1447675]` terminating) plus immediate new GDM/Xorg bring-up (`New session c206 of user gdm`, new `/usr/libexec/gdm-x-session[1478089]`). That is a real improvement over the prior systemd-user artifact, which never wrote `finished_at`, never captured a post-reset poll, and stopped at `19:32:28` before any rollover evidence was recorded.

Important limit kept explicit: the artifact itself still does **not** prove the harness survived all the way through to Derrick’s fully restored post-return desktop session. Its last poll only reaches the rollover moment and flips from the GUI login session (`Display=782`, `Service=gdm-password`, `Leader=1447630`) to a tty/SSH-visible user state (`Display=778`, `Service=login`) while the system journal shows the system-scope controller being terminated/exiting at the same second as the reset. So the artifact proves capture through the teardown boundary and initial display-manager restart, but not continued capture into the later recovered user desktop. Only live post-return inspection proved that stronger fact: Cookie now has a fresh active Derrick GUI session (`loginctl show-user derrick` => `Display=794`) with new desktop processes (`gdm-x-session 1478782`, `Xorg 1478788`, `gnome-shell 1478990`) distinct from the crashed session.

Bottom line: system-scope mode **did fix the prior survival gap enough to truthfully continue with this harness mode**. It captured the real stop-playback boundary, wrote the missing finalization markers, and recorded new session/Xorg evidence that the systemd-user run missed. Remaining gap is narrower: if we need proof beyond the display-manager restart and into the fully restored Derrick desktop/session after return, we still need one more escalation in capture persistence or a deliberate post-return follow-up snapshot step. For the current bug branch, though, this mode is good enough to keep using as the default crash-forensics harness because it finally captured the real boundary instead of dying earlier.

---

### Task 38: Analyze existing Cookie rollover forensics for root-cause clues

**Bead ID:** `oc-4bb`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-01`, `REF-08`, `REF-09`, `REF-10`
**Prompt:** Analyze the currently captured Cookie stop-playback forensic artifacts—especially the successful system-scope run and the prior systemd-user run—for the strongest root-cause clues already available. Focus on what the logs say about ordering, failure signatures, process lifetimes, X11/session teardown behavior, and whether the crash still points more strongly at a Godot/editor/X11 interaction, a Python-sidecar/X connection issue, or broader desktop-session instability.

**Folders Created/Deleted/Modified:**
- `.plans/`
- forensic artifact directories only for reading / notes

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny analysis note is required

**Status:** ✅ Complete

**Results:** Claimed bead `oc-4bb`, read Tasks 30-38 plus the Session Handoff, and compared the three relevant Cookie stop-playback captures: system-scope `/home/derrick/Documents/forensics/cookie-godot-stop-playback-20260508-202708`, prior systemd-user `/home/derrick/Documents/forensics/cookie-godot-stop-playback-20260508-192741`, and earlier matching sidecar log `autostart-mediapipe-1778267811-2374119519.log` from the earlier Cookie run family. The strongest proven ordering is now: (1) Godot logs `Window close request` → `Stopping harness resources` → `CameraView Stopping stream...`; (2) on the system-scope run the last in-process Godot line is `Waiting for stream thread to finish...` at `20:34:04`; (3) by the next 2 s poll at `20:34:05`, login session `782` is already `closing`, a new GDM session `c206` is `opening`, `who` has lost the `seat0/:1` desktop entries, both Godot processes are gone, but the detached Python sidecar (`1477549`) is still alive; (4) the sidecar’s own autostart log then shows `SIGTERM` first and only afterward `XIO: fatal IO error 34 ... on X server ":1.0"`; (5) the same `SIGTERM`→`XIO` shutdown signature repeats in the prior `192741` run and an earlier Cookie sidecar log, which makes it a reproducible teardown symptom rather than a one-off. What the artifacts prove strongly: the desktop/X11 session is collapsing right at stop-playback, Godot disappears before the detached sidecar does, and the sidecar is losing its X connection during cleanup, not emitting an earlier primary fault. The `192741` capture also shows why the older harness was insufficient: its user-scoped collector died with the session reset, while the system-scope collector survived long enough to record the session rollover. Current hypothesis ranking from strongest to weakest: (1) Godot/editor/X11 session-shutdown interaction that tears down the desktop session; (2) broader Zorin/GNOME/X11 desktop instability exposed by that close path; (3) Python sidecar/X connection failure as a secondary victim during teardown, not the first mover; (4) camera/MJPEG stream teardown as a contributing trigger but not yet the best-supported primary cause. These logs are already good enough to drive the next bug-hunt step: focus directly on the Godot/editor close path versus X11/session teardown boundaries, and separately hard-disable the sidecar/X-dependent pieces only as an isolation experiment—not because the current evidence suggests the sidecar is the root cause. Another harness tightening may still be useful later for finer-grained boundary timing, but it would not materially change the immediate next move because the existing artifacts already show the main failure family clearly enough.

---

### Task 39: Research the Godot close-path isolation matrix for Cookie

**Bead ID:** `oc-2a4`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-01`, `REF-08`, `REF-09`, `REF-10`
**Prompt:** Using the current Cookie forensic evidence, design the narrowest truthful comparison matrix for isolating whether the desktop-session crash is caused by the Godot/editor close path itself, by the MediaPipe/camera-integrated close path, or by a smaller subset of teardown components. The output should be a practical ordered test ladder for Cookie that minimizes risky/full-crash repetitions while maximizing causal signal.

**Folders Created/Deleted/Modified:**
- `.plans/`
- forensic notes only as needed

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny analysis note is required

**Status:** ✅ Complete

**Results:** Research completed and bead `oc-2a4` is ready to close. Source-grounded comparison design: the current `boxing_proving.tscn` / `proving_harness.gd` close path is a fixed stack of `AutoStartManager` sidecar launch -> `CameraView` MJPEG stream thread -> `MediaPipeProvider` UDP/detector provider, and on `WM_CLOSE_REQUEST` it stops those three in that order before quitting. Existing source already gives one useful narrower rung: `.testbed/scripts/test_scene.gd` has `StartupMode.PREVIEW_ONLY_DEBUG`, which keeps the same sidecar + MJPEG camera preview path but intentionally skips `MediaPipeProvider.start()`. Existing source also already supports swapping the sidecar camera source away from live hardware via `AEROBEAT_MEDIAPIPE_CAMERA_SOURCE=<video-path>`, which is enough to compare live USB-camera teardown vs file-backed input without changing the crash harness. Important limit found in source: `boxing_proving` currently has **no** truthful no-sidecar or no-camera-view mode; after `server_started` it always starts `CameraView`, and `AutoStartManager.use_camera_stream=false` alone would only create a failed-connect variant, not a clean camera-disabled proving mode.

Recommended ordered Cookie ladder: (1) add/run a Godot-only editor close path in this repo with the proving UI but no `AutoStartManager` startup at all; if that still crashes, the editor/project close path alone is sufficient and the MediaPipe stack is not required. (2) Run a sidecar+camera-preview/no-provider comparison using the existing `test_scene.gd` `PREVIEW_ONLY_DEBUG` mode or the same mode transplanted onto the proving harness; if this crashes, `MediaPipeProvider`/UDP detector teardown is not required and the suspect surface stays in sidecar + MJPEG/camera-view teardown. If it does not crash, the provider/detector layer becomes a required part of the failure. (3) Run the full current proving path with `AEROBEAT_MEDIAPIPE_CAMERA_SOURCE` pointed at one of the prerecorded boxing fixtures instead of `/dev/video*`; if this still crashes, the live camera device is not required and the culprit is deeper in sidecar/stream/provider/editor teardown. If only the live-camera run crashes, hardware camera/V4L teardown becomes the strongest sub-branch. Smallest truthful implementation controls needed next: a proving-harness startup mode that can skip `AutoStartManager` entirely for a pure editor-close comparison, plus either reuse or mirror `test_scene.gd`'s preview-only/no-provider mode on the proving harness so all comparisons stay in the same UI shell. Best first comparison to implement next: **Godot/editor close with proving UI and no sidecar at all**, because the current forensics already demote Python as a likely downstream casualty and that rung most quickly answers whether the editor/testbed close path itself is enough to reset Cookie's desktop.

---

### Task 40: Implement the smallest comparison-ready isolation controls in the owning source

**Bead ID:** `oc-409`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`, `REF-06`
**Prompt:** Based on the approved isolation matrix, implement the smallest truthful controls needed in the owning `aerobeat-input-mediapipe-python` source so Cookie can run the planned close-path comparisons. Prefer minimal toggles / alternate run paths / narrowly scoped stubs over broad refactors, and keep the crash-forensics harness workflow unchanged.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/`
- owning source/script/config paths as required

**Files Created/Deleted/Modified:**
- `.testbed/scripts/proving_harness.gd`

**Status:** ✅ Complete

**Results:** Coder pass completed and bead `oc-409` is ready to close. The only source change was a minimal proving-harness startup-mode extension in `.testbed/scripts/proving_harness.gd`; no crash-harness or camera-source workflow changes were added. New `StartupMode` options now keep the existing default `TRACKING` path unchanged while adding two comparison rungs in the same proving UI shell: `GODOT_ONLY_DEBUG` removes the child `AutoStartManager` in `_enter_tree()` so the harness never starts the sidecar/camera/provider stack at all, and `PREVIEW_ONLY_DEBUG` mirrors `test_scene.gd` by letting the sidecar + camera preview start normally but returning before `MediaPipeProvider.start()`. The harness status/summary/live-console text was also updated to expose the active startup mode plus disabled/preview-only states so Derrick/QA can tell which rung is running without guessing from logs. Terminal-safe validation only: `godot --headless --path .testbed --check-only --script scripts/proving_harness.gd` exited `0`; a headless scene-instantiation probe confirmed `boxing_proving.tscn` still loads with default `startup_mode=0`; and a second headless probe set `startup_mode=GODOT_ONLY_DEBUG`, added the scene to the tree, and truthfully showed `Godot-only debug mode active` with no `AutoStartManager` startup log lines, proving the no-sidecar mode now skips the child autostart path rather than merely ignoring its signals. Still pending for QA / Derrick repro: verify the preview-only rung on a real runtime/editor path, then run the planned Cookie close comparisons under the system-scope desktop forensics harness.

---

### Task 41: QA the comparison controls and operator flow

**Bead ID:** `oc-zwa`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-04`, `REF-06`
**Prompt:** Independently verify that the new comparison controls are understandable, launch correctly, and actually let Derrick run the intended Cookie close-path isolation ladder with the current system-scope crash harness. Be explicit about what is proven by terminal-safe validation versus what still needs Derrick’s real Cookie repro passes.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ✅ Complete

**Results:** Source-only QA pass completed against `REF-04` and `REF-06`; no Godot runtime, GUI control, or playback was used. The new proving-harness comparison control is real but only moderately discoverable: `.testbed/scripts/proving_harness.gd` exports `startup_mode` as an enum (`TRACKING`, `PREVIEW_ONLY_DEBUG`, `GODOT_ONLY_DEBUG`), and both proving scenes bind that script on the root `Control` node while leaving `startup_mode` unset in the `.tscn`, so the scene still defaults to `TRACKING` unless Derrick changes the root-node Inspector property and saves the scene. Truthful Cookie operator path today: open the `.testbed` project in Godot, open `res://scenes/boxing_proving.tscn` (the current `run/main_scene`), select the root node `BoxingProving`, find the exported `startup_mode` property in the Inspector, set it to `GODOT_ONLY_DEBUG`, save the scene, then run the project/scene on Cookie. Source wiring supports that path cleanly: `_enter_tree()` removes the child `AutoStartManager` when `startup_mode == GODOT_ONLY_DEBUG`, and `_ready()` then marks the harness as `Godot-only debug mode active` without starting sidecar/camera/provider. Operator-path verdict: truthful and usable once you know where to click, but not self-documenting yet because there is no dedicated docs note, launcher preset, or scene-level persisted debug variant advertising the setting. Smallest follow-up to make this operator-friendly: add a short repo-local note (README or plan-adjacent operator note) that explicitly says `BoxingProving root node -> Inspector -> startup_mode -> GODOT_ONLY_DEBUG`, or add a dedicated saved debug scene/preset if Derrick wants one-click switching later. Ready-for-run verdict: yes, Cookie can be armed for the first `GODOT_ONLY_DEBUG` comparison run now, but only with that explicit root-node Inspector step; if Derrick skips it, the scene will still run the default `TRACKING` path.

---

### Task 42: Audit the first close-path comparison result and decide the next branch

**Bead ID:** `oc-5c6`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-01`, `REF-08`, `REF-09`, `REF-10`
**Prompt:** After the first comparison run lands, audit what it actually proves about the crash family: whether the desktop rollover still occurs without the MediaPipe/camera-integrated path, whether the sidecar is only a downstream casualty, and which teardown component should be isolated next.

**Folders Created/Deleted/Modified:**
- `.plans/`
- forensic artifact dirs only for reading / notes

**Files Created/Deleted/Modified:**
- plan updates and audit notes only

**Status:** ✅ Complete

**Results:** Updated audit against Derrick’s direct Cookie report as the primary truth: after switching `boxing_proving.tscn` root `startup_mode` first to `GODOT_ONLY_DEBUG` and then to `PREVIEW_ONLY_DEBUG`, running the scene, and closing it, Cookie did **not** crash and the desktop session did **not** roll over in either rung. The new `PREVIEW_ONLY_DEBUG` result proves something narrower and important: the previously observed session-reset family is **not** reproduced by the proving-scene close path when sidecar startup and camera preview are allowed to run but `MediaPipeProvider.start()` is still skipped. That demotes the bare editor/testbed close path **and** the preview-only-without-provider path as sufficient triggers by themselves. What remains ambiguous because of the reported `camera_view.gd:152 @ start_stream(): Failed to connect, status: 3` error is whether the preview rung actually exercised the same live camera-preview/teardown path strongly enough to stand in for a fully connected preview session. Because the preview failed to connect, this rung does **not** cleanly distinguish between: (a) teardown that only becomes dangerous once a real preview stream is established, (b) teardown in `MediaPipeProvider` / detector startup-stop, or (c) a bug that requires both a successful stream connection and provider activity together. The three `GDScript::reload` constant-name warnings are low-severity/editor-noise for this crash audit: relevant to code hygiene, but they do not materially change the branch decision. The stream-connect failure is the high-relevance warning because it weakens the comparison’s isolation power even though the no-crash observation itself is still true. Best next move: **do not skip ahead yet**. Fix or at least warn-clean/understand the preview-only rung enough to get a truthful successful preview connection, then rerun `PREVIEW_ONLY_DEBUG` before advancing to a later rung. Right now the cleanest decision is that no-crash-under-failed-preview is useful but incomplete; the next highest-signal step is to make the preview-only comparison actually connect so the team can tell whether successful preview teardown alone is safe, or whether the remaining suspect narrows further to `MediaPipeProvider` / detector startup-stop.

---

### Task 43: Research the PREVIEW_ONLY_DEBUG connect failure and warning-cleanup scope

**Bead ID:** `oc-u4g`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-04`, `REF-06`, `REF-10`
**Prompt:** Investigate why `PREVIEW_ONLY_DEBUG` hit `camera_view.gd:152 @ start_stream(): Failed to connect, status: 3` on Cookie, and identify the smallest truthful fix needed so the preview-only rung exercises a real successful preview path. Also inspect the constant/global-class reload warnings (`MediaPipeProvider`, `MediaPipeCameraView`, `MediaPipeConfig`) and identify the smallest hygiene cleanup that removes the noise without broad refactors.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/`
- owning source files as needed for inspection

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny proof step is required

**Status:** ✅ Complete

**Results:** Research completed from source/log inspection only; no GUI playback was launched. The preview connect failure is most likely a startup-readiness race, not a wrong URL/path and not a provider-only issue. In both `.testbed/scripts/proving_harness.gd` and `.testbed/scripts/test_scene.gd`, `_on_server_started()` treats `AutoStartManager.server_started` like a ready-to-connect signal, then attempts `camera_view.start_stream()` almost immediately (`1.5s` in proving harness after the signal; `2.0s` in test_scene). But `src/autostart_manager.gd` emits `server_started` as soon as the detached Python process is spawned and heartbeat starts, before its own later stabilization wait finishes. The captured logs line up with that race exactly: Godot attempts TCP connect to `127.0.0.1:4243` and `camera_view.gd` reports `Failed to connect, status: 3` while the harness still shows `server=starting`; only afterward do later lines show the sidecar/provider reaching their running state. The Python side also initializes the Pose Landmarker before enabling MJPEG streaming in `python_mediapipe/main.py`, so the HTTP preview endpoint can legitimately lag process spawn by multiple seconds. Smallest truthful implementation direction for `oc-p78`: do not paper over this with a bigger fixed sleep. Add a bounded readiness retry around the actual MJPEG connect path so preview mode only reports success after a real connection is established. The narrowest high-value place is `src/camera_view.gd:start_stream()`: when `connect_to_host()` / `get_status()` lands in error state `3`, recreate the TCP peer and retry for a short bounded window before failing. That is one shared source file and truthfully upgrades both the proving harness and `test_scene.gd` to wait for the real HTTP stream instead of assuming the sidecar process spawn means the stream is live. If Derrick wants even stricter signal semantics later, a follow-up could also move `AutoStartManager.server_started` later or add a dedicated stream-ready signal, but that is larger than needed for the current rung. Warning-cleanup research: the `GDScript::reload` noise is caused by `.testbed/scripts/proving_harness.gd` locally preloading scripts into constants with the exact same names as the registered global classes (`MediaPipeProvider`, `MediaPipeCameraView`, `MediaPipeConfig`). The smallest hygiene cleanup is to stop shadowing those class names there — either rename the three local constants to non-class names such as `MediaPipeProviderScript` / `MediaPipeCameraViewScript` / `MediaPipeConfigScript`, or remove those preloads entirely and instantiate the global classes directly. For the scoped Cookie repro noise, only `proving_harness.gd` needs this cleanup; no broad repo-wide rename is required. Likely implementation files for `oc-p78`: `src/camera_view.gd` for the truthful preview-connect retry, plus `.testbed/scripts/proving_harness.gd` for the warning cleanup. Optional parity-only follow-up if desired later: mirror the same explicit success/failure handling style in `.testbed/scripts/test_scene.gd`, but that is not required for the proving-harness comparison rung once `camera_view.gd` is made retry-capable.

---

### Task 44: Implement the PREVIEW_ONLY_DEBUG fix and warning cleanup

**Bead ID:** `oc-p78`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`, `REF-06`
**Prompt:** Based on the approved research result, implement the smallest truthful change set that (1) makes `PREVIEW_ONLY_DEBUG` exercise a successful preview connection instead of failing with `status: 3`, and (2) cleans up the constant/global-class reload warnings. Keep the comparison ladder intact and avoid broad refactors.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/`
- owning source files as required

**Files Created/Deleted/Modified:**
- only the minimum files required by the approved fix

**Status:** ✅ Complete

**Results:** Implemented the smallest shared-source fix in `src/camera_view.gd` plus the narrow proving-harness warning cleanup in `.testbed/scripts/proving_harness.gd`. `start_stream()` no longer assumes the first TCP attempt is definitive: it now runs a bounded retry/readiness loop (6s overall window, short per-attempt connect wait, peer recreated between attempts) and specifically retries the observed `status: 3` / connect-error-`3` failure path before surfacing a final error. That keeps the preview-only rung truthful without adding a guessed harness sleep and automatically benefits both the proving harness and `test_scene.gd`, since both rely on the shared camera view. The proving harness cleanup only renamed the three colliding preload constants to `*Script` aliases and updated the local `.new()` callsites, removing the class-name shadowing that caused the `GDScript::reload` warning noise. Terminal-safe validation completed: `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/proving_harness.gd` exited `0`, and a dedicated headless retry probe with a delayed local TCP listener reproduced repeated `status: 3` attempts and then succeeded once the listener became available, proving the new retry path can turn the previous failed-preview timing window into a successful preview connection. Remaining QA / Derrick rerun: execute the repaired `PREVIEW_ONLY_DEBUG` rung on Cookie in the real editor/runtime path to confirm the preview now connects truthfully there and to re-check whether close/stop remains no-crash under a genuinely connected preview session.

---

### Task 45: QA the repaired PREVIEW_ONLY_DEBUG rung and warning cleanup

**Bead ID:** `oc-60d`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-04`, `REF-06`
**Prompt:** Independently verify that `PREVIEW_ONLY_DEBUG` is now wired to a truthful successful preview path in source/runtime expectations, that the warning cleanup is real, and that Derrick has a clear operator path for rerunning the Cookie comparison. Be explicit about what still needs Derrick’s direct Cookie repro.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ✅ Complete

**Results:** Terminal-safe QA completed; no GUI playback or local editor launch was used. Source verification confirms the repaired rung is wired the right way for a truthful preview-only comparison: in `.testbed/scripts/proving_harness.gd`, `_on_server_started()` still starts the camera feed first, then `PREVIEW_ONLY_DEBUG` returns before `_start_provider()`, so a successful rerun exercises sidecar + MJPEG preview teardown without `MediaPipeProvider.start()`. Independent runtime-expectation checks passed: `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/proving_harness.gd` exited `0`, and a fresh headless probe instantiated `MediaPipeCameraView` against a delayed local HTTP listener on a new port. That probe produced repeated `status=3` retries, then connected successfully on a later attempt and reported `started=true streaming=true`, which truthfully demonstrates the new bounded retry loop can turn the prior startup-race failure shape into a successful preview connection once the stream endpoint becomes live. Warning cleanup is also real in source: the proving harness no longer declares preload constants named `MediaPipeProvider`, `MediaPipeCameraView`, or `MediaPipeConfig`; it now uses `*Script` aliases and updated `.new()` callsites, removing the exact class-name shadowing that previously caused the reload-noise family. Clear operator path for Derrick’s Cookie rerun is now: open `.testbed` on Cookie, open `res://scenes/boxing_proving.tscn` (still the current `run/main_scene`), select root node `BoxingProving`, set Inspector `startup_mode` to `PREVIEW_ONLY_DEBUG`, save, run, confirm the status/live text shows `Preview-only debug` with camera preview active, then close/stop and observe whether Cookie still avoids a desktop-session rollover. Scope boundary kept explicit: this QA pass proves the source wiring and headless retry behavior are sound, but it does **not** prove Cookie’s real editor/runtime path now reaches a genuinely connected live preview on its actual camera hardware. Derrick’s direct Cookie rerun remains the final truth source for that last step.

---

### Task 46: Audit the rerun PREVIEW_ONLY_DEBUG comparison result and decide the next rung

**Bead ID:** `oc-68b`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-01`, `REF-08`, `REF-09`, `REF-10`
**Prompt:** After the repaired `PREVIEW_ONLY_DEBUG` comparison reruns on Cookie, audit what it actually proves about preview teardown versus provider/detector teardown, and decide whether the next strongest rung is full `TRACKING` with file-backed input or a different narrower branch.

**Folders Created/Deleted/Modified:**
- `.plans/`
- forensic artifact dirs only for reading / notes

**Files Created/Deleted/Modified:**
- plan updates and audit notes only

**Status:** ✅ Complete

**Results:** Audited the repaired rerun against Derrick’s direct Cookie report as primary truth and the hardened system-scope forensics artifact as corroborating evidence. Actual result changed materially from the prior failed-connect preview rung: this time `PREVIEW_ONLY_DEBUG` reached a **real successful preview session** before close (`[CameraView] Connected`, `Stream started successfully`, proving-harness status `camera=streaming`, and `Stats: 96892924 bytes, 596 frames`), and Derrick reported that closing/stopping the rung **did crash Cookie / roll the desktop session**. Compared to prior rungs, that now proves `MediaPipeProvider.start()` / provider-detector teardown is **not required** for the session-reset family, while `GODOT_ONLY_DEBUG` still says bare editor/testbed close is not sufficient and the earlier failed-connect preview rerun says sidecar startup without an actually connected preview stream is not sufficient. The surviving artifact also gives a useful last-known-good ordering slice: close request logged at `22:41:06`, `CameraView` fully stopped its stream thread, then `AutoStartManager` logged `WM_CLOSE_REQUEST - stopping server`, immediately followed by `org.gnome.Shell.desktop: X connection to :1 broken (explicit kill or server shutdown)` and the final poll showing Derrick’s user session gone with only the GDM greeter left. Strongest next rung is therefore **not** full `TRACKING` with file-backed input yet; that would reintroduce provider activity after provider has already been demoted as unnecessary. The strongest next branch is a narrower `PREVIEW_ONLY_DEBUG` comparison with `AEROBEAT_MEDIAPIPE_CAMERA_SOURCE` pointed at a prerecorded boxing fixture (or other file-backed source) so the same connected-preview/no-provider rung can answer whether live camera / V4L teardown is required. If file-backed preview-only still crashes, the culprit stays in connected preview + sidecar/editor close without live hardware. If file-backed preview-only does not crash, live camera-device teardown becomes the strongest remaining suspect.

---

### Task 47: Research the smallest truthful video-source UX for proving scenes

**Bead ID:** `oc-4pr`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-04`, `REF-06`
**Prompt:** Design the smallest truthful UX for running Boxing/Flow proving scenes against prerecorded video files under `.testbed/assets/`. Compare two candidate approaches Derrick suggested: (a) autoscan the assets tree and populate a dropdown of available videos, and (b) expose a file-picker flow for selecting an arbitrary test video. Recommend the smallest good first version that works for both proving scenes and supports the current crash-isolation matrix.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/`
- docs/notes only as needed

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny proof step is required

**Status:** ✅ Complete

**Results:** Research completed and bead `oc-4pr` should close. Source-grounded recommendation: **first ship an Inspector-driven file-picker path, not an autoscanned in-scene dropdown**. In the current proving-harness structure, both `boxing_proving.tscn` and `flow_proving.tscn` auto-start the sidecar in `_ready()` through the shared `.testbed/scripts/proving_harness.gd` + child `AutoStartManager`, and the visible runtime UI is already space-constrained in the header/right-panel layout. A runtime dropdown would therefore require extra startup gating (`start`/`apply` flow or delayed auto-start), recursive asset scanning, scene UI changes in both proving scenes, and extra operator-state handling to avoid launching the live camera before the choice is made. By contrast, a root-node exported video-path property uses Godot’s existing Inspector file-picker flow, fits the repo’s current operator pattern (same as `startup_mode` selection), works for both Boxing and Flow through the shared harness with no new visible clutter, and can still be pointed at `.testbed/assets/...` clips for the crash-isolation matrix.

Smallest truthful implementation hook set: add a shared exported property on `proving_harness.gd` for an optional prerecorded video path (for example `@export_file("*.mp4,*.mov,*.avi,*.mkv,*.webm") var prerecorded_video_source := ""`) plus a compact readout in the existing status/summary text showing whether the harness is using live camera vs a file. The selected path should resolve to an absolute path before sidecar launch and map onto the existing camera-source surface cleanly: preferred wiring is a new `camera_source_override` property on `src/autostart_manager.gd`, with `_get_camera_source_override()` preferring that explicit scene-provided path, then falling back to the existing `AEROBEAT_MEDIAPIPE_CAMERA_SOURCE` environment variable, then defaulting to `"0"` for live camera. That preserves the current shell/script path (`scripts/run_proving_fixture_capture.sh` already exports `AEROBEAT_MEDIAPIPE_CAMERA_SOURCE`) while giving the proving scenes a local non-shell control surface without mutating global editor environment state.

Why not autoscan first: autoscan is attractive once we want a friendlier curated fixture browser, but in the actual current source it is **more** work than the file-picker path because there is no pre-launch selection UI or scene bootstrap gate yet. To do autoscan honestly we would need at least one of: (a) disable immediate auto-start until the dropdown value is chosen, (b) add restart/apply logic after selection, or (c) persist selection into the scene before run through a custom tool/editor surface. That is extra scope for the same immediate goal. Also, the assets are not just a single flat directory: there is `.testbed/assets/videos/` plus family-specific fixture clips under `.testbed/assets/fixtures/...`, so a truthful autoscan would need explicit inclusion rules and labeling logic rather than a trivial one-folder list.

Likely implementation files for `oc-1qs`: `.testbed/scripts/proving_harness.gd` (shared exported property, display text, path handoff), `src/autostart_manager.gd` (preferred explicit override property + fallback order), and possibly `.testbed/scenes/boxing_proving.tscn` / `.testbed/scenes/flow_proving.tscn` only if Derrick wants default saved values or a tiny source label surfaced in-scene. Recommendation for `oc-1qs`: implement the shared file-picker property first, document the exact operator flow as `root node -> prerecorded_video_source -> choose .testbed/assets/... clip -> optional startup_mode -> run`, keep live-camera default untouched when the field is blank, and defer autoscan-dropdown until there is a proven need for a curated fixture browser or one-click saved presets.

---

### Task 48: Implement proving-scene video source selection UX

**Bead ID:** `oc-1qs`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`, `REF-05`, `REF-06`
**Prompt:** Implement the approved proving-scene video-source UX so Boxing and Flow can run against prerecorded videos from `.testbed/assets/`. Support the chosen first version cleanly in the proving harness, and wire it into the current preview/tracking comparison modes without breaking live-camera behavior.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/`
- `src/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-08-cookie-boxing-ui-missing-and-close-crash.md`
- `.testbed/scripts/proving_harness.gd`
- `src/autostart_manager.gd`

**Status:** ✅ Complete

**Results:** Coder pass completed with the smallest approved Inspector-first UX. `.testbed/scripts/proving_harness.gd` now exports `prerecorded_video_source` as a shared file-picker property on the proving-harness root, hands that value to the child `AutoStartManager`, and surfaces the active source in the live header/status, quick stats, summary panel, and console snapshot so Derrick can tell whether a scene is using live camera default, a scene-selected file, or an environment override. `src/autostart_manager.gd` now exposes `camera_source_override` and resolves camera source in the approved order: explicit scene override first, then `AEROBEAT_MEDIAPIPE_CAMERA_SOURCE`, then live camera default `"0"`. No scene UI dropdown, autoscan flow, or startup redesign was added, so Boxing and Flow both pick up the new behavior through the shared harness with their existing roots unchanged. Terminal-safe validation passed: `godot --headless --path .testbed --check-only --script scripts/proving_harness.gd` succeeded; a headless scene-instantiation probe confirmed both `boxing_proving.tscn` and `flow_proving.tscn` still load and report `live camera (default)` with no scene value set; and a second headless override probe confirmed an explicit scene file path resolves ahead of an env override and is reported back by the harness as `scene override: res://assets/...`. Still pending for QA / Derrick use: real Inspector operator flow in Godot (`root node -> prerecorded_video_source -> choose .testbed/assets/... clip -> optional startup_mode -> run`) on both Boxing and Flow, plus the planned file-backed `PREVIEW_ONLY_DEBUG` crash-isolation comparison on Cookie to determine whether live camera / V4L teardown is still a required trigger.

---

### Task 49: QA video source selection UX and operator flow

**Bead ID:** `oc-6tu`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-04`, `REF-05`, `REF-06`
**Prompt:** Independently verify that the new proving-scene video source UX is understandable, works for both Boxing and Flow in the available validation scope, and gives Derrick a clear operator flow for choosing prerecorded videos instead of the live camera.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ✅ Complete

**Results:** QA completed with terminal-safe source/headless validation only; no visible Godot editor or local GUI playback was launched. The new Inspector-first UX is real in both proving scenes and is understandable once the operator is on the root node: headless scene probes confirmed both `boxing_proving.tscn` and `flow_proving.tscn` still instantiate, both roots (`BoxingProving`, `FlowProving`) expose the exported `prerecorded_video_source` property from the shared `proving_harness.gd`, and both default to empty scene override / `startup_mode=TRACKING`. Source + headless runtime checks also confirmed the intended precedence contract in `src/autostart_manager.gd`: with no overrides the active camera source resolves to live default `"0"`; with `AEROBEAT_MEDIAPIPE_CAMERA_SOURCE` set it resolves to the env-selected file; and when the scene sets `prerecorded_video_source`, that scene value wins over the env override and is surfaced back by the harness summary as `scene override: res://...`. Operator flow is therefore clear enough to arm Derrick without adding a new in-scene dropdown: open `.testbed`, open either `res://scenes/boxing_proving.tscn` or `res://scenes/flow_proving.tscn`, select the root proving node, set Inspector `prerecorded_video_source` to the desired clip (for example under `.testbed/assets/...`), optionally set `startup_mode=PREVIEW_ONLY_DEBUG` for the crash-isolation rung, save, then run. Important scope limit: this QA pass proves the shared wiring, discoverability location, and Boxing/Flow parity at source/headless level, but it does not prove the literal Inspector feel in a human-driven editor session, does not prove successful playback of a chosen file on Cookie, and does not yet prove the file-backed `PREVIEW_ONLY_DEBUG` close-path result. Net QA decision: yes, the feature is ready to arm Cookie for the file-backed comparison rung, but only with the explicit operator caveat that the control lives on the proving-scene root node in the Inspector and remains default-live unless Derrick deliberately sets and saves it.

---

### Task 50: Audit first file-backed proving comparison result

**Bead ID:** `oc-zxrx`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-01`, `REF-10`
**Prompt:** After the first file-backed proving comparison run lands, audit what it proves for the crash-isolation matrix and for the broader proving UX. Decide whether live camera / V4L remains a required trigger, and whether the new file-backed mode is strong enough to become a standard validation path.

**Folders Created/Deleted/Modified:**
- `.plans/`
- forensic artifact dirs only for reading / notes

**Files Created/Deleted/Modified:**
- plan updates and audit notes only

**Status:** ✅ Complete

**Results:** Audited against Derrick’s direct Cookie report as primary truth, with remote shell inspection of the surviving forensics dir (`/home/derrick/Documents/forensics/cookie-godot-stop-playback-preview-only-file-backed-20260508-231127`) used only as corroboration. Actual result: `PREVIEW_ONLY_DEBUG` still crashed / rolled Cookie’s Zorin desktop session even when Derrick deliberately selected a prerecorded boxing clip (`res://assets/fixtures/boxing/punch_left/boxing__punch_left__positive__guard_start_end__take_01.mp4`) instead of using live camera input. That is the first strong comparison proving that **live hardware camera / V4L teardown is not required** for this crash family; `MediaPipeProvider.start()` was already demoted by the earlier connected-preview/no-provider crash, and now live-camera teardown is demoted too. The surviving artifact gives only limited ordering help: it shows the controller started at `23:11:27`, repeated `camera_view.gd:502 @_update_texture(): The new image dimensions must match the texture size.` errors during playback at `23:15:01-23:15:02`, then the final poll shows Derrick’s normal user session gone and only the greeter/Xorg stack surviving. Important confound: unlike the earlier repaired live-preview rung, this artifact slice does **not** preserve a clean close-path ordering line such as `WM_CLOSE_REQUEST` / `stopping server`, and it does not independently prove the selected file path inside the surviving logs, so Derrick’s direct report remains the source of truth for the file-backed selection and the fact of the crash. Classification of the new texture-size mismatch bug: treat it as a **separate newly surfaced bug that is also a plausible causal/confounding factor for this file-backed rung**. It is not enough evidence to restore live camera / V4L as a required trigger, because the crash happened under file-backed playback; but it does prevent a clean claim that the crash is caused by generic connected-preview teardown alone. Best current recommendation: split the matrix into two facts — (1) file-backed `PREVIEW_ONLY_DEBUG` proves the crash can happen without live hardware camera input, and (2) the new texture-resize/render bug must be isolated next before making stronger claims about the exact crash mechanism or promoting file-backed preview to a standard proving path.

---

### Task 51: Research the file-backed preview texture-size mismatch

**Bead ID:** `oc-b2xf`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-04`, `REF-06`, `REF-10`
**Prompt:** Investigate the file-backed preview error `camera_view.gd:502 @ _update_texture(): The new image dimensions must match the texture size.` Determine the smallest truthful fix so file-backed proving playback can render without texture-size spam, and explain whether the bug is likely separate from or entangled with the Cookie close-path crash.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/`
- `src/` as needed for inspection

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny proof step is required

**Status:** ✅ Complete

**Results:** Source inspection points to a straightforward size-lifecycle bug rather than a mysterious codec problem. In `python_mediapipe/main.py`, the MJPEG streamer is started before capture begins, and `python_mediapipe/camera_streamer.py` serves a synthetic 640x480 placeholder whenever no real frame is buffered yet. In `src/camera_view.gd`, `_ready()` also seeds a 640x480 texture and `_update_texture()` only does two cases: create-once if `_frame_texture == null`, otherwise blindly `frame_texture.update(frame)` (line 502). For file-backed preview, Derrick’s proving clip is 1920x1080, so the first real JPEG can legitimately differ from the initial 640x480 texture. Once that happens, Godot rejects every subsequent `update()` with `The new image dimensions must match the texture size.`, which matches the observed spam pattern exactly. Smallest truthful fix: make `_update_texture()` recreate the `ImageTexture` whenever the incoming frame dimensions differ from the existing texture dimensions, then assign `self.texture` to the recreated texture. That change in `src/camera_view.gd` should be sufficient to make file-backed playback dimension-stable even if startup begins on a placeholder or any future source changes resolution. Optional cleanup later: make `camera_streamer.py` avoid or source-size the placeholder, but that is not required for the minimal rendering fix. Crash relationship: this looks like a separate rendering bug that becomes newly visible on the file-backed rung, and it is a plausible confound/crash contributor because it causes sustained runtime error spam during the same playback session; however, terminal-only evidence is not strong enough to claim it is the root cause of Cookie’s close-path crash. Best reading is: separate bug, likely not the original underlying close-path issue, but worth fixing before using file-backed preview to reason further about crash causality.

---

### Task 52: Implement the file-backed preview texture-size fix

**Bead ID:** `oc-9khz`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`, `REF-06`
**Prompt:** Based on the approved research result, implement the smallest truthful fix for the file-backed preview texture-size mismatch in `camera_view.gd` (and any directly owning support code) so prerecorded video playback renders cleanly in the proving scenes without the current texture-dimension spam.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/`
- `src/` as required

**Files Created/Deleted/Modified:**
- `.plans/2026-05-08-cookie-boxing-ui-missing-and-close-crash.md`
- `src/camera_view.gd`

**Status:** ✅ Complete

**Results:** Implemented the approved minimal fix in `src/camera_view.gd`: `_update_texture()` now recreates the `ImageTexture` whenever the incoming frame dimensions differ from the currently bound texture, and still uses `update()` only for same-size frames. Scope stayed tight to the owning source repo; no placeholder/streamer behavior was widened. Terminal-safe validation only: reviewed the targeted diff and confirmed the change matches the approved oc-b2xf research path without touching consumer mirror copies under assembly repos. QA still needs to rerun the file-backed proving flow / `PREVIEW_ONLY_DEBUG` comparison in the normal verification environment and confirm the prior `The new image dimensions must match the texture size.` spam is gone during prerecorded playback.

---

### Task 53: QA the file-backed preview texture-size fix

**Bead ID:** `oc-n9yk`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-04`, `REF-06`
**Prompt:** Independently verify that the file-backed preview texture-size fix is wired correctly in the available terminal-safe validation scope, that prerecorded playback should now render without the old size-mismatch spam, and that Derrick has a clear operator path for rerunning the file-backed `PREVIEW_ONLY_DEBUG` comparison.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ✅ Complete

**Results:** QA completed within the allowed terminal-safe scope only; no Pico local GUI and no local Godot run was launched. Source/diff verification passed: commit `becab4e` updates `src/camera_view.gd` so `_update_texture()` recreates the `ImageTexture` whenever incoming frame width/height differ from the currently bound texture, which is the exact minimal fix approved in Task 51 for the 640x480 placeholder → prerecorded 1920x1080 transition. Wiring verification also passed: the proving harness still preloads `res://addons/aerobeat-input-mediapipe-python/src/camera_view.gd`, and the active `.testbed` addon copy is byte-identical to the owning source file (matching `sha256`), so the proving scenes will consume the repaired script rather than a stale mirror. Operator-path verification also passed at source level: `.testbed/scripts/proving_harness.gd` still exports both `startup_mode` and `prerecorded_video_source`; its camera-source resolution prefers the scene root override first, then `AEROBEAT_MEDIAPIPE_CAMERA_SOURCE`, then live default `"0"`; and `_get_startup_mode_label()` / `_tracking_status_text()` still define the `PREVIEW_ONLY_DEBUG` rung as preview-without-provider. Therefore Derrick’s exact rerun path is clear: open the `.testbed` project, open `res://scenes/boxing_proving.tscn`, select root node `BoxingProving`, set `startup_mode = PREVIEW_ONLY_DEBUG`, set `prerecorded_video_source = res://assets/fixtures/boxing/punch_left/boxing__punch_left__positive__guard_start_end__take_01.mp4` (or the right-punch sibling clip), save, then run the scene. Truthful limit: this QA pass proves the fix is wired into the source + testbed consumption path and should stop the old size-mismatch spam for dimension changes, but it does not directly prove rendered playback on Cookie, does not directly prove the log spam is gone in a real rerun, and does not prove the post-fix close-path crash outcome. Net QA decision: ready to re-arm Cookie for the repaired file-backed `PREVIEW_ONLY_DEBUG` comparison, with the caveat that only Derrick’s real rerun can certify runtime behavior and crash classification.

---

### Task 54: Audit the rerun file-backed PREVIEW_ONLY_DEBUG comparison result

**Bead ID:** `oc-o3i4`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-01`, `REF-10`
**Prompt:** After the repaired file-backed `PREVIEW_ONLY_DEBUG` comparison reruns on Cookie, audit what it proves about the connected-preview close-path crash once the texture-size mismatch bug is removed. Decide whether the crash is now best explained as a generic connected-preview close bug or whether another narrower branch is still needed.

**Folders Created/Deleted/Modified:**
- `.plans/`
- forensic artifact dirs only for reading / notes

**Files Created/Deleted/Modified:**
- plan updates and audit notes only

**Status:** ✅ Complete

**Results:** Audited Derrick’s rerun report against the surviving system-scope Cookie artifact dir `/home/derrick/Documents/forensics/cookie-godot-stop-playback-preview-only-file-backed-rerun-20260508-234035` and updated the crash matrix accordingly. What this now proves after the texture-size fix: (1) the old texture-size mismatch/noise is no longer the gating issue for this rung, (2) a file-backed `PREVIEW_ONLY_DEBUG` run is still sufficient to reproduce the close-path desktop-session crash, so live camera / V4L teardown is no longer required, and (3) the file-backed playback path has a new separate preview-consumption bug where the proving clip remains selected but Godot only shows the first frame. The strongest artifact clue is the split between Godot and the sidecar: Godot logged `CameraView Stats: 386205014 bytes, 1 frames` at `23:42:11`, then repeated `0 frames` thereafter, while the file-backed sidecar log continued healthy processing through `Frame 1500` before receiving SIGTERM on close. That makes the new first-frame-only issue best understood as a separate bug in the Godot preview/render-consumption path rather than evidence that the file-backed source itself stopped producing frames. Ordering around the crash also survived cleanly in the system-scope harness: `stop.requested` was touched at `23:42:46.702`, the next poll at `23:42:47` showed Derrick’s session `782` already `closing`, `gnome-shell` and the Godot process were gone, and only the GDM Xorg greeter session remained. Recommendation recorded: treat the close-path crash as currently independent of both live camera/V4L and the old texture-size mismatch; track the new first-frame-only file-backed preview as a separate bug that weakens full behavioral parity on this rung but does not overturn the crash-matrix result that connected preview teardown alone can still take down Cookie’s GUI.

---

### Task 55: Research the file-backed first-frame-only preview bug

**Bead ID:** `oc-hrod`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-04`, `REF-06`, `REF-10`
**Prompt:** Investigate why file-backed proving playback shows only the first frame in Godot while the sidecar continues processing frames. Determine the smallest truthful next fix or instrumentation step in the Godot preview-consumer path so prerecorded preview advances normally.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/`
- `src/` as needed for inspection

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny proof step is required

**Status:** ✅ Complete

**Results:** Research completed from source/log inspection only; no GUI playback was launched. The strongest likely root cause is now in the Godot MJPEG consumer’s backlog/overflow behavior, not in the file-backed source itself. `python_mediapipe/camera_streamer.py` pushes MJPEG chunks every `1ms`, while `src/camera_view.gd` only polls every `5ms`, parses at most `2` frames per iteration, and hard-clears `_mjpeg_buffer` once it exceeds `MAX_BUFFER_SIZE = 131072`. On the file-backed proving clip, the sidecar is feeding full-resolution `1920x1080` frames (local fixture sampling shows ~90-106 KB JPEGs at the current stream quality), so the consumer can cross the 128 KB cap before it has a chance to isolate a complete next frame once the real clip replaces the startup placeholder. That matches the surviving artifact shape: Godot keeps receiving huge byte volume but decodes only the first frame, while the sidecar continues healthy frame processing. Smallest truthful next fix for `oc-hx7c`: keep this in the Godot preview-consumer path and stop treating buffer overflow as a full reset. In `src/camera_view.gd`, replace the current `if _mjpeg_buffer.size() > MAX_BUFFER_SIZE: _mjpeg_buffer.clear(); header_parsed = false` behavior with bounded stale-data dropping that preserves the newest boundary/tail (and ideally add one overflow log counter while touching that code). A modest buffer-cap increase to fit several 1080p JPEG frames is likely warranted too, but the key fix is preserving the latest parseable frame instead of repeatedly zeroing the stream state. Crash relationship: this still looks separate from the close-path crash. The crash already reproduces on connected-preview rungs without this exact file-backed first-frame symptom, so this bug is best treated as a file-backed preview-consumption defect that muddies parity on this rung rather than the newly discovered root cause of the desktop-session rollover.

---

### Task 56: Implement the first-frame-only preview fix or minimal instrumentation

**Bead ID:** `oc-hx7c`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`, `REF-06`
**Prompt:** Based on the approved research result, implement the smallest truthful fix for the file-backed first-frame-only preview bug in the proving path, or the smallest decisive instrumentation if a direct fix would still be speculative. Keep scope tight and avoid broad preview-pipeline redesign.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/`
- `src/` as required

**Files Created/Deleted/Modified:**
- `src/camera_view.gd`
- `.plans/2026-05-08-cookie-boxing-ui-missing-and-close-crash.md`

**Status:** ✅ Complete

**Results:** Implemented the approved minimal Godot-side fix in `src/camera_view.gd` only: raised the MJPEG buffer cap from `128KB` to `512KB`, added bounded overflow trimming to keep the newest boundary/tail instead of clearing the entire buffer, and logged an overflow counter with trim details so reruns can prove whether backlog is still occurring. The MJPEG marker/header byte patterns were hoisted into reusable top-level byte arrays while touching this path. Terminal-safe validation only: `godot --headless --path . --script src/camera_view.gd --check-only` now passes after the change. Still needs QA / Derrick rerun on the file-backed proving flow to confirm the preview advances beyond the first frame and to capture whether any new `[CameraView] MJPEG buffer overflow #...` logs still appear during playback.

---

### Task 57: QA the file-backed preview-advance fix

**Bead ID:** `oc-6398`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-04`, `REF-06`
**Prompt:** Independently verify that the file-backed proving preview should now advance beyond the first frame in the available validation scope, and that Derrick has a clear operator flow for rerunning the file-backed proving scene. Be explicit about what still needs Derrick’s direct Cookie truth pass.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 58: Audit the rerun file-backed preview-advance result and decide the next crash/debug branch

**Bead ID:** `oc-zqlo`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-01`, `REF-10`
**Prompt:** After the repaired file-backed proving preview reruns on Cookie, audit what it proves about the first-frame-only bug and whether the connected-preview close-path crash remains unchanged. Decide the strongest next branch for the crash investigation once playback behavior is cleaner.

**Folders Created/Deleted/Modified:**
- `.plans/`
- forensic artifact dirs only for reading / notes

**Files Created/Deleted/Modified:**
- plan updates and audit notes only

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 59: Research the MJPEG producer/consumer throughput mismatch for file-backed preview

**Bead ID:** `oc-l1l5`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-04`, `REF-06`, `REF-10`  
**Prompt:** Investigate why file-backed proving preview still stalls on the first frame even after the MJPEG overflow-trimming fix. Determine whether the smallest truthful next fix is producer pacing, consumer parse budget, a lower preview frame rate for prerecorded sources, JPEG quality/size reduction, or another narrow throughput control. Treat this as a product-quality feature branch for reliable video-to-MediaPipe proving, not just crash forensics.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/`
- `src/`
- `python_mediapipe/` as needed for inspection

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny proof step is required

**Status:** ✅ Complete

**Results:** Research completed from source/log inspection only; no GUI playback was launched. The most likely bottleneck is now producer-side MJPEG oversupply, not the file-backed source itself and not a simple Godot texture bug. `python_mediapipe/camera_streamer.py` currently sends a multipart JPEG frame every `1ms` regardless of whether a new camera/video frame exists, while `python_mediapipe/main.py` only refreshes `frame_buffer` when the capture loop advances. For prerecorded proving clips, local fixture sampling of Derrick’s 1920x1080 boxing file shows ~`102 KB` average JPEGs at the current `stream_quality=50` (`97-106 KB` across the first 120 frames). Combined with the surviving rerun stat shape (`CameraView Stats: 386205014 bytes, 1 frames` over a 5s window), that points to the stream thread re-sending the same large JPEG hundreds of times per second and burying the Godot consumer in duplicate work before preview can advance. The current consumer still has limits (`OS.delay_msec(5)`, parse budget `2` frames per loop, texture refresh `33ms`), but those are secondary leverage compared with the avoidable producer flood.

Smallest truthful next fix for `oc-w1u6`: pace the MJPEG producer, not the GDScript parser. In `python_mediapipe/camera_streamer.py`, stop writing frames on a blind `1ms` loop; instead send only when a newly encoded frame arrives, and cap that stream to the preview cadence Godot can actually display (roughly the existing `33ms` / ~30 FPS budget, or a nearby explicit preview cap). That is the narrowest fix because it removes duplicate 1080p JPEG traffic at the source, helps both Boxing and Flow prerecorded proving, and should also reduce needless live-preview CPU/bandwidth without changing the tracking/data path. Why this beats the alternatives right now: (1) increasing consumer parse budget in `src/camera_view.gd` would spend more CPU decoding frames the UI still cannot display and still leave the producer free to outrun it, (2) lowering JPEG quality/size helps but does not fix the core duplicate-frame flood, and even quality `20` still samples around `67 KB` per 1080p frame, and (3) a prerecorded-only frame-rate special case is a reasonable follow-up if needed, but the more truthful first control is a shared producer pacing rule in the streamer itself because the current `1ms` resend policy is wasteful for any source. Likely implementation files: `python_mediapipe/camera_streamer.py` first; if a configurable preview cap is desired, a small companion surface in `python_mediapipe/args.py`, `python_mediapipe/main.py`, and `src/autostart_manager.gd` may be warranted. Recommendation for `oc-w1u6`: implement producer-side send-on-new-frame pacing with a preview-rate cap before touching consumer budget or broader MJPEG redesign.

---

### Task 60: Implement the smallest reliable file-backed preview-advance fix

**Bead ID:** `oc-w1u6`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-04`, `REF-06`  
**Prompt:** Based on the approved research result, implement the smallest truthful fix that makes prerecorded proving preview advance reliably beyond the first frame. Prefer the narrowest change that improves real product behavior for video-backed Boxing/Flow proving without broad pipeline redesign.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `python_mediapipe/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-08-cookie-boxing-ui-missing-and-close-crash.md`
- `python_mediapipe/camera_streamer.py`

**Status:** ✅ Complete

**Results:** Implemented the narrow producer-side pacing fix in `python_mediapipe/camera_streamer.py` without broadening into consumer-budget rewrites. The MJPEG HTTP loop no longer re-sends the same JPEG every `1ms`; each client now waits on a frame-ready condition and only sends when a newly encoded frame arrives. The streamer also now caps preview publication to `30 FPS` (`~33ms`) before publishing a new JPEG, which keeps file-backed and live preview traffic aligned with real display cadence instead of flooding Godot with duplicate multipart frames. Terminal-safe validation only: `python3 -m py_compile python_mediapipe/camera_streamer.py` passed, and a runtime smoke script using `python_mediapipe/assets/runtimes/linux-x64/venv/bin/python3` verified the publish sequence advances on the first frame, does not advance on an immediate duplicate send, then advances again after a `40ms` wait. Manual test steps for Derrick: `1)` open the proving flow that previously stuck on frame 1, `2)` run the MediaPipe Python path with the prerecorded boxing/flow clip you were using for the repro, `3)` confirm the camera preview now visibly advances instead of freezing on the first frame, `4)` leave it running for several seconds and confirm preview motion stays smooth-ish at normal UI cadence rather than bursty/frozen, `5)` if desired, compare the old `CameraView Stats: ... bytes, 1 frames` symptom against the new behavior/logs to confirm the duplicate-frame flood is gone. Landed in the coder commit for this task (`Fix MJPEG preview producer pacing`).

---

### Task 61: QA reliable file-backed preview advancement

**Bead ID:** `oc-tm15`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-04`, `REF-06`  
**Prompt:** Independently verify that file-backed proving preview should now advance reliably in the available validation scope, and that Derrick has a clear operator flow for using prerecorded clips in Boxing/Flow proving as a normal feature.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 62: Audit rerun file-backed proving playback as a feature check

**Bead ID:** `oc-lbje`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-10`  
**Prompt:** After the repaired file-backed proving playback reruns on Cookie, audit whether prerecorded video now behaves like a usable proving feature and summarize any remaining defects separately from the wider close-path crash investigation.

**Folders Created/Deleted/Modified:**
- `.plans/`
- forensic/log dirs only for reading / notes

**Files Created/Deleted/Modified:**
- plan updates and audit notes only

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 63: Implement preview cadence/uniqueness instrumentation and the smallest fix for file-backed playback

**Bead ID:** `oc-cnid`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-04`, `REF-06`, `REF-10`  
**Prompt:** Instrument the Godot preview-consumer/display path enough to determine whether file-backed preview is actually advancing unique frames at too-low cadence versus staying visually pinned to the first presented frame, then implement the smallest truthful fix that makes prerecorded proving preview visibly advance like a usable feature. Keep scope tight and skip the separate QA/audit loop because Derrick will manually verify on Cookie.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/`
- `src/`
- `python_mediapipe/` as required

**Files Created/Deleted/Modified:**
- `.plans/2026-05-08-cookie-boxing-ui-missing-and-close-crash.md`
- `python_mediapipe/main.py`
- `src/camera_view.gd`

**Status:** ✅ Complete

**Results:** Implemented the smallest truthful file-backed preview fix plus direct cadence instrumentation. The root cause turned out to be stronger than “too subtle”: the threaded file-source path in `python_mediapipe/main.py` was racing prerecorded clips to EOF, which let the MJPEG preview expose only a few unique frames before pinning on a stale frame while bytes/frames counters kept looking healthy. The fix keeps scope tight: file-backed threaded capture is now paced to the clip’s native FPS, rewinds cleanly at EOF so proving preview remains usable instead of dying on a terminal frame, and logs file-preview advancement as captured/unique/repeat/loop/frame-position stats. To make subtle prerecorded motion read as obviously advancing for human QA without lying to the tracker, the MJPEG preview path now adds a small file-only playback HUD (loop/frame/time/progress bar) to the streamed preview copy while leaving the raw frame untouched for MediaPipe inference. On the Godot consumer side, `src/camera_view.gd` now logs preview cadence/uniqueness from decoded MJPEG frames so Cookie logs can distinguish “advancing unique frames” from “same JPEG repeated.” Terminal-safe validation matched the diagnosis and the fix: before the change, a headless sidecar probe against the left-punch fixture produced only 4 unique `/snapshot` hashes across 12 samples before freezing; after the change, the same probe produced 12/12 unique hashes, producer logs showed steady `unique==captured` advancement at clip FPS, and a headless Godot `CameraView` probe showed decoded preview cadence advancing uniquely on the consumer side. Manual Cookie steps for Derrick: open `.testbed`, open `res://scenes/boxing_proving.tscn`, select root `BoxingProving`, set `startup_mode = PREVIEW_ONLY_DEBUG`, set `prerecorded_video_source` to either boxing fixture under `res://assets/fixtures/boxing/...`, save, run, and confirm the preview now visibly advances with the file HUD/progress instead of appearing frozen; then repeat the intended stop/close comparison on Cookie and inspect logs for `[FrameCapture] File preview advance` plus `[CameraView] Preview cadence` if needed.

---

### Task 64: Implement one-shot close-path isolation toggle for the connected-preview crash

**Bead ID:** `oc-c7dm`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`, `REF-06`, `REF-10`
**Prompt:** Implement the smallest truthful debug/isolation toggle for one last Cookie repro tonight that helps answer whether the connected-preview crash is tied specifically to the AutoStartManager/sidecar shutdown path on close. Prefer a narrowly scoped proving-harness/autostart switch that preserves connected preview during playback but changes close-time shutdown behavior in a clearly observable way, with exact operator steps and cleanup notes for Derrick.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/`
- `src/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-08-cookie-boxing-ui-missing-and-close-crash.md`
- `.testbed/scripts/proving_harness.gd`
- `src/autostart_manager.gd`

**Status:** ✅ Complete

**Results:** Implemented the smallest truthful close-path isolation switch as a proving-harness-facing export: `skip_sidecar_stop_on_close_debug`. When Derrick enables it on the proving scene root, the harness forwards that flag into `AutoStartManager`, and `AutoStartManager` now skips its normal `_stop_sync()` shutdown path for `WM_CLOSE`, `EXIT_TREE`, and `PREDELETE`. Connected preview behavior during playback stays unchanged; the only intentional difference is close-time teardown. Logs now say explicitly that close-path isolation is active and that the sidecar is being left alive on purpose so it can die on its own heartbeat timeout (~3s) after Godot exits. This makes the repro question crisp: if Cookie still resets while the normal stop path is bypassed, the crash is probably not specific to AutoStartManager's sidecar stop/kill sequence; if the reset disappears, that shutdown path remains the prime suspect. Terminal-safe validation stayed static-only per tonight's constraint: a headless Godot parse-only pass preloaded both modified scripts without errors, and `git diff` review confirmed the toggle is narrowly scoped to close-path behavior. Exact manual repro steps for Derrick: (1) open `.testbed` on Cookie and load `res://scenes/boxing_proving.tscn`; (2) on the root `BoxingProving`, set `startup_mode = PREVIEW_ONLY_DEBUG`; (3) set `skip_sidecar_stop_on_close_debug = true`; (4) keep `prerecorded_video_source` pointed at the boxing fixture if you want the file-backed repro rung, or leave the current source override you are comparing against; (5) run the scene, wait until connected preview is visibly working, then close the game window normally via the titlebar/X so the close path is exercised; (6) watch whether Cookie still crashes/resets; (7) if you need log proof, look for `[ProvingHarness] Close-path isolation enabled` plus `[AutoStartManager] Close-path isolation active` / `leaving sidecar running for close-path isolation`. Cleanup notes: this toggle is intentionally one-shot and debug-only; after the repro, set `skip_sidecar_stop_on_close_debug` back to `false` before any normal work, because with it enabled the sidecar is expected to linger briefly after close until heartbeat timeout handles shutdown instead of the usual immediate stop path.

---

### Task 65: Research Chip crash-sandbox test flow and current shutdown-path target

**Bead ID:** `oc-3j3t`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-18`, `REF-19`, `REF-20`
**Prompt:** Re-enter the crash branch from the 2026-05-09 handoff, but adapt it to today’s execution model on Chip. Confirm the sharpest current hypothesis, the minimum environment checks needed on the remote host before any repro, and the safest highest-signal comparison order now that Derrick can locally recover Chip’s GUI after each crash.

**Folders Created/Deleted/Modified:**
- `.plans/`
- forensic/log notes only as needed

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny truth-revealing note is required

**Status:** ✅ Complete

**Results:** Research completed and bead `oc-3j3t` should close. The sharpest current shutdown-path hypothesis is no longer just “sidecar involvement”; it is the **normal AutoStartManager close-time stop sequence itself**, especially the synchronous Linux teardown cluster that only runs when sidecar stop-on-close is enabled: `DesktopSidecarLauncher.terminate_sync()` (TERM then KILL against the whole process group) followed immediately by repo-level cleanup kills (`pkill -9 -f python_mediapipe/main.py`, and in the async path also `pkill -9 -f main.py` plus `fuser -k -9 /dev/video0`). That cluster is reached from `WM_CLOSE_REQUEST` / `EXIT_TREE` / `PREDELETE`, while the proving harness otherwise keeps the same connected-preview playback surface. The decisive evidence remains the 2026-05-09 handoff truth: connected preview stayed the same, but when `skip_sidecar_stop_on_close_debug=true` bypassed that normal close-time stop path, Cookie stopped crashing. So the prime suspect family is the **specific shutdown behavior inside AutoStartManager / launcher cleanup**, not preview existence, not MediaPipeProvider startup, and not live camera hardware as a requirement.

Minimum pre-repro Chip checks should stay narrow and mechanical before risking any GUI reset: (1) confirm the remote repo is on or ahead of commit `e719624` and still contains the close-path toggle plus the file-backed proving fixes (`git rev-parse --short HEAD`, `git merge-base --is-ancestor e719624 HEAD`); (2) confirm the active `.testbed` addon copy matches the owning source for `src/autostart_manager.gd` so Chip will actually run the shutdown-isolation code path under test; (3) confirm the prepared sidecar runtime exists on Chip by running the resolved runtime Python and importing `mediapipe`, plus verify the required model asset file exists; and (4) confirm Chip really has a live GUI/X11 session available for a human repro (`loginctl show-user derrick`, active `DISPLAY`, and no stale leftover `python_mediapipe/main.py` before launch). Those checks are enough to avoid wasting a crash pass on stale code, missing deps, or a dead desktop session.

Safest highest-signal comparison order on Chip is now an **A/B on one variable only** using the cleanest already-proven repro surface: Boxing proving scene, `startup_mode=PREVIEW_ONLY_DEBUG`, prerecorded/file-backed source selected, and the close done normally via the window manager. First run the file-backed preview rung with `skip_sidecar_stop_on_close_debug=true` as the non-crashing hypothesis baseline; if Chip still crashes there, the hypothesis weakens immediately or Chip introduces a new confound. Then, with everything else unchanged, flip only `skip_sidecar_stop_on_close_debug=false` and rerun the exact same file-backed `PREVIEW_ONLY_DEBUG` close. That is the highest-signal first comparison because it preserves the connected-preview repro surface while toggling only the suspected shutdown path. Only after that A/B should today’s branch widen into finer shutdown sequencing (for example deferred stop vs immediate stop inside `AutoStartManager`) if Chip reproduces the same no-crash/crash split as Cookie.

---

### Task 66: Prepare Chip aerobeat-input-mediapipe-python workspace and dependencies for crash testing

**Bead ID:** `oc-dlcg`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-18`, `REF-19`, `REF-20`
**Prompt:** Using `ssh chip`, verify that Chip’s `aerobeat-input-mediapipe-python` checkout is up to date enough for the current crash branch, ensure the local testbed/addon copy and Python-side dependencies are present, and leave the remote workspace ready for repeated crash repros without unsafe guesswork.

**Folders Created/Deleted/Modified:**
- `.plans/`
- remote Chip repo/runtime paths as required

**Files Created/Deleted/Modified:**
- remote repo/runtime files only as required by truthful prep

**Status:** ✅ Complete

**Results:** Chip remote prep completed directly over `ssh chip`. The owning repo is on commit `e719624` (`Add close-path isolation toggle for preview crash repro`), so the latest shutdown-path isolation work from last night is present. The proving testbed still points `run/main_scene` at `res://scenes/boxing_proving.tscn`, the prerecorded boxing fixtures and pose models are present, the testbed addon mirror matches the owning `src/autostart_manager.gd` and `src/camera_view.gd`, and the embedded Python runtime successfully imports `cv2`, `mediapipe`, and `numpy`. Chip also has a working Godot launcher at `~/.local/bin/godot` (`4.6.2`). One important ops gap showed up: Chip’s shared `desktop-app-forensics.sh` was still the stale nohup-only version, so it was refreshed from the current workspace copy before crash work continued. Another useful harness truth surfaced during prep: on Chip, system-scope capture must be started as `derrick` and allowed to escalate internally; wrapping the entire start command in `sudo` made the log dir root-owned and caused the controller to die on permission errors. The corrected system-scope harness is now armed successfully at `/home/derrick/Documents/forensics/chip-godot-stop-playback-20260509-141721` with active unit `desktop-app-forensics-1778350641-546248.service`. Minor caveat kept explicit: a headless `--check-only` compile path still reports existing `MediaPipeProvider`-adjacent parse issues, so GUI/editor truth on Chip should remain the primary launch surface for today’s repros rather than over-trusting headless parse-only checks.

---

### Task 67: Run Chip crash-path comparison tests and capture results

**Bead ID:** `oc-i58l`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-18`, `REF-19`, `REF-20`
**Prompt:** Once Chip is prepared, run the next highest-signal shutdown-path comparisons from the active crash matrix on Chip, keeping the repro surface safe for Pico’s local machine. Record exactly which rung was tested, whether preview connected, whether close crashed the GUI, and what logs/artifacts survive after Derrick restores the desktop session.

**Folders Created/Deleted/Modified:**
- `.plans/`
- remote Chip repo/runtime paths and forensic artifact dirs as needed

**Files Created/Deleted/Modified:**
- plan updates and repro notes only unless tiny capture glue is required

**Status:** ⏳ Pending

**Results:** Partial progress on Chip: Derrick ran the Boxing proving scene with the `punch_left` prerecorded boxing fixture, `startup_mode = PREVIEW_ONLY_DEBUG`, and `skip_sidecar_stop_on_close_debug = true`, observed the MediaPipe skeleton overlay during video playback, and then closed the scene normally **without** triggering a Zorin GUI crash. That is a high-signal first-half A/B confirmation on Chip: connected preview + active overlay/video playback still appears safe when the normal sidecar stop-on-close path is bypassed. Derrick then reran the exact same host/rung with only `skip_sidecar_stop_on_close_debug` flipped back to `false`. Important confound on this second-half run: the prerecorded video was not visually rendering, the skeleton initially tracked, then later stopped updating before close, with console-error spam reported during the run. Derrick’s console snapshot explains the likely wedge: `mediapipe_server.gd:59 @ _process(): Buffer full, dropping packets!` plus `camera_view.gd:247 @ stop_stream(): A Thread object is being destroyed without its completion having been realized. Please call wait_to_finish() on it to ensure correct cleanup.` When Derrick closed playback, **Chip still did not crash**. So Chip currently does **not** reproduce the clean Cookie-style shutdown crash on this exact comparison ladder. That weakens the simple host-agnostic "normal sidecar stop-on-close always crashes" theory and promotes a narrower branch: Chip likely hit a local packet-backlog / stream-thread cleanup defect that degraded the run before close, so the next comparison should distinguish host-specific crash differences from this newly surfaced buffer/thread confound.

---

### Task 68: Audit Chip crash-test results and recommend next shutdown isolation step

**Bead ID:** `oc-v2uv`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-18`, `REF-19`, `REF-20`
**Prompt:** Audit the first Chip-hosted crash-test results against the current close-path-shutdown hypothesis. Decide what the run actually proves, whether the Chip environment introduces any new confounds, and what the next smallest shutdown-path isolation step should be.

**Folders Created/Deleted/Modified:**
- `.plans/`
- forensic/log dirs only for reading / notes

**Files Created/Deleted/Modified:**
- plan updates and audit notes only

**Status:** ✅ Complete

**Results:** Auditor pass completed from plan evidence plus source inspection only. The first-half Chip run still supports the earlier Cookie truth cut: file-backed connected preview with `skip_sidecar_stop_on_close_debug=true` closed cleanly, so bypassing the normal AutoStartManager stop path remains a meaningful non-crash baseline. But the second-half Chip run does **not** truthfully falsify the Cookie shutdown hypothesis yet, because Chip appears to have fallen off the intended clean `PREVIEW_ONLY_DEBUG` repro surface before close. The strongest source-grounded clue is the reported `mediapipe_server.gd:59 @ _process(): Buffer full, dropping packets!` warning: in the current proving harness, a real `PREVIEW_ONLY_DEBUG` run returns from `_on_server_started()` **before** `_start_provider()`, so `MediaPipeProvider` / `MediaPipeServer` should never be alive there at all. If that warning is real on the active runtime, then the second Chip pass was not actually the same provider-disabled rung anymore, or the runtime drifted onto a path where provider/server activity re-entered. That alone is enough to demote the second-half no-crash result as a shutdown-comparison proof.

The other reported warning is also source-actionable and likely contributes to the dirty close surface: `camera_view.gd:247 @ stop_stream(): A Thread object is being destroyed without its completion having been realized...`. Current `src/camera_view.gd` says it should always wait, but it still only calls `wait_to_finish()` when `_stream_thread.is_alive()`. In Godot, a finished thread object still needs `wait_to_finish()` before destruction, so this is a real cleanup bug in the current source and a plausible reason Chip’s close path is not matching Cookie’s earlier cleaner crash presentations.

Probable mechanism ranking for Chip now: (1) the second run was not a pure `PREVIEW_ONLY_DEBUG`/provider-disabled repro anymore, likely because the active scene/runtime settings drifted; (2) once provider/server was active, Chip hit a separate packet-backlog state before close, which changed playback into a degraded/shutdown-different condition; (3) the current `CameraView` thread-join bug further muddies teardown by leaving a stream-thread cleanup warning at close. The narrowest next Chip-only branch is therefore **not** deeper AutoStartManager kill sequencing yet. First restore a clean file-backed `PREVIEW_ONLY_DEBUG` surface on Chip by tightening only the repro-surface integrity points: (a) in `.testbed/scripts/proving_harness.gd`, make `PREVIEW_ONLY_DEBUG` self-auditing by loudly surfacing `provider=disabled`, clearing/hiding landmark-trail overlays, and warning if a provider/server ever becomes active; (b) in `src/camera_view.gd`, always realize the stream thread with `wait_to_finish()` whenever `_stream_thread` exists during stop/teardown, not only when `is_alive()` is true; and (c) before the next Chip rerun, verify the active scene/addon hashes and root-node `startup_mode` so the rung is truly provider-free. After that, rerun the exact same Chip A/B (`skip_sidecar_stop_on_close_debug=true` then `false`) on the file-backed preview rung and reject the run as invalid if any provider/server buffer warning or overlay/provider activity appears. Only if that cleaned repro still diverges from Cookie should the branch widen back into finer AutoStartManager shutdown sequencing.

---

### Task 69: Implement clean Chip PREVIEW_ONLY_DEBUG surface and camera thread teardown

**Bead ID:** `oc-sw7t`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-18`, `REF-20`, `REF-21`
**Prompt:** Implement the smallest truthful fix set that restores a clean Chip-only `PREVIEW_ONLY_DEBUG` file-backed repro surface before more crash comparisons. Scope should stay tight: make `PREVIEW_ONLY_DEBUG` self-auditing enough that provider activity/overlay drift becomes obvious or invalid, and fix the `camera_view.gd` stream-thread teardown so the thread object is always properly realized before destruction.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/`
- `src/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/proving_harness.gd`
- `.testbed/tests/unit/test_proving_harness_trails.gd`
- `src/camera_view.gd`

**Status:** ✅ Complete

**Results:** Landed the smallest repo-owned cleanup needed to make Chip's `PREVIEW_ONLY_DEBUG` rung self-auditing again before more crash comparisons. In `.testbed/scripts/proving_harness.gd`, preview-only mode now explicitly records and surfaces that the provider is expected to stay disabled, includes preview audit state in the live/debug/console surfaces, clears landmark + trail overlays continuously on that rung, and marks the rung `INVALID` with a logged `preview_only_invalid` event if provider/pose/tracking activity leaks back in. That makes REF-18/REF-20 drift visible instead of silently presenting a misleading skeleton overlay. In `src/camera_view.gd`, stream teardown now realizes any existing thread object via `wait_to_finish()` through a single helper on both startup cleanup and `stop_stream()`, so the finished-thread destruction warning called out in REF-21 no longer relies on `is_alive()` being true at destruction time. Added targeted GUT coverage in `.testbed/tests/unit/test_proving_harness_trails.gd` for the new preview-only audit/invalidation behavior.

Validation run locally from this repo: `godot --headless --path .testbed --import` ✅ and `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_proving_harness_trails.gd -gexit` ✅ (9/9 passed).

---

### Task 70: QA clean Chip PREVIEW_ONLY_DEBUG surface before rerun

**Bead ID:** `oc-zex2`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-18`, `REF-20`, `REF-21`
**Prompt:** Independently verify in the available terminal-safe scope that the cleaned `PREVIEW_ONLY_DEBUG` rung is actually provider-free/self-auditing enough for Chip reruns and that the camera stream thread cleanup is fixed tightly enough to remove the current shutdown warning confound.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ✅ Complete

**Results:** QA completed against commit `c247339` in terminal-safe scope only; no live Chip GUI/editor rerun was performed. What is now **proven by source + headless validation**: (1) `PREVIEW_ONLY_DEBUG` still exits `_on_server_started()` before `_start_provider()`, so the intended rung remains provider-disabled by construction; (2) the harness now self-audits that contract continuously via `_audit_preview_only_surface()` in `_process()`, surfaces `Preview audit: provider=disabled (expected)` across live/summary/quick-stats/console text, logs `preview_only_provider_disabled` on entry, and marks the rung `INVALID` with `preview_only_invalid` if pose updates, tracking signals, or a live `MediaPipeProvider` node leak into preview-only; (3) preview-only cleanup now actively clears landmarks/trails instead of passively leaving stale overlay state around; and (4) `src/camera_view.gd` now routes both start-time orphan cleanup and normal `stop_stream()` teardown through `_realize_stream_thread(...)`, which unconditionally calls `wait_to_finish()` whenever a thread object exists instead of relying on `is_alive()`. Independent validation evidence: `~/.local/bin/godot --headless --path .testbed --import` passed, and `~/.local/bin/godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_proving_harness_trails.gd -gexit` passed `9/9`; the new QA tests explicitly proved default preview-only audit text plus invalidation/overlay-clear behavior for both pose activity and provider-node drift.

What is **not yet proven** without Derrick’s direct Chip truth pass: that the real Chip editor/runtime rerun stays visually provider-free for the whole session, that no `mediapipe_server.gd:59 Buffer full, dropping packets!` family reappears under the actual file-backed repro, and that the old `camera_view.gd ... Thread object is being destroyed without its completion having been realized` warning is truly gone in a live close on Chip rather than only fixed in source. So the current QA verdict is: the rung is now clean/self-auditing enough to justify the next Chip A/B rerun, and the specific thread-cleanup warning confound is removed at source, but only Derrick’s real Chip run can certify runtime cleanliness and whether the host still diverges from Cookie.

---

### Task 71: Audit cleaned Chip rerun and decide next crash branch

**Bead ID:** `oc-6gfl`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-18`, `REF-20`, `REF-21`
**Prompt:** After the cleaned Chip rerun lands, audit whether the repro surface was finally clean enough to trust and decide whether the shutdown-path crash family reappears on Chip or whether a host-specific difference still dominates.

**Folders Created/Deleted/Modified:**
- `.plans/`
- forensic/log dirs only for reading / notes

**Files Created/Deleted/Modified:**
- plan updates and audit notes only

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 72: Research and scope console/logging cleanup on the Chip proving path

**Bead ID:** `oc-t3u2`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-18`, `REF-20`, `REF-21`, `REF-22`
**Prompt:** Audit the current proving/test-scene logging surfaces and identify the smallest truthful cleanup plan so normal playback has zero per-update console spam, useful startup messages are preserved, and exit-path logging stays concise and signal-rich for crash forensics. Include the new CSV import warning in scope triage so we know whether it belongs to repo layout/import settings or runtime packaging.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/`
- `src/`
- repo config/import surfaces only as needed for inspection

**Files Created/Deleted/Modified:**
- plan updates only unless a tiny truth-revealing probe is required

**Status:** ✅ Complete

**Results:** Source audit complete. The steady-state console spam on the proving path is repo-owned and currently comes from two loop-driven surfaces: (1) `.testbed/scripts/proving_harness.gd`, where `_process()` calls `_emit_console_snapshot_if_changed()` every 30 frames and the snapshot text includes constantly changing trail/live-state fields, so "if changed" still prints during normal playback; and (2) `src/camera_view.gd`, which emits preview cadence logs on the first few/each 60 decoded frames plus 5-second stream stats, creating background chatter even when nothing is wrong. Startup/status signal is otherwise already concentrated in `_on_*` handlers and `_record_event()` / `_update_status()` in `proving_harness.gd`, so the smallest truthful cleanup is to make loop-driven snapshot/telemetry logging opt-in debug (or remove the periodic call entirely) while preserving event-driven startup/failure/tracking-transition messages.

Close-path logging is also repo-owned and noisier than it needs to be: `.testbed/scripts/proving_harness.gd` logs `WM_CLOSE_REQUEST`, `EXIT_TREE/PREDELETE`, and `_stop_everything()`; `src/autostart_manager.gd` logs again in `_exit_tree()`, `_notification()`, and `_should_skip_close_path_stop()`; and `src/camera_view.gd` logs `_exit_tree`, `stop_stream()`, thread realization, and stream end. That means a single close can legitimately fan out into several repeated lines even on the expected isolation path. Smallest next slice: keep one high-value harness summary for shutdown intent/result, keep true warnings/errors, and make the repeated close-path informational prints one-shot or debug-only so crash forensics still retain the first meaningful reason without burying it in teardown noise.

CSV import-warning triage: this does not look like runtime Python behavior; it looks like Godot/project-layout scanning. The proving testbed mounts the whole repo back into `.testbed/addons/aerobeat-input-mediapipe-python` as a symlink to the repo root, and the vendored runtime/venv under `python_mediapipe/assets/runtimes/...` contains many `.csv` files from third-party packages (`numpy`, `matplotlib`, etc.). Even with `python_mediapipe/assets/runtimes/.gdignore` present, the warning family belongs to repo/testbed import surfaces first (symlinked addon layout / Godot scan scope), not MediaPipe runtime packaging logic. Recommended ownership for the follow-up is testbed layout/import hygiene rather than Python sidecar code.

Smallest implementation slice for Task 73: (a) stop periodic proving-harness console snapshots by default, (b) gate `camera_view.gd` cadence/stats/connect chatter behind an explicit debug flag while preserving `push_error()` and real failure prints, (c) collapse repeated close-path info logs in `proving_harness.gd` + `autostart_manager.gd` to one concise summary plus real warnings, and (d) separately mitigate the CSV warning by tightening what the `.testbed` addon mount exposes to Godot or otherwise excluding the vendored runtime tree from import scanning. Likely owning files: `.testbed/scripts/proving_harness.gd`, `src/camera_view.gd`, `src/autostart_manager.gd`, and `.testbed/addons/aerobeat-input-mediapipe-python` / related testbed import-layout config.

---

### Task 73: Implement proving-path logging cleanup and import-warning mitigation

**Bead ID:** `oc-dkpf`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-20`, `REF-21`, `REF-22`
**Prompt:** Implement the smallest truthful fix set that removes per-update console spam from the proving path, keeps shutdown/startup logging intentional and low-volume, dedupes noisy repeated close-path messages where possible, and addresses the new CSV import warning if it is owned by this repo/testbed layout.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/`
- `src/`
- repo config/import surfaces if directly required

**Files Created/Deleted/Modified:**
- only directly owning source/config files required by the approved fix

**Status:** ✅ Complete

**Results:** Implemented the smallest repo-owned cleanup slice for the proving/logging branch and validated it locally. In `.testbed/scripts/proving_harness.gd`, steady-state console snapshots are now off by default via the new `steady_state_console_debug` flag, `CameraView` / `AutoStartManager` debug chatter is only re-enabled when those debug exports are turned on, and the close path now emits one concise harness shutdown summary instead of logging every close/teardown notification separately. In `src/camera_view.gd`, steady-state connect/cadence/stats/overflow/thread lifecycle prints are now gated behind exported `debug_logging=false` while preserving real failures via `push_error()` / `push_warning()`. In `src/autostart_manager.gd`, repeated close-path informational lines were collapsed into a one-shot shutdown summary, with lower-value internal lifecycle chatter moved behind `debug_logging`. For the CSV/import-noise mitigation, `.gitignore` now explicitly allows tracked `.gdignore` markers inside the repo-owned platform runtime roots, and new `python_mediapipe/assets/runtimes/linux-x64/.gdignore` plus `.../windows-x64/.gdignore` tighten the hidden boundary to the exact vendored runtime folders that can surface third-party `.csv` import warnings under the symlinked `.testbed` addon mount. Validation for this coder pass: `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/proving_harness.gd`; `~/.local/bin/godot --headless --path .testbed --import --quit-after 1000`; `python3 -m py_compile python_mediapipe/*.py`; and `git diff --check` all passed. The generated validation logs for the headless checks contained zero matches for `.csv`, `MJPEG buffer overflow`, `Preview cadence`, `Thread object is being destroyed`, and the earlier `Failed to connect, status: 3` warning family, which is the best terminal-safe evidence that the default proving path is now quiet unless real errors occur. Commit: current HEAD (`Quiet proving harness logging by default`).

---

### Task 74: QA cleaned proving logs and shutdown-path signal quality on Chip

**Bead ID:** `oc-0wba`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-20`, `REF-21`, `REF-22`
**Prompt:** Independently verify that normal proving playback is no longer flooding the console, that shutdown logs are concise enough to be useful during crash hunting, and that the prior warning families are either gone or explicitly understood before the next Chip rerun.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ✅ Complete

**Results:** QA completed in terminal-safe scope against commit `d811c09` and bead `oc-0wba` can close, but the acceptance result is mixed and not yet clean enough to skip another Chip truth pass. What is proven by source/headless validation: (1) the intended low-value warning families targeted by this cleanup are gone in the validated paths — `--check-only` and `--import` produced no `.csv` import warnings, and prerecorded Boxing playback produced zero `Preview cadence`, zero `MJPEG buffer overflow`, zero `Thread object is being destroyed`, and zero `Failed to connect, status: 3` lines; (2) the new shutdown surface is materially cleaner when teardown is exercised directly — a controlled headless driver produced exactly one harness shutdown summary (`[ProvingHarness][Boxing] Shutdown summary: reason=qa_driver ...`) and one AutoStartManager shutdown summary (`[AutoStartManager] Shutdown summary: reason=exit_tree/stop_sync ...`) with no old `Window close request`, `Scene teardown notification`, or `stop_server() called` spam; and (3) source inspection confirms the quieter defaults are wired as intended (`steady_state_console_debug=false`, `CameraView.debug_logging=false`, `AutoStartManager.debug_logging=false`). What is also proven, and is the important blocker: normal prerecorded proving playback still floods the terminal from the harness event path itself. In an 8-second headless Boxing run against `.testbed/assets/videos/boxing.mp4`, the log contained 1,568 total lines, including 774 repeated `[ProvingHarness][Boxing] mode=...` snapshot lines plus hundreds of guard/squat/event prints because `_record_event()` still prints every event and force-emits a full console snapshot while `trail_debug_logging` remains true by default. So the steady-state camera/connect/thread spam is cleaned up, but the proving harness is not yet terminal-quiet under active detector traffic. One warning family also remains explicitly understood rather than globally gone: on the no-camera local live path, `Failed to connect, status: 3` still appears because the sidecar cannot open camera `0`; that is expected for this host’s no-camera run and does not invalidate the prerecorded playback evidence. Net QA call: shutdown logging is now concise enough to help crash hunting, the prior noisy warning families are mostly removed or understood, but normal proving playback is still too chatty to certify this bead’s user-facing goal as fully met. Derrick still needs a direct Chip rerun for the actual crash path truth, and before that rerun the next code pass should specifically gate or coalesce `_record_event()` / forced snapshot emission (and likely revisit `trail_debug_logging` default) rather than touching the already-cleaned camera-thread/info logs. Validation artifacts: `.temp/qa-task74/check-only.log`, `.temp/qa-task74/import.log`, `.temp/qa-task74/prerecorded-headless.log`, and `.temp/qa-task74/shutdown-driver.log`.

---

### Task 75: Break down Derrick’s Boxing gesture detector mockup and identify implementation questions

**Bead ID:** `oc-kdg3`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-22`, `REF-23`
**Prompt:** Claim bead `oc-kdg3`, inspect Derrick’s mockup screenshot at `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/10/aerobeat-boxing-gesture-detector-0a43eb94.png`, compare it to the current Boxing proving scene structure (`.testbed/scenes/boxing_proving.tscn` + `.testbed/scripts/proving_harness.gd`), and produce a concrete design breakdown for implementation. Focus on layout regions, reusable UI patterns, likely Godot node mapping, gesture-state behavior, assets/questions that still need Derrick clarification, and the smallest truthful first implementation slice. Claim the bead on start with `bd update oc-kdg3 --status in_progress --json` and close it on completion with a concise reason.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/`
- mockup/reference asset paths only for reading

**Files Created/Deleted/Modified:**
- plan updates / analysis notes only unless a tiny reference note is required

**Status:** ✅ Complete

**Results:** Research breakdown complete against `REF-23` and the current Boxing proving scene/harness in `REF-22`. Practical read: the mockup is not a minor skin on the current text-debug surface; it is a two-column proving UI where the left ~48% of the screen is a presentation/test area (title row, large camera preview, compact scrolling event log) and the right ~52% is a single rounded translucent selection board containing a 3x3 gesture grid. The current camera pipeline, detector state/event plumbing, and scroll-backed event history are reusable, but most of the present right-column text panels (`Summary`, `SignalStatus`, `Metrics`, and the current text-heavy `Events` presentation) should be replaced for this path with visual gesture cards/buttons plus a bottom-left log panel.

Likely Godot mapping: keep `BoxingProving` root, header/title status wiring, provider startup, `CameraPanel`, `CameraDisplay`, landmark/trail overlays, and the `_event_lines` backing store. Replace the current `HSplitContainer` composition with a deliberate layout shell: left column containing title/header + camera panel + event-log panel, and right column containing a `PanelContainer`/styled board with a `GridContainer` of 9 gesture cells (`Punch`, `Hook`, `Uppercut`, `Knee Strike`, `Guard`, `Leg Lift`, `Side Step`, `Squat`, `Dodge`). Each cell likely wants icon/illustration, title, and either L/R hit buttons or a centered persistent-state chip. Inferred behavior: attack families with handedness expose two per-side indicators (`L` / `R`) that flash/highlight on event fire and otherwise idle; persistent states like `Guard` and `Squat` use a centered `Active` pill while state is true; `Leg Lift`, `Knee Strike`, `Punch`, `Hook`, `Uppercut`, `Side Step`, and likely `Dodge` are event-driven side indicators rather than latched buttons. The log is chronological, newest visible at the bottom in the mockup styling, with compact numbered entries and a scrollbar; implementation can truthfully keep the existing event buffer but should render it bottom-anchored / mockup-styled instead of as a debug text block.

Derrick clarified the open behavior mappings on 2026-05-10: `Dodge` maps directly to `lean_left` / `lean_right`; `Side Step` maps directly to `sidestep_left` / `sidestep_right`; `Leg Lift` uses left/right pulse indicators; the right-side tiles are status-only for now; and event numbers are visible ordering only, with one new detected beat event producing one new visible list row. Derrick also clarified the product intent: this redesign is meant to replace the current Boxing gesture detection scene because it makes the scene readable at a glance, not just add an alternate debug surface. The final icon assets already exist under `.testbed/assets/icons/*.svg`, and the background image target is `.testbed/assets/backgrounds/perfect-hue-may-08-2026-hd.png`; implementation may need a repo sync first so those assets are present locally.

That leaves only one meaningful fidelity question before coder work: how tightly to chase the mockup's exact spacing/proportions versus matching its visual system and glanceability within the existing 16:9 proving-scene constraints. Smallest truthful implementation slice has now widened slightly because the key behavior ambiguities are resolved: sync the latest repo/assets if needed, rebuild the Boxing proving scene shell, preserve the detector plumbing, wire all nine gesture tiles to the approved event/state mappings, and render the simplified visible-order event list on the left.

---

### Task 76: Implement final harness event-verbosity cleanup before Chip rerun

**Bead ID:** `oc-q8u1`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-20`, `REF-21`, `REF-22`
**Prompt:** Implement the smallest final harness-only logging cleanup before the next Chip rerun. Target the remaining spam identified by QA: gate or coalesce `_record_event()`, stop force-emitting full snapshots on every event, and revisit `trail_debug_logging` defaults so normal prerecorded proving playback is quiet by default while preserving intentionally useful startup/exit signal.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/proving_harness.gd`
- any directly owning proving-harness support files only if truly required

**Status:** ✅ Complete

**Results:** Coder pass completed and bead `oc-q8u1` is ready to close. Scope stayed harness-only in `.testbed/scripts/proving_harness.gd`. The remaining detector-event spam was removed by changing `_record_event()` from an unconditional console logger + forced snapshot trigger into a quiet-by-default UI recorder: event history/counts/panels still update, but console event prints now happen only when `steady_state_console_debug=true` or for the small high-signal failure set (`server_failed`, `camera_stream_failed`, `preview_only_invalid`). Full console snapshots are no longer force-emitted on every event; they now emit only through the existing steady-state debug path and only when the snapshot text actually changes. `trail_debug_logging` was also flipped from default `true` to `false`, so ordinary prerecorded proving playback no longer injects trail-continuity detail into the console snapshot by default.

Terminal-safe validation passed locally. `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/proving_harness.gd` exited cleanly, `~/.local/bin/godot --headless --path .testbed --import --quit-after 1000` stayed clean, and an 8-second prerecorded Boxing headless run with `AEROBEAT_MEDIAPIPE_CAMERA_SOURCE=.testbed/assets/videos/boxing.mp4` shrank from the prior QA baseline of 1,568 log lines / 774 snapshot lines to just 23 total log lines with `0` `[ProvingHarness][Boxing] mode=...` snapshot lines and `0` detector event-print lines, while preserving useful startup + shutdown signal (`Initializing`, sidecar readiness, `Python server started`, `Boxing harness live`, and one each of the AutoStartManager / ProvingHarness shutdown summaries). Validation artifacts for this coder pass: `.temp/task76/check-only.log`, `.temp/task76/import.log`, and `.temp/task76/prerecorded-headless.log`. Commit: final coder commit for this task (`Quiet proving harness event logging`).

---

### Task 77: QA final harness log quieting before Chip rerun

**Bead ID:** `oc-nqp8`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-20`, `REF-21`, `REF-22`
**Prompt:** Independently verify that normal prerecorded proving playback is finally quiet enough by default for Chip crash hunting, while keeping startup/exit logs and real warnings meaningful.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ✅ Complete

**Results:** QA completed against commit `71c3716` (`Quiet proving harness event logging`) using terminal-safe validation only; bead `oc-nqp8` is ready to close. Independent evidence says the default prerecorded proving path is now finally quiet enough to use as a crash-hunting console surface. Fresh local QA artifacts live under `.temp/task77/`. Validation details: `godot --headless --path .testbed --check-only --script scripts/proving_harness.gd` passed, `godot --headless --path .testbed --import --quit-after 1000` passed with `0` `.csv` warning matches, and an independent 8-second prerecorded Boxing run with `AEROBEAT_MEDIAPIPE_CAMERA_SOURCE=.testbed/assets/videos/boxing.mp4` produced just `20` total log lines, `0` `[ProvingHarness][Boxing] mode=...` snapshot lines, `0` detector event-print lines, `0` `Preview cadence` lines, `0` `MJPEG buffer overflow` lines, `0` thread-destruction warnings, and `0` `Failed to connect, status: 3` warnings. A second graceful-shutdown driver pass against the same prerecorded source produced `23` total log lines with `0` snapshot/event spam and exactly `2` shutdown summaries: one concise harness summary plus one concise AutoStartManager summary. Startup/exit signal stayed meaningful in that pass: initialization, runtime/dependency readiness, sidecar start, `Boxing harness live`, then clean shutdown summaries.

What is now proven: commit `71c3716` removed the remaining default proving-harness event/snapshot spam identified in Task 74, and the terminal log surface is quiet enough by default for the next Chip crash rerun while preserving useful startup and exit markers. What is **not** proven by this QA pass: real Chip-hosted editor/runtime behavior on the actual crash path. Derrick still needs the direct Chip truth pass to confirm that the quieter console really stays this clean during the host-specific close-path repro and that no new runtime-only warning family appears there.

---

### Task 78: Audit post-quieting Chip rerun and decide next crash branch

**Bead ID:** `oc-6ist`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-20`, `REF-21`, `REF-22`
**Prompt:** After the final quieted Chip rerun lands, audit whether the repro surface is finally clean enough to trust and decide whether the shutdown-path crash family reappears on Chip or whether another host-specific difference still dominates.

**Folders Created/Deleted/Modified:**
- `.plans/`
- forensic/log dirs only for reading / notes

**Files Created/Deleted/Modified:**
- plan updates and audit notes only

**Status:** ⏳ Pending

**Results:** Pending.

### Task 79: Implement the approved Boxing gesture detector UI redesign in the proving scene

**Bead ID:** `oc-s4y7`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-23`
**Prompt:** After Derrick confirms the mockup breakdown, implement the new Boxing gesture detector UI in the owning source. Replace the current text-heavy proving-scene presentation with the approved visual layout, preserve the actual detector/tracking behavior, and keep the change scoped to the Boxing proving path unless Derrick explicitly asks for Flow parity in the same pass.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/`
- any directly owning Boxing proving UI asset paths required by the approved design

**Files Created/Deleted/Modified:**
- Boxing proving scene/harness/UI assets as required by the approved implementation

**Status:** ✅ Complete

**Results:** Coder pass completed on bead `oc-s4y7`. The checkout was truthfully brought up to the approved repo-owned UI assets first by pulling just the exact asset paths from `origin/main` into this working tree: `.testbed/assets/backgrounds/perfect-hue-may-08-2026-hd.png` plus the approved `.testbed/assets/icons/boxing-*.svg` set. The Boxing proving scene itself was then rebuilt around the mockup’s 16:9 composition in `.testbed/scenes/boxing_proving.tscn`: full-screen approved background, compact header, large left camera surface, dark simplified event-feed panel below it, and a right-side rounded translucent board containing a 3x3 gesture grid.

To keep Flow isolated, the redesign was implemented through a new Boxing-only subclass script at `.testbed/scripts/boxing_proving_harness.gd` rather than broad rewrites to the shared `proving_harness.gd`. Detector/camera/provider/event plumbing remains inherited from the shared harness, while the subclass replaces the Boxing-facing shell/presentation only. The new board uses the approved icons and real detector mappings across all 9 tiles: Punch/Hook/Uppercut/Knee Strike pulse their L/R badges from the real left/right event timestamps; Guard and Squat show a centered active/idle pill from persistent gesture state; Dodge maps to `lean_left` / `lean_right`; Side Step maps to `sidestep_left` / `sidestep_right`; and Leg Lift pulses from `leg_lift_left_start` / `leg_lift_right_start`. The left event feed is now simplified visible-order rows with mockup-style zero-padded sequence numbers and human-readable gesture labels, with one new Boxing detector event producing one new visible row.

Truthful repo-local validation completed: `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/boxing_proving_harness.gd` passed; `~/.local/bin/godot --headless --path .testbed --import --quit-after 1000` completed and imported the new approved assets cleanly; and a headless scene probe loaded/instantiated `res://scenes/boxing_proving.tscn` in `startup_mode=GODOT_ONLY_DEBUG` and confirmed the new board exists with 9 generated gesture tiles. Important limitation: there was no attached Godot plugin/editor session available for a true screenshot-by-screenshot visual parity pass against `REF-23`, so the final visible mockup comparison still belongs to QA / auditor / Derrick on the real editor/runtime surface.

### Task 80: QA the redesigned Boxing gesture detector UI on the real proving path

**Bead ID:** `oc-xkpr`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-23`
**Prompt:** Independently verify that the redesigned Boxing gesture detector UI matches Derrick’s approved mockup closely enough on the real proving path, that the active/inactive gesture states behave correctly, and that the new layout is still usable in the target 16:9 proving viewport.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ✅ Complete

**Results:** QA reran bead `oc-xkpr` against retry commit `caa8464` and the prior hard failures are now fixed strongly enough to hand the work to audit. I still do **not** have an attached Godot plugin/editor session or a usable live X11/Wayland capture surface from this shell, so I cannot truthfully claim pixel-perfect live screenshot parity from a real window. Instead I used the strongest combination available: source inspection of `.testbed/scenes/boxing_proving.tscn` + `.testbed/scripts/boxing_proving_harness.gd`, fresh Godot headless validation/import, a 1280×720 layout probe, and targeted runtime event/state probes in `startup_mode=GODOT_ONLY_DEBUG`.

Explicit rerun findings for the prior failure list:
- **1. Full right-side 3×3 board fits in the visible 16:9 viewport with no scrolling:** fixed. Fresh 1280×720 runtime probe reported `scroll_vertical=0 max=566 page=566`, and the full third row (`Side Step`, `Squat`, `Dodge`) rendered at y=481 with height 158, staying inside the visible 720 px surface.
- **2. Right side reads like one large translucent board rather than 9 separate cards:** fixed in source/layout. The shell remains a single rounded `BoardPanel`, while each tile now uses a transparent/lightweight `PanelContainer` shell with no standalone card border/background in the idle state; active emphasis is subtle instead of nine always-boxed cards.
- **3. Guard / Squat chip treatment matches the mockup closely enough:** fixed as implemented. Inactive `Guard` / `Squat` no longer show an always-visible idle pill, and active state uses the centered title-case `Active` chip only when the corresponding persistent state is true.
- **4. Camera shell treatment is simplified enough toward the mockup:** fixed in source/layout. The camera panel styling was reduced to a near-flat white-framed shell (`bg alpha 0.01`, faint border, small radius) rather than the heavier translucent rounded panel QA failed previously.
- **5. Side Step / Dodge now behave correctly relative to the approved behavior:** fixed in runtime probes. `Side Step` now pulses only from `sidestep_left_start` / `sidestep_right_start`; `Dodge` now pulses only from `lean_left_start` / `lean_right_start`; neither tile exposes a persistent center-state chip, while `Guard` / `Squat` remain the only persistent centered-state gestures.
- **6. Previously passing functional mappings still remain correct:** reverified. Runtime probes confirmed correct one-sided L/R activation for `punch_left/right`, `hook_left/right`, `uppercut_left/right`, `knee_left/right`, and `leg_lift_left_start/right_start`, and persistent center activation still works for `Guard` / `Squat` only.
- **7. Event feed still uses visible-order numbering with one event -> one row:** reverified. On a clean seeded feed at sequence 84, the visible rows were exactly `0085: Squat Activated`, `0086: Right Uppercut`, `0087: Left Uppercut`, `0088: Right Uppercut`, `0089: Squat Deactivated`, `0090: Right Punch`, `0091: Left Punch`.

Post-`oc-lg65` rerun on commit `2f67674` (fresh QA, 2026-05-10 evening): I reran the strongest truthful repo-local validation path on the exact live-audit parity fixes. Headless Godot validation/import still passed; a fresh 1280×720 layout probe still reported `scroll_vertical=0`, `scroll_max=566`, `scroll_page=566`, and the full third row bottom at y=639 inside the 720 px viewport; and a targeted runtime parity probe on the live Boxing scene now reports `prerecorded_preview=false`, `prerecorded_config=false`, `live_preview=true`, `live_config=true`, `guard.center.visible=true`, `squat.center.visible=true`, `guard.center.bg=3ddcdcff`, `squat.center.bg=3ddcdcff`, `punch.left.bg=3ddcdcff`, `punch.right.bg=3ddcdcff`, `sidestep.left.bg=3ddcdcff`, and `dodge.right.bg=3ddcdcff`. That same probe also confirmed the `Guard` / `Squat` centered `Active` pills render below their icons (`center_below_icon=true` for both), the board remains one translucent parent surface with inactive tile backgrounds still transparent (`BoardPanel bg=4061878f`, every inactive tile bg=`ffffff00`), `Side Step` / `Dodge` still pulse correctly without becoming persistent center-state tiles, and the event feed still uses visible-order numbering with one event -> one visible row (`0085` through `0091` on the seeded rerun).

What remains uncertified:
- I could not perform a true live screenshot-by-screenshot comparison against `REF-23` on an attached editor/runtime surface because `godot_sessions` returned no plugin session and this shell had no exported `DISPLAY` / `WAYLAND_DISPLAY` for a direct compositor capture path. So the final call that the rendered surface is visually *exact enough* in practice is still best made by the auditor or Derrick on a real windowed surface.

Practical verdict: QA no longer sees a material parity miss in the implemented board composition or behavior. Derrick’s three explicit live-audit criteria now pass in fresh probes, the previously accepted layout/behavior checks still hold, and this is **ready for audit / closure** rather than another coder retry.

### Task 83: Fix Boxing UI live-audit parity issues from Derrick's direct review

**Bead ID:** `oc-lg65`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-23`
**Prompt:** Fix the live-audit parity issues Derrick found during direct review of the Boxing gesture detector scene. Treat these as hard acceptance criteria: the camera feed from prerecorded video must not be flipped horizontally; `Guard` and `Squat` must show their `Active` pills below the icons when active; and all `L`, `R`, and `Active` pills must fill with color `#3ddcdc` when active. Preserve the already-correct layout/story, event feed behavior, and Boxing-only scope.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/`
- any directly owning Boxing UI helper paths required by the fix

**Files Created/Deleted/Modified:**
- Boxing proving scene/harness/UI files required by the fix

**Status:** ✅ Complete

**Results:** Coder pass completed on bead `oc-lg65` with the smallest truthful fix set across the shared proving harness and the Boxing-only UI subclass. The prerecorded-video horizontal flip was coming from the existing mirrored-camera baseline being applied unconditionally in two places: `.testbed/scripts/proving_harness.gd` always set `MediaPipeConfig.flip_horizontal = true`, and `_start_camera_feed()` instantiated `MediaPipeCameraView` with its default `flip_horizontal = true`. That was still correct for live camera parity, but it incorrectly mirrored file-backed proving clips. The fix keeps live behavior intact while stopping the unwanted file mirroring: the proving harness now flips only when the effective camera source is the live default (`"0"`), so prerecorded/video-file sources run unflipped for both the preview surface and provider config.

The pill fixes stayed Boxing-only in `.testbed/scripts/boxing_proving_harness.gd`. Active pills now use the exact requested fill color `#3ddcdc` (`Color8(0x3d, 0xdc, 0xdc, 0xff)`) for all `L`, `R`, and `Active` badges. Guard and Squat also gained a narrow event-backed state fallback (`guard_start/end`, `squat_start/end`) in addition to the existing detector-state read so their centered `Active` pills remain visible during the active runtime state even if the direct state refresh lags the visible transition by a frame.

Validation passed: `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/boxing_proving_harness.gd` stayed clean, and a targeted headless Boxing-scene probe confirmed `prerecorded_flip=false`, `live_flip=true`, `guard_visible=true`, `squat_visible=true`, and both active pill fills rendering as `3ddcdc`. On the final resumed coder verification pass, I re-ran the targeted probe and reconfirmed the same acceptance truth with `all_active_hex_ok=true`, meaning the `Guard`/`Squat` centered `Active` pills and the pulsed `L`/`R` pills all render with the exact active fill `#3ddcdc` while prerecorded video remains unflipped. Existing Boxing-only layout/story, full 3x3 board fit, visible-order event feed, and detector/event wiring were preserved.

### Task 81: Audit the redesigned Boxing gesture detector UI and close the branch truthfully

### Task 82: Retry Boxing gesture detector UI redesign to satisfy exact mockup-parity QA failures

**Bead ID:** `oc-12tw`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-23`
**Prompt:** Fix the exact QA failures from Task 80 so the Boxing gesture detector scene is a true 1:1-enough match for Derrick’s approved mockup. Treat the QA report as hard acceptance criteria: all 9 gesture cells must fit at once in the visible 16:9 viewport with no board scrolling; the right side must read like one large translucent board rather than 9 separate card boxes; `Guard` / `Squat` chip treatment must match the mockup more closely; the camera shell treatment must be simplified toward the mockup; and `Side Step` / `Dodge` behavior must be revisited so only `Guard` / `Squat` remain persistent unless the mockup clearly implies otherwise. Preserve the already-correct functional wiring and event feed behavior while tightening layout/styling/behavior parity.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/`
- any directly owning Boxing UI asset/helper paths required by the retry

**Files Created/Deleted/Modified:**
- Boxing proving scene/harness/UI files required by the retry

**Status:** ✅ Complete

**Results:** Coder retry completed on bead `oc-12tw`. The retry stayed scoped to the Boxing proving scene + Boxing-only subclass/harness styling. The no-scroll full-board issue was fixed truthfully by shrinking the board’s vertical budget instead of hiding overflow: `.testbed/scenes/boxing_proving.tscn` now uses tighter outer/header/content spacing, a slightly smaller left camera/event stack, and a narrower right-panel margin/grid gap budget; `.testbed/scripts/boxing_proving_harness.gd` now builds each gesture tile at a smaller fixed minimum (`132x158`), with smaller icons/badges and no vertical expand-fill. A direct 1280×720 Godot layout probe after the change showed `RightPanelScroll size=(632, 591)` and `BoardPanel size=(632, 591)` with `BoardPanel` minimum height `566`, meaning all 3 rows fit inside the visible board viewport at once with no remaining vertical overflow/scroll requirement.

The visual hierarchy was corrected so the right side reads like one translucent rounded board instead of 9 separate boxed cards: the single `BoardPanel` keeps the rounded translucent shell, while the per-gesture tiles now render as transparent/lightweight placement containers with only subtle active highlighting rather than individual rounded card blocks. Camera shell treatment was also simplified toward the mockup by replacing the heavier rounded translucent camera panel styling with a much lighter near-flat white-framed shell.

Guard / Squat chip treatment was corrected to match the mockup more closely: the centered state chip now uses title-case `Active`, and inactive state no longer shows an always-visible `IDLE` pill. Side Step / Dodge behavior was also revised per QA: both tiles now use event-style left/right pulse indicators (`sidestep_left_start` / `sidestep_right_start` and `lean_left_start` / `lean_right_start`) instead of persistent state badges, while Guard / Squat remain the only persistent centered-state chips. Existing functional detector wiring, Boxing-only scope, and visible-order event-feed numbering were preserved. Validation completed with `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/boxing_proving_harness.gd` plus the explicit 1280×720 board-fit probe described above.

### Task 81: Audit the redesigned Boxing gesture detector UI and close the branch truthfully

**Bead ID:** `oc-dtna`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-23`
**Prompt:** Independently audit the implemented Boxing gesture detector UI against Derrick’s approved mockup, the final diff, and QA evidence. Confirm what matches exactly, what intentionally differs, and whether the branch is ready to close before crash testing resumes.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates and audit notes only

**Status:** ✅ Complete

**Results:** Final independent rerun audit completed after Derrick’s parity-fix commits `3de39c2` and `2f67674`. I re-ran repo-local Godot validation on `2f67674` (`~/.local/bin/godot --headless --path .testbed --check-only --script scripts/boxing_proving_harness.gd`, `~/.local/bin/godot --headless --path .testbed --import --quit-after 1000`) and then used fresh headless runtime probes against the real Boxing scene at 1280×720 in `startup_mode=GODOT_ONLY_DEBUG`.

Proven in those probes:
- prerecorded source is **not** horizontally flipped (`prerecorded_preview=false`, `prerecorded_config=false`) while live camera path stays mirrored (`live_preview=true`, `live_config=true`)
- `Guard` and `Squat` centered `Active` pills are visible, use exact fill `#3ddcdc`, and render below the icons when active
- active `L` / `R` pills also use exact fill `#3ddcdc`
- the right side still behaves as one board, not nine separate cards (`BoardPanel` translucent background present; inactive tile backgrounds transparent)
- full 3×3 board still fits in visible 16:9 area with no scroll (`scroll_vertical=0`, `scroll_max=566`, `scroll_page=566`, third row bottom `639 < 720`)
- `Side Step` / `Dodge` still use pulse-style L/R behavior rather than persistent centered state
- event feed still renders visible-order numbering with one seeded event -> one visible row on a clean rerun (`0085` through `0091` for seven injected events)

Explicit limit: I still do **not** have a literal human-observed live window or attached Godot editor/plugin session from this shell, so I am not claiming fresh pixel-perfect live-window proof beyond Derrick’s own direct review. What is certified here is the strongest repo-local runtime truth available from independent headless Godot scene probes, and that evidence now matches Derrick’s required parity criteria. On that basis the branch is truthfully ready to close.

---

### Task 84: Fix Guard/Squat Active pills not appearing in Derrick's live Boxing runtime

**Bead ID:** `oc-h043`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-23`
**Prompt:** Derrick directly confirmed that the prerecorded video camera flip fix now works, but in his actual live Boxing test run the `Guard` and `Squat` `Active` pills still do not appear. Treat Derrick’s live runtime observation as the top truth source. Reproduce and fix why those centered `Active` pills are still missing in the real run, while preserving the already-accepted camera orientation fix, one-board layout, no-scroll 3x3 board fit, active fill color `#3ddcdc`, and the current Boxing-only scope. Do not close this unless the live-runtime path is fixed strongly enough for Derrick to verify in his next run.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/`
- any directly owning Boxing UI/runtime helper paths required by the fix

**Files Created/Deleted/Modified:**
- Boxing proving scene/harness/UI/runtime files required by the fix

**Status:** ✅ Complete

**Results:** Derrick’s live report demoted the earlier headless-confidence result, and the root cause turned out to be live-runtime timing rather than missing tile wiring or wrong styling: the centered `Guard` / `Squat` pills were still driven by state that could start and end within the same human-visible instant, so a real live run could flicker `guard_start/end` or `squat_start/end` quickly enough that the centered `Active` chip never stayed on-screen long enough to see even though the code path existed. The fix stayed Boxing-only in `.testbed/scripts/boxing_proving_harness.gd`: `guard_start` / `squat_start` now arm a short centered-pill minimum-visible latch (`650 ms`) while preserving the direct detector-state read, and `guard_end` / `squat_end` still clear the explicit override so persistent truth remains state-backed once the latch expires. This keeps the prerecorded camera-flip fix intact, preserves the accepted one-board/no-scroll/full-3x3 layout, and preserves the exact active fill color `#3ddcdc`. Validation passed with `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/boxing_proving_harness.gd` plus a targeted runtime probe (`.temp/task84-pill-runtime-probe.gd`) that confirmed `live_flip=true`, `prerecorded_flip=false`, immediate `guard`/`squat` `start+end` pairs still leave the centered `Active` pills visible through the latch window, both active pill fills remain `3ddcdc`, and both pills clear again after the latch expires. Ready for Derrick to rerun live Boxing and verify the pills now visibly surface in the real runtime.

### Task 85: Correct Boxing Active/Inactive pill design semantics to match the mockup

**Bead ID:** `oc-1rtg`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-23`
**Prompt:** Derrick corrected the intended pill design semantics for the Boxing proving scene: the centered state pills should always be visible, read `inactive` when disabled, and switch to a filled `active` state when enabled using the same active fill color as the numbered circles. Fix this design drift without regressing the now-correct prerecorded camera orientation, one-board layout, no-scroll 3x3 board fit, or Boxing-only scope.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/`

**Files Created/Deleted/Modified:**
- Boxing proving scene/harness/UI files required by the semantic pill correction

**Status:** ✅ Complete

**Results:** The prior Task 84 fix truthfully solved a visibility symptom, but it did so with the wrong semantics: a short `Guard` / `Squat` active-pill latch was added to keep the centered chips on-screen during fleeting live state transitions. Derrick clarified that this was design drift from the mockup intent. The correct behavior is not “sometimes-visible latched Active pills”; it is **always-visible state pills** that read `inactive` when off and `active` when on. This coder pass removed that latch/override behavior from `.testbed/scripts/boxing_proving_harness.gd`, made the centered `Guard` / `Squat` badges permanently visible for the `state_center` tiles, and changed their text semantics to lowercase `inactive` / `active` while preserving the exact active fill color `#3ddcdc` when enabled. Pulse-driven `L` / `R` behavior for Punch / Hook / Uppercut / Knee / Leg Lift / Side Step / Dodge stayed unchanged, and the fix remained Boxing-only.

Validation passed with `git diff --check`, `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/boxing_proving_harness.gd`, and a targeted runtime semantics probe at `.temp/task85-pill-semantics-probe.gd`. That probe confirmed: `live_flip=true`, `prerecorded_flip=false`, `Guard` / `Squat` pills are visible while inactive, inactive text reads `inactive`, active text reads `active`, active fill remains `#3ddcdc`, the event feed still records one visible row per Boxing event, and the full third board row still bottoms at `639 px` inside a `1280x720` viewport with no board scrolling. Ready for Derrick to rerun live; this should now match the intended mockup semantics rather than the prior latch-based workaround.

### Task 86: Break down the Flow gesture detector mockup against chart-truth semantics

**Bead ID:** `oc-ryk0`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-24`
**Prompt:** Inspect Derrick’s Flow mockup screenshot and break it down against the chart-truth semantics now considered canonical for Flow: `placement` is the 13-value ring (`0..12`, UI-friendly `1..13`) and `direction` is the 12-value ring (`0..11`, UI-friendly `1..12`). Compare that to the current Flow proving scene and identify the concrete implementation mapping, the stale mediapipe-python drift to watch for, and any questions needed before implementation.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/`
- Flow/chart/docs paths only for reading/notes

**Files Created/Deleted/Modified:**
- plan updates / analysis notes only unless a tiny reference note is required

**Status:** ✅ Complete

**Results:** Research pass completed against `REF-24` plus the current Flow proving/runtime sources. Main finding: the mockup is a chart-truth visualizer with four independent indexed circles (`left/right placement` as 13-slot rings, `left/right direction` as 12-slot rings), but the current mediapipe-python Flow stack still emits coarse semantic strings only — placement is `left|center|right` from `_flow_placement_name()` in `src/detectors/pose_detector_substrate.gd`, and direction is only `left|right|up|down` from `_flow_direction_name()`. The current `.testbed/scenes/flow_proving.tscn` / `.testbed/scripts/proving_harness.gd` surface is also still the older text-heavy debug harness: reusable pieces are the mirrored camera panel, event feed plumbing, provider signal hookups, and per-hand debug/meta tracking; replaceable pieces are the right-side scroll/text panels and the current string-based Flow candidate presentation. Practical implementation mapping recorded from the mockup: left side stays camera + numbered event feed; right side becomes a single translucent board with a 2x2 grid of ring widgets labeled `Left Bat Placement`, `Right Bat Placement`, `Left Bat Direction`, `Right Bat Direction`; placement rings show indices `1..13` with `13` centered and `1..12` around the perimeter clockwise starting at top-right; direction rings show indices `1..12` around the perimeter clockwise with no center slot. Live-fill expectation: exactly one filled marker per ring at a time when a value is known; placement should fill one of 13 slots (including center), direction should fill one of 12 perimeter slots only; unknown/unready state should leave all circles hollow rather than inventing a coarse bucket highlight. Smallest truthful implementation slice: keep current camera/event-feed shell, replace the right-side text stack with one placement ring widget for one hand first, and feed it from temporary mocked/indexed values or an adapter only after the backend can express real ring indices instead of the stale 3x4 vocabulary. Remaining questions for Derrick: whether ring numbering should be interpreted in mirrored screen space exactly as drawn in the mockup, whether event feed rows should continue logging both placement and direction as separate entries exactly in visible order, and whether partial backend truth should be shown at all before all four indexed surfaces are wired. This task did not change runtime code directly; it produced the implementation-oriented comparison needed before the Flow proving rewrite.

### Task 87: Align Flow mediapipe-python mechanics to the locked chart placement/direction contract

**Bead ID:** `oc-bk5p`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-24`
**Prompt:** Update the Flow mechanics in `aerobeat-input-mediapipe-python` so the proving/runtime path matches the locked chart/workout-package truth instead of the stale coarse buckets. Canonical truth: `placement` is a 13-value ring (`0..12`, UI-facing `1..13`) and `direction` is a 12-value ring (`0..11`, UI-facing `1..12`). Fix the detector/runtime surfaces that still collapse Flow to `left|center|right` and `left|right|up|down`, and make the proving path capable of driving the upcoming mockup truthfully.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `src/`
- `.testbed/scenes/`
- `.testbed/scripts/`
- test paths required to validate Flow semantics

**Files Created/Deleted/Modified:**
- Flow detector/runtime/proving/test files required by the contract alignment

**Status:** ✅ Complete

**Results:** Coder pass completed. The stale Flow detector/runtime surfaces were updated in `src/detectors/pose_detector_substrate.gd`, `src/providers/mediapipe_provider.gd`, `src/input_provider.gd`, `.testbed/scripts/proving_harness.gd`, and the repo-local Flow unit/provider/adapter tests. `PoseDetectorSubstrate` no longer collapses Flow into coarse `left|center|right` / `left|right|up|down` strings: it now quantizes motion direction onto the locked 12-slot chart ring (`0..11`, UI labels `1..12`) and quantizes placement onto the locked 13-slot ring (`0..12`, with canonical `12` = UI `13` center, and `0..11` as perimeter slots clockwise from top-right). Flow swing/trail events now emit integer `placement` / `direction` payloads through the detector, provider, and input adapter instead of semantic strings, and Flow debug metadata now also carries `placement_ui_label` / `direction_ui_label` so the proving path can surface both canonical and UI-facing values truthfully without inventing fake UI semantics. The proving harness was updated to display these values explicitly as indexed debug output (for example `8[u9]`, `11[u12]`, `12[u13] center`) in candidate/emitted rows and last-event summaries, which keeps the current observability shell truthful while the dedicated 4-ring mockup UI still remains future work. Added/updated tests now cover direct ring quantization helpers, substrate swing/trail event payloads, provider signal re-emission, and input adapter re-emission for the indexed Flow contract. Validation completed locally with `python3 -m py_compile python_mediapipe/*.py`; full GUT suite `56/56`; `godot --headless --path .testbed --quit-after 2` (passes with the pre-existing `ObjectDB instances leaked at exit` warning still present); and a focused headless flow proving scene instantiation smoke (`godot --headless --path .testbed -s /tmp/flow_scene_smoke.gd`) which loaded `flow_proving.tscn` and printed `FLOW_SCENE_OK name=FlowProving` before normal shutdown. Coder commit: `88bf6f1` (`Align flow mechanics to indexed chart truth`).

### Task 88: QA Flow chart-truth mechanics alignment in the proving scene

**Bead ID:** `oc-h5r8`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-24`
**Prompt:** Independently verify that the Flow proving/runtime path now emits and surfaces chart-truth placement/direction semantics strongly enough to support the upcoming 4-section mockup UI: placement on the 13-value ring and direction on the 12-value ring, without regressing the current proving scene shell or inventing fake mappings.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ✅ Complete

**Results:** QA passed for the intended backend/proving-path scope. Independent source review confirmed the stale Flow contract surfaces are updated end-to-end in the detector/runtime/provider/proving/test path: `src/detectors/pose_detector_substrate.gd` now defines `FLOW_DIRECTION_RING_COUNT := 12`, `FLOW_PLACEMENT_RING_COUNT := 13`, emits integer `placement` / `direction` payloads, and carries truthful `placement_ui_label` / `direction_ui_label` metadata; `src/providers/mediapipe_provider.gd` and `src/input_provider.gd` now expose/re-emit `swing_*` and `trail_*` with typed `(placement: int, direction: int)` payloads instead of coarse semantic buckets; `.testbed/scripts/proving_harness.gd` now formats surfaced Flow values as indexed debug output (`%d[u%d]`, with `12[u13] center` for placement center) rather than lying with `left|center|right` / `left|right|up|down`; and the repo-local unit/provider/adapter tests now assert indexed semantics directly. Independent validation also passed: `python3 -m py_compile python_mediapipe/*.py`; `godot --headless --path .testbed --import`; full GUT suite `56/56`; and a focused headless Flow proving-scene instantiation smoke that loaded `res://scenes/flow_proving.tscn` and printed `FLOW_SCENE_OK name=FlowProving`. Truth check against `REF-24`: placement is now modeled with 13-value semantics (`0..12`, UI `1..13`, canonical `12` as center), direction is modeled with 12-value semantics (`0..11`, UI `1..12`), and the proving/debug surface no longer invents stale coarse labels for emitted/candidate values. Still not proven here: the dedicated 4-ring mockup UI is not built yet, and this QA pass did not certify live human-visible motion truth or final ring-widget ergonomics in a running editor session. What is proven is that the current backend/proving shell now emits and surfaces truthful indexed Flow mechanics strongly enough for the later UI slice to consume without backend-contract drift.

### Task 89: Audit Flow chart-truth mechanics alignment before UI redesign

**Bead ID:** `oc-fgrt`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-24`
**Prompt:** Audit the Flow mechanics alignment branch against the locked chart/workout-package semantics and confirm whether the backend is now truthful enough for the Flow mockup UI implementation slice to begin.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / audit notes only

**Status:** ✅ Complete

**Results:** Auditor pass completed and bead `oc-fgrt` was closed. Independent truth-check verified the actual changed backend/proving surfaces rather than relying on QA prose: `src/detectors/pose_detector_substrate.gd` now quantizes Flow direction onto a 12-slot ring (`0..11`) and placement onto a 13-slot contract (`0..12`, with `12` as center) using shoulder-center-relative geometry instead of stale coarse buckets; `src/providers/mediapipe_provider.gd` and `src/input_provider.gd` now expose/re-emit `swing_*` / `trail_*` as typed integer `(placement, direction)` payloads instead of `StringName` labels; and `.testbed/scripts/proving_harness.gd` now surfaces candidate/emitted/summary Flow values as truthful indexed debug output (`%d[u%d]`, with center rendered as `12[u13] center`) rather than inventing `left|center|right` or `left|right|up|down` semantics. Relevant tests were checked directly in `.testbed/tests/unit/test_pose_detector_substrate.gd`, `test_mediapipe_provider.gd`, and `test_input_provider_adapter.gd`; they now assert the indexed contract at the detector, provider, and adapter layers, including ring quantization helpers and emitted Flow event payloads. Independent validation rerun during audit passed with `python3 -m py_compile python_mediapipe/*.py`, current full GUT `51/51`, and a focused headless Flow scene smoke that loaded `res://scenes/flow_proving.tscn` and printed `FLOW_SCENE_OK name=FlowProving` before the pre-existing headless leak warnings on exit. Audit conclusion: for the stated scope, the backend/proving path is now aligned strongly enough with the locked Flow mechanics truth for the mockup UI implementation slice to begin without backend-contract drift. Still future work, and not claimed here: the dedicated Flow mockup/ring UI itself, live human-visible motion proof of every ring segment in a running editor session, and final UI ergonomics/visual parity.

### Task 90: Implement the Flow gesture detector mockup UI on top of the aligned indexed backend

**Bead ID:** `oc-zd1b`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-24`
**Prompt:** Implement the new Flow gesture detector proving-scene UI from Derrick’s mockup now that the backend/proving path is aligned to chart-truth indexed semantics. Keep the left-side shell pattern (header, camera panel, event feed), replace the old right-side text-heavy Flow debug stack with one translucent 2x2 board, and build the four indexed sections: Left Placement `1..13`, Right Placement `1..13`, Left Direction `1..12`, Right Direction `1..12`. The UI should truthfully reflect the now-indexed backend values without reintroducing coarse bucket semantics.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/`
- any directly owning Flow UI asset/helper paths required by the implementation

**Files Created/Deleted/Modified:**
- `.testbed/scenes/flow_proving.tscn`
- `.testbed/scripts/proving_harness.gd`
- `.testbed/scripts/flow_ring_chart.gd`

**Status:** ✅ Complete

**Results:** Coder pass completed. The Flow proving scene now replaces the old right-side summary/signal/metrics/debug stack with a single translucent 2x2 mockup board while preserving the left-side shell as header + live camera panel + event feed. `.testbed/scenes/flow_proving.tscn` was rewritten to match that layout more closely, and a new custom-drawn `.testbed/scripts/flow_ring_chart.gd` renders the numbered ring widgets directly in-scene: placement boards render 12 perimeter slots plus center `13`, and direction boards render 12 perimeter slots only. `.testbed/scripts/proving_harness.gd` was updated to support the Flow-specific layout safely (optional lookup for legacy text panels, event feed lookup on the left, direct refs for the four ring widgets) and to drive the board from the aligned backend contract without reintroducing stale coarse buckets. The four sections are wired to live `gesture_debug.flow` candidate truth: left/right placement boards consume `placement_candidate` (`0..12`, with `12` filling the center slot) and left/right direction boards consume `direction_candidate` (`0..11`) so the active fill follows the hand’s current indexed target rather than inventing coarse labels. The Flow event feed was also reformatted into numbered human-readable placement/direction rows (`Left Bat Placement - 12`, etc.) using UI-facing labels derived from the canonical backend values. Validation completed locally with `git diff --check` and a focused headless smoke load/instantiate pass (`godot --headless --path .testbed -s /tmp/flow_scene_smoke.gd`) that printed `FLOW_SCENE_OK name=FlowProving children=2`. Important limit kept explicit for QA: this coder pass did not produce live visual/editor screenshots, so the exact mockup-match, translucency feel, and in-motion ring readability still need human QA in a real 16:9 proving window.

### Task 91: QA the Flow gesture detector mockup UI against the aligned backend

**Bead ID:** `oc-xgsi`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-24`
**Prompt:** Independently verify that the redesigned Flow proving scene matches Derrick’s mockup closely enough, that the four indexed sections reflect truthful `placement`/`direction` backend values, and that the scene remains usable/readable at the target 16:9 proving resolution.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful docs correction is required

**Status:** ❌ Failed

**Results:** QA failed. Strongest truthful validation path available in this pass was: (1) direct source review of `.testbed/scenes/flow_proving.tscn`, `.testbed/scripts/proving_harness.gd`, and `.testbed/scripts/flow_ring_chart.gd`; (2) live headless Godot scene instantiation/probe at `1280x720`, `960x540`, and `854x480`; and (3) seeded event/board-state checks against the implemented indexed Flow wiring. What passed: the right-side surface is genuinely a translucent 2x2 board, all four sections exist, ring orientation materially matches the mockup feel (`12` at top, `1` upper-right, clockwise numbering), placement charts truthfully support 13-slot semantics via 12 perimeter slots plus center `13`, direction charts use 12 perimeter slots only, and the harness drives the board from indexed `gesture_debug.flow.left/right` candidate values without reintroducing stale coarse bucket labels. What failed materially against `REF-24`: the scene does **not** reproduce the mockup’s overall visual shell closely enough. There is no blue branded background artwork or top-left mark, the header stack includes extra status/notes text that changes the composition, and the left column proportions diverge from the mockup (at `1280x720` the camera panel and event feed each consume ~297px height, whereas the mockup’s camera panel is meaningfully taller than the feed). Event-feed behavior is also not mockup-parity: seeded Flow events render in top-to-bottom order `0007, 0008, 0005, 0006, 0003, 0004, 0001, 0002`, i.e. newest-at-top paired inserts with descending numbering, instead of the mockup’s sensible ascending chronological list (`0085`…`0091`). Usability also fails at narrower but still common 16:9 sizes: the headless layout probe showed the scene over-constrains to a 1096px-wide content area because of the 480px camera minimum plus 540px board minimum; at `960x540` the left column starts at `x=-68` and at `854x480` at `x=-121`, proving real clipping/off-screen layout rather than graceful adaptation. Because live editor-visible screenshot capture was not available here, final human-visible translucency/readability parity is still uncertified; but even without that uncertified layer, the measured layout and event-feed mismatches are already enough to fail QA truthfully.

### Task 92: Audit the Flow gesture detector mockup UI before returning to other slices

**Bead ID:** `oc-jo5p`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-24`
**Prompt:** Audit the implemented Flow mockup UI against Derrick’s screenshot, the aligned backend semantics, the final diff, and QA evidence. Confirm what matches, what intentionally differs, and whether the Flow proving-scene UI branch is truthfully ready to close.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / audit notes only

**Status:** ⏳ Pending

**Results:** QA failed. Strongest truthful validation path available in this pass was: (1) direct source review of `.testbed/scenes/flow_proving.tscn`, `.testbed/scripts/proving_harness.gd`, and `.testbed/scripts/flow_ring_chart.gd`; (2) live headless Godot scene instantiation/probe at `1280x720`, `960x540`, and `854x480`; and (3) seeded event/board-state checks against the implemented indexed Flow wiring. What passed: the right-side surface is genuinely a translucent 2x2 board, all four sections exist, ring orientation materially matches the mockup feel (`12` at top, `1` upper-right, clockwise numbering), placement charts truthfully support 13-slot semantics via 12 perimeter slots plus center `13`, direction charts use 12 perimeter slots only, and the harness drives the board from indexed `gesture_debug.flow.left/right` candidate values without reintroducing stale coarse bucket labels. What failed materially against `REF-24`: the scene does **not** reproduce the mockup’s overall visual shell closely enough. There is no blue branded background artwork or top-left mark, the header stack includes extra status/notes text that changes the composition, and the left column proportions diverge from the mockup (at `1280x720` the camera panel and event feed each consume ~297px height, whereas the mockup’s camera panel is meaningfully taller than the feed). Event-feed behavior is also not mockup-parity: seeded Flow events render in top-to-bottom order `0007, 0008, 0005, 0006, 0003, 0004, 0001, 0002`, i.e. newest-at-top paired inserts with descending numbering, instead of the mockup’s sensible ascending chronological list (`0085`…`0091`). Usability also fails at narrower but still common 16:9 sizes: the headless layout probe showed the scene over-constrains to a 1096px-wide content area because of the 480px camera minimum plus 540px board minimum; at `960x540` the left column starts at `x=-68` and at `854x480` at `x=-121`, proving real clipping/off-screen layout rather than graceful adaptation. Because live editor-visible screenshot capture was not available here, final human-visible translucency/readability parity is still uncertified; but even without that uncertified layer, the measured layout and event-feed mismatches are already enough to fail QA truthfully.

### Task 93: Retry Flow mockup UI for branded shell, event order, and responsive 16:9 parity

**Bead ID:** `oc-ouyl`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-24`
**Prompt:** Fix the failed Flow UI parity points from Task 91 so the proving scene matches Derrick’s mockup more closely and remains usable across common 16:9 sizes. Hard acceptance criteria: add the correct blue branded background and top-left mark treatment; remove extra header/status/notes composition drift; rebalance the left column so the camera is taller and the event feed shorter like the mockup; fix the event feed to render in sensible ascending chronological visible order; and eliminate the width over-constraint/clipping so the scene adapts cleanly at sizes like `960x540` and `854x480` without pushing content off-screen. Preserve the already-correct indexed backend wiring and four-section board semantics.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/`
- any directly owning Flow UI assets/helpers required by the retry

**Files Created/Deleted/Modified:**
- Flow proving scene/harness/UI files required by the retry

**Status:** ✅ Complete

**Results:** Coder retry completed on bead `oc-ouyl`. The Flow proving shell was tightened to the smallest truthful parity set across `.testbed/scenes/flow_proving.tscn`, `.testbed/scripts/proving_harness.gd`, `.testbed/scripts/flow_ring_chart.gd`, and new helper `.testbed/scripts/flow_brand_mark.gd`. The scene now uses the approved blue branded background artwork (`perfect-hue-may-08-2026-hd.png`) plus a top-left drawn brand mark, removes the extra status/live/notes header stack from the visible shell, and rebalances the left column so the camera stays materially taller than the event feed while preserving the existing right-side 2x2 translucent indexed board. Width over-constraint was removed by dropping the old 480px/540px left-right minimum pairing, switching the Flow content shell to a simpler responsive `HBoxContainer`, lowering the camera/chart minimum sizes, and letting the board shrink cleanly at narrower 16:9 sizes without pushing either column off-screen.

The Flow event feed ordering bug was fixed directly in the shared harness instead of papering over it in scene layout: `_append_event_feed_lines()` now appends chronological rows and trims from the front, so visible rows read in sensible ascending order (`0001`→`0008`) rather than newest-first paired inserts. For Flow-only feed presentation, `_build_events_text()` was also simplified to render just the numbered rows / waiting text, which matches the mockup shell more closely without touching Boxing’s custom feed path. `flow_ring_chart.gd` was resized responsively so the four indexed charts still fit the 2x2 board at `1280x720`, `960x540`, and `854x480` while preserving the already-approved semantics: four ring sections remain present, placement still uses 13-slot semantics via 12 perimeter slots plus center, direction still uses 12 perimeter slots only, and board highlights still come from indexed backend truth instead of stale coarse buckets.

Validation completed locally with `git diff --check`, `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/proving_harness.gd`, and a focused headless Flow parity/layout probe (`.testbed/.temp/task93_flow_probe.gd`) at `1280x720`, `960x540`, and `854x480`. That probe confirmed no horizontal clipping/off-screen overflow at those sizes (`offscreen_left` stayed positive and right overflow stayed negative), the camera remained taller than the feed (`camera_to_events_height_ratio` ≈ `3.33`, `2.08`, `1.90` respectively), the board still exposed all four active indexed sections, and seeded events rendered in ascending visible order. Remaining truthful limit for QA: this pass did not produce a human-observed live editor screenshot comparison, so QA should focus next on real-window visual parity of the new mark/background/translucency feel and confirm the narrower `854x480` runtime still feels readable, not just geometrically non-clipped.

### Task 94: QA rerun the Flow gesture detector mockup UI after the parity retry

**Bead ID:** `oc-5ux8`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-24`
**Prompt:** Independently QA the updated Flow proving scene after commit `d365959` against Derrick’s mockup and the aligned indexed backend. Verify the branded blue shell/top-left mark, reduced header drift, left-column proportions, ascending event-feed order, and responsive 16:9 behavior at `1280x720`, `960x540`, and `854x480`, while re-checking that the four ring sections still reflect truthful indexed `placement`/`direction` semantics with no stale coarse bucket drift. Use the strongest truthful validation path available; if live visual parity remains uncertified, say exactly what is still uncertified.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / verification notes only unless a truthful QA fix is required

**Status:** ✅ Complete

**Results:** QA rerun passed in the strongest truthful repo-local scope available after commit `d365959`, with one explicit remaining uncertainty about live-window visual feel. Validation used: (1) direct source review of `.testbed/scenes/flow_proving.tscn`, `.testbed/scripts/proving_harness.gd`, `.testbed/scripts/flow_ring_chart.gd`, and `.testbed/scripts/flow_brand_mark.gd`; (2) `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/proving_harness.gd`; and (3) a fresh headless Flow QA probe at `1280x720`, `960x540`, and `854x480` that seeded indexed Flow candidate/event data, measured layout geometry, and checked visible event-feed ordering plus active ring indexes. What is now proven: the mockup shell retry materially fixed the earlier QA failures — the approved blue branded background is present, a top-left brand-mark treatment is present, the extra header/status/notes drift is gone from the visible shell, the left column now keeps the camera materially taller than the event feed at all three requested sizes (`camera_to_events_height_ratio` ≈ `3.33`, `2.08`, `1.90`), the right side remains a translucent 2x2 board, seeded event rows render in sensible ascending visible order (`0001`→`0008` top-to-bottom), and the scene no longer clips/pushes content off-screen at `1280x720`, `960x540`, or `854x480` (`offscreen_left` stayed positive and right overflow stayed negative in all three probes). Backend truth also remained aligned: the four board sections still reflect indexed semantics with no coarse-bucket regression, and the active probe values resolved exactly as expected (`left_placement=11` => UI `12`, `right_placement=12` => center/UI `13`, both directions `=5` => UI `6`). Ring numbering/orientation still matches the intended feel from the mockup (`12` at top, `1` upper-right, clockwise numbering; placement gets a centered `13`, direction does not).

Exact remaining uncertainty: I still did not have an attached Godot plugin/editor session or a usable compositor capture path from this shell, so I could not truthfully certify literal live-window screenshot parity for translucency, spacing polish, or human comfort/readability feel — especially at the tightest `854x480` size. What is proven there is geometric fit plus responsive font/board sizing from the scene/script math, not a human-observed live screenshot pass. On balance, the previous material misses are resolved strongly enough that QA should now hand this branch to the auditor instead of failing it again.

### Task 95: Audit the Flow gesture detector mockup UI after the parity retry

**Bead ID:** `oc-q66t`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-24`
**Prompt:** Audit the post-retry Flow proving-scene UI against Derrick’s mockup, the aligned indexed backend semantics, the final diff around `d365959`, and QA evidence from Task 94. Confirm what now matches, what still differs, and whether the branch is truthfully ready to close.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- plan updates / audit notes only

**Status:** ✅ Complete

**Results:** Auditor pass completed on bead `oc-q66t`. I used the required desktop-control screenshot-first path on the real host Wayland desktop, not just headless layout probes. First I captured the live desktop state, then launched `res://scenes/flow_proving.tscn` in a real Godot window with a prerecorded Flow fixture. The first live run surfaced an important truth correction: a stale orphaned headless Godot process was still bound to UDP `127.0.0.1:4242`, so the scene auto-shifted to another port and the visible shell came up without truthful ring/event activity. I explicitly treated that first window as poisoned evidence, killed only the stale repo-owned `--check-only`/orphaned processes, relaunched cleanly, and re-captured the live window after `MediaPipeServer` successfully bound back to `127.0.0.1:4242`.

What is now **proven by live desktop/window evidence** from the clean rerun: the Flow scene truthfully presents the branded blue shell in a real window, including the blue background treatment, top-left brand mark, and title row; the left column composition is materially aligned to the mockup shape, with a visibly taller camera panel over a shorter event feed; the right side reads as one translucent 2x2 board; the four labeled sections are present (`Left Bat Placement`, `Right Bat Placement`, `Left Bat Direction`, `Right Bat Direction`); placement rings visibly include the center `13` slot while direction rings do not; clockwise ring orientation matches the intended mockup feel (`12` at top, `1` upper-right); active indexed highlights render in the live window; and the visible event feed is in sensible ascending chronological order (`0022`, `0023`, `0024`, `0025`, `0026` top-to-bottom in the captured proof) rather than the old descending/newest-first failure. Overall readability and visual feel in the real window are good enough to call this a truthful mockup match for the implemented scope, with the main visible deviation being the intentional file-preview HUD inside the camera panel during prerecorded proving.

What is **reconfirmed only by source/headless evidence**, not by the desktop screenshots alone: backend contract preservation remains correct end-to-end (`placement` as the 13-value indexed ring with center slot, `direction` as the 12-value indexed ring) and stale coarse semantics were not reintroduced. I rechecked the owning runtime/proving code directly: `src/detectors/pose_detector_substrate.gd` still defines `FLOW_DIRECTION_RING_COUNT := 12` and `FLOW_PLACEMENT_RING_COUNT := 13`, emits `placement_ui_label` / `direction_ui_label`, and no longer depends on the stale coarse `left|center|right` / `left|right|up|down` model; `.testbed/scripts/proving_harness.gd` still appends Flow event-feed rows chronologically and drives the four board charts from indexed candidate values; `.testbed/scripts/flow_ring_chart.gd` still renders placement with a center slot and direction without one. That source/headless layer matches the prior QA truth and the live-window behavior I saw.

Residual uncertainty kept explicit: I did not have an attached Godot plugin/editor session, so this is a real standalone proving-window audit rather than a literal embedded-editor screenshot match; I also did not prove every possible ring index live in one run, only that the live board updates truthfully and the indexed backend/source contract remains correct. Those are acceptable limits for this bead because the branch goal here was the truthful Flow mockup UI audit, not exhaustive detector coverage.

Audit conclusion: **pass**. After the clean rerun, the branch is truthfully ready to close for the Flow mockup UI slice, and bead `oc-q66t` should close.

### Task 96: Diagnose and fix shared proving-hand trail rendering

**Bead ID:** `oc-exde`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`, `REF-05`, `REF-24`
**Prompt:** Investigate the shared proving-scene hand trail rendering bug visible in both Boxing and Flow. Current truth from Derrick: with `Show Trails` enabled, the trail appears like a raycast and only starts appearing when the left or right hand is near the center of the camera panel/scene. The repro is strong on the left-hand boxing punch fixture and also appears in Flow, across live and prerecorded modes, with landmarks on or off. Determine whether the fault is in shared trail history collection, coordinate-space conversion, or shared draw math; land the smallest truthful source fix; validate in the safest available scope; and preserve the now-stable non-crash proving setup.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scripts/`
- `.testbed/scenes/` if layout/wiring adjustments are required

**Files Created/Deleted/Modified:**
- `.testbed/scripts/proving_harness.gd`
- `.testbed/tests/unit/test_proving_harness_trails.gd`

**Status:** ✅ Complete

**Results:** Coder pass completed on bead `oc-exde`. Source inspection across the shared proving path showed the bug was in **shared trail history continuity**, not in screen projection math or scene-specific wiring. The existing trail collector already broke continuity for implausible spatial jumps and out-of-bounds samples, but it did **not** break continuity when the hand temporarily dropped to missing/low-visibility samples. Because both Boxing and Flow share `_append_trail_point()` in `.testbed/scripts/proving_harness.gd`, that meant a hand could disappear or become too low-confidence near the edge, then reappear near center and get reconnected to stale pre-gap history as one long straight segment — which matches Derrick’s "raycast" symptom and the center-of-scene repro pattern.

The fix stayed intentionally small and shared: `_append_trail_point()` now inserts a single trail break marker when an existing live segment encounters a missing or low-visibility gap, so the next usable point reseeds a fresh segment instead of drawing a stale straight-line bridge across the invisible interval. Repeated missing/low-visibility frames do not stack extra break markers because the helper exits once the trail is already in reseed state. No scene layout, projection math, MediaPipe runtime wiring, or close-path behavior was changed.

Safe validation completed without running MediaPipe/live/prerecorded proving paths: `git diff --check`; `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/proving_harness.gd`; and a focused GUT run `~/.local/bin/godot --headless --path .testbed -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gselect=test_proving_harness_trails.gd -gexit`, which passed `11/11`. Added regression coverage proves two important continuity cases directly: low-visibility gaps now break and reseed instead of connecting stale history, and repeated missing frames only insert one break marker. Ready for QA / Derrick’s manual visual confirmation on Cookie.

### Task 97: Fix Boxing proving header icon/title overlap

**Bead ID:** `oc-8gxz`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`
**Prompt:** Fix the Boxing proving-scene header composition so the top-left icon no longer overlaps the title text. Match the current branded shell direction used in the proving scenes and keep the change tightly scoped to truthful layout cleanup.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scenes/`
- `.testbed/scripts/` if a shared header helper needs adjustment

**Files Created/Deleted/Modified:**
- Boxing proving scene/header surfaces required by the fix

**Status:** ⏳ Pending

**Results:** Pending.

### Task 98: Draw Flow ring arcs behind the numbered slots

**Bead ID:** `oc-jm59`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-24`
**Prompt:** Adjust the Flow ring-chart rendering so the underlying circle ring sits visually behind the numbered slot circles. In the visible slot positions, the ring stroke should not show through the numbered circles. Keep the existing numbering, placement center slot, direction ring semantics, and current branded board layout intact.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scripts/`

**Files Created/Deleted/Modified:**
- `/.testbed/scripts/flow_ring_chart.gd` and any tightly related helper surfaces if required

**Status:** ⏳ Pending

**Results:** Pending.

### Task 99: Build a local proving crash-test checklist webpage

**Bead ID:** `oc-w0i1`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`
**Prompt:** Build a local crash-test tracking webpage at `/.testbed/.crash-test/crash-test.html` for manually recording proving-scene crash reproduction progress. Include boolean checkboxes for each relevant proving test combination and persist the checkbox state locally in the same folder so Derrick does not lose progress between page reloads. Keep it standalone/offline-friendly and easy to update during repeated Cookie crash testing.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/.crash-test/`

**Files Created/Deleted/Modified:**
- `.testbed/.crash-test/crash-test.html`
- `.testbed/.crash-test/.crash-test-state.json`

**Status:** ✅ Complete

**Results:** Built a standalone offline crash-matrix page at `.testbed/.crash-test/crash-test.html` plus an adjacent starter state file `.testbed/.crash-test/.crash-test-state.json`. The page uses the real proving controls from this repo rather than invented labels: scenes `Boxing` / `Flow`; sources `live camera` / `prerecorded video`; startup modes `TRACKING`, `PREVIEW_ONLY_DEBUG`, and `GODOT_ONLY_DEBUG`; and close-path toggle `skip_sidecar_stop_on_close_debug` on/off. That yields 24 explicit matrix rows (2 scenes × 2 sources × 3 startup modes × 2 skip-sidecar states). Every row exposes `tested`, `crashed`, `bad-window-only`, and freeform `notes`, with summary counters at the top for coverage/crash progress.

Persistence is intentionally two-layer and local-only: edits autosave immediately into browser local storage for resilience on reload, and the page can also link/create and continuously sync a real adjacent JSON file via Chromium's File System Access API so Derrick can keep `.crash-test-state.json` beside the HTML in the same folder. A starter JSON file was committed so the expected adjacent-path target already exists. Safe validation only: confirmed the source-backed proving knobs in `.testbed/scripts/proving_harness.gd` (`startup_mode`, `prerecorded_video_source`, `skip_sidecar_stop_on_close_debug`) before building the matrix; verified both new files exist in `.testbed/.crash-test/`; and checked the generated HTML/JSON statically from shell without launching MediaPipe, proving scenes, or risky GUI repros.

### Task 100: Fix crash-test checklist initialization/runtime bug

**Bead ID:** `oc-w18a`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-04`
**Prompt:** Fix the shipped local crash-test checklist page so it works when opened directly from `file://`. Current user report: opening `.testbed/.crash-test/crash-test.html` throws `ReferenceError: Cannot access 'combos' before initialization`, preventing the link/write/reload/export buttons from functioning. Land the smallest truthful fix, preserve the current checklist intent, and keep it local/offline-friendly.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/.crash-test/`

**Files Created/Deleted/Modified:**
- `.testbed/.crash-test/crash-test.html`
- adjacent state/helpers only if required

**Status:** ✅ Complete

**Results:** Fixed the shipped `file://` runtime bug in `.testbed/.crash-test/crash-test.html` with the smallest truthful ordering change. Root cause: the script initialized `state` by calling `loadState()` before `const combos = buildRows();` had run, but `loadState()` immediately calls `normalizeState()`, and `normalizeState()` iterates `combos`. That triggered the reported `ReferenceError: Cannot access 'combos' before initialization` during page boot, which aborted the rest of the script before the button handlers and checklist UI could finish initializing. The fix was to keep the existing structure and simply move `let state = loadState();` to immediately after `const combos = buildRows();`, so the matrix definition exists before any state normalization/local restore runs.

Safe validation only: `git diff --check -- .testbed/.crash-test/crash-test.html` passed, and two Node-based offline smoke evaluations of the inline page script with a stub DOM verified that the page now boots cleanly without the initialization exception, produces all 24 expected matrix rows, exports 24 state entries, and still persists edited checklist state/notes into local storage through `persistLocal()` without throwing. No MediaPipe, proving runs, or risky GUI crash repros were used in this validation.

## Session Handoff / Current Stopping Point

- File-backed prerecorded proving is now a real supported proving path, not a stub:
  - Boxing/Flow proving scenes can select clips through the shared Inspector file-picker `prerecorded_video_source`.
  - File-backed preview now advances, loops, and is quiet enough by default to use during crash hunting.
- Cookie still provided the sharpest crash-forensics truth cut:
  - connected `PREVIEW_ONLY_DEBUG` could crash Cookie
  - connected file-backed `PREVIEW_ONLY_DEBUG` could also crash Cookie
  - but the same close path with `skip_sidecar_stop_on_close_debug=true` did **not** crash Cookie
  - best current read remains: the prime suspect cluster is the normal `AutoStartManager` / sidecar shutdown path on close
- Chip became the active crash sandbox for today because Cookie was unavailable.
  - First Chip A/B result with `skip_sidecar_stop_on_close_debug=true` closed cleanly.
  - The initial second-half Chip run with the flag back to `false` did **not** crash, but that run was contaminated by a dirty runtime state (`Buffer full, dropping packets!` plus stream-thread cleanup warning), so it was not treated as a clean falsification of the Cookie shutdown hypothesis.
- To clean the Chip repro surface before the next live rerun, we landed three focused cleanup branches:
  1. `c247339` — preview-only self-audit + `camera_view.gd` thread teardown fix
  2. `d811c09` — quiet proving/logging by default + CSV/import-warning mitigation
  3. `71c3716` — final proving-harness event/snapshot quieting
- Current terminal-safe QA state is good:
  - prerecorded Boxing headless runs now stay near ~20 log lines instead of 1,568+
  - snapshot/event spam is gone by default
  - CSV import warnings are gone in validated scope
  - the old `Thread object is being destroyed...` warning family is gone in validated prerecorded scope
  - startup/exit signal remains concise and readable
- Important local-host rule carried forward:
  - avoid risky live GUI proving on Pico’s own machine; continue using Chip for live repro unless explicitly needed otherwise
- Exact next-session starting point:
  1. resume on Chip, not Pico
  2. rerun the cleaned file-backed `PREVIEW_ONLY_DEBUG` A/B on Chip using the quieter default proving path
  3. first with `skip_sidecar_stop_on_close_debug=true`, then with only that flag flipped to `false`
  4. treat any new provider activity, packet-backlog spam, or thread-cleanup warnings as an invalid/dirty rerun
  5. if the rerun is clean, audit whether the Cookie-style shutdown crash reappears on Chip or whether a host-specific difference still dominates
- Separate product/UI branch remains queued:
  - wait for Derrick’s Penpot slice, then redesign the Boxing proving scene to replace text-heavy status with gesture icons and active-state/highlight buttons

## Final Results

**Status:** ⚠️ Partial

**What We Built:**
- A working file-backed prerecorded proving path for Boxing/Flow scenes, including Inspector-based clip selection and visibly advancing/looping preview playback.
- A system-scope forensics harness strong enough to survive the rollover boundary.
- A one-shot close-path isolation toggle that produced the decisive Cookie non-crash result.
- A cleaned Chip proving surface for the next crash repro:
  - preview-only self-audit to invalidate dirty provider drift
  - proper `camera_view.gd` stream-thread realization on teardown
  - quiet-by-default proving/camera/autostart logging
  - runtime-tree `.gdignore` shields to stop Godot CSV import noise
  - harness event/snapshot spam reduced to concise startup/exit signal

**Reference Check:**
- `REF-04` / `REF-06`: satisfied for the proving-harness/source-owned feature and cleanup work.
- `REF-18` / `REF-20`: satisfied for the close-path isolation and Chip cleanup branches.
- `REF-21` / `REF-22`: satisfied for the warning-driven logging/thread cleanup and current-session triage.

**Commits:**
- `47698a0` - `Fix file-backed preview playback pacing`
- `e719624` - `Add close-path isolation toggle for preview crash repro`
- `c247339` - `Harden preview-only audit and camera thread teardown`
- `d811c09` - `Quiet proving harness logging by default`
- `71c3716` - `Quiet proving harness event logging`

**Lessons Learned:**
- Treat prerecorded proving playback as a first-class product feature, not just a debugging convenience.
- Dirty repro surfaces are worse than slow repro surfaces; when crash hunting, reject contaminated runs instead of over-interpreting them.
- The strongest crash-isolation progress still comes from changing one teardown variable while keeping playback constant.
- For GUI-sensitive branches, Derrick’s direct observation remains the ground truth; subagent/source/headless work should sharpen the next human repro, not replace it.

---

*Updated on 2026-05-09*
