# Proving Scene Video Fixtures — Plain-Language Guide

## Why this exists

This is the **quick human guide** for the proving-scene video fixture system.

The technical design doc (`docs/proving-scene-video-fixtures.md`) is the source of truth for the format. This companion doc is the "what should I actually do?" version for Derrick while testing on Cookie.

If you only remember one thing, remember this:

> A video fixture is a short recorded clip plus a small JSON sidecar file that says what that clip is supposed to prove.

The goal is to make future detector checks **repeatable** without pretending prerecorded clips can replace live testing.

---

## Plain-English version

### What is a fixture?

A fixture is a **saved test example**.

For this repo, one fixture usually means:

- one short `.mp4` video
- one `.fixture.json` file with the same basename
- optional notes/screenshots if something about the clip matters

Example:

- `boxing__punch_left__positive__cam-cookie-logitech-c920__take-01.mp4`
- `boxing__punch_left__positive__cam-cookie-logitech-c920__take-01.fixture.json`

Think of the video as the **evidence** and the JSON file as the **label + expectations**.

### What problem do fixtures solve?

They let us replay the **same known clip** later and ask:

- does the detector still emit the same event?
- does the proving scene still show the same debug/status truth?
- did a code or threshold change break something that used to work?

That makes them good for **regression testing**.

### What fixtures do *not* solve

Fixtures do **not** prove that live camera play feels good.

They also do **not** prove:

- every body type works
- every room works
- every webcam works
- thresholds are universally correct
- live timing/latency feels good
- occlusion/framing problems are solved in the real world

If a prerecorded clip passes but live testing feels bad, **trust live testing**.

---

## The main idea

Record short, boring, clear clips.

Not flashy demos. Not combo reels. Not 45 seconds of many different moves.

Each clip should answer one practical question like:

- "Does left punch still emit `punch_left`?"
- "Does guard enter, stay active, and exit cleanly?"
- "Does left trail still produce the expected Flow payload?"
- "Does the signal re-arm between repeated reps?"

That is the whole philosophy.

---

## The important terms, simplified

### Proving scene

A Godot scene used for **truth-checking detector behavior**.

Instead of just playing the game, the proving scene exposes extra debug/status info so you can see what the detector thinks is happening.

Relevant scenes:

- `boxing_proving.tscn`
- `flow_proving.tscn`

### Detector family

The broad system being tested.

Here that means:

- `boxing`
- `flow`

### Feature

The specific motion or state you care about.

Examples:

- Boxing: `punch_left`, `hook_right`, `guard`, `knee_left`
- Flow: `swing_left`, `trail_right`

### Intent

Why the clip exists.

Common values:

- `positive` = the target thing **should happen**
- `negative` = the target thing **should not happen**
- `boundary` = near-threshold / ambiguous / tuning-oriented
- `rearm` = focused on reset + repeat behavior
- `occlusion` = something is partly hidden
- `framing` = camera position/crop is part of the test

### Motion shape

What kind of movement pattern the clip contains.

- `oneshot` = one event like a punch or swing
- `state` = enter/hold/exit state like guard or squat
- `continuous` = ongoing motion like trail
- `mixed` = multiple things together

For the first useful fixture set, prefer **single-feature clips**, not mixed clips.

### Approval level

How trusted the clip is.

- `candidate` = captured, but not yet blessed as baseline truth
- `canonical` = approved baseline clip you want automation to keep passing
- `deprecated` = kept for history, not active baseline

### Sidecar / metadata file

This is the `.fixture.json` file beside the video.

Its job is to answer questions a filename cannot answer cleanly, such as:

- who recorded this?
- on what machine/camera?
- what exactly should happen?
- what should *not* happen?
- when in the clip should the action happen?
- what can this clip prove?
- what can it *not* prove?

### Expected events

The detector outputs that should happen during the clip.

Example:

- one `punch_left`
- one `swing_right` with a specific payload

### Forbidden events

Things that would indicate a false positive or cross-trigger.

Example:

- the left punch clip should not also emit `hook_left`

### State window

The part of the clip where a state should be active.

Useful for things like:

- guard
- squat
- trail

### Ready / reset / re-arm

This is the detector’s ability to become ready again after firing.

Plain English:

- **ready** = can detect the next rep
- **reset** = currently recovering / not ready to fire again yet
- **re-arm** = returns to ready so the next rep can count

This matters a lot for repeated punches or repeated swings.

### Observability surfaces

The on-screen or debug outputs that tell you what the system thinks is happening.

Examples:

- signal board status
- event counts
- last event payload
- candidate placement/direction
- debug fields in `gesture_debug`

Fixtures should eventually help verify not just "did the detector fire?" but also "did the proving scene *show truthful debug information*?"

---

## How to record the videos

### Recording goal

Make the clip easy for future-you to understand and easy for automation to use.

That means:

- stable camera
- stable lighting
- stable framing
- one main purpose per clip
- enough neutral time before and after the action

### Recommended recording setup on Cookie

For practical Cookie capture, aim for:

- the camera Derrick is actually using for testing
- a fixed camera position
- even lighting if possible
- a plain-ish background if possible
- body parts needed for the move clearly visible
- no zooming, no crop changes, no camera motion during the take

For lower-body Boxing clips (`knee_*`, `leg_lift_*`, `squat`, `sidestep_*`), make sure the full lower body stays in frame.

### Record camera-style input, not screen recordings

Use a clip that represents the **detector input**.

Do **not** make the fixture itself a proving-scene screen recording.

Why:

- the detector cares about camera input
- the proving scene UI can change later
- the same raw clip can be reused for detector-only checks and proving-scene checks

### Recommended clip shape

Each clip should usually have three parts:

1. **lead-in** — 0.5 to 1.5 seconds of neutral/ready pose
2. **action** — do the move being tested
3. **settle** — 0.5 to 2 seconds after the move so reset/re-arm/exit can be observed

### Practical recording rules

Good clips are:

- short
- clear
- repeatable
- easy to label

Good examples:

- one clean left punch
- one guard enter / hold / exit
- one left swing
- one right trail enter / sustain / exit
- one repeated punch clip specifically for re-arm behavior

Bad examples:

- a montage of many actions
- a clip where the target action is unclear
- a clip where the action starts instantly with no lead-in
- a clip where the camera or framing changes mid-take

### How many takes to keep

Keep multiple takes while exploring if needed, but only bless a clip as a real fixture when it is:

- clearly readable to a human
- labeled honestly
- stable enough to be useful later

Do not overwrite an old take in place. Increment the take number.

---

## How to name the videos

Use this basename format:

```text
<family>__<feature>__<intent>__cam-<capture-rig>__take-<nn>
```

Examples:

```text
boxing__punch_left__positive__cam-cookie-logitech-c920__take-01.mp4
boxing__guard__rearm__cam-cookie-logitech-c920__take-02.mp4
flow__swing_right__positive__cam-cookie-logitech-c920__take-01.mp4
flow__trail_left__positive__cam-cookie-logitech-c920__take-03.mp4
```

### Naming rules in plain English

- keep everything lowercase
- use the real feature name
- say what the clip is trying to prove (`positive`, `negative`, etc.)
- include the capture rig at a high level
- use `take-01`, `take-02`, and so on
- the `.mp4` and `.fixture.json` should share the exact same basename

### Where files should live

Put curated fixtures here:

```text
.testbed/assets/fixtures/
```

Organize them like this:

```text
.testbed/assets/fixtures/
  boxing/
    punch_left/
    guard/
    knee_right/
  flow/
    swing_left/
    trail_right/
```

So a full example path looks like:

```text
.testbed/assets/fixtures/boxing/punch_left/boxing__punch_left__positive__cam-cookie-logitech-c920__take-01.mp4
```

---

## What each clip should show

### Boxing one-shot clips

Examples:

- `punch_left`
- `hook_right`
- `uppercut_left`
- `knee_right`

What the clip should show:

- a neutral starting pose
- one clear target motion
- enough settle time for the system to reset

What you want later automation to verify:

- the target event happened once
- sibling events did not trigger by mistake
- the detector became ready again by the end

### Boxing state clips

Examples:

- `guard`
- `squat`
- `lean_left`
- `sidestep_right`
- `leg_lift_left`

What the clip should show:

- enter the state clearly
- hold it long enough to be visible
- exit it clearly

What you want later automation to verify:

- `*_start` happened
- the state stayed active during the hold window
- `*_end` happened
- the state cleared properly afterward

### Flow swing clips

Examples:

- `swing_left`
- `swing_right`

What the clip should show:

- a neutral start
- one clear swing
- enough settle time to return to ready

What you want later automation to verify:

- one swing event fired
- the payload matched expectations (placement/direction)
- candidate and emitted values made sense in the proving scene/debug output
- the detector re-armed afterward

### Flow trail clips

Examples:

- `trail_left`
- `trail_right`

What the clip should show:

- neutral start
- a clear sustained trail motion
- a clear exit

What you want later automation to verify:

- trail became active
- expected payloads appeared
- the sustained phase looked coherent
- trail exited cleanly by the end

---

## What the metadata / sidecar file is for

The sidecar file is what turns "a random video" into "a usable test fixture."

Without the sidecar, you might know the clip is called `punch_left`, but you do not know:

- whether it is approved or still a candidate
- the exact timing window where the event should occur
- what false positives are forbidden
- what payload should be emitted
- what the clip is allowed to prove
- what debug surfaces should be visible

### In practical terms, the sidecar should tell future-you:

- what this clip is
- why it exists
- how trustworthy it is
- what pass/fail should mean

### What to fill out carefully

The most important fields to keep honest are:

- `approval_level`
- `family`
- `feature`
- `intent`
- `claims`
- `non_claims`
- `expected_events`
- `forbidden_events`
- timing fields
- observability expectations

If those are sloppy, the fixture becomes misleading.

---

## What these fixtures can prove

Used correctly, fixtures can help prove:

- a known clip still emits the expected event class
- a known clip still produces the expected Flow payload shape
- reset/re-arm logic still behaves the same way
- the proving scene still surfaces the expected status/debug fields
- a regression was introduced after a code or threshold change

This is valuable because it gives repeatable evidence.

---

## What these fixtures cannot prove

Be strict here.

Fixtures cannot prove:

- that live play feels responsive
- that the move is comfortable or readable for real people in real sessions
- that the thresholds are correct for everyone
- that the feature works well under fatigue
- that the feature is robust to all camera angles or all occlusions
- that the feature works on all machines, cameras, or rooms

In other words: fixtures prove **repeatable clip behavior**, not **universal product truth**.

---

## Recommended first fixture slice

For the first genuinely useful set, prioritize clips that cover the major motion types.

### Strong first picks

Boxing:

- `punch_left`
- `punch_right`
- `hook_left`
- `hook_right`
- `uppercut_left`
- `uppercut_right`
- `guard`
- `knee_left`
- `knee_right`

Flow:

- `swing_left`
- `swing_right`
- `trail_left`
- `trail_right`

### If you want the smallest practical starter subset

Start with just these:

- `boxing__punch_left__positive__cam-cookie-logitech-c920__take-01`
- `boxing__guard__positive__cam-cookie-logitech-c920__take-01`
- `flow__swing_left__positive__cam-cookie-logitech-c920__take-01`
- `flow__trail_right__positive__cam-cookie-logitech-c920__take-01`

That gives you:

- one Boxing one-shot
- one Boxing sustained state
- one Flow swing
- one Flow trail

Which is enough to prove the workflow is real before expanding it.

---

## Practical workflow Derrick can follow on Cookie

### 1. Pick one feature

Example:

- `punch_left`

### 2. Record a few short takes

Try for:

- neutral start
- one clear action
- settle time afterward

### 3. Keep the clearest take

Pick the take a human can look at and say:

- yes, that is clearly the move we meant

### 4. Name it immediately

Example:

- `boxing__punch_left__positive__cam-cookie-logitech-c920__take-01.mp4`

### 5. Put it in the correct fixture folder

Example:

- `.testbed/assets/fixtures/boxing/punch_left/`

### 6. Create the matching `.fixture.json`

Use `docs/proving-scene-video-fixture-template.fixture.json` as the starter template.

### 7. Fill out the truth carefully

Especially:

- what event should happen
- what must not happen
- when it should happen
- what this clip can and cannot prove

### 8. Keep optional notes if something matters

Useful examples:

- subject drifted slightly left during the take
- lighting was worse than normal
- good motion shape but framing is tighter than preferred

### 9. Promote only the clean clips

Only mark a clip as `canonical` when it is genuinely readable and stable enough to rely on later.

---

## Heuristics for deciding if a clip is good enough

A clip is probably good enough when:

- a human can identify the intended move quickly
- the move is the main thing happening in the clip
- framing is good enough to see the relevant limbs/body region
- the start and end are clear enough for timing windows
- the clip is not mislabeled or overly ambiguous

A clip is probably **not** good enough for canonical use when:

- the move is sloppy or unclear
- another event could plausibly be the real label
- framing hides the important body part
- the clip only works because of a weird exaggerated motion
- the clip would confuse future-you in a month

If in doubt, keep it as `candidate`, not `canonical`.

---

## Suggested "open this first" files

If Derrick wants the shortest useful path:

1. `docs/proving-scene-video-fixtures-plain-language.md` — this guide
2. `docs/proving-scene-video-fixtures.md` — technical source-of-truth design
3. `docs/proving-scene-video-fixture-template.fixture.json` — template for making actual fixtures

---

## Bottom line

The durable rule is simple:

- record **short, clear, single-purpose camera clips**
- name them predictably
- pair each one with a truthful sidecar JSON file
- use them for repeatable regression checks
- do **not** confuse fixture success with live human verification success

That keeps the system practical, honest, and actually useful.