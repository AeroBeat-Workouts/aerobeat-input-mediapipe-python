# AeroBeat MediaPipe Python

MediaPipe pose tracking for AeroBeat using a Python sidecar plus Godot glue.

This repo is **partially migrated** into the broader AeroBeat input-provider contract:

- it now has a root addon entrypoint at `input_provider.gd`
- it includes a thin assembly-facing `AeroInputProvider` adapter for lifecycle + polling access
- it **does not** yet implement the full contract surface such as gesture callbacks, haptics, velocity, or 6DOF transforms
- provider registration / consumer wiring in `aerobeat-assembly-community` remains follow-on work in that repo, not hidden here

## Repo layout

- `input_provider.gd` — assembly-facing addon entrypoint
- `src/` — Godot-side implementation used by the local testbed
- `python_mediapipe/` — Python sidecar and Python-only test scripts
- `.testbed/` — local Godot testbed project with relative repo-local symlinks
- `tests/` — repo-local Godot test scripts

## Current truthful runtime state

### What the repo can do today

- run the Python sidecar directly from this repo
- auto-create a local `venv/` and install `python_mediapipe/requirements.txt` from the Godot testbed
- receive pose landmarks in Godot and expose head/hand/foot polling helpers
- use either a webcam (`--camera 0`) or a video path (`--camera path/to/file.mp4`) when launching the Python sidecar directly

### What is still manual / partial

- **MediaPipe task model files are not bundled or auto-downloaded by this repo**
- the Godot auto-start flow installs Python packages, but it still expects the required `pose_landmarker_*.task` file to already exist in the repo root
- the assembly-community repo still owns addon registration / consumer wiring
- the root `input_provider.gd` is an adapter layer, not a claim that the full contract is finished

## Requirements

- Python 3.8+
- a local virtual environment or system Python capable of installing:
  - `mediapipe>=0.10.0`
  - `opencv-python`
  - `numpy`
- one of the following model files in the **repo root**:
  - `pose_landmarker_lite.task`
  - `pose_landmarker_full.task`
  - `pose_landmarker_heavy.task`

The testbed defaults to `model_complexity = 1`, so by default it expects:

```text
pose_landmarker_full.task
```

## Python setup

There is **no** `./install_deps.sh` in the current tracked repo state.

### Manual setup

From the repo root:

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r python_mediapipe/requirements.txt
```

### Testbed auto-install

The `.testbed/` Godot project can create `./venv/` automatically and install Python packages from:

```text
python_mediapipe/requirements.txt
```

That auto-install does **not** fetch the MediaPipe `.task` model files for you.

## Running the Python sidecar directly

From the repo root:

```bash
source venv/bin/activate
python3 python_mediapipe/main.py --camera 0 --show-window
```

Run against a video file instead of a live camera:

```bash
source venv/bin/activate
python3 python_mediapipe/main.py --camera .testbed/assets/videos/boxing.mp4 --show-window
```

Useful options:

```bash
# Use a different model file already present in the repo root
python3 python_mediapipe/main.py --camera 0 --model-complexity 0
python3 python_mediapipe/main.py --camera 0 --model-complexity 1
python3 python_mediapipe/main.py --camera 0 --model-complexity 2

# Enable binary UDP output explicitly
python3 python_mediapipe/main.py --camera 0 --binary-protocol
```

> Note: the current tracked CLI/runtime defaults still lean toward JSON unless you explicitly opt into binary behavior in code or launch flags. Keep docs and runtime expectations aligned with the repo you actually have checked out.

## Running the Godot testbed

The local testbed lives under `.testbed/`.

It expects these repo-local links:

- `.testbed/src -> ../src`
- `.testbed/python_mediapipe -> ../python_mediapipe`
- `.testbed/addons/aerobeat-core -> ../../../aerobeat-core`

Open the testbed in Godot 4.6:

```bash
godot --path .testbed
```

The testbed will:

- look for Python
- auto-install Python dependencies into `./venv/` if needed
- fail early with a clear error if the required `.task` model file is missing
- start the Python sidecar and connect the local provider when everything is available

If auto-start fails, the test scene includes manual recovery guidance that points back to this repo root.

## Test assets

Canonical repo-local test videos now live under:

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

```bash
python3 python_mediapipe/test_filter.py
```

### Python performance test runner

```bash
python3 python_mediapipe/test_runner.py \
  --video .testbed/assets/videos/boxing.mp4 \
  --output test_report.json
```

## Provider contract stance

This repo now exposes an assembly-facing `input_provider.gd`, but the current implementation is intentionally narrow and honest:

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

## License

Mozilla Public License 2.0 (MPL 2.0)
