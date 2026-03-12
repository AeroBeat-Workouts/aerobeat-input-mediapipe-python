# AeroBeat GamePad Input Support Plan

**Date:** 2026-02-07  
**Godot Version:** 4.6  
**Status:** Planning Phase  

---

## Target Repository

**Local Path:** `~/Documents/GitHub/AeroBeat/aerobeat-input-gamepad/`
**GitHub:** `https://github.com/derrickbarra/aerobeat-input-gamepad`

---

## Overview

This document outlines the implementation plan for GamePad/Controller input support in AeroBeat, providing a controller-based alternative to camera tracking for boxing gameplay.

---

## Input Mapping Scheme

### Primary Button Layout (Xbox-style naming)

| Action | Xbox | PlayStation | Generic |
|--------|------|-------------|---------|
| Left Punch | X Button | □ (Square) | Button 0 |
| Right Punch | B Button | ○ (Circle) | Button 1 |
| Left Hook | Y Button | △ (Triangle) | Button 3 |
| Right Hook | A Button | X (Cross) | Button 2 |
| Guard/Block | Left Trigger (LT) | L2 | Axis 4 |
| Guard/Block | Right Trigger (RT) | R2 | Axis 5 |
| Left Uppercut | LB | L1 | Button 4 |
| Right Uppercut | RB | R1 | Button 5 |
| Dodge Left | Left Stick Left | Left Stick Left | Axis 0 - |
| Dodge Right | Left Stick Right | Left Stick Right | Axis 0 + |
| Dodge Back | Left Stick Down | Left Stick Down | Axis 1 + |
| Special Move | View Button | Touchpad | Button 6 |
| Pause/Menu | Menu Button | Options | Button 7 |

### Alternative Mapping (Face Buttons Only)

For accessibility, provide an alternative layout using only face buttons:

| Action | Mapping |
|--------|---------|
| Left Punch | Left Stick Click (L3) |
| Right Punch | Right Stick Click (R3) |
| Guard | Any Face Button (hold) |

---

## Analog Stick for Directional Punches

### Left Stick (Movement)
- **Neutral Zone:** Center ± 0.15 deadzone
- **Directional Zones:**
  - **Left Zone:** Dodge left (cardio/balance)
  - **Right Zone:** Dodge right (cardio/balance)
  - **Up Zone:** Lean forward (power boost)
  - **Down Zone:** Lean back (defensive)

### Right Stick (Precision Punching)
- **Analog Punch Direction:** 
  - Pushing stick in direction + face button = directional punch
  - Up + Punch = Uppercut
  - Side + Punch = Hook
  - Neutral + Punch = Jab/Straight
- **Intensity Mapping:**
  - Stick deflection 0-100% maps to punch power 50-100%
  - Quick snap = power boost

---

## Trigger Mechanics

### Guard/Block System
- **Single Trigger (Either):** Standard guard
- **Both Triggers:** Heavy guard (reduced stamina drain, slower movement)
- **Trigger Pressure:** Analog blocking strength
  - 50-70%: Light guard
  - 70-90%: Medium guard
  - 90-100%: Heavy guard

### Adaptive Trigger Support (PS5 DualSense)
- Light resistance when guarding
- Increased resistance when stamina low
- Kickback on successful block

---

## Haptic Feedback (Vibration)

### Vibration Events

| Event | Pattern | Intensity |
|-------|---------|-----------|
| Punch Landed | Short pulse (50ms) | 0.3 |
| Punch Blocked | Short pulse (30ms) | 0.2 |
| Heavy Punch | Long pulse (150ms) | 0.7 |
| KO Punch | Strong pulse (300ms) | 1.0 |
| Player Hit | Double pulse | 0.5 |
| Low Stamina | Slow heartbeat | 0.2 (pulsing) |
| Round Start | Single pulse | 0.4 |
| Victory | Celebration pattern | 0.6 |

### Rumble Implementation
```gdscript
# Example haptic pattern
Input.start_joy_vibration(device_id, weak_magnitude, strong_magnitude, duration)
```

### HD Haptics (DualSense)
- Use `Input.vibrate_handheld()` with frequency patterns
- Different patterns for different punch types

---

## Godot 4.6 InputMap Configuration

### Project Settings → Input Map

```
# Required Actions
left_punch       → Joy Button 0 (X/□)
right_punch      → Joy Button 1 (B/○)
left_hook        → Joy Button 3 (Y/△)
right_hook       → Joy Button 2 (A/X)
left_uppercut    → Joy Button 4 (LB/L1)
right_uppercut   → Joy Button 5 (RB/R1)
guard            → Joy Axis 4+ (LT/L2) OR Joy Axis 5+ (RT/R2)
dodge_left       → Joy Axis 0- (Left Stick Left)
dodge_right      → Joy Axis 0+ (Left Stick Right)
lean_forward     → Joy Axis 1- (Left Stick Up)
lean_back        → Joy Axis 1+ (Left Stick Down)
pause            → Joy Button 6 (Menu/Options)
special          → Joy Button 7 (View/Touchpad)
```

### Code-Based Registration
```gdscript
extends Node

func _ready():
    _register_gamepad_actions()

func _register_gamepad_actions():
    # Left Punch - X/□
    InputMap.add_action("gp_left_punch")
    var left_punch_event = InputEventJoypadButton.new()
    left_punch_event.button_index = JOY_BUTTON_X
    InputMap.action_add_event("gp_left_punch", left_punch_event)
    
    # Right Punch - B/○
    InputMap.add_action("gp_right_punch")
    var right_punch_event = InputEventJoypadButton.new()
    right_punch_event.button_index = JOY_BUTTON_B
    InputMap.action_add_event("gp_right_punch", right_punch_event)
    
    # Guard - Left Trigger (analog)
    InputMap.add_action("gp_guard")
    var guard_event = InputEventJoypadMotion.new()
    guard_event.axis = JOY_AXIS_TRIGGER_LEFT
    guard_event.axis_value = 0.5  # Deadzone
    InputMap.action_add_event("gp_guard", guard_event)
```

---

## Controller Detection & Abstraction

### Device Detection
```gdscript
func _input(event):
    if event is InputEventJoypadButton or event is InputEventJoypadMotion:
        _on_gamepad_input(event)

func _on_gamepad_input(event):
    var device_name = Input.get_joy_name(event.device)
    var device_guid = Input.get_joy_guid(event.device)
    
    match _get_controller_type(device_name):
        "xbox": _apply_xbox_mapping()
        "playstation": _apply_playstation_mapping()
        "nintendo": _apply_nintendo_mapping()
        _: _apply_generic_mapping()
```

### Controller Type Detection
```gdscript
enum ControllerType {
    XBOX,
    PLAYSTATION,
    NINTENDO,
    GENERIC
}

func _get_controller_type(device_name: String) -> ControllerType:
    var lower_name = device_name.to_lower()
    
    if "xbox" in lower_name or "microsoft" in lower_name:
        return ControllerType.XBOX
    elif "playstation" in lower_name or "dualshock" in lower_name or "dualsense" in lower_name:
        return ControllerType.PLAYSTATION
    elif "nintendo" in lower_name or "switch" in lower_name:
        return ControllerType.NINTENDO
    else:
        return ControllerType.GENERIC
```

---

## Action Mapping Abstraction

### Unified Input Interface
```gdscript
class_name InputMapper
extends RefCounted

enum InputType {
    CAMERA,
    GAMEPAD,
    KEYBOARD,
    MOUSE
}

var _current_input_type: InputType = InputType.CAMERA

signal punch_detected(hand: String, punch_type: String, power: float)
signal guard_state_changed(is_guarding: bool, intensity: float)
signal dodge_detected(direction: Vector2)

func map_gamepad_to_action(event: InputEvent) -> void:
    if event.is_action_pressed("gp_left_punch"):
        punch_detected.emit("left", "jab", _calculate_punch_power())
    elif event.is_action_pressed("gp_right_punch"):
        punch_detected.emit("right", "jab", _calculate_punch_power())
    elif event.is_action_pressed("gp_left_hook"):
        punch_detected.emit("left", "hook", _calculate_punch_power())
    elif event.is_action_pressed("gp_right_hook"):
        punch_detected.emit("right", "hook", _calculate_punch_power())
    
    # Guard with analog pressure
    if event.is_action("gp_guard"):
        var pressure = Input.get_action_strength("gp_guard")
        guard_state_changed.emit(true, pressure)
```

---

## Fallback When Camera Unavailable

### Auto-Detection Logic
```gdscript
func _detect_available_inputs():
    var has_camera = _check_camera_available()
    var has_gamepad = Input.get_connected_joypads().size() > 0
    
    if has_camera:
        _set_input_mode(InputType.CAMERA)
    elif has_gamepad:
        _set_input_mode(InputType.GAMEPAD)
    else:
        _set_input_mode(InputType.KEYBOARD)
```

### Seamless Switching
- Monitor for controller connect/disconnect events
- Automatically switch to gamepad when connected
- Preserve game state during switch
- Show UI notification of input change

---

## UI Indicators

### In-Game HUD
- **Controller Icon:** Small gamepad icon when active
- **Button Prompts:** Dynamic button display matching controller type
- **Stamina Bar:** Integrated with rumble feedback

### Tutorial Overlays
- Show button prompts appropriate to connected controller
- Highlight active buttons during tutorial
- Visual + haptic feedback for correct inputs

### Controller Status Widget
```
┌─────────────────────┐
│ 🎮 Controller 1     │
│ Xbox Controller     │
│ Battery: 75%        │
│ Vibration: ON       │
└─────────────────────┘
```

---

## Tutorial/Help System

### Controller Setup Flow
1. **Detection Screen:** "Press any button to detect controller"
2. **Calibration:** Analog stick deadzone calibration
3. **Button Test:** Interactive button mapping test
4. **Tutorial Mode:** Guided practice with each punch type

### In-Game Help
- Context-sensitive button prompts
- "Hold LT to Guard" style hints
- Practice mode with visual indicators

---

## Accessibility Considerations

### Motor Accessibility
- **Toggle Mode:** Single press to guard instead of hold
- **Reduced Input Mode:** Face buttons only, no stick required
- **Button Remapping:** Full customization in settings
- **Hold Duration:** Adjustable for guard actions

### Visual Accessibility
- **High Contrast Prompts:** Clear button indicators
- **Alternative Icons:** Symbols + text labels
- **Button Glow:** Visual feedback for button presses

### Cognitive Accessibility
- **Simplified Controls:** Option to reduce move set
- **Input Buffering:** Forgiving timing windows
- **Visual Cues:** Pre-punch windup indicators

---

## Implementation Architecture

### Directory Structure
```
aerobeat-input-gamepad/
├── src/
│   ├── gamepad_driver.gd          # Main driver entry
│   ├── input_mapper.gd            # Action abstraction
│   ├── controller_detector.gd     # Device detection
│   ├── haptics_manager.gd         # Vibration control
│   ├── button_prompts.gd          # Dynamic UI prompts
│   └── mappings/
│       ├── base_mapping.gd
│       ├── xbox_mapping.gd
│       ├── playstation_mapping.gd
│       └── nintendo_mapping.gd
├── test/
│   ├── test_gamepad_driver.gd
│   ├── test_input_mapper.gd
│   └── test_haptics.gd
└── assets/
    ├── button_prompts/
    │   ├── xbox/
    │   ├── playstation/
    │   └── nintendo/
    └── haptic_patterns/
```

### Core Classes

```gdscript
# GamepadDriver - Main entry point
class_name GamepadDriver
extends Node

@export var enable_haptics: bool = true
@export var vibration_strength: float = 0.7

var _mapper: InputMapper
var _haptics: HapticsManager
var _detector: ControllerDetector

func _ready():
    _mapper = InputMapper.new()
    _haptics = HapticsManager.new()
    _detector = ControllerDetector.new()
    
    Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _on_joy_connection_changed(device_id: int, connected: bool):
    if connected:
        var controller_type = _detector.get_controller_type(device_id)
        _mapper.apply_mapping(controller_type)
        Events.input_device_changed.emit(InputType.GAMEPAD)
```

---

## Testing Strategy

### Unit Tests (GUT)

```gdscript
# test_gamepad_driver.gd
extends GutTest

var _driver: GamepadDriver

func before_each():
    _driver = GamepadDriver.new()
    add_child(_driver)

func test_punch_mapping():
    var event = InputEventJoypadButton.new()
    event.button_index = JOY_BUTTON_X
    event.pressed = true
    
    watch_signals(_driver._mapper)
    Input.parse_input_event(event)
    
    assert_signal_emitted(_driver._mapper, "punch_detected")

func test_guard_analog_pressure():
    Input.action_press("gp_guard", 0.8)
    
    watch_signals(_driver._mapper)
    await wait_frames(1)
    
    assert_signal_emitted_with_parameters(
        _driver._mapper, 
        "guard_state_changed", 
        [true, 0.8]
    )
```

### Integration Tests
- **Controller Connection:** Test hot-plug scenarios
- **Mapping Switching:** Verify correct mapping per controller type
- **Haptic Feedback:** Test all vibration patterns
- **Fallback Behavior:** Camera → Gamepad → Keyboard transition

### Manual Testing Checklist
- [ ] Xbox One/Series controller (Windows)
- [ ] Xbox One/Series controller (macOS)
- [ ] DualShock 4 (Windows/macOS)
- [ ] DualSense (Windows/macOS)
- [ ] Nintendo Switch Pro Controller
- [ ] Generic USB controller
- [ ] Bluetooth connection
- [ ] Wired connection
- [ ] Hot-plug detection

### Performance Tests
- Input latency < 16ms (1 frame at 60fps)
- Haptic feedback without frame drops
- Multiple controller support

---

## Dependencies

### Godot Built-in
- `Input` singleton
- `InputEventJoypadButton`
- `InputEventJoypadMotion`
- `Input.start_joy_vibration()`

### AeroBeat Core
- `aerobeat-core` (Input contracts)
- `aerobeat-ui` (Button prompt display)

### Optional
- `aerobeat-accessibility` (Assist features)

---

## Platform Considerations

| Platform | Notes |
|----------|-------|
| Windows | Native XInput support, best compatibility |
| macOS | May require controller drivers for some devices |
| Linux | SDL2 gamepad support |
| Web | Limited support, basic XInput only |

---

## Future Enhancements

1. **Motion Controls:** Gyro-based punching (Switch/PS)
2. **Touchpad Gestures:** PS4/PS5 touchpad for special moves
3. **LED Integration:** Controller light feedback
4. **Audio Passthrough:** Controller speaker for punch sounds
5. **AI Training Mode:** Adaptive difficulty based on input patterns

---

## Related Documents

- `PLAN-KEYBOARD.md` - Keyboard input planning
- `PLAN-MOUSE.md` - Mouse input planning
- `aerobeat-core` Input Contract Specification
