# Phase 0: Core Interface

**Prerequisite:** None  
**Next Phase:** Phase 1 (Godot 4.6 Upgrade)  
**Success Criteria:** All core unit tests pass

---

## Goal

Create the `AeroInputProvider` interface and supporting enums in `aerobeat-core`. This is the foundation - everything else builds on this contract.

---

## Files to Create

### 1. `aerobeat-core/src/interfaces/input_provider.gd`

```gdscript
class_name AeroInputProvider
extends Node
## Abstract interface for all input strategies
## All input drivers must implement this interface

enum TrackingMode {
    MODE_2D,      # 2D viewport coordinates (x, y)
    MODE_3D       # 3D world coordinates (x, y, z)
}

enum BodyTrackFlags {
    NONE = 0,
    HEAD = 1,
    LEFT_HAND = 2,
    RIGHT_HAND = 4,
    LEFT_FOOT = 8,
    RIGHT_FOOT = 16,
    ALL = 31
}

# Core interface methods - must be implemented by all providers
func get_left_hand_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
    push_error("AeroInputProvider: get_left_hand_position() must be overridden")
    return null

func get_right_hand_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
    push_error("AeroInputProvider: get_right_hand_position() must be overridden")
    return null

func get_head_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
    push_error("AeroInputProvider: get_head_position() must be overridden")
    return null

func get_left_foot_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
    push_error("AeroInputProvider: get_left_foot_position() must be overridden")
    return null

func get_right_foot_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
    push_error("AeroInputProvider: get_right_foot_position() must be overridden")
    return null

func set_tracking_mode(mode: TrackingMode) -> void:
    push_error("AeroInputProvider: set_tracking_mode() must be overridden")

func set_body_track_flags(flags: int) -> void:
    push_error("AeroInputProvider: set_body_track_flags() must be overridden")

func is_tracking() -> bool:
    push_error("AeroInputProvider: is_tracking() must be overridden")
    return false

func get_tracking_confidence(body_part: int) -> float:
    push_error("AeroInputProvider: get_tracking_confidence() must be overridden")
    return 0.0
```

### 2. `aerobeat-core/plugin.cfg`

```ini
[plugin]
name="AeroBeat Core"
description="Core interfaces and utilities for AeroBeat ecosystem"
author="AeroBeat Team"
version="1.0.0"
script="plugin.gd"
```

### 3. `aerobeat-core/plugin.gd`

```gdscript
@tool
extends EditorPlugin

func _enter_tree():
    # Core is interface-only, no scene additions needed
    pass

func _exit_tree():
    pass
```

---

## Tests to Create

### `aerobeat-core/test/unit/test_input_provider.gd`

```gdscript
extends GutTest

func test_aero_input_provider_is_abstract():
    var provider = AeroInputProvider.new()
    
    var result = provider.get_left_hand_position()
    assert_null(result, "Abstract method should return null")

func test_tracking_mode_enum_values():
    assert_eq(AeroInputProvider.TrackingMode.MODE_2D, 0)
    assert_eq(AeroInputProvider.TrackingMode.MODE_3D, 1)

func test_body_track_flags_bitfield():
    assert_eq(AeroInputProvider.BodyTrackFlags.NONE, 0)
    assert_eq(AeroInputProvider.BodyTrackFlags.HEAD, 1)
    assert_eq(AeroInputProvider.BodyTrackFlags.LEFT_HAND, 2)
    assert_eq(AeroInputProvider.BodyTrackFlags.RIGHT_HAND, 4)
    
    var combined = AeroInputProvider.BodyTrackFlags.HEAD | AeroInputProvider.BodyTrackFlags.LEFT_HAND
    assert_eq(combined, 3, "Combined flags should work")
```

---

## Directory Structure After

```
aerobeat-core/
├── src/
│   └── interfaces/
│       └── input_provider.gd
├── test/
│   └── unit/
│       └── test_input_provider.gd
├── plugin.cfg
└── plugin.gd
```

---

## Implementation Checklist

Subagents: Mark off each task as completed.

### Files to Create
- [x] `aerobeat-core/src/interfaces/input_provider.gd` created
- [x] `aerobeat-core/plugin.cfg` created
- [x] `aerobeat-core/plugin.gd` created
- [x] `aerobeat-core/test/unit/test_input_provider.gd` created

### Directory Structure
- [x] `aerobeat-core/src/interfaces/` directory exists
- [x] `aerobeat-core/test/unit/` directory exists

### Code Verification
- [x] `input_provider.gd` defines `AeroInputProvider` class
- [x] `AeroInputProvider` extends `Node`
- [x] `TrackingMode` enum defined with `MODE_2D` and `MODE_3D`
- [x] `BodyTrackFlags` enum defined with all body parts
- [x] All interface methods push errors (abstract behavior)

### Plugin Setup
- [x] `plugin.cfg` has correct name and version
- [x] `plugin.gd` uses `@tool` annotation
- [x] No errors when plugin loads in Godot

### Tests
- [x] Test file extends `GutTest`
- [x] `test_aero_input_provider_is_abstract()` passes
- [x] `test_tracking_mode_enum_values()` passes
- [x] `test_body_track_flags_bitfield()` passes

### Verification
- [x] Project opens in Godot 4.6 without errors
- [x] All unit tests pass
- [x] No GDScript warnings

---

**Truth Checkpoint:** If all checkboxes above are marked complete, Phase 0 is complete.

---

*See 00-MASTER-ROADMAP.md for context*
