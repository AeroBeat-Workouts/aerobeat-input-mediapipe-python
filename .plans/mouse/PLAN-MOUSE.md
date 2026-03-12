# AeroBeat Mouse Input Support Plan

**Date:** 2026-02-08  
**Godot Version:** 4.6  
**Status:** Planning Phase

---

## Target Repository

**Local Path:** `~/Documents/GitHub/AeroBeat/aerobeat-input-mouse/`

**GitHub:** `https://github.com/derrickbarra/aerobeat-input-mouse`

---

## Overview

This document outlines the implementation plan for Mouse-based input support in AeroBeat, providing a low-barrier alternative to camera tracking and controllers for boxing gameplay. Mouse input enables quick "pick up and play" access for users without specialized hardware.

---

## Mouse-Based Punch Mechanics

### Core Concept: Click + Drag Gestures

| Punch Type | Gesture | Description |
|------------|---------|-------------|
| **Left Jab** | Left-click + short drag up | Quick forward motion |
| **Right Jab** | Right-click + short drag up | Quick forward motion |
| **Left Hook** | Left-click + drag left-to-right | Horizontal sweeping motion |
| **Right Hook** | Right-click + drag right-to-left | Horizontal sweeping motion |
| **Left Uppercut** | Left-click + drag down-to-up | Upward scooping motion |
| **Right Uppercut** | Right-click + drag down-to-up | Upward scooping motion |

### Gesture Recognition Algorithm

```gdscript
class_name MousePunchDetector
extends Node

signal punch_detected(hand: String, punch_type: String, power: float)

var _drag_start_pos: Vector2
var _drag_start_time: float
var _is_dragging: bool = false
var _active_button: MouseButton

const MIN_DRAG_DISTANCE: float = 30.0  # pixels
const MAX_DRAG_TIME: float = 0.3  # seconds
const DIRECTION_THRESHOLD: float = 0.7  # cosine similarity

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        _handle_mouse_button(event)
    elif event is InputEventMouseMotion and _is_dragging:
        _track_drag(event)

func _handle_mouse_button(event: InputEventMouseButton) -> void:
    if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
        if event.pressed:
            _start_drag(event.position, event.button_index)
        else:
            _end_drag(event.position)

func _start_drag(pos: Vector2, button: MouseButton) -> void:
    _drag_start_pos = pos
    _drag_start_time = Time.get_time_dict_from_system()["second"]
    _is_dragging = true
    _active_button = button

func _end_drag(end_pos: Vector2) -> void:
    if not _is_dragging:
        return
    
    var drag_vector = end_pos - _drag_start_pos
    var drag_distance = drag_vector.length()
    var drag_time = Time.get_time_dict_from_system()["second"] - _drag_start_time
    
    if drag_distance >= MIN_DRAG_DISTANCE and drag_time <= MAX_DRAG_TIME:
        var punch = _classify_punch(drag_vector, _active_button)
        var power = clamp(drag_distance / 200.0, 0.3, 1.0)
        punch_detected.emit(punch.hand, punch.type, power)
    
    _is_dragging = false

func _classify_punch(vector: Vector2, button: MouseButton) -> Dictionary:
    var normalized = vector.normalized()
    var hand = "left" if button == MOUSE_BUTTON_LEFT else "right"
    
    # Check directions using dot product
    var up = Vector2.UP
    var right = Vector2.RIGHT
    
    if normalized.dot(up) > DIRECTION_THRESHOLD:
        return {"hand": hand, "type": "jab"}
    elif normalized.dot(right) > DIRECTION_THRESHOLD and hand == "left":
        return {"hand": hand, "type": "hook"}
    elif normalized.dot(-right) > DIRECTION_THRESHOLD and hand == "right":
        return {"hand": hand, "type": "hook"}
    elif normalized.y < -0.5 and abs(normalized.x) < 0.5:
        return {"hand": hand, "type": "uppercut"}
    
    return {"hand": hand, "type": "jab"}  # default
```

---

## Alternative: Velocity-Based Punch Detection

### Rapid Click Detection

For users who prefer not to drag, rapid clicking can simulate punches:

```gdscript
# Rapid click = power punch
const CLICK_INTERVAL: float = 0.15  # seconds
var _last_click_time: float = 0.0

func _detect_rapid_clicks() -> void:
    var current_time = Time.get_time_dict_from_system()["second"]
    var interval = current_time - _last_click_time
    
    if interval < CLICK_INTERVAL:
        # Rapid click detected - boost power
        punch_detected.emit(hand, "power_punch", 1.0)
    else:
        # Normal click
        punch_detected.emit(hand, "jab", 0.5)
    
    _last_click_time = current_time
```

---

## Guard/Block Mechanics

### Implementation Options

| Method | Input | Behavior |
|--------|-------|----------|
| **Right-Click Hold** | Hold RMB | Guard stance (blocks face) |
| **Scroll Wheel** | Scroll up/down | Toggle guard on/off |
| **Spacebar Hybrid** | Hold Space | Guard (works with WASD movement) |
| **Mouse Back Button** | Mouse 4 | Quick guard toggle |

### Scroll-Based Guard Intensity

```gdscript
# Scroll up = increase guard height (high guard)
# Scroll down = decrease guard height (body guard)
func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            _guard_height = clamp(_guard_height + 0.1, 0.0, 1.0)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _guard_height = clamp(_guard_height - 0.1, 0.0, 1.0)
```

---

## Movement Controls

### WASD + Mouse Hybrid

| Action | Input | Description |
|--------|-------|-------------|
| Dodge Left | A key or mouse to left edge | Quick left dodge |
| Dodge Right | D key or mouse to right edge | Quick right dodge |
| Lean Back | S key | Defensive retreat |
| Lean Forward | W key | Aggressive advance |

### Screen-Edge Dodge

```gdscript
const EDGE_THRESHOLD: int = 50  # pixels from screen edge

func _check_edge_dodge(mouse_pos: Vector2, screen_size: Vector2) -> void:
    if mouse_pos.x < EDGE_THRESHOLD:
        dodge_detected.emit("left")
    elif mouse_pos.x > screen_size.x - EDGE_THRESHOLD:
        dodge_detected.emit("right")
```

---

## Godot 4.6 InputMap Configuration

### Project Settings → Input Map

```
mouse_left_punch    → Mouse Button Left (click)
mouse_right_punch   → Mouse Button Right (click)
mouse_guard         → Mouse Button Right (hold)
mouse_guard_toggle  → Mouse Button Middle
mouse_dodge_left    → Mouse Position Left Edge
mouse_dodge_right   → Mouse Position Right Edge
```

### Code-Based Registration

```gdscript
extends Node

func _ready():
    _register_mouse_actions()

func _register_mouse_actions():
    # Left punch
    InputMap.add_action("mouse_left_punch")
    var left_event = InputEventMouseButton.new()
    left_event.button_index = MOUSE_BUTTON_LEFT
    InputMap.action_add_event("mouse_left_punch", left_event)
    
    # Right punch
    InputMap.add_action("mouse_right_punch")
    var right_event = InputEventMouseButton.new()
    right_event.button_index = MOUSE_BUTTON_RIGHT
    InputMap.action_add_event("mouse_right_punch", right_event)
```

---

## Accessibility Considerations

### Motor Accessibility

| Feature | Implementation |
|---------|---------------|
| **Click instead of drag** | Option for rapid-click punching |
| **Larger gesture zones** | Configurable drag distance threshold |
| **Reduced precision mode** | Broader direction detection angles |
| **Sticky guard** | Toggle mode instead of hold |
| **One-handed mode** | Single button + directional keys |

### Visual Accessibility

- **Cursor size options**: Large, high-contrast cursor
- **Trail visualization**: Show drag path for feedback
- **Screen flash**: Visual confirmation of punch detection
- **Guard indicator**: Visual cue when guard is active

### Cognitive Accessibility

- **Simplified controls**: Just click = punch, no gestures
- **Extended timing**: Longer windows for gesture completion
- **Visual tutorials**: Animated demonstrations of each punch type

---

## Implementation Architecture

### Directory Structure

```
aerobeat-input-mouse/
├── src/
│   ├── mouse_driver.gd           # Main driver entry
│   ├── gesture_detector.gd       # Drag gesture recognition
│   ├── velocity_detector.gd      # Rapid click detection
│   ├── mouse_mapper.gd           # Action abstraction
│   └── accessibility/
│       ├── large_cursor.gd
│       ├── gesture_trail.gd
│       └── one_handed_mode.gd
├── test/
│   ├── test_gesture_detector.gd
│   ├── test_mouse_driver.gd
│   └── test_accessibility.gd
└── assets/
    └── cursors/
        ├── default.png
        ├── large.png
        ├── high_contrast.png
        └── boxing_gloves/
            ├── left_glove.png
            └── right_glove.png
```

### Core Classes

```gdscript
# MouseDriver - Main entry point
class_name MouseDriver
extends Node

@export var enable_gestures: bool = true
@export var enable_accessibility: bool = false
@export var cursor_style: CursorStyle = CursorStyle.DEFAULT

var _gesture_detector: GestureDetector
var _velocity_detector: VelocityDetector
var _accessibility: AccessibilityManager

enum CursorStyle { DEFAULT, LARGE, HIGH_CONTRAST, GLOVES }

func _ready():
    _gesture_detector = GestureDetector.new()
    _velocity_detector = VelocityDetector.new()
    _accessibility = AccessibilityManager.new()
    
    if enable_gestures:
        _gesture_detector.punch_detected.connect(_on_punch_detected)
    
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_punch_detected(hand: String, punch_type: String, power: float) -> void:
    Events.mouse_punch_detected.emit(hand, punch_type, power)
    _trigger_haptic_feedback(power)

func _trigger_haptic_feedback(power: float) -> void:
    # Screen shake for punch feedback
    var shake_intensity = power * 2.0
    Events.camera_shake_requested.emit(shake_intensity, 0.1)
```

---

## Testing Strategy

### Unit Tests (GUT)

```gdscript
# test_gesture_detector.gd
extends GutTest

var _detector: GestureDetector

func before_each():
    _detector = GestureDetector.new()
    add_child(_detector)

func test_jab_detection():
    watch_signals(_detector)
    
    # Simulate upward drag
    _detector._start_drag(Vector2(500, 500), MOUSE_BUTTON_LEFT)
    _detector._end_drag(Vector2(500, 400))  # Up 100px
    
    assert_signal_emitted_with_parameters(
        _detector, 
        "punch_detected", 
        ["left", "jab", 0.5]
    )

func test_hook_direction():
    watch_signals(_detector)
    
    # Simulate left-to-right hook
    _detector._start_drag(Vector2(400, 500), MOUSE_BUTTON_LEFT)
    _detector._end_drag(Vector2(600, 500))  # Right 200px
    
    assert_signal_emitted_with_parameters(
        _detector,
        "punch_detected",
        ["left", "hook", 1.0]
    )
```

### Manual Testing Checklist

- [ ] All punch types detect correctly
- [ ] Guard toggle/hold works
- [ ] WASD movement integrates smoothly
- [ ] Edge dodge triggers appropriately
- [ ] Accessibility modes function
- [ ] One-handed mode usable
- [ ] Cursor styles change correctly
- [ ] Screen shake feedback feels good

---

## Dependencies

### Godot Built-in
- `Input` singleton
- `InputEventMouseButton`
- `InputEventMouseMotion`

### AeroBeat Core
- `aerobeat-core` (Input contracts)
- `aerobeat-ui` (Cursor themes)

### Optional
- `aerobeat-accessibility` (Assist features)

---

## Platform Considerations

| Platform | Support | Notes |
|----------|---------|-------|
| Windows | ⭐⭐⭐⭐⭐ | Full mouse support |
| macOS | ⭐⭐⭐⭐⭐ | Full mouse support |
| Linux | ⭐⭐⭐⭐⭐ | Full mouse support |
| Web | ⭐⭐⭐⭐ | May need pointer lock for edge detection |
| Mobile | ⭐⭐ | Touch-as-mouse fallback |

---

## Future Enhancements

1. **Multi-touch gestures**: Two-finger swipe for special moves
2. **Pressure sensitivity**: For styluses with pressure
3. **Mouse acceleration**: Power boost for fast swipes
4. **AI training mode**: Adaptive difficulty based on input patterns
5. **Custom cursor workshop**: User-uploaded cursor themes

---

## Related Documents

- `PLAN-KEYBOARD.md` - Keyboard input planning
- `PLAN-GAMEPAD.md` - Gamepad input planning
- `aerobeat-core` Input Contract Specification
- `INTEGRATION-ARCHITECTURE.md` - Input system integration
