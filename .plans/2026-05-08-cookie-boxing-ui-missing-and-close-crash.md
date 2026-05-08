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

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 25: Use instrumentation findings to fix missing Boxing trails

**Bead ID:** `oc-krx`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-04`, `REF-06`, `REF-17`  
**Prompt:** After the instrumentation pass identifies the real failure, implement the smallest truthful fix so Boxing shows believable short hand trails in the real proving path instead of only endpoint circles, without reintroducing the slash bug.

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

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending

**Lessons Learned:** Pending.

---

*Completed on Pending*
