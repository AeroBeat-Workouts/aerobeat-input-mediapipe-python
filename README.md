# AeroBeat MediaPipe Python

MediaPipe pose tracking for AeroBeat using a Python sidecar plus Godot glue.

This repo is **partially migrated** into the broader AeroBeat input-provider contract:

- it now has an addon entrypoint at `src/input_provider.gd`
- it includes a thin assembly-facing `AeroInputProvider` adapter for lifecycle + polling access
- it **does not** yet implement the full contract surface such as gesture callbacks, haptics, velocity, or 6DOF transforms
- provider registration / consumer wiring in `aerobeat-assembly-community` remains follow-on work in that repo, not hidden here

## Repo layout

- `src/input_provider.gd` — assembly-facing addon entrypoint
- `src/` — Godot-side implementation used by the local testbed and downstream addon installs
- `python_mediapipe/` — Python sidecar, runtime-preparation helper, and Python-only test scripts
- `python_mediapipe/assets/models/` — committed MediaPipe `.task` model assets used by the sidecar
- `python_mediapipe/assets/runtimes/` — generated desktop runtime roots under the unified runtime contract, **not committed**
  - `python_mediapipe/assets/runtimes/linux-x64/` — current host's prepared Linux dev runtime on this machine
  - `python_mediapipe/assets/runtimes/macos-x64/` — scaffolded target location for macOS desktop runtimes
  - `python_mediapipe/assets/runtimes/windows-x64/` — scaffolded target location for Windows desktop runtimes
- `.testbed/` — hidden Godot workbench project restored via GodotEnv
- `.testbed/tests/` — repo-local Godot automated test scripts
- `.testbed/addons.jsonc` — committed dev/test dependency contract for the workbench

## Unified desktop runtime system

Desktop sidecar execution now uses **one platform-keyed runtime family** instead of a generic `python_mediapipe/assets/venv/` path:

- `python_mediapipe/assets/runtimes/linux-x64/`
- `python_mediapipe/assets/runtimes/macos-x64/`
- `python_mediapipe/assets/runtimes/windows-x64/`

These runtime roots are:

- generated locally
- intentionally gitignored
- platform-specific
- still **unfrozen** (Python code + prepared Python environment, not a packaged binary)
- shared between desktop dev and desktop export concepts by **path family**, with differences expressed through runtime mode / manifest validation rather than unrelated folders

The current runtime contract is enforced by:

- `python_mediapipe/runtime_paths.py` on the Python side
- `python_mediapipe/prepare_runtime.py` for runtime preparation / scaffolding
- `src/runtime/desktop_sidecar_runtime.gd` for Godot-side runtime resolution and validation
- `src/process/desktop_sidecar_launcher.gd` for platform-aware launch / teardown structure

Mobile is intentionally outside this contract and should continue using the native MediaPipe path.

## GodotEnv development flow

This repo now uses the AeroBeat GodotEnv package convention for the local workbench.

- Canonical dev/test manifest: `.testbed/addons.jsonc`
- Installed dev/test addons: `.testbed/addons/`
- GodotEnv cache: `.testbed/.addons/`
- Hidden workbench project: `.testbed/project.godot`
- Repo-local unit tests: `.testbed/tests/`

The repo root remains the package/published boundary for downstream consumers. Day-to-day development, debugging, and validation happen from the hidden `.testbed/` workbench with GodotEnv restoring this repo itself, the sibling `aerobeat-input-core` repo (mounted under the historical addon key/path `aerobeat-core` for compatibility), and GUT.

### Restore dev/test dependencies

From the repo root:

```bash
cd .testbed
godotenv addons install
```

That restores:

- `aerobeat-input-mediapipe-python` from `..` as a local symlinked package
- `aerobeat-input-core` from `../../aerobeat-input-core`, mounted under the compatibility addon key/path `aerobeat-core`
- `gut` from its upstream Git source into `.testbed/addons/gut`

Manual `.testbed/src`, `.testbed/python_mediapipe`, and repo-owned `.testbed/addons/aerobeat-core` links are no longer the repo contract and should not be recreated by hand. GodotEnv now restores the compatibility mount from the sibling `aerobeat-input-core` repo.

## Current truthful runtime state

### What the repo can do today

- run the Python sidecar directly from this repo on Linux using the prepared `linux-x64` runtime
- create and validate the current host's repo-owned Linux dev runtime at `python_mediapipe/assets/runtimes/linux-x64/`
- scaffold the macOS and Windows runtime roots / manifests for contract work, without claiming they are host-validated here
- receive pose landmarks in Godot and expose head/hand/foot polling helpers
- use either a webcam (`--camera 0`) or a video path (`--camera path/to/file.mp4`) when launching the Python sidecar directly
- look up MediaPipe models from committed assets under `python_mediapipe/assets/models/`
- fail fast in Godot when the expected desktop runtime manifest, sentinel, Python executable, or model assets are missing or invalid

### What is still manual / partial

- the assembly-community repo still owns addon registration / consumer wiring
- `src/input_provider.gd` is an adapter layer, not a claim that the full contract is finished
- desktop export/build integration is **not** yet automated here; exported builds are expected to use the same `assets/runtimes/<platform>/` family, but packaging / hydration policy still needs follow-on work
- macOS and Windows runtime prep / launch branches are present as architecture scaffolding, **not** as validated desktop parity claims
- full end-to-end runtime still depends on legitimate local prerequisites such as a working camera / display stack and Python package install success

## Platform validation status

Treat the repo as:

- **Linux desktop:** validated on the current host for runtime prep, direct sidecar runs, Godot runtime resolution, and platform-aware launcher integration
- **macOS desktop:** path/layout/launcher scaffolding exists in code, but runtime prep and lifecycle behavior are **not validated here**
- **Windows desktop:** path/layout/launcher scaffolding exists in code, but runtime prep and lifecycle behavior are **not validated here**
- **Mobile:** intentionally excluded from this Python desktop runtime system

That means the repo is currently **Linux-proven, macOS/Windows-scaffolded**.

## Requirements

- Python 3.8+
- ability to prepare the current host's local desktop runtime under `python_mediapipe/assets/runtimes/<platform>/`
- committed MediaPipe model assets under `python_mediapipe/assets/models/`:
  - `pose_landmarker_lite.task`
  - `pose_landmarker_full.task`
  - `pose_landmarker_heavy.task`

The testbed defaults to `model_complexity = 1`, so by default it uses:

```text
python_mediapipe/assets/models/pose_landmarker_full.task
```

## Runtime preparation expectations

This repo now treats the Python runtime as a **sidecar-owned generated asset**, not a random user-managed environment.

Canonical current contract:

- runtime family root: `python_mediapipe/assets/runtimes/`
- current host dev runtime on this machine: `python_mediapipe/assets/runtimes/linux-x64/`
- Linux runtime-local Python executable on this machine: `python_mediapipe/assets/runtimes/linux-x64/venv/bin/python`
- runtime manifest: `python_mediapipe/assets/runtimes/<platform>/runtime-manifest.json`
- runtime sentinel: `python_mediapipe/assets/runtimes/<platform>/.runtime-ready`
- durable committed assets: Python code + `.task` models
- non-durable generated assets: prepared platform runtime contents

`python_mediapipe/prepare_runtime.py` is the canonical helper for preparing or scaffolding a runtime root.

### Linux dev preparation on this host

From the repo root:

```bash
python3 python_mediapipe/prepare_runtime.py --platform linux-x64 --mode dev --create-venv --validate
python_mediapipe/assets/runtimes/linux-x64/venv/bin/pip install -r python_mediapipe/requirements.txt
python3 python_mediapipe/prepare_runtime.py --platform linux-x64 --mode dev --validate
```

Notes:

- `--create-venv` only creates a real venv for the **current host platform**
- the helper may scaffold foreign-platform manifest/sentinel files, but that is **not** the same as producing a working foreign-platform runtime on this Linux host
- source-checkout/dev runs expect a prepared local runtime for the current platform
- release/export flows should also resolve the same `assets/runtimes/<platform>/` family, but this repo does not yet automate final packaging/bundling policy

## Running the Python sidecar directly

From the repo root:

```bash
python_mediapipe/assets/runtimes/linux-x64/venv/bin/python python_mediapipe/main.py --camera 0 --show-window
```

Run against a video file instead of a live camera:

```bash
python_mediapipe/assets/runtimes/linux-x64/venv/bin/python python_mediapipe/main.py --camera .testbed/assets/videos/boxing.mp4 --show-window
```

Useful options:

```bash
# Switch model asset selection (loaded from python_mediapipe/assets/models/)
python_mediapipe/assets/runtimes/linux-x64/venv/bin/python python_mediapipe/main.py --camera 0 --model-complexity 0
python_mediapipe/assets/runtimes/linux-x64/venv/bin/python python_mediapipe/main.py --camera 0 --model-complexity 1
python_mediapipe/assets/runtimes/linux-x64/venv/bin/python python_mediapipe/main.py --camera 0 --model-complexity 2

# Serialization mode
python_mediapipe/assets/runtimes/linux-x64/venv/bin/python python_mediapipe/main.py --camera 0 --binary-protocol
python_mediapipe/assets/runtimes/linux-x64/venv/bin/python python_mediapipe/main.py --camera 0 --json-protocol

# Runtime optimization flags that are now wired into the sidecar
python_mediapipe/assets/runtimes/linux-x64/venv/bin/python python_mediapipe/main.py --camera 0 --preprocess-size 480
python_mediapipe/assets/runtimes/linux-x64/venv/bin/python python_mediapipe/main.py --camera 0 --udp-batch-size 2
python_mediapipe/assets/runtimes/linux-x64/venv/bin/python python_mediapipe/main.py --camera 0 --use-roi --roi-size 320 --roi-padding 50
```

Notes:

- the sidecar defaults to JSON output unless you opt into `--binary-protocol`
- `--preprocess-size` resizes frames before inference
- `--udp-batch-size` uses the built-in batched UDP sender
- `--use-roi` enables predictive ROI cropping based on recent pose history

## Running the Godot workbench

The local workbench lives under `.testbed/`.

Restore its dependencies first:

```bash
cd .testbed
godotenv addons install
cd ..
```

Then open it in Godot 4.6:

```bash
godot --path .testbed
```

The workbench will:

- load this repo from `res://addons/aerobeat-input-mediapipe-python/`
- fail early with a clear error if the required `.task` model file is missing from `python_mediapipe/assets/models/`
- resolve the unified platform-keyed desktop runtime family and fail fast if the prepared runtime is missing or invalid
- use the Linux launcher path that is validated on this host; other desktop launcher branches exist in code but are not claimed as validated here

If auto-start fails on this host, the test scene under `.testbed/scenes/` includes manual recovery guidance pointing back to the repo root and `python_mediapipe/assets/runtimes/linux-x64/`.

## Desktop build/export guidance

Current truthful guidance:

- desktop exports should conceptually use the same runtime family under `python_mediapipe/assets/runtimes/<platform>/`
- runtime selection is platform-keyed (`linux-x64`, `macos-x64`, `windows-x64`) and mode-aware (`dev` vs `release`)
- release mode should validate the runtime manifest / sentinel / platform match before launch rather than silently falling back to system Python
- this repo does **not** yet provide a finished export-packaging pipeline that prepares and bundles each desktop runtime automatically
- do **not** describe macOS or Windows desktop export support as verified until those runtime branches are actually prepared and tested on those hosts

## Test assets

Canonical repo-local test videos live under:

```text
.testbed/assets/videos/
```

Examples:

- `.testbed/assets/videos/boxing.mp4`
- `.testbed/assets/videos/female_boxer.mp4`
- `.testbed/assets/videos/group_dance.mp4`
- `.testbed/assets/videos/hiphop_dance.mp4`
- `.testbed/assets/videos/punching_bag.mp4`
- `.testbed/assets/videos/shadow_boxing.mp4`

The older tracked `.testbed/videos/` layout is no longer the canonical location.

## Validation helpers

### Python filter test

If you use the repo-local sidecar runtime on this Linux host, prefer `python_mediapipe/assets/runtimes/linux-x64/venv/bin/python` for Python-side checks.

```bash
python_mediapipe/assets/runtimes/linux-x64/venv/bin/python python_mediapipe/test_filter.py
```

### Python performance test runner

```bash
python_mediapipe/assets/runtimes/linux-x64/venv/bin/python python_mediapipe/test_runner.py \
  --video .testbed/assets/videos/boxing.mp4 \
  --output test_report.json
```

## Provider contract stance

This repo now exposes an assembly-facing `src/input_provider.gd` via `plugin.cfg`, but the current implementation is intentionally narrow and honest:

- `start()` / `stop()` / `is_tracking()` are adapted
- head/hand/foot position polling is adapted
- lower-body support is reported because foot polling exists
- gesture callbacks are **not** implemented here yet
- haptics are **not** implemented here yet
- velocity / rotation / full `tracking_updated` spatial output are **not** implemented here yet

If you need full contract parity, plan that work explicitly instead of assuming it already landed.

## Follow-on work that belongs elsewhere

Do not silently hide these in this repo:

- assembly-community provider registration
- consumer wiring / input-manager hookup
- cross-repo validation that the adapter is used correctly in an assembly project

Those belong in consuming repos such as `aerobeat-assembly-community`.

## Validation notes

- `.testbed/addons.jsonc` is the committed dev/test dependency contract.
- The workbench consumes this package from the repo root (`subfolder: "/"`) via GodotEnv rather than manual `.testbed` symlinks.
- The local core contract currently comes from the sibling `aerobeat-input-core` repo while still mounting under `res://addons/aerobeat-core/` for compatibility with current repo code.
- CI follows the same GodotEnv restore/import/GUT flow as local workbench validation.
- The repo now commits the required `.task` model assets instead of expecting them to appear separately in the repo root.

## License

Mozilla Public License 2.0 (MPL 2.0)
