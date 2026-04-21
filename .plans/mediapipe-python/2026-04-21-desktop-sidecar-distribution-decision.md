# AeroBeat MediaPipe Python

**Date:** 2026-04-21  
**Status:** Draft  
**Agent:** Pico 🐱‍🏍

---

## Goal

Choose and lock the desktop distribution strategy for the MediaPipe Python sidecar so AeroBeat desktop builds no longer depend on an unmanaged host Python environment.

---

## Overview

The current repo is now in a good, truthful state for development: MediaPipe model assets are committed under `python_mediapipe/assets/models/`, the sidecar-owned generated environment lives under `python_mediapipe/assets/venv/`, and the local Godot workbench validates the repaired contract. That solves the repo-shape/runtime-truth problem, but it does **not** yet answer the product/distribution question for shipped desktop builds.

The real decision is not “Python or no Python,” but **where the runtime burden lives** and **when it is hydrated**. We have four viable families of solutions: commit runtime artifacts directly in source control, store runtime artifacts outside git (for example S3) and hydrate them at build time, hydrate them at first app launch through a launcher/bootstrapper, or freeze the sidecar into a platform-native executable and treat that as the shipped runtime artifact. Each option shifts complexity between repo size, CI/build engineering, end-user experience, offline behavior, and debugging/iteration ergonomics.

Next session should be a decision session, not another vague exploration pass. The output we want is a locked architectural choice plus explicit follow-on implementation constraints for desktop, while preserving the current `mediapipe-native` direction for mobile. We should leave that session with one chosen path, one rejected-path rationale section, and a concrete implementation phase plan.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Completed runtime-contract repair plan and final results | `.plans/mediapipe-python/2026-04-21-sidecar-audit-and-repair.md` |
| `REF-02` | Current repo contract after the repair | `README.md` |
| `REF-03` | Current Godot auto-start/runtime path behavior | `src/autostart_manager.gd` |
| `REF-04` | Current Python sidecar runtime layout | `python_mediapipe/` |
| `REF-05` | Current committed model asset location | `python_mediapipe/assets/models/` |
| `REF-06` | Current sidecar-owned generated env location | `python_mediapipe/assets/venv/` |
| `REF-07` | Existing mobile-native direction to preserve as separate from desktop | `../aerobeat-input-mediapipe-native/` |

---

## Decision To Make Next Session

Choose one desktop-side distribution strategy and lock it in:

1. **Repo-committed portable Python runtime**
   - commit per-platform Python runtimes + packages into source control
   - likely largest repo footprint
   - simplest “everything is in repo” mental model

2. **S3-hosted portable Python runtime hydrated at build time**
   - keep runtime artifacts out of git
   - builder fetches exact platform runtime before export
   - exported build ships with bundled Python runtime

3. **S3-hosted frozen sidecar hydrated at build time**
   - builder fetches per-platform frozen sidecar binaries before export
   - likely cleanest shipped desktop runtime contract
   - smaller shipped artifacts than full portable Python

4. **Launcher/bootstrap download on user machine**
   - smallest installer / build payload
   - highest end-user/bootstrap complexity
   - stronger online dependency and support burden

---

## Decision Criteria

Use these criteria explicitly when choosing:

- **End-user experience**
  - does the desktop build “just run” offline?
  - is first-run download/setup acceptable?

- **Build determinism**
  - can local/CI builds resolve the exact runtime artifact reliably?
  - do we have checksum/version pinning?

- **Repo hygiene**
  - how much binary weight lands in source control?
  - do we need Git LFS or avoid it entirely?

- **Artifact size per desktop platform**
  - frozen sidecar estimate: roughly ~150–300 MB/platform
  - bundled portable Python estimate: roughly ~450–750 MB/platform
  - current local Linux evidence: `python_mediapipe/assets/venv/` ~532 MB, models ~44 MB

- **Operational complexity**
  - who owns runtime packaging, storage, caching, invalidation, and updates?
  - is the burden on source control, builder, launcher, or release pipeline?

- **Debuggability / developer ergonomics**
  - how easy is it to inspect/patch the runtime during development?
  - can dev mode and shipped mode stay cleanly separated?

- **Platform separation**
  - desktop can choose Python/frozen-sidecar strategies
  - mobile should continue using native MediaPipe (`aerobeat-input-mediapipe-native`)

---

## Tasks

### Task 1: Build the decision matrix

**Bead ID:** `Pending`  
**SubAgent:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Prepare a concise decision matrix comparing repo-committed runtime, S3 build-time hydrated portable runtime, S3 build-time hydrated frozen sidecar, and launcher-time hydration. Score them against end-user experience, build determinism, repo hygiene, artifact size, operational complexity, debuggability, and fit with the existing mobile-native split. Include one recommended path and one runner-up, but do not lock the decision yourself.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- decision-support notes if needed

**Status:** ⏳ Pending

**Results:** Reserved for next session.

---

### Task 2: Define the preferred dev vs shipped runtime split

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Based on the selected desktop distribution strategy, define the clean separation between development-time runtime behavior and exported-build runtime behavior. Explicitly state how Godot should resolve the sidecar in source checkouts versus shipped builds, and which paths/artifacts are authoritative in each mode.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- decision plan only unless explicitly approved for implementation

**Status:** ⏳ Pending

**Results:** Reserved for next session.

---

### Task 3: Lock the chosen artifact strategy

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**References:** `REF-01`, `REF-07`  
**Prompt:** Capture the final chosen strategy and the explicit reasons for rejecting the alternatives. If the path uses S3/build-time hydration, define manifest/checksum/cache expectations. If the path uses frozen sidecars, define per-platform artifact naming and builder handoff. If the path uses bundled portable Python, define repo/LFS/artifact storage policy. The result should be a locked decision with follow-on implementation guidance, not code changes yet.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- this plan file

**Status:** ⏳ Pending

**Results:** Reserved for next session.

---

## Final Results

**Status:** ⚠️ Pending Decision

**What We Built:** A next-session decision plan for choosing the desktop MediaPipe sidecar distribution strategy.

**Reference Check:**
- `REF-01` anchors this decision plan to the now-complete runtime-contract repair work.
- `REF-02` through `REF-06` describe the current truthful repo state that future desktop packaging must preserve or supersede.
- `REF-07` keeps the desktop decision from accidentally collapsing the separate mobile-native direction.

**Commits:**
- None yet

**Lessons Learned:**
- The repo/runtime cleanup is complete enough that the next step should be a deliberate architecture decision, not more exploratory drift.
- Desktop and mobile should stay intentionally separated here.
- The real tradeoff is where runtime complexity lives: git, builder, launcher, or frozen artifact pipeline.

---

*Drafted on 2026-04-21*
