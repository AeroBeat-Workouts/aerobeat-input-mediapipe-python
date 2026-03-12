# Phase 1: Godot 4.6 Upgrade + Plugin Configuration

**Prerequisite:** Phase 0 complete  
**Next Phase:** Phase 2 (MediaPipe Provider)  
**Success Criteria:** All 3 repos open in Godot 4.6 without errors, plugins activate correctly

---

## Goal

Upgrade all three repositories to Godot 4.6 and configure plugin activation.

---

## Repository Updates

### 1. aerobeat-core

**File:** `.testbed/project.godot`

```ini
; Engine Configuration
config_version=5
config/features=PackedStringArray("4.6", "Forward Plus")
config/icon="res://icon.svg"

[application]
config/name="AeroBeat Core Testbed"

[autoload]
AeroInputProvider="*res://src/interfaces/input_provider.gd"

[debug]
gdscript/warnings/untyped_declaration=1

[editor]
version_control/plugin_name="GitPlugin"
version_control/autoload_on_startup=true

[rendering]
renderer/rendering_method="forward_plus"
```

**Also create:** `.testbed/icon.svg` (placeholder icon)

### 2. aerobeat-assembly-community

**File:** `project.godot`

```ini
; Engine Configuration
config_version=5
config/features=PackedStringArray("4.6", "Forward Plus")
config/icon="res://icon.svg"

[application]
config/name="AeroBeat Assembly"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.6", "Forward Plus")
config/icon="res://icon.svg"

[autoload]
InputManager="*res://src/input_manager.gd"

[debug]
gdscript/warnings/untyped_declaration=1

[editor_plugins]
enabled=PackedStringArray()

[gui]
theme/custom_font="res://assets/fonts/default_font.tres"

[input]
ui_accept={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194309,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":0,"button_index":0,"pressure":0.0,"pressed":false,"script":null)
]
}

[layer_names]
3d_render/layer_1="World"
3d_render/layer_2="UI"

[rendering]
renderer/rendering_method="forward_plus"
textures/vram_compression/import_etc2_astc=true
```

### 3. aerobeat-input-mediapipe-python

**File:** `.testbed/project.godot` (verify/update)

```ini
; Engine Configuration
config_version=5
config/features=PackedStringArray("4.6", "Forward Plus")
config/icon="res://icon.svg"

[application]
config/name="AeroBeat MediaPipe Testbed"

[autoload]
MediaPipeProvider="*res://src/providers/mediapipe_provider.gd"

[debug]
gdscript/warnings/untyped_declaration=1

[editor_plugins]
enabled=PackedStringArray("res://addons/gut/plugin.cfg")

[rendering]
renderer/rendering_method="forward_plus"
```

---

## Plugin Activation Matrix

| Repo | Plugin | project.godot Section | Notes |
|------|--------|----------------------|-------|
| aerobeat-core | Self | `[autoload]` | Interface autoload |
| aerobeat-assembly-community | aerobeat-core | `[editor_plugins]` | Via addon |
| aerobeat-assembly-community | aerobeat-input-mediapipe | `[editor_plugins]` | Via addon |
| mediapipe-python | aerobeat-core | `[editor_plugins]` | For tests |
| mediapipe-python | gut | `[editor_plugins]` | Test framework |

### Assembly Plugin Activation

**File:** `aerobeat-assembly-community/project.godot`

Add after submodules are set up:

```ini
[editor_plugins]
enabled=PackedStringArray("res://addons/aerobeat-core/plugin.cfg", "res://addons/aerobeat-input-mediapipe/plugin.cfg")
```

---

## .gitignore Updates

Add to all three repos:

```gitignore
# Godot 4
.godot/
.import/
export.cfg
export_presets.cfg

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/

# Build artifacts
build/
dist/
*.tmp
```

---

## Verification Script

### `verify_upgrade.gd`

```gdscript
extends SceneTree

func _init():
    print("=== Godot 4.6 Upgrade Verification ===")
    
    # Check version
    var version = Engine.get_version_info()
    print("Godot Version: ", version.major, ".", version.minor, ".", version.patch)
    
    # Verify 4.6+
    if version.major < 4 or (version.major == 4 and version.minor < 6):
        push_error("Requires Godot 4.6 or later")
        quit(1)
    
    print("✅ Version check passed")
    
    # Check key features
    print("Checking JSON parsing...")
    var json = JSON.new()
    var err = json.parse('{"test": true}')
    if err == OK:
        print("✅ JSON parsing works")
    else:
        push_error("JSON parsing failed")
        quit(1)
    
    print("Checking PackedStringArray...")
    var arr := PackedStringArray(["test", "array"])
    if arr.size() == 2:
        print("✅ PackedStringArray works")
    else:
        push_error("PackedStringArray failed")
        quit(1)
    
    print("\n=== All checks passed! ===")
    quit(0)
```

---

## Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| Import warnings | `.godot/` folder cache | Delete `.godot/` folder, reopen |
| Plugin load errors | Outdated plugin.gd | Update to @tool syntax |
| GDScript warnings | Deprecated syntax | Update yield → await |
| Missing features | Wrong config_version | Ensure config_version=5 |
| Plugin not activating | Missing `[editor_plugins]` | Add enabled list |
| Autoload error | Wrong autoload path | Check script path exists |

---

## Post-Upgrade Checklist

### aerobeat-core
- [x] `.testbed/project.godot` has `config_version=5`
- [x] `.testbed/project.godot` has `config/features=PackedStringArray("4.6", ...)`
- [x] `[autoload]` section configured
- [ ] Opens in Godot 4.6 without import errors
- [ ] Phase 0 tests still pass

### aerobeat-assembly-community
- [x] `project.godot` has `config_version=5`
- [x] `project.godot` has `config/features=PackedStringArray("4.6", ...)`
- [x] `run/main_scene` points to `res://scenes/main.tscn`
- [x] `[autoload]` section configured
- [x] `[editor_plugins]` section ready (add after submodules)
- [ ] Opens in Godot 4.6 without import errors

### aerobeat-input-mediapipe-python
- [x] `.testbed/project.godot` verified at 4.6
- [x] `[editor_plugins]` includes GUT
- [ ] Opens in Godot 4.6 without errors

---

## Truth Checkpoint

**Phase 1 Complete When:**
- [x] All 3 repos use `config_version=5`
- [x] All 3 repos specify `features=PackedStringArray("4.6", ...)`
- [ ] All projects open in Godot 4.6 without errors
- [x] `.gitignore` files updated in all repos
- [ ] Phase 0 tests still pass
- [x] Verification script runs successfully

---

## Key Changes from Expert Review

| Issue | Fix Applied |
|-------|-------------|
| **No plugin activation** | Added `[editor_plugins]` sections |
| **No autoload config** | Added `[autoload]` sections |
| **No .gitignore** | Added comprehensive .gitignore template |
| **Missing verification** | Added upgrade verification script |

---

*See 00-MASTER-ROADMAP.md for context*
*Updated with expert recommendations 2026-02-06*
