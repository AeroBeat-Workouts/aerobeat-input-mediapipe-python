# Proving Scene Human Verification Checklist

## Purpose

Use this checklist when Derrick runs the **Boxing Detector Proving** and **Flow Detector Proving** scenes on Cookie.

This document is intentionally about **human verification and evidence capture**. It does **not** claim detector retuning is already done, and it does **not** replace later tuning beads. Its job is to make live testing repeatable, honest, and immediately usable.

## What this pass proves

If followed carefully, this pass can prove:

- the proving scenes launch and stay readable on Cookie
- the live camera view, landmarks, trails, and right-side debug panels remain usable during motion
- each shipped Boxing and Flow signal can be exercised by a real person
- visible ready/reset/suppression/active states match what the detector appears to be doing
- obvious false positives, false negatives, re-arm/reset failures, and readability problems are captured with evidence

## What this pass does not prove

This pass does **not** by itself prove:

- perfect thresholds
- robust performance across all bodies, clothing, rooms, or cameras
- 3D semantics beyond the current mirrored 2D camera baseline
- that prerecorded fixtures are unnecessary
- that any detector should be retuned in a particular way without follow-up analysis

---

## Evidence package Derrick should capture for every session

Create one session folder outside the repo or in a temporary synced notes location and keep the following together:

- session notes file
- at least one screenshot of each scene in a stable ready state
- screenshots of any clear false positive / false negative / readability issue
- short clips for each important success and failure pattern
- rep counts by feature
- ambiguity tags for anything questionable
- a short end-of-session summary with top blockers and recommended next bead(s)

### Required tags

Use these tags in notes so later tuning work can group findings quickly:

- `FP` — false positive
- `FN` — false negative
- `AMB` — ambiguous / hard to judge
- `RESET` — failed to re-arm or clear cleanly
- `READABILITY` — UI too hard to read during motion
- `FRAME` — camera framing issue
- `OCCLUSION` — body part hidden / self-occluded
- `TRACKING` — landmark/tracking instability
- `LATENCY` — visible lag or delayed fire
- `FATIGUE` — issue may be tester fatigue rather than detector logic

### Minimum evidence per feature family

For every feature family below, try to capture:

- **1 screenshot** showing the scene in the relevant ready/active/reset state when possible
- **1 short success clip** where the expected event or state clearly happens
- **1 failure clip** if you observe any FP, FN, weak reset, or unclear UI
- **rep counts** in the log
- **notes** describing what you intended versus what fired

---

## Before starting either scene

### Environment checklist

- Confirm Cookie has the intended camera selected and positioned for a full-body standing view.
- Confirm the room has even front lighting if possible.
- Wear clothing that keeps wrists, elbows, knees, and ankles reasonably legible.
- Leave enough space to lean, sidestep, squat, and lift knees without leaving frame.
- Avoid background movement for the first pass.

### Launch checklist

- From the repo root, restore the GodotEnv workbench mounts before opening Godot:
  - `cd .testbed && godotenv addons install && cd ..`
- If you also need the local Python sidecar runtime on Cookie, prepare that separately from the repo root:
  - `python3 python_mediapipe/prepare_runtime.py --platform linux-x64 --mode dev --install-requirements --validate`
- Open `.testbed` in Godot.
- Run **Boxing Detector Proving** first.
- Later run **Flow Detector Proving**.
- Wait for the status line to reach the live/ready state.

### Global proving-harness checks

These should be verified once per scene before feature-specific testing.

1. **Scene reaches live state**
   - Expected visible result:
     - status line becomes live/green rather than stuck on initializing
     - camera feed is present
     - quick stats show server ready and camera streaming
   - Capture:
     - 1 screenshot of the full scene once stable
     - note any startup delay or failure

2. **Tracking acquired**
   - Expected visible result:
     - tracking state is not lost
     - visible landmark count is non-zero
     - landmarks overlay lines up with the body
   - Capture:
     - 1 screenshot with landmarks aligned
     - note any drift, jitter, or obvious landmark mismatch

3. **Baseline calibration stabilizes**
   - Expected visible result:
     - summary panel shows baseline calibrated true after a short neutral stance
     - shoulder width / torso height stop jumping wildly
   - Capture:
     - note whether calibration was quick, slow, or unstable
     - tag `TRACKING` if never settles

4. **Readable during motion**
   - Expected visible result:
     - Derrick can glance at the right-side boards while moving and still tell what fired
     - event feed and persistent rows remain understandable
   - Capture:
     - note any font-size, layout, clipping, panel-overflow, or glanceability issue
     - tag `READABILITY` if the dashboard is too busy to use live

5. **Tracking lost / restored behavior**
   - Exercise by briefly leaving frame or occluding enough to break tracking once.
   - Expected visible result:
     - status changes to tracking lost, then tracking restored after reacquisition
     - overlays clear/recover sensibly
   - Capture:
     - short clip of loss and restore
     - note whether stale active states remain stuck afterward
     - tag `RESET` if a stale state survives reacquire

---

# Boxing scene checklist

Run `boxing_proving.tscn`.

## Boxing board surfaces Derrick should actively watch

While testing, keep an eye on these visible surfaces:

- camera panel with mirrored body view
- landmark overlay
- quick stats:
  - tracking state
  - head / hand confidence
  - height state
  - guard active
  - attack gates armed
- summary panel:
  - body-state booleans
  - height ratio / squat depth
  - lateral offsets
- boxing signal board:
  - punch/hook/uppercut rows with `status`, `count`, `last`, `power`
  - guard suppression line
  - guard / squat / lean / sidestep / leg_lift rows with `active`, `start/end`, `last`
  - knee rows with `status`, `count`, `last`, `power`
- live event feed

## Boxing test method

For each feature below:

- start from a neutral ready stance
- perform **5 intentional reps per side** for one-shot events
- perform **3 enter/hold/exit cycles** for sustained states
- after each rep cluster, pause in neutral long enough to verify reset / re-arm
- if a feature is unstable, do 5 more reps and capture at least one clip

## Boxing features and expected visible proof

### 1. Straight punch left

- Exercise:
  - throw a clear left straight from guard/neutral
- Expected visible result:
  - `punch_left` row count increments once per real punch
  - `punch_left` status flips from `READY` to `RESET` immediately after fire, then returns to `READY` once arm retracts
  - event feed shows `punch_left [power=...]`
- Watch for:
  - event firing while only raising guard
  - double-fire on one punch
  - never re-arming after retracting
- Capture:
  - rep count: intended vs detected
  - false positives and false negatives
  - one clip with a clean rep, one clip if reset is weak

### 2. Straight punch right

Same expectations as left, but for `punch_right`.

### 3. Hook left

- Exercise:
  - throw a clear left hook with bent elbow and lateral motion
- Expected visible result:
  - `hook_left` count increments
  - `hook_left` power updates on the last fired rep
  - row returns to `READY` after motion settles
- Watch for:
  - straight punches misclassified as hooks
  - hooks missed unless exaggerated
- Capture:
  - intended/detected rep counts
  - note whether classification depends on overacting the motion

### 4. Hook right

Same expectations as left, but for `hook_right`.

### 5. Uppercut left

- Exercise:
  - throw a clear upward left uppercut
- Expected visible result:
  - `uppercut_left` count increments
  - last power value looks non-zero and changes across stronger/weaker reps
  - row re-arms after the hand settles
- Watch for:
  - hooks being mistaken for uppercuts
  - vertical motion required to be unrealistically large
- Capture:
  - one clean clip
  - note any directional ambiguity

### 6. Uppercut right

Same expectations as left, but for `uppercut_right`.

### 7. Guard state

- Exercise:
  - raise both hands into guard, hold briefly, then drop out
  - repeat 3 times
- Expected visible result:
  - `guard` row `active=true` while hands are up
  - `guard_start` and `guard_end` counts stay balanced over repeated cycles
  - quick stats shows `Guard active: true` during hold
  - `guard suppression: ON` appears, and attack-family rows should show `SUPPRESSED` rather than cleanly firing punches/hooks/uppercuts during guard
- Watch for:
  - guard never ending after hands lower
  - attacks incorrectly firing while clean guard is held
  - suppression lingering after leaving guard
- Capture:
  - screenshot of guard active + suppression on
  - clip showing entry, hold, exit
  - note if suppression feels too broad or too sticky

### 8. Squat state

- Exercise:
  - lower into squat, hold briefly, stand up
  - repeat 3 times
- Expected visible result:
  - `squat` row toggles `active=true` during the lowered state
  - `squat_start` / `squat_end` counts advance sensibly
  - summary panel height ratio and squat depth shift clearly
- Watch for:
  - squat only detected at extreme depth
  - delayed end when standing back up
- Capture:
  - screenshot while active
  - note whether depth thresholds feel practical

### 9. Weave left state

- Exercise:
  - weave torso/head clearly to Derrick's left, then return neutral
- Expected visible result:
  - `weave_left` activates without also activating `weave_right`
  - lateral offset lines in the summary move in the expected direction
  - state clears near neutral
- Watch for:
  - weave confused with sidestep
  - state staying on after recentring
- Capture:
  - intended/detected enter/exit counts
  - tag `AMB` if body English needed is unclear

### 10. Weave right state

Same expectations as left, but for `weave_right`.

### 11. Sidestep left state

- Exercise:
  - shift body laterally to Derrick's left while staying relatively aligned
- Expected visible result:
  - `sidestep_left` activates
  - `sidestep_right` stays off
  - body/head/hip offsets support the movement direction
- Watch for:
  - lean being mistaken for sidestep
  - state only firing after leaving safe frame center
- Capture:
  - clip showing clean enter and return
  - note how much travel is required

### 12. Sidestep right state

Same expectations as left, but for `sidestep_right`.

### 13. Knee left

- Exercise:
  - lift left knee sharply, lower fully, repeat
- Expected visible result:
  - `knee_left` row count increments once per rep
  - row returns to `READY` only after lowering enough
  - `power` should change with stronger vs weaker lifts
- Watch for:
  - repeated firing while the knee remains up
  - left/right confusion
  - false fires when only shifting weight
- Capture:
  - intended vs detected count
  - one clip showing re-arm after lowering

### 14. Knee right

Same expectations as left, but for `knee_right`.

### 15. Leg lift left state

- Exercise:
  - raise left leg into a held lift, hold briefly, lower
- Expected visible result:
  - `leg_lift_left` row becomes `active=true`
  - `leg_lift_left_start` and `_end` counts stay balanced
  - current detector inputs show left leg angle / foot rise moving in the expected direction
- Watch for:
  - state activating from a knee motion that should only be one-shot
  - state never clearing when lowered
- Capture:
  - screenshot while held active
  - note difference between knee and leg-lift behavior

### 16. Leg lift right state

Same expectations as left, but for `leg_lift_right`.

## Boxing combined-state checks

These are important because a feature may work alone but fail in context.

### A. Guard suppression vs attacks

- Hold guard and intentionally make small punch-like motions.
- Expected visible result:
  - attack-family rows stay suppressed or do not increment from minor guarded motion
- Capture:
  - note any attack events that still leak through clean guard

### B. Reset / re-arm loop for one-shot attacks

- Pick one side and do 5 punches, 5 hooks, 5 uppercuts, 5 knees with full reset between reps.
- Expected visible result:
  - counts match intended reps closely
  - rows return to `READY` between reps
- Capture:
  - exact intended vs detected totals
  - `RESET` tag if any row sticks in `RESET`

### C. Neutral clearing after movement cluster

- After a mixed motion sequence, return to neutral for 2-3 seconds.
- Expected visible result:
  - no sustained state remains incorrectly active
  - attack rows eventually show ready again
- Capture:
  - note any stale guard/squat/lean/sidestep/leg-lift state

---

# Flow scene checklist

Run `flow_proving.tscn`.

## Flow board surfaces Derrick should actively watch

- mirrored camera panel
- landmark overlay plus wrist trails
- quick stats:
  - swing gates armed
  - active trails
  - per-hand candidate placement / direction
  - local trail points / duration
- summary panel:
  - last emitted events for `swing_*` and `trail_*`
  - swing ready per hand
  - trail active per hand
  - placement vs direction candidate lines
  - mirrored-hand sanity readouts
- flow signal board:
  - `swing_left`, `swing_right`, `trail_left`, `trail_right`
  - each row's `status`, `count`, `last`, emitted placement/direction, candidate placement/direction, duration, arc, net, consistency, lane spread, confidence
- detector metrics panel:
  - per-hand swing/trail window analysis
  - latest position, avg_x, center_offset, velocity, direction
- event feed

## Flow test method

For each hand and family:

- perform **5 clean reps** for a chosen pattern
- hold / sustain where trail behavior should remain active
- pause to let the hand settle and verify re-arm
- do at least one deliberate off-nominal rep to see a near miss or failure mode

## Supported Flow payload dimensions

Every emitted Flow event has:

- **hand:** `left` or `right`
- **family:** `swing` or `trail`
- **placement:** `left`, `center`, or `right`
- **direction:** `left`, `right`, `up`, or `down`

That means the proving scene can visibly emit a **payload matrix** across both hands and both families. For immediate human testing on Cookie, use this rule:

- **First-pass minimum:** for each hand, capture at least one successful `swing_*` and one successful `trail_*`, and across the whole session observe all three placements and all four directions at least once.
- **Preferred fuller pass:** over repeated sessions, fill the full hand × family × placement × direction matrix where physically practical.

If a specific combination is awkward or unclear, record it as `AMB` instead of pretending it passed.

## Flow features and expected visible proof

### 1. Swing left

- Exercise:
  - perform a short decisive left-hand swing gesture
- Expected visible result:
  - `swing_left` count increments once per successful gesture
  - row shows `status=RESET` immediately after fire, then returns to `READY` after the hand settles
  - emitted placement/direction fields populate
  - candidate placement/direction nearby should make sense before or around the fire
- Watch for:
  - double-fire from one swing
  - direction wrong even when timing is correct
  - placement reported off by one lane
- Capture:
  - clip showing gesture plus right-side row
  - rep counts and payload notes

### 2. Swing right

Same expectations as left, but for `swing_right`.

### 3. Trail left

- Exercise:
  - perform a sustained left-hand trail motion long enough to stay active
- Expected visible result:
  - `trail_left` row becomes `ACTIVE` during sustained motion, then `IDLE` after it ends
  - count increments when emitted according to the interval / payload changes
  - emitted and candidate placement/direction remain intelligible
  - duration, arc, net distance, directional consistency, lane spread, and confidence look stable rather than chaotic
- Watch for:
  - trail never becoming active
  - trail staying active after motion stops
  - emitted payload thrashing every moment
- Capture:
  - screenshot while `ACTIVE`
  - clip showing enter, sustain, exit
  - note whether state feels stable enough for charted gameplay

### 4. Trail right

Same expectations as left, but for `trail_right`.

## Flow placement checks

Do these for both hands when possible.

### A. Center placement

- Exercise:
  - perform motions roughly centered on the body
- Expected visible result:
  - candidate and/or emitted placement reads `center`
- Capture:
  - at least one successful clip
  - note if center drifts left/right without obvious reason

### B. Left placement

- Exercise:
  - perform motions clearly on the left side of the body frame
- Expected visible result:
  - placement reads `left`
- Capture:
  - at least one clip or screenshot
  - tag `FRAME` if only achievable near the edge of the camera view

### C. Right placement

- Exercise:
  - perform motions clearly on the right side of the body frame
- Expected visible result:
  - placement reads `right`
- Capture:
  - at least one clip or screenshot

## Flow direction checks

Across both hands and families, try to observe all four directions at least once.

### A. Direction left

- Expected visible result:
  - emitted/candidate direction reads `left`

### B. Direction right

- Expected visible result:
  - emitted/candidate direction reads `right`

### C. Direction up

- Expected visible result:
  - emitted/candidate direction reads `up`

### D. Direction down

- Expected visible result:
  - emitted/candidate direction reads `down`

For each direction:

- Capture one success example.
- Note if the motion only works with exaggerated amplitude.
- Tag `AMB` if the scene makes it hard to tell whether the detector was wrong or the performed gesture was mixed-direction.

## Flow state / reset checks

### A. Swing re-arm

- Perform 5 repeated swing reps with a clear pause between each.
- Expected visible result:
  - row returns to `READY` between reps
  - counts stay close to intended reps
- Capture:
  - intended vs detected totals
  - tag `RESET` if the gate stays closed too long

### B. Trail enter / sustain / exit

- Perform 3 clear trail sequences per hand.
- Expected visible result:
  - row transitions into `ACTIVE`, remains there while motion stays coherent, and returns to `IDLE` when motion stops or coherence is lost
- Capture:
  - clip of one clean full lifecycle
  - note any sticky active state

### C. Candidate-vs-emitted truth

- Watch candidate placement/direction before a successful fire.
- Expected visible result:
  - candidate values should usually foreshadow emitted payload rather than contradict it wildly
- Capture:
  - note cases where emitted payload surprises Derrick despite apparently stable candidates
  - tag `AMB` if not enough time to read live

### D. Mirrored-hand sanity

- Move only one hand at a time.
- Expected visible result:
  - left-hand actions mostly affect left-hand rows and metrics; same for right
- Capture:
  - note any crosstalk or side confusion

---

# Camera framing and occlusion checks

Do these after the basic clean pass, for both Boxing and Flow as relevant.

## 1. Too close / too far

- Step slightly too close, then slightly too far.
- Expected visible result:
  - either continued usable tracking or obvious degradation Derrick can document
- Capture:
  - note which distance breaks first
  - tag `FRAME`

## 2. Partial hand occlusion

- Hide one hand briefly behind the body or out of frame during a feature test.
- Expected visible result:
  - either graceful non-fire or a clearly recoverable state
- Capture:
  - tag `OCCLUSION`
  - note if stale events/states persist after hand returns

## 3. Lower-body occlusion risk

- Test knees / leg lifts / squat with camera framing that barely includes the legs.
- Expected visible result:
  - limitations become obvious and documentable rather than mysterious
- Capture:
  - note minimum viable framing for lower-body signals

---

# Logging format Derrick should use during the session

Use one log row per feature attempt cluster, not one row per single rep, unless a feature is very unstable.

Minimum fields:

- scene
- feature
- side/hand if applicable
- intended reps
- detected reps
- emitted payloads observed
- expected visible proof
- observed behavior
- tags
- artifact names
- recommended follow-up

A ready-to-copy template lives in:

- `docs/proving-scene-human-verification-log-template.md`

---

# Immediate recommended first Cookie pass

If time is limited, do this order first:

1. Global harness checks in Boxing scene
2. Boxing: guard, straight punches, hooks, uppercuts, knees, then sustained states
3. Global harness checks in Flow scene
4. Flow: one clean swing and one clean trail per hand
5. Across the whole Flow pass, make sure all directions (`left/right/up/down`) and placements (`left/center/right`) are observed at least once
6. Finish with one deliberate tracking-loss / reacquire check and one framing/occlusion check

This first pass should optimize for **finding obvious truth gaps quickly**, not exhaustive perfection.

---

# Pass / fail guidance

A feature should be marked:

- **PASS** if the expected visible proof is present, rep counts are reasonably close, and reset behavior is trustworthy
- **SOFT FAIL** if it technically works but requires exaggerated motion, has unclear UI, or shows noticeable ambiguity
- **FAIL** if it commonly misfires, misses intentional reps, sticks active/reset, swaps side/direction/placement incorrectly, or becomes unreadable during motion
- **NOT TESTED** if Derrick ran out of time or framing/setup blocked the check

When in doubt, mark `SOFT FAIL` or `AMB`, capture evidence, and keep the claim honest.
