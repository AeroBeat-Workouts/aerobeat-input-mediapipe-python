# Unified Unfrozen Platform Runtimes for the MediaPipe Python Sidecar

**Date:** 2026-04-23  
**Status:** Accepted (documentation decision; implementation pending)  
**Agent:** Pico 🐱‍🏍

---

## Decision

Adopt a **single desktop runtime system** rooted at:

- `python_mediapipe/assets/runtimes/windows-x64/`
- `python_mediapipe/assets/runtimes/macos-x64/`
- `python_mediapipe/assets/runtimes/linux-x64/`

These directories are **generated, platform-specific, unfrozen, and gitignored**. They replace the prior idea of a separate canonical `python_mediapipe/assets/venv/` path for development while also avoiding a second top-level release-only runtime family.

Desktop development and desktop exported builds will use the **same path family** and the **same runtime contract**. They will differ by **preparation mode, manifest contents, validation expectations, and launcher behavior**, not by storing runtimes in unrelated locations.

Mobile remains out of scope for this system and should continue using the native MediaPipe path.

---

## Context

Recent cleanup already removed the stale local `.testbed/venv` and confirmed that `python_mediapipe/assets/venv/` had become the truthful desktop-side local runtime location. That cleaned up the immediate repo confusion, but it still left the architecture in an awkward state:

- one generic local venv path implied a universal runtime shape that is not actually portable
- development and release were drifting toward separate path families
- current Godot process/bootstrap code is still strongly Linux-oriented
- desktop runtime expectations were not yet expressed as an explicit per-platform contract

Derrick now prefers a cleaner architecture: one desktop runtime system, platform-keyed, unfrozen, locally prepared, and explicit about what is generated vs committed.

---

## Why one universal venv will not work

A single shared `venv/` directory cannot be the desktop portability answer because Python virtual environments are not meaningfully cross-platform artifacts.

Reasons:

1. **Executable layout differs by platform**
   - Linux/macOS typically use `bin/python`
   - Windows uses `Scripts/python.exe`

2. **Native wheels are platform-specific**
   - `mediapipe`, `opencv`, `numpy`, and transitive native dependencies resolve different wheels or compiled artifacts per OS/arch
   - wheel compatibility tags differ across Linux/macOS/Windows

3. **Interpreter bindings are path-sensitive**
   - virtualenv metadata and entrypoints encode interpreter locations and assumptions from the machine that created them

4. **Process and shell assumptions differ**
   - current repo code uses `/bin/bash`, `setsid`, `/bin/kill`, `pkill`, `fuser`, `which`, `grep`, and `/tmp`, all of which are Linux-specific or at least non-portable as written

5. **Camera/display/runtime dependencies differ**
   - desktop camera backend behavior is not uniform across the three platforms
   - current auto-start logic also assumes Linux display environment handling (`DISPLAY`, `xdpyinfo`)

So the correct unit is not “one venv for all desktops.” The correct unit is **one generated runtime per target desktop platform**.

---

## Why separate `assets/venv` is no longer preferred

`python_mediapipe/assets/venv/` was a good intermediate cleanup target because it moved ownership away from `.testbed/venv`. But as the long-term architecture, it is weaker than a platform-keyed runtime layout.

Problems with keeping a single `assets/venv/` concept:

- it implies a generic runtime instead of a platform-runtime contract
- it makes release/runtime hydration want a different top-level layout later
- it hides the reality that Windows/macOS/Linux need different prepared outputs
- it makes it harder for Godot to reason explicitly about desktop target platform
- it nudges documentation toward “the venv” when the real product concept is “the desktop runtime for this platform”

The new runtime layout is clearer: desktop runtime ownership is still under the sidecar, but it is **keyed by platform from day one**.

---

## Final folder layout

Committed durable assets:

- `python_mediapipe/main.py`
- `python_mediapipe/requirements.txt`
- `python_mediapipe/assets/models/*.task`
- runtime-preparation scripts
- runtime manifests produced as part of preparation if we decide they are useful to retain for inspection in dev; otherwise generated alongside runtime contents and treated as generated artifacts

Generated desktop runtime roots:

- `python_mediapipe/assets/runtimes/windows-x64/`
- `python_mediapipe/assets/runtimes/macos-x64/`
- `python_mediapipe/assets/runtimes/linux-x64/`

Expected contents within each runtime root (shape, not final filename list):

- platform-local Python environment
- installed Python packages for that platform
- runtime manifest describing preparation mode and validation details
- any generated helper scripts/launch wrappers needed for that platform
- sentinel/version files used by Godot/runtime validation

Non-goals:

- no single shared `python_mediapipe/assets/venv/` as the long-term architecture
- no claim that all three runtime roots already work today
- no change to mobile runtime architecture here

---

## Meaning of “unfrozen, platform-specific runtime”

In this decision, **unfrozen** means we are still shipping/running the Python sidecar as Python code plus a prepared Python runtime environment, not converting it into a PyInstaller/Nuitka-style frozen executable bundle.

Implications:

- the runtime remains inspectable and debuggable as Python
- dependencies are installed into a platform-local environment
- startup still launches Python with `main.py`
- the runtime can be regenerated from source + manifest + requirements
- platform specificity is explicit and expected

This is different from a frozen sidecar, where the runtime artifact would usually be a platform-native executable bundle with most Python packaging details hidden inside build artifacts.

---

## Dev vs release is a mode/manifest distinction, not a path distinction

Development and exported desktop builds should resolve runtimes from the same path family: `python_mediapipe/assets/runtimes/<platform>/`.

The difference should be recorded in **mode + manifest**, for example:

- `mode: dev`
- `mode: release`

Likely behavioral differences:

### Dev mode

- may create or refresh the runtime automatically
- may install from local internet/package indexes
- may permit more verbose diagnostics
- may use source-checkout-relative paths
- may tolerate missing runtime by offering a clear “prepare runtime first” path or an explicit controlled install flow

### Release mode

- should not silently hydrate from the internet unless that is later chosen as a product requirement
- should expect the runtime for the target platform to have been prepared before packaging/export or bundled as part of release assembly
- should validate manifest/version/platform match before launch
- should fail fast with user-visible, explicit error logging if the runtime is missing or invalid

This keeps one architecture while still allowing different operational policies.

---

## Runtime preparation script responsibilities

We will need a preparation command/script family that is the source of truth for building the runtime root for a specific platform.

Responsibilities should include:

1. determine target platform key (`windows-x64`, `macos-x64`, `linux-x64`)
2. create/reset the runtime directory safely
3. create the platform-local Python environment in that runtime root
4. install dependencies from `python_mediapipe/requirements.txt`
5. verify required model assets are present
6. emit a runtime manifest describing what was prepared
7. create any helper wrappers needed for launch on that platform
8. record validation evidence such as Python version, package versions, target platform, and preparation timestamp
9. optionally support `dev` vs `release` preparation modes
10. fail loudly if preparation is incomplete or platform-incompatible

Important: these scripts prepare platform runtimes; they do **not** magically make a Linux-prepared runtime portable to Windows or macOS.

---

## Godot/runtime resolution rules

The Godot side should move from “find a generic venv” to “resolve the correct desktop runtime for the current execution context.”

Required rules:

1. **Desktop-only branch**
   - only use this runtime system for desktop platforms
   - mobile should continue down the native MediaPipe path

2. **Determine execution mode**
   - detect editor/dev/source-checkout usage versus exported desktop runtime
   - mode affects validation/behavior, not the base path family

3. **Determine platform key**
   - map current runtime to `windows-x64`, `macos-x64`, or `linux-x64`

4. **Resolve runtime root**
   - look for `python_mediapipe/assets/runtimes/<platform-key>/`

5. **Resolve platform-specific Python executable**
   - Linux/macOS likely `bin/python`
   - Windows likely `Scripts/python.exe`

6. **Validate manifest and sentinel files before launch**
   - confirm platform match
   - confirm expected mode or acceptable mode
   - confirm required runtime files exist

7. **Launch using platform-appropriate process strategy**
   - current Linux process-group shell strategy is not portable as-is
   - Windows/macOS need their own startup/teardown implementations

8. **Fail fast and stop safely**
   - if runtime is missing, malformed, or platform-mismatched, log clearly and do not continue into ambiguous partial startup

---

## Desktop-only scope; mobile exclusion is intentional

This runtime system is for **desktop** sidecar delivery only.

It should cover:

- Linux desktop
- macOS desktop
- Windows desktop

It should **not** replace or blur into the mobile path. Mobile continues to use native MediaPipe integration and should not inherit the Python sidecar runtime contract by accident.

This separation matters because desktop and mobile have different packaging, execution, permissions, performance, and distribution constraints.

---

## Controlled fail-fast strategy

If a runtime is missing or bad, the system should stop clearly instead of drifting into confusing fallback behavior.

Required fail-fast behavior:

- detect missing runtime root
- detect missing Python executable within the platform runtime
- detect missing or unreadable runtime manifest
- detect platform mismatch between host/export and runtime manifest
- detect missing required model assets
- detect dependency/import failure during startup validation
- log the exact missing/bad component and expected path
- emit a stable Godot-side error/state signal
- avoid silent fallback to unrelated runtimes unless an explicitly designed fallback policy exists

Recommended stance:

- dev can optionally offer guided remediation messaging
- release should prefer immediate explicit failure over trying unrelated host-Python/system-Python fallbacks

That keeps runtime state legible and supportable.

---

## Tradeoffs vs a frozen sidecar

### Benefits of this unfrozen runtime design

- easier debugging and inspection during development
- one conceptual runtime architecture for dev and desktop release preparation
- less hidden packaging complexity than a frozen executable pipeline
- keeps Python source and dependency behavior transparent

### Costs / risks

- larger prepared runtime footprints than a tightly optimized frozen binary may achieve
- more exposure to platform-specific Python/wheel issues
- more launcher/process-management work on Windows/macOS/Linux
- export/build pipeline must prepare or bundle the correct platform runtime explicitly
- current codebase is still Linux-centric, so cross-platform support requires real engineering rather than path renaming

### Compared with a frozen sidecar

A frozen sidecar may still become the cleaner product/release strategy later if desktop shipping size, startup simplicity, or support burden dominate. But for now, the chosen direction is to first define a **truthful, unified unfrozen platform-runtime architecture** rather than splitting dev and release into separate path families prematurely.

---

## Current-state honesty

This decision does **not** mean cross-platform desktop runtime support already exists.

Current code still contains Linux-oriented assumptions, including but not limited to:

- `/bin/bash`
- `setsid`
- `/bin/kill`
- `pkill`
- `fuser`
- `/tmp`
- `which`
- `grep`
- `DISPLAY` and `xdpyinfo`
- Linux-flavored `bin/python` resolution

So this document is an architecture decision and implementation target, not a claim of current parity across Windows/macOS/Linux.

---

## Consequences

Follow-on implementation work should:

- replace `assets/venv` assumptions with platform-runtime resolution
- add runtime manifests and validation
- update `.gitignore` to ignore generated `assets/runtimes/*` contents
- add platform-specific preparation scripts
- separate Linux/macOS/Windows process start/stop behavior
- wire export/build steps so exported desktop builds know how the correct runtime arrives

Until that lands, the repo should continue to be described as Linux-proven and cross-platform-planned rather than cross-platform-complete.
