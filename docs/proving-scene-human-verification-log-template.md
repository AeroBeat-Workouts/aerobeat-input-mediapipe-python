# Proving Scene Human Verification Log Template

Copy this into a session note and fill it while testing on Cookie.

---

## Session metadata

- Date:
- Machine: Cookie
- Tester: Derrick
- Camera/device:
- Lighting notes:
- Clothing notes:
- Distance from camera:
- Scene order:
- Build / commit under test:

## Session-level summary

- Overall harness startup result:
- Overall tracking quality:
- Biggest Boxing issue:
- Biggest Flow issue:
- Biggest readability issue:
- Biggest framing / occlusion issue:
- Recommended next bead(s):

## Artifact index

- Screenshot folder/path:
- Clip folder/path:
- Notes file path:

---

## Global harness checks

| Scene | Check | Expected | Observed | Tags | Artifacts | Result |
| --- | --- | --- | --- | --- | --- | --- |
| Boxing | Scene reaches live state | Green/live status, camera feed, streaming |  |  |  | PASS / SOFT FAIL / FAIL |
| Boxing | Tracking acquired | Landmarks align, tracking not lost |  |  |  | PASS / SOFT FAIL / FAIL |
| Boxing | Baseline calibrated | Calibration settles from neutral stance |  |  |  | PASS / SOFT FAIL / FAIL |
| Boxing | Readable during motion | Right-side panels remain glanceable |  |  |  | PASS / SOFT FAIL / FAIL |
| Boxing | Tracking loss / restore | Lost/restored states are sensible |  |  |  | PASS / SOFT FAIL / FAIL |
| Flow | Scene reaches live state | Green/live status, camera feed, streaming |  |  |  | PASS / SOFT FAIL / FAIL |
| Flow | Tracking acquired | Landmarks align, tracking not lost |  |  |  | PASS / SOFT FAIL / FAIL |
| Flow | Baseline calibrated | Calibration settles from neutral stance |  |  |  | PASS / SOFT FAIL / FAIL |
| Flow | Readable during motion | Right-side panels remain glanceable |  |  |  | PASS / SOFT FAIL / FAIL |
| Flow | Tracking loss / restore | Lost/restored states are sensible |  |  |  | PASS / SOFT FAIL / FAIL |

---

## Boxing feature log

| Feature | Side | Intended reps / cycles | Detected reps / cycles | Expected visible proof | Observed behavior | FP | FN | Reset / re-arm notes | Readability / framing notes | Tags | Artifacts | Result |
| --- | --- | --- | --- | --- | --- | ---: | ---: | --- | --- | --- | --- | --- |
| punch | left |  |  | Count increments, ready->reset->ready, power visible |  |  |  |  |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| punch | right |  |  | Count increments, ready->reset->ready, power visible |  |  |  |  |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| hook | left |  |  | Count increments, power visible, re-arms after settle |  |  |  |  |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| hook | right |  |  | Count increments, power visible, re-arms after settle |  |  |  |  |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| uppercut | left |  |  | Count increments, power visible, re-arms after settle |  |  |  |  |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| uppercut | right |  |  | Count increments, power visible, re-arms after settle |  |  |  |  |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| guard | both | 3 cycles |  | active=true while held, start/end balanced, suppression on |  |  |  |  |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| squat | both | 3 cycles |  | active=true while lowered, start/end balanced |  |  |  |  |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| weave | left | 3 cycles |  | weave_left active, clears at neutral |  |  |  |  |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| weave | right | 3 cycles |  | weave_right active, clears at neutral |  |  |  |  |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| sidestep | left | 3 cycles |  | sidestep_left active, clears at neutral |  |  |  |  |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| sidestep | right | 3 cycles |  | sidestep_right active, clears at neutral |  |  |  |  |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| knee | left | 5 reps |  | Count increments once per rep, power visible, re-arms after lowering |  |  |  |  |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| knee | right | 5 reps |  | Count increments once per rep, power visible, re-arms after lowering |  |  |  |  |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| leg_lift | left | 3 cycles |  | active=true while held, start/end balanced |  |  |  |  |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| leg_lift | right | 3 cycles |  | active=true while held, start/end balanced |  |  |  |  |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |

### Boxing combined-state notes

- Guard suppression vs attacks:
- Attack re-arm loop quality:
- Neutral clearing after mixed sequence:

---

## Flow feature log

| Family | Hand | Placement target | Direction target | Intended reps / cycles | Detected reps / cycles | Emitted payloads observed | Candidate payloads observed | Expected visible proof | Observed behavior | FP | FN | Reset / active-state notes | Readability / framing notes | Tags | Artifacts | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---: | ---: | --- | --- | --- | --- | --- |
| swing | left |  |  | 5 reps |  |  |  | Count increments, ready->reset->ready, emitted payload makes sense |  |  |  |  |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| swing | right |  |  | 5 reps |  |  |  | Count increments, ready->reset->ready, emitted payload makes sense |  |  |  |  |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| trail | left |  |  | 3 cycles |  |  |  | ACTIVE during sustained motion, IDLE after exit, payload sensible |  |  |  |  |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| trail | right |  |  | 3 cycles |  |  |  | ACTIVE during sustained motion, IDLE after exit, payload sensible |  |  |  |  |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |

### Flow placement coverage

| Placement | Seen? | Which hand/family | Artifacts | Notes |
| --- | --- | --- | --- | --- |
| left |  |  |  |  |
| center |  |  |  |  |
| right |  |  |  |  |

### Flow direction coverage

| Direction | Seen? | Which hand/family | Artifacts | Notes |
| --- | --- | --- | --- | --- |
| left |  |  |  |  |
| right |  |  |  |  |
| up |  |  |  |  |
| down |  |  |  |  |

### Preferred full matrix tracker

Use this if Derrick wants to grow toward full payload coverage over multiple sessions.

| Family | Hand | Placement | Direction | Seen? | Artifact | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| swing | left | left | left |  |  |  |
| swing | left | left | right |  |  |  |
| swing | left | left | up |  |  |  |
| swing | left | left | down |  |  |  |
| swing | left | center | left |  |  |  |
| swing | left | center | right |  |  |  |
| swing | left | center | up |  |  |  |
| swing | left | center | down |  |  |  |
| swing | left | right | left |  |  |  |
| swing | left | right | right |  |  |  |
| swing | left | right | up |  |  |  |
| swing | left | right | down |  |  |  |
| swing | right | left | left |  |  |  |
| swing | right | left | right |  |  |  |
| swing | right | left | up |  |  |  |
| swing | right | left | down |  |  |  |
| swing | right | center | left |  |  |  |
| swing | right | center | right |  |  |  |
| swing | right | center | up |  |  |  |
| swing | right | center | down |  |  |  |
| swing | right | right | left |  |  |  |
| swing | right | right | right |  |  |  |
| swing | right | right | up |  |  |  |
| swing | right | right | down |  |  |  |
| trail | left | left | left |  |  |  |
| trail | left | left | right |  |  |  |
| trail | left | left | up |  |  |  |
| trail | left | left | down |  |  |  |
| trail | left | center | left |  |  |  |
| trail | left | center | right |  |  |  |
| trail | left | center | up |  |  |  |
| trail | left | center | down |  |  |  |
| trail | left | right | left |  |  |  |
| trail | left | right | right |  |  |  |
| trail | left | right | up |  |  |  |
| trail | left | right | down |  |  |  |
| trail | right | left | left |  |  |  |
| trail | right | left | right |  |  |  |
| trail | right | left | up |  |  |  |
| trail | right | left | down |  |  |  |
| trail | right | center | left |  |  |  |
| trail | right | center | right |  |  |  |
| trail | right | center | up |  |  |  |
| trail | right | center | down |  |  |  |
| trail | right | right | left |  |  |  |
| trail | right | right | right |  |  |  |
| trail | right | right | up |  |  |  |
| trail | right | right | down |  |  |  |

---

## Framing / occlusion checks

| Scene | Check | Observed behavior | Tags | Artifacts | Result |
| --- | --- | --- | --- | --- | --- |
| Boxing | Too close / too far |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| Boxing | Partial hand occlusion |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| Boxing | Lower-body framing |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| Flow | Too close / too far |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |
| Flow | Partial hand occlusion |  |  |  | PASS / SOFT FAIL / FAIL / NOT TESTED |

---

## End-of-session conclusions

- Most trustworthy Boxing features:
- Most questionable Boxing features:
- Most trustworthy Flow features:
- Most questionable Flow features:
- Any obvious false-positive clusters:
- Any obvious false-negative clusters:
- Any reset / re-arm bugs:
- Any readability bugs:
- Any framing / occlusion blockers:
- Suggested next detector-tuning investigation:
- Suggested next UI / proving-scene improvement:
