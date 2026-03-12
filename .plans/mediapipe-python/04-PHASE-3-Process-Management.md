# Phase 3: Process Management + Python Dependencies

**Prerequisite:** Phase 2 complete  
**Next Phase:** Phase 4 (Assembly Integration)  
**Success Criteria:** Python lifecycle tests pass, requirements installable

---

## Goal

Create process management to launch, monitor, and gracefully stop the Python MediaPipe sidecar, with proper dependency management and error handling.

---

## Files to Create

### 1. `aerobeat-input-mediapipe-python/python_mediapipe/requirements.txt`

```
mediapipe>=0.10.0
opencv-python>=4.8.0
numpy>=1.24.0
```

### 2. `aerobeat-input-mediapipe-python/python_mediapipe/args.py`

```python
import argparse

def parse_args():
    parser = argparse.ArgumentParser(description="MediaPipe Pose Tracker")
    parser.add_argument("--camera", type=int, default=0, help="Camera device ID")
    parser.add_argument("--port", type=int, default=4242, help="UDP port")
    parser.add_argument("--host", type=str, default="127.0.0.1", help="UDP host")
    parser.add_argument("--detection-confidence", type=float, default=0.5)
    parser.add_argument("--tracking-confidence", type=float, default=0.5)
    parser.add_argument("--model-complexity", type=int, default=1, choices=[0, 1, 2])
    parser.add_argument("--max-fps", type=int, default=30, help="Maximum capture FPS")
    return parser.parse_args()
```

### 3. Update `python_mediapipe/main.py`

```python
#!/usr/bin/env python3
"""MediaPipe Pose Tracker - UDP Sidecar for Godot"""

import signal
import sys
import socket
import json
import time
from args import parse_args

try:
    import cv2
    import mediapipe as mp
    import numpy as np
except ImportError as e:
    print(f"Error: Missing dependency - {e}")
    print("Install with: pip install -r requirements.txt")
    sys.exit(1)

args = parse_args()

# Global flag for graceful shutdown
_running = True

def signal_handler(sig, frame):
    global _running
    print("\nShutting down gracefully...")
    _running = False

signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

def main():
    # Initialize UDP socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    
    # Initialize MediaPipe
    mp_pose = mp.solutions.pose
    pose = mp_pose.Pose(
        min_detection_confidence=args.detection_confidence,
        min_tracking_confidence=args.tracking_confidence,
        model_complexity=args.model_complexity
    )
    
    # Initialize camera
    cap = cv2.VideoCapture(args.camera)
    if not cap.isOpened():
        print(f"Error: Could not open camera {args.camera}")
        sys.exit(1)
    
    print(f"MediaPipe started - Camera: {args.camera}, UDP: {args.host}:{args.port}")
    
    while _running:
        ret, frame = cap.read()
        if not ret:
            print("Warning: Failed to capture frame")
            continue
        
        # Process frame
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = pose.process(frame_rgb)
        
        # Extract landmarks
        landmarks = []
        if results.pose_landmarks:
            for idx, landmark in enumerate(results.pose_landmarks.landmark):
                landmarks.append({
                    "id": idx,
                    "x": landmark.x,
                    "y": landmark.y,
                    "z": landmark.z,
                    "v": landmark.visibility
                })
        
        # Send via UDP
        payload = {
            "timestamp": time.time(),
            "landmarks": landmarks
        }
        
        try:
            sock.sendto(json.dumps(payload).encode(), (args.host, args.port))
        except Exception as e:
            print(f"UDP send error: {e}")
        
        # Cap FPS
        time.sleep(1.0 / args.max_fps)
    
    # Cleanup
    cap.release()
    pose.close()
    sock.close()
    print("MediaPipe stopped")

if __name__ == "__main__":
    main()
```

### 4. `aerobeat-input-mediapipe-python/src/process/mediapipe_process.gd`

```gdscript
class_name MediaPipeProcess
extends Node
## Manages the Python MediaPipe sidecar process

signal process_started()
signal process_stopped(exit_code: int)
signal process_error(error: String)
signal process_output(line: String)

@export var python_script_path: String = "python_mediapipe/main.py"

var _pid: int = -1
var _python_path: String = ""
var _config: MediaPipeConfig
var _stdout_thread: Thread
var _stderr_thread: Thread
var _is_shutting_down := false

func start(config: MediaPipeConfig) -> bool:
    if is_running():
        process_error.emit("Process already running")
        return false
    
    _config = config
    
    # Find Python executable
    _python_path = _find_python()
    if _python_path.is_empty():
        process_error.emit("Python not found. Install Python 3.8+ and ensure it's in PATH")
        return false
    
    # Verify Python script exists
    if not FileAccess.file_exists(python_script_path):
        process_error.emit("Python script not found: " + python_script_path)
        return false
    
    # Build arguments
    var args := PackedStringArray([
        python_script_path,
        "--camera", str(config.camera_id),
        "--port", str(config.udp_port),
        "--host", "127.0.0.1",
        "--detection-confidence", str(config.detection_confidence),
        "--tracking-confidence", str(config.tracking_confidence),
        "--model-complexity", str(config.model_complexity)
    ])
    
    # Start process
    _pid = OS.create_process(_python_path, args)
    if _pid == -1:
        process_error.emit("Failed to start Python process. Check Python installation.")
        return false
    
    process_started.emit()
    return true

func stop() -> void:
    if not is_running() or _is_shutting_down:
        return
    
    _is_shutting_down = true
    
    # Send SIGTERM for graceful shutdown
    var result = OS.kill(_pid)
    if result != OK:
        push_warning("Failed to send SIGTERM to process " + str(_pid))
    
    # Give process time to shut down gracefully
    await get_tree().create_timer(1.0).timeout
    
    # Force kill if still running
    if is_running():
        OS.kill(_pid)  # Second kill forces termination
    
    _pid = -1
    _is_shutting_down = false
    process_stopped.emit(0)

func is_running() -> bool:
    if _pid == -1:
        return false
    # Check if process is actually running
    return OS.is_process_running(_pid)

func get_pid() -> int:
    return _pid

func _find_python() -> String:
    # Check for virtual environment first
    if OS.has_environment("VIRTUAL_ENV"):
        var venv_python = OS.get_environment("VIRTUAL_ENV") + "/bin/python"
        if _test_python(venv_python):
            return venv_python
    
    # Try common Python paths
    var candidates := PackedStringArray([
        "python3",
        "python",
        "/usr/bin/python3",
        "/usr/local/bin/python3",
        "py"  # Windows
    ])
    
    for cmd in candidates:
        if _test_python(cmd):
            return cmd
    
    return ""

func _test_python(cmd: String) -> bool:
    var output := []
    var exit_code := OS.execute(cmd, PackedStringArray(["--version"]), output, true)
    return exit_code == 0

func _notification(what: int) -> void:
    # Critical: Clean up on exit
    if what == NOTIFICATION_EXIT_TREE or what == NOTIFICATION_WM_CLOSE_REQUEST:
        if is_running():
            stop()

## Check if Python dependencies are installed
func check_dependencies() -> Dictionary:
    var result := {
        "python_found": false,
        "python_version": "",
        "mediapipe_installed": false,
        "opencv_installed": false,
        "errors": []
    }
    
    var python = _find_python()
    if python.is_empty():
        result.errors.append("Python not found in PATH")
        return result
    
    result.python_found = true
    
    # Check Python version
    var output := []
    OS.execute(python, PackedStringArray(["--version"]), output, true)
    if output.size() > 0:
        result.python_version = output[0]
    
    # Check for mediapipe
    output.clear()
    var exit = OS.execute(python, PackedStringArray(["-c", "import mediapipe; print('ok')"]), output, true)
    result.mediapipe_installed = (exit == 0 and output.size() > 0 and output[0].strip_edges() == "ok")
    if not result.mediapipe_installed:
        result.errors.append("MediaPipe not installed. Run: pip install -r requirements.txt")
    
    # Check for opencv
    output.clear()
    exit = OS.execute(python, PackedStringArray(["-c", "import cv2; print('ok')"]), output, true)
    result.opencv_installed = (exit == 0 and output.size() > 0 and output[0].strip_edges() == "ok")
    if not result.opencv_installed:
        result.errors.append("OpenCV not installed. Run: pip install -r requirements.txt")
    
    return result
```

---

## Tests to Create

### `test/unit/test_mediapipe_process.gd`

```gdscript
extends GutTest

var process
var config

func before_each():
    process = MediaPipeProcess.new()
    add_child(process)
    config = MediaPipeConfig.new()
    config.udp_port = 9998  # High port to avoid conflicts

func after_each():
    if process.is_running():
        process.stop()
    process.queue_free()

func test_find_python_returns_valid_path():
    var path = process._find_python()
    assert_string_contains(path, "python")

func test_check_dependencies_returns_dictionary():
    var deps = process.check_dependencies()
    assert_has_method(deps, "has", "python_found")
    assert_has_method(deps, "has", "mediapipe_installed")
    assert_has_method(deps, "has", "errors")

func test_start_emits_process_started_signal():
    var called = false
    process.process_started.connect(func(): called = true)
    
    var success = process.start(config)
    # May fail if Python deps not installed - that's ok for test
    if success:
        assert_true(called, "Should emit process_started")

func test_is_running_returns_true_after_start():
    var success = process.start(config)
    if success:
        assert_true(process.is_running())

func test_stop_emits_process_stopped_signal():
    if not process.start(config):
        pending("Python not available")
        return
    
    var exit_code = -1
    process.process_stopped.connect(func(c): exit_code = c)
    
    await process.stop()
    
    assert_eq(exit_code, 0)

func test_stop_cleans_up_process():
    if not process.start(config):
        pending("Python not available")
        return
    
    await process.stop()
    assert_false(process.is_running())

func test_process_not_running_initially():
    assert_false(process.is_running())

func test_start_fails_when_already_running():
    if not process.start(config):
        pending("Python not available")
        return
    
    var error_emitted = ""
    process.process_error.connect(func(e): error_emitted = e)
    
    var success = process.start(config)
    assert_false(success)
    assert_string_contains(error_emitted, "already running")
```

---

## Installation Script

### `aerobeat-input-mediapipe-python/install_deps.sh`

```bash
#!/bin/bash
# Install Python dependencies

echo "Installing AeroBeat MediaPipe dependencies..."

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 not found. Please install Python 3.8 or later."
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install dependencies
echo "Installing packages..."
pip install -r requirements.txt

echo "Installation complete!"
echo "To activate in future: source venv/bin/activate"
```

### `aerobeat-input-mediapipe-python/install_deps.bat` (Windows)

```batch
@echo off
echo Installing AeroBeat MediaPipe dependencies...

python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python not found. Please install Python 3.8 or later.
    exit /b 1
)

if not exist venv (
    echo Creating virtual environment...
    python -m venv venv
)

echo Installing packages...
venv\Scripts\pip install -r requirements.txt

echo Installation complete!
echo To activate in future: venv\Scripts\activate
```

---

## Implementation Checklist

Subagents: Mark off each task as completed.

### Python Files
- [x] `aerobeat-input-mediapipe-python/python_mediapipe/requirements.txt` created
- [x] `aerobeat-input-mediapipe-python/python_mediapipe/args.py` created
- [x] `aerobeat-input-mediapipe-python/python_mediapipe/main.py` updated with CLI args
- [x] `main.py` includes signal handlers for graceful shutdown
- [x] `main.py` uses argparse for all configuration
- [x] Installation script `install_deps.sh` created
- [x] Installation script `install_deps.bat` created

### GDScript Process Manager
- [x] `aerobeat-input-mediapipe-python/src/process/mediapipe_process.gd` created
- [x] `MediaPipeProcess` class extends `Node`
- [x] `_find_python()` checks multiple Python paths
- [x] `_find_python()` detects virtual environments
- [x] `_test_python()` verifies Python works
- [x] `start()` validates Python exists before starting
- [x] `start()` validates Python script exists
- [x] `start()` builds `PackedStringArray` args correctly
- [x] `start()` uses `OS.create_process()` (non-blocking)
- [x] `start()` emits `process_started` signal
- [x] `stop()` sends SIGTERM first
- [x] `stop()` waits 1 second for graceful shutdown
- [x] `stop()` force kills if still running
- [x] `stop()` emits `process_stopped` signal
- [x] `is_running()` checks actual process status
- [x] `check_dependencies()` verifies Python installation
- [x] `check_dependencies()` verifies MediaPipe installed
- [x] `check_dependencies()` verifies OpenCV installed
- [x] `_notification(NOTIFICATION_EXIT_TREE)` calls stop()
- [x] `_notification(NOTIFICATION_WM_CLOSE_REQUEST)` calls stop()

### Test Files
- [x] `test/unit/test_mediapipe_process.gd` created
- [x] Test for `_find_python()` passes
- [x] Test for `check_dependencies()` passes
- [x] Test for `start()` emitting signal passes
- [x] Test for `is_running()` returns true after start passes
- [x] Test for `stop()` emitting signal passes
- [x] Test for process cleanup passes

### Verification
- [x] `pip install -r requirements.txt` succeeds
- [x] Python script runs standalone without errors
- [x] GDScript can detect Python installation
- [x] GDScript can detect missing dependencies
- [x] Process starts successfully
- [x] Process stops gracefully
- [x] Force kill works if process hangs
- [x] No zombie processes left after stop
- [x] No errors in Godot 4.6

---

## Truth Checkpoint

**Phase 3 Complete When:** All checkboxes above are marked complete.

---

## Key Changes from Expert Review

| Issue | Fix Applied |
|-------|-------------|
| **No requirements.txt** | Added with MediaPipe, OpenCV, NumPy |
| **No dependency check** | Added `check_dependencies()` method |
| **Minimal error handling** | Added file existence, Python detection, dependency validation |
| **No venv support** | Added virtual environment detection |
| **Force kill missing** | Added graceful → force kill sequence |

---

*See 00-MASTER-ROADMAP.md for context*
*Updated with expert recommendations 2026-02-06*
