# AeroBeat MediaPipe Human Verification and Video Fixtures

**Date:** 2026-05-05  
**Status:** Draft  
**Agent:** Pico 🐱‍🏍

---

## Goal

Turn the proving-scene observability work into a real verification pipeline by (1) running substantial human movement testing across supported Boxing and Flow features, and (2) building reusable feature-specific video fixtures that can support more automated regression checks later.

---

## Overview

The previous proving-scene plan is now complete for observability scope only. We have much better persistent status boards, richer detector debug state, and automated evidence that the scenes and detector wiring are structurally sound. What we do not have yet is real-world confidence: no live motion truth pass has certified readability, threshold correctness, reset behavior, or robustness under actual camera use.

This follow-up phase deliberately separates two kinds of truth work that should reinforce each other but not be confused. First, human verification: Derrick will exercise the Boxing and Flow proving scenes with real motion and capture what succeeds, what fails, and what feels ambiguous. Second, repeatable automation assets: short canonical feature videos that can later be replayed to check detector output and proving-scene surfaces without pretending prerecorded clips are a full substitute for real-person testing.

Because Derrick plans to sync this repo onto Cookie and test there, this plan should leave the repo in a clean pushed state quickly, with an explicit checklist/matrix to guide the human pass and a concrete path toward fixture creation. Any threshold tuning discovered during human testing should be recorded against explicit beads instead of being mixed into vague session notes. If fixture automation reveals separate harness needs, that should also become explicit repo-local work rather than silent scope creep.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Observability pass plan and audit results | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-05-mediapipe-proving-scene-human-verification-and-tuning.md` |
| `REF-02` | Boxing proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/boxing_proving.tscn` |
| `REF-03` | Flow proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/flow_proving.tscn` |
| `REF-04` | Shared proving harness | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/proving_harness.gd` |
| `REF-05` | Detector substrate | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/detectors/pose_detector_substrate.gd` |
| `REF-06` | Existing future perf bead to keep isolated | `oc-nua` |

---

## Tasks

### Task 1: Prepare human verification checklist and evidence workflow

**Bead ID:** `oc-5mi`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Create a concrete human-verification checklist for Derrick to use while testing on Cookie. It should enumerate every supported Boxing and Flow feature/state, say what should be visible in the proving scenes, what failure modes to watch for, and what evidence to capture (notes, screenshots, clips, counts, ambiguity tags). Include an explicit way to record false positives, false negatives, reset/re-arm issues, readability issues, and camera-framing/occlusion issues. Claim the bead at start and close it only when the checklist/workflow is written into the repo clearly enough for Derrick to use immediately.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/proving-scene-human-verification-checklist.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/proving-scene-human-verification-log-template.md`

**Status:** ✅ Complete

**Results:** Added durable repo-local human verification docs under `docs/`: `proving-scene-human-verification-checklist.md` and `proving-scene-human-verification-log-template.md`. The checklist now covers global harness readiness/tracking/readability checks; every shipped Boxing feature/state (`punch_*`, `hook_*`, `uppercut_*`, `guard`, `squat`, `lean_*`, `sidestep_*`, `knee_*`, `leg_lift_*`); every shipped Flow feature family/state (`swing_*`, `trail_*`, ready/reset/active behavior); and the practical evidence workflow Derrick should capture on Cookie, including screenshots, clips, rep counts, ambiguity tags, false-positive/false-negative counts, reset/re-arm notes, readability notes, and framing/occlusion notes. It also includes an honest Flow payload-coverage strategy: first-pass minimum coverage plus a durable full hand × family × placement × direction tracker for later sessions.

---

### Task 2: Run human verification and capture tuning findings

**Bead ID:** `oc-n0s`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Use the checklist and live proving scenes to run substantial human verification across supported Boxing and Flow features. Record exact findings for false positives, false negatives, reset/re-arm behavior, readability/ergonomics, and camera-framing/occlusion behavior. If Derrick supplies the movement pass directly, convert that evidence into precise repo-local notes and follow-up work items. Claim the bead at start and close it only when the human verification evidence is captured clearly enough to drive threshold-tuning work.

**Folders Created/Deleted/Modified:**
- same proving/doc paths as above

**Files Created/Deleted/Modified:**
- human verification evidence notes and any follow-up docs

**Status:** ⏳ Pending

**Results:** Pending

---

### Task 3: Design reusable feature-specific video fixture format and harness expectations

**Bead ID:** `oc-cmq`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Define how reusable Boxing/Flow video fixtures should be captured, cataloged, and consumed for repeatable automated proving. Recommend clip granularity, naming, metadata/provenance, expected outputs, and how fixtures should validate detector events and proving-scene observability surfaces without overstating what prerecorded footage can prove. Claim the bead at start and close it only when the proposed fixture format/workflow is concrete enough to implement.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/`
- documented future canonical fixture tree under `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/assets/fixtures/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/proving-scene-video-fixtures.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/proving-scene-video-fixture-template.fixture.json`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/README.md`

**Status:** ✅ Complete

**Results:** Added durable repo-local fixture-design docs: `docs/proving-scene-video-fixtures.md` and `docs/proving-scene-video-fixture-template.fixture.json`, plus a README pointer to both. The design now defines a canonical fixture tree under `.testbed/assets/fixtures/`, a strict basename convention, fixture taxonomy (`positive` / `negative` / `boundary` / `rearm` / `occlusion` / `framing`; `canonical` / `candidate` / `deprecated`), capture rules, per-fixture JSON sidecar metadata, expected automation outputs, and the three-layer validation model (detector events, reset/state truth, proving-scene observability truth). It also keeps the claims honest: fixtures are regression aids for repeatable detector/proving checks and do not replace live human verification for ergonomics, latency, framing, occlusion, or threshold confidence. This initial JSON-oriented draft is now being revised in follow-up bead `oc-7qr` so the human-authored fixture format uses YAML instead.

---

### Task 3A: Switch fixture sidecars/docs to YAML and add first human-facing example

**Bead ID:** `oc-7qr`  
**SubAgent:** `primary` (for `research` / `coder` workflow roles)  
**Role:** `research` then `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Revise the fixture design from JSON sidecars to YAML sidecars because this is human-authored fixture metadata and comments/descriptions matter. Update the docs, template, and README references accordingly, and add a concrete example fixture for Boxing / oneshot / `punch_left` / `candidate` / `positive`. Keep the naming, capture, and truth-boundary guidance intact while making the format friendlier for human authors.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/proving-scene-video-fixtures.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/proving-scene-video-fixtures-plain-language.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/proving-scene-video-fixture-template.fixture.yaml`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/assets/fixtures/boxing/punch_left/boxing__punch_left__positive__cam-cookie-logitech-c920__take-01.fixture.yaml`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/README.md`

**Status:** ✅ Complete

**Results:** Reworked the human-facing fixture authoring guidance from JSON to YAML across the technical doc, plain-language guide, and README pointers, while preserving the same naming convention, taxonomy axes, capture rules, and truth-boundary warnings from `REF-01` through `REF-05`. Added an explicit YAML rationale in the docs: fixture sidecars are human-authored and benefit from comments/descriptions during capture/review, while automation outputs can remain JSON. Replaced the old JSON starter template with `docs/proving-scene-video-fixture-template.fixture.yaml` and added the first concrete example sidecar at `.testbed/assets/fixtures/boxing/punch_left/boxing__punch_left__positive__cam-cookie-logitech-c920__take-01.fixture.yaml` for Boxing / oneshot / `punch_left` / `candidate` / `positive`. Both YAML files were sanity-checked by loading them successfully with `python3` + `yaml.safe_load`. 

---

### Task 3B: Annotate YAML fixture files with field explanations and required/optional guidance

**Bead ID:** `oc-lgt`  
**SubAgent:** `primary` (for `research` / `coder` workflow roles)  
**Role:** `research` then `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Add inline YAML comments to the human-facing fixture template and the first concrete Boxing example so Derrick can see what each field means, what it affects, and whether it is required or optional. Keep the files valid YAML and prefer practical plain-English comments over abstract schema language.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/assets/fixtures/boxing/punch_left/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/`

**Files Created/Deleted/Modified:**
- YAML template and first Boxing example sidecar

**Status:** ✅ Complete

**Results:** Added plain-English inline YAML comments directly into both the shared template and the first concrete Boxing example so human authors can understand the format without cross-referencing external docs. The comments now explain what nearly every field/section is for, whether it is required, optional, or conditionally optional, what kind of value belongs there, and why the field matters for review, regression truth, or detector interpretation. Nested areas such as `camera`, `clip_timing`, `review`, `expected_detector_behavior`, `expected_observability`, and `artifacts` now include practical authoring guidance, including notes about when empty arrays/values are appropriate for one-shot vs state fixtures. Both YAML files were re-validated successfully with `python3` + `yaml.safe_load`. Changes were committed and pushed in `18c1c52` (`docs: annotate fixture yaml fields`).

---

### Task 4: Build first reusable Boxing/Flow fixture set and automation entrypoints

**Bead ID:** `oc-qu0`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Implement the first reusable feature-specific video fixture path for Boxing and Flow. Create the agreed fixture layout, fixture metadata, and automation entrypoints/checks needed to replay or evaluate those clips against expected detector/proving outputs. Keep the claims honest: fixtures are regression aids, not a replacement for human verification. Claim the bead at start, validate the workflow, commit/push changes, and close the bead only when the first fixture slice is genuinely usable.

**Folders Created/Deleted/Modified:**
- fixture directories / docs / scripts as determined by Task 3

**Files Created/Deleted/Modified:**
- fixture assets/metadata/scripts/tests as needed

**Status:** ⏳ Pending

**Results:** Pending

---

### Task 5: QA + audit the new verification pipeline

**Bead ID:** `oc-azy`  
**SubAgent:** `primary` (for `qa` / `auditor` workflow roles)  
**Role:** `qa` then `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Independently verify that the human-verification workflow and the first video-fixture automation path are truthful, usable, and clearly bounded. Certify what the pipeline proves, what it does not prove, and whether follow-up threshold/perf work needs new beads. Use explicit notes instead of broad claims.

**Folders Created/Deleted/Modified:**
- same owning repo paths as implementation

**Files Created/Deleted/Modified:**
- notes/plan updates only unless truth fixes are required

**Status:** ⏳ Pending

**Results:** Pending

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending

**Reference Check:** Pending

**Commits:**
- Pending

**Lessons Learned:** Pending

---

*Completed on Pending*
