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

**Status:** ⏳ Pending

**Results:** Pending.

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

**Status:** ⏳ Pending

**Results:** Pending.

---

## Session Handoff / Current Stopping Point

- Derrick confirmed the Boxing proving UI is now visible on both Pico's terminal and Cookie, but the hand-trail branch remains unresolved and should no longer be advanced by theory-only fixes.
- New explicit rule from this session: subagent claims are not enough on GUI-sensitive branches without deterministic artifacts or exact-path visual proof.
- Two new recorded boxing videos now exist as candidate fixtures and should become the first deterministic proving-validation inputs:
  - `.testbed/assets/fixtures/boxing/punch_left/boxing__punch_left__positive__guard_start_end__take_01.mp4`
  - `.testbed/assets/fixtures/boxing/punch_right/boxing__punch_right__positive__guard_start_end__take_01.mp4`
  - matching candidate fixture YAMLs were created and partially filled from Derrick's metadata
- Deterministic validation branch is active:
  - `oc-9wd` research completed: existing videos + durable logs + screenshotable rendered output is the right primitive
  - `oc-b10` implementation is/was in flight at stop time
  - `oc-amo` QA remains pending behind that implementation
- Crash-forensics branch is also active:
  - `oc-a8h` armed the first Cookie host-local harness and `oc-73r` audited the result
  - that first capture was useful only as a pre-crash slice; it did not survive long enough to capture the actual stop-playback desktop reset boundary
  - next required improvement is a systemd-hardened detached capture mode that survives a GNOME/Xorg desktop-session reset better
  - hardened harness branch is active: `oc-30v` research, `oc-8pl` implementation, `oc-dn7` QA
- Important new truth from this session: Pico's own Zorin GUI also crashed twice during risky local GUI-coupled work, and host journal evidence showed an actual session-reset family with `Connection to xwayland lost`, `Xwayland terminated, exiting since it was mandatory`, and `Xwayland exited unexpectedly`.
- Therefore next session should avoid unsafe local live GUI proving on Pico's host and prioritize:
  1. systemd-hardened crash capture on Cookie / potentially Pico host too
  2. deterministic video-driven proving validation using the new prerecorded boxing fixtures
  3. only then return to trail/overlay behavior using artifact-backed evidence rather than webcam-only live retests

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending

**Lessons Learned:** Pending.

---

*Completed on Pending*
