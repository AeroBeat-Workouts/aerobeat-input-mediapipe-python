# Phase 4: Assembly Integration + Submodule Setup

**Prerequisite:** Phase 3 complete  
**Next Phase:** Phase 5 (Integration Tests)  
**Success Criteria:** Assembly integration tests pass, submodules configured

---

## Goal

Create the Assembly's InputManager, main scene, configure git submodules, and wire everything together.

---

## Submodule Directory Structure

The assembly uses git submodules to include core and input driver:

```
aerobeat-assembly-community/
├── addons/
│   ├── aerobeat-core/              # git submodule → ../aerobeat-core
│   ├── aerobeat-input-mediapipe/   # git submodule → ../aerobeat-input-mediapipe-python
│   └── gut/                        # git submodule or copied
├── src/
│   ├── main.gd
│   ├── input_manager.gd
│   └── scenes/
│       └── main_scene.gd
├── scenes/
│   └── main.tscn
└── project.godot
```

### Submodule Configuration

**File:** `.gitmodules`

```ini
[submodule "addons/aerobeat-core"]
    path = addons/aerobeat-core
    url = ../aerobeat-core
    branch = main

[submodule "addons/aerobeat-input-mediapipe"]
    path = addons/aerobeat-input-mediapipe
    url = ../aerobeat-input-mediapipe-python
    branch = main
```

---

## Files to Create

### 1. `aerobeat-assembly-community/src/input_manager.gd`

```gdscript
class_name InputManager
extends Node
## Manages input providers and strategy switching

signal provider_changed(provider_name: String)
signal provider_registered(name: String, provider: AeroInputProvider)
signal tracking_started()
signal tracking_stopped()
signal tracking_failed(error: String)

var _providers: Dictionary = {}  # name -> provider instance
var _current_provider: AeroInputProvider = null
var _current_name: String = ""
var _is_initializing := false

func register_provider(name: String, provider: AeroInputProvider) -> void:
    if _providers.has(name):
        push_warning("Overwriting existing provider: " + name)
    
    _providers[name] = provider
    provider_registered.emit(name, provider)

func unregister_provider(name: String) -> void:
    if _providers.has(name):
        if _current_provider == _providers[name]:
            stop_camera()
            _current_provider = null
            _current_name = ""
        _providers.erase(name)

func has_provider(name: String) -> bool:
    return _providers.has(name)

func get_provider_names() -> Array:
    return _providers.keys()

func set_strategy(name: String) -> bool:
    if not _providers.has(name):
        push_error("Unknown input provider: " + name)
        return false
    
    # Stop current if switching
    if _current_provider != null and _current_provider != _providers[name]:
        stop_camera()
    
    _current_provider = _providers[name]
    _current_name = name
    provider_changed.emit(name)
    return true

func get_current_strategy() -> String:
    return _current_name

func initialize_camera() -> bool:
    if _current_provider == null:
        tracking_failed.emit("No input provider selected")
        return false
    
    if _is_initializing:
        tracking_failed.emit("Already initializing")
        return false
    
    _is_initializing = true
    
    # Check if provider has start method (it should)
    if not _current_provider.has_method("start"):
        _is_initializing = false
        tracking_failed.emit("Provider does not support starting")
        return false
    
    # Start the provider (this starts UDP server + Python sidecar)
    var success = _current_provider.start()
    _is_initializing = false
    
    if success:
        tracking_started.emit()
    else:
        tracking_failed.emit("Failed to start provider")
    
    return success

func stop_camera() -> void:
    if _current_provider and _current_provider.has_method("stop"):
        _current_provider.stop()
    tracking_stopped.emit()

func is_tracking() -> bool:
    if _current_provider and _current_provider.has_method("is_tracking"):
        return _current_provider.is_tracking()
    return false

func get_provider() -> AeroInputProvider:
    return _current_provider

func _notification(what: int) -> void:
    if what == NOTIFICATION_EXIT_TREE:
        stop_camera()
```

### 2. `aerobeat-assembly-community/src/main.gd`

```gdscript
extends Node
## Main entry point for AeroBeat Assembly

@onready var input_manager: InputManager = $InputManager
@onready var ui: CanvasLayer = $UI
@onready var status_label: Label = $UI/TrackingStatus

func _ready():
    print("AeroBeat Assembly started")
    print("Godot version: ", Engine.get_version_info())
    
    # Connect signals
    input_manager.tracking_started.connect(_on_tracking_started)
    input_manager.tracking_stopped.connect(_on_tracking_stopped)
    input_manager.tracking_failed.connect(_on_tracking_failed)
    
    # Register input providers
    _register_input_providers()
    
    # Select MediaPipe strategy
    if input_manager.has_provider("mediapipe"):
        print("Initializing MediaPipe...")
        input_manager.set_strategy("mediapipe")
        
        # Check dependencies first
        var provider = input_manager.get_provider()
        if provider.has_method("check_dependencies"):
            var deps = provider.check_dependencies()
            if not deps.python_found:
                _show_error("Python not found. Install Python 3.8+")
                return
            if not deps.mediapipe_installed:
                _show_error("MediaPipe not installed. Run: pip install -r requirements.txt")
                return
        
        # Initialize camera
        var success = input_manager.initialize_camera()
        if not success:
            _show_error("Failed to initialize camera")
    else:
        push_warning("MediaPipe provider not available")
        status_label.text = "Tracking: Provider not available"

func _register_input_providers():
    # Register MediaPipe provider
    var mediapipe = MediaPipeProvider.new()
    mediapipe.name = "MediaPipeProvider"
    add_child(mediapipe)
    input_manager.register_provider("mediapipe", mediapipe)
    print("Registered MediaPipe provider")

func _on_tracking_started():
    print("Tracking started")
    status_label.text = "Tracking: Active"

func _on_tracking_stopped():
    print("Tracking stopped")
    status_label.text = "Tracking: Off"

func _on_tracking_failed(error: String):
    push_error("Tracking failed: " + error)
    status_label.text = "Tracking: Error - " + error

func _show_error(message: String):
    push_error(message)
    status_label.text = "Error: " + message

func _exit_tree():
    input_manager.stop_camera()
```

### 3. `aerobeat-assembly-community/scenes/main.tscn`

```
[gd_scene load_steps=5 format=3 uid="uid://main_scene"]

[ext_resource type="Script" path="res://src/main.gd" id="1_main"]
[ext_resource type="Script" path="res://src/input_manager.gd" id="2_input"]

[sub_resource type="LabelSettings" id="1"]
font_size = 24
font_color = Color(1, 1, 1, 1)
outline_size = 2
outline_color = Color(0, 0, 0, 1)

[node name="Main" type="Node"]
script = ExtResource("1_main")

[node name="InputManager" type="Node" parent="."]
script = ExtResource("2_input")

[node name="UI" type="CanvasLayer" parent="."]

[node name="TrackingStatus" type="Label" parent="UI"]
offset_left = 20.0
offset_top = 20.0
offset_right = 300.0
offset_bottom = 60.0
text = "Tracking: Initializing..."
label_settings = SubResource("1")

[node name="DebugInfo" type="Label" parent="UI"]
offset_left = 20.0
offset_top = 70.0
offset_right = 400.0
offset_bottom = 200.0
text = "Debug info will appear here"
label_settings = SubResource("1")
```

---

## Setup Script

### `aerobeat-assembly-community/setup_dev.py`

```python
#!/usr/bin/env python3
"""Setup development environment for AeroBeat Assembly"""

import subprocess
import os
import sys

def run_command(cmd, cwd=None):
    """Run a shell command and return success status"""
    print(f">>> {cmd}")
    result = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True)
    if result.stdout:
        print(result.stdout)
    if result.stderr:
        print(result.stderr, file=sys.stderr)
    return result.returncode == 0

def setup_submodules():
    """Initialize and update git submodules"""
    print("Setting up git submodules...")
    
    # Check if we're in a git repo
    if not os.path.exists(".git"):
        print("Warning: Not a git repository. Submodules may not work correctly.")
        return False
    
    submodules = [
        ("../aerobeat-core", "addons/aerobeat-core"),
        ("../aerobeat-input-mediapipe-python", "addons/aerobeat-input-mediapipe")
    ]
    
    for source, dest in submodules:
        if not os.path.exists(dest):
            print(f"Adding submodule: {source} -> {dest}")
            if not run_command(f'git submodule add "{source}" "{dest}"'):
                print(f"Failed to add submodule {source}")
                return False
    
    # Initialize and update
    if not run_command("git submodule update --init --recursive"):
        print("Failed to update submodules")
        return False
    
    print("Submodules configured successfully")
    return True

def verify_structure():
    """Verify the expected directory structure exists"""
    print("Verifying directory structure...")
    
    required_paths = [
        "addons/aerobeat-core/src/interfaces/input_provider.gd",
        "addons/aerobeat-input-mediapipe/src/providers/mediapipe_provider.gd",
        "src",
        "scenes",
        "test"
    ]
    
    all_exist = True
    for path in required_paths:
        if os.path.exists(path):
            print(f"  ✓ {path}")
        else:
            print(f"  ✗ {path} (will be created)")
            all_exist = False
    
    return all_exist

def create_directories():
    """Create necessary directories"""
    dirs = ["src", "scenes", "test/unit", "test/integration"]
    for d in dirs:
        os.makedirs(d, exist_ok=True)
        print(f"Created: {d}")

def update_project_plugins():
    """Update project.godot to enable plugins"""
    print("Updating project.godot plugin configuration...")
    
    plugin_section = """
[editor_plugins]
enabled=PackedStringArray("res://addons/aerobeat-core/plugin.cfg", "res://addons/aerobeat-input-mediapipe/plugin.cfg")
"""
    
    project_file = "project.godot"
    if not os.path.exists(project_file):
        print(f"Error: {project_file} not found")
        return False
    
    with open(project_file, "r") as f:
        content = f.read()
    
    # Check if already has editor_plugins
    if "[editor_plugins]" in content:
        print("Plugin configuration already exists")
        return True
    
    # Append plugin section
    with open(project_file, "a") as f:
        f.write(plugin_section)
    
    print("Plugin configuration added")
    return True

def main():
    print("=== AeroBeat Assembly Setup ===\n")
    
    # Create directories
    create_directories()
    
    # Setup submodules
    if not setup_submodules():
        print("\nWarning: Submodule setup had issues. You may need to configure manually.")
    
    # Verify structure
    verify_structure()
    
    # Update plugins
    update_project_plugins()
    
    print("\n=== Setup complete ===")
    print("Next steps:")
    print("1. Open this project in Godot 4.6")
    print("2. Install Python dependencies: cd addons/aerobeat-input-mediapipe && ./install_deps.sh")
    print("3. Run the project!")

if __name__ == "__main__":
    main()
```

---

## Tests to Create

### `test/integration/test_assembly_integration.gd`

```gdscript
extends GutTest

var main_scene

func before_each():
    main_scene = preload("res://scenes/main.tscn").instantiate()
    add_child(main_scene)
    # Wait for _ready
    await get_tree().process_frame

func after_each():
    main_scene.queue_free()

func test_main_scene_instantiates():
    assert_not_null(main_scene)

func test_input_manager_exists():
    var im = main_scene.get_node_or_null("InputManager")
    assert_not_null(im)
    assert_is(im, InputManager)

func test_input_manager_has_mediapipe_provider():
    var im = main_scene.get_node("InputManager")
    assert_true(im.has_provider("mediapipe"))

func test_set_strategy_changes_provider():
    var im = main_scene.get_node("InputManager")
    var success = im.set_strategy("mediapipe")
    assert_true(success)
    assert_not_null(im.get_provider())
    assert_eq(im.get_current_strategy(), "mediapipe")

func test_provider_is_mediapipe_type():
    var im = main_scene.get_node("InputManager")
    im.set_strategy("mediapipe")
    var provider = im.get_provider()
    assert_is(provider, MediaPipeProvider)
    assert_is(provider, AeroInputProvider)

func test_tracking_signals_exist():
    var im = main_scene.get_node("InputManager")
    
    var started = false
    var stopped = false
    
    im.tracking_started.connect(func(): started = true)
    im.tracking_stopped.connect(func(): stopped = true)
    
    # Just verify signals are connected
    assert_has_signal(im, "tracking_started")
    assert_has_signal(im, "tracking_stopped")
```

---

## Implementation Checklist

Subagents: Mark off each task as completed.

### Submodule Configuration
- [x] `aerobeat-assembly-community/.gitmodules` created
- [x] Submodule entry for `addons/aerobeat-core` added
- [x] Submodule entry for `addons/aerobeat-input-mediapipe` added
- [ ] `git submodule update --init --recursive` succeeds
- [ ] `addons/aerobeat-core/` directory exists with files
- [ ] `addons/aerobeat-input-mediapipe/` directory exists with files

### InputManager
- [x] `aerobeat-assembly-community/src/input_manager.gd` created
- [x] `InputManager` class extends `Node`
- [x] `_providers` dictionary defined
- [x] `register_provider()` method works
- [x] `unregister_provider()` method works
- [x] `has_provider()` method works
- [x] `set_strategy()` method works
- [x] `get_current_strategy()` returns correct name
- [x] `initialize_camera()` starts provider
- [x] `stop_camera()` stops provider
- [x] `is_tracking()` delegates to provider
- [x] `get_provider()` returns current provider
- [x] Signals defined: `provider_changed`, `tracking_started`, `tracking_stopped`, `tracking_failed`
- [x] `_notification(NOTIFICATION_EXIT_TREE)` calls stop_camera()

### Main Scene
- [x] `aerobeat-assembly-community/src/main.gd` created
- [x] `main.gd` extends `Node`
- [x] `@onready` vars for InputManager and UI
- [x] `_ready()` registers providers
- [x] `_ready()` selects MediaPipe strategy
- [x] `_ready()` calls `check_dependencies()` before init
- [x] `_ready()` handles missing Python gracefully
- [x] `_ready()` handles missing MediaPipe gracefully
- [x] `_register_input_providers()` creates MediaPipeProvider
- [x] `_on_tracking_started()` updates UI
- [x] `_on_tracking_stopped()` updates UI
- [x] `_on_tracking_failed()` shows error
- [x] `_exit_tree()` stops camera
- [x] `aerobeat-assembly-community/scenes/main.tscn` created
- [x] Scene has InputManager node
- [x] Scene has UI with status label

### Setup Script
- [x] `aerobeat-assembly-community/setup_dev.py` created
- [x] Creates necessary directories
- [x] `setup_submodules()` initializes git submodules
- [x] `verify_structure()` checks all paths exist
- [x] `update_project_plugins()` adds `[editor_plugins]` to project.godot

### Test Files
- [x] `test/integration/test_assembly_integration.gd` created
- [ ] `test_main_scene_instantiates()` passes
- [ ] `test_input_manager_exists()` passes
- [ ] `test_input_manager_has_mediapipe_provider()` passes
- [ ] `test_set_strategy_changes_provider()` passes
- [ ] `test_provider_is_mediapipe_type()` passes
- [ ] `test_tracking_signals_exist()` passes

### Verification
- [ ] `setup_dev.py` runs without errors
- [ ] All submodules initialized correctly
- [ ] Project opens in Godot 4.6 without errors
- [ ] Main scene instantiates
- [ ] InputManager registers MediaPipe provider
- [ ] All integration tests pass
- [ ] No errors when running main scene

**Status: File creation complete. Remaining items require submodule initialization and runtime verification.**

---

## Truth Checkpoint

**Phase 4 Complete When:** All checkboxes above are marked complete.

---

## Key Changes from Expert Review

| Issue | Fix Applied |
|-------|-------------|
| **Submodule structure unclear** | Added explicit `.gitmodules` and directory tree |
| **No dependency check** | Added `check_dependencies()` call in main.gd |
| **Missing error signals** | Added `tracking_failed` signal to InputManager |
| **No setup automation** | Enhanced `setup_dev.py` with verification |
| **Weak error handling** | Added dependency validation before camera init |

---

*See 00-MASTER-ROADMAP.md for context*
*Updated with expert recommendations 2026-02-06*
