# AeroBeat Keyboard Input Support Plan

**Date:** 2026-02-08  
**Godot Version:** 4.6  
**Status:** Planning Phase  

---

## Target Repository

**Local Path:** `~/Documents/GitHub/AeroBeat/aerobeat-input-keyboard/`
**GitHub:** `https://github.com/derrickbarra/aerobeat-input-keyboard`

---

## Overview

This document outlines the implementation plan for Keyboard input support in AeroBeat, providing a keyboard-based alternative to camera tracking and gamepad for boxing gameplay. Keyboard input serves as the most accessible fallback option and supports both traditional two-handed layouts and one-handed accessibility configurations.

---

## Input Mapping Scheme

### Primary Layout: WASD + Punch Keys (Two-Handed)

The standard keyboard layout uses WASD for movement/dodging and the left hand for punches, with guard on the spacebar.

| Action | Primary Key | Alternative |
|--------|-------------|-------------|
| **Movement/Dodging** |||
| Dodge Left | A | Left Arrow |
| Dodge Right | D | Right Arrow |
| Lean Forward | W | Up Arrow |
| Lean Back | S | Down Arrow |
| **Punches (Left Hand)** |||
| Left Jab | J | NumPad 4 |
| Right Jab | L | NumPad 6 |
| Left Hook | U | NumPad 7 |
| Right Hook | O | NumPad 9 |
| Left Uppercut | I | NumPad 8 |
| Right Uppercut | K | NumPad 5 |
| **Defense/Special** |||
| Guard/Block | Space | Left Shift |
| Heavy Guard | Space + Shift | - |
| Special Move | Enter | Right Shift |
| Pause/Menu | Escape | P |

### Arrow Key Alternative Layout

For users who prefer arrow keys for movement or have different keyboard configurations:

| Action | Arrow Layout |
|--------|--------------|
| Dodge Left | Left Arrow |
| Dodge Right | Right Arrow |
| Lean Forward | Up Arrow |
| Lean Back | Down Arrow |
| Left Punch | Z |
| Right Punch | X |
| Left Hook | A |
| Right Hook | S |
| Left Uppercut | Q |
| Right Uppercut | W |
| Guard | Space |
| Special | C |

---

## Two-Handed vs One-Handed Layouts

### Two-Handed Standard (Recommended)

```
┌─────────────────────────────────────────────────────────────┐
│  TWO-HANDED LAYOUT                                          │
│                                                             │
│  Left Hand (Movement)    │    Right Hand (Punches)          │
│  ┌───┬───┬───┐          │    ┌───┬───┬───┐                 │
│  │   │ W │   │ Forward  │    │ U │ I │ O │  Hook│Up│Hook   │
│  ├───┼───┼───┤          │    ├───┼───┼───┤                 │
│  │ A │ S │ D │Lft│Bck│Rt│    │ J │ K │ L │ Lft│Up│Rgt      │
│  └───┴───┴───┘          │    └───┴───┴───┘                 │
│                          │                                    │
│  SPACE = Guard/Block    │    ENTER = Special Move           │
│  SHIFT + SPACE = Heavy Guard                                  │
└─────────────────────────────────────────────────────────────┘
```

**Advantages:**
- Natural separation of movement and action
- Allows simultaneous movement and punching
- Familiar to PC gamers (WASD standard)
- Reduces finger fatigue during extended play

### One-Handed Accessibility Layout

For users with limited mobility or who prefer single-hand operation:

```
┌─────────────────────────────────────────────────────────────┐
│  ONE-HANDED LAYOUT (Left Hand on WASD cluster)              │
│                                                             │
│  ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐                 │
│  │ Q │ W │ E │ R │ T │ Y │ U │ I │ O │ P │                 │
│  └───┴───┴─┬─┴───┴───┴───┴───┴─┬─┴───┴───┘                 │
│            │ A │ S │ D │ F │ G │ H │ J │                     │
│            └───┴─┬─┴───┴───┴───┴─┬─┴───┘                       │
│                  │ Z │ X │ C │ V │ B │                         │
│                  └───┴───┴───┴───┴───┘                         │
│                                                                │
│  MOVEMENT (WASD):                                              │
│    W = Forward    A = Left    S = Back    D = Right            │
│                                                                │
│  PUNCHES (Modifier + Action):                                  │
│    Hold SPACE + press punch key:                               │
│      Q = Left Hook        U = Right Hook                       │
│      W = Left Uppercut    I = Right Uppercut                   │
│      A = Left Jab         J = Right Jab                        │
│                                                                │
│  GUARD:                                                        │
│    Hold G (no modifier needed)                                 │
│    Hold G + Shift = Heavy Guard                                │
│                                                                │
│  SPECIAL:                                                      │
│    Press E (when special meter full)                           │
│                                                                │
│  PAUSE:                                                        │
│    Press Escape                                                │
└─────────────────────────────────────────────────────────────┘
```

**One-Handed Key Mapping:**

| Action | Key | Notes |
|--------|-----|-------|
| Dodge Left | A | Direct |
| Dodge Right | D | Direct |
| Lean Forward | W | Direct |
| Lean Back | S | Direct |
| Left Jab | Space + A | Modifier combo |
| Right Jab | Space + J | Modifier combo |
| Left Hook | Space + Q | Modifier combo |
| Right Hook | Space + U | Modifier combo |
| Left Uppercut | Space + W | Modifier combo |
| Right Uppercut | Space + I | Modifier combo |
| Guard | G | Direct hold |
| Heavy Guard | G + Shift | Modifier combo |
| Special | E | Direct (when available) |
| Pause | Escape | Direct |

**Advantages:**
- Accessible to users with limited mobility
- All actions reachable without hand movement
- Clear modifier-based system
- Can be used with accessibility hardware

---

## Accessibility Considerations

### Key Remapping System

AeroBeat will provide comprehensive key remapping through both in-game UI and configuration files.

#### In-Game Remapping UI
```gdscript
# KeyRemapper.gd - UI for remapping keys
class_name KeyRemapper
extends Control

@onready var action_list: VBoxContainer = $ActionList
@onready var remap_dialog: AcceptDialog = $RemapDialog

var _current_remapping: String = ""
var _is_waiting_for_input: bool = false

func _ready():
    _populate_action_list()
    InputMap.configuration_changed.connect(_on_config_changed)

func _populate_action_list():
    var actions = ["kb_left_punch", "kb_right_punch", "kb_guard", 
                   "kb_dodge_left", "kb_dodge_right", "kb_special"]
    
    for action in actions:
        var row = HBoxContainer.new()
        
        var label = Label.new()
        label.text = action.replace("kb_", "").replace("_", " ").capitalize()
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        
        var key_button = Button.new()
        key_button.text = _get_key_name(action)
        key_button.pressed.connect(_on_key_button_pressed.bind(action))
        
        row.add_child(label)
        row.add_child(key_button)
        action_list.add_child(row)

func _get_key_name(action: String) -> String:
    var events = InputMap.action_get_events(action)
    if events.size() > 0 and events[0] is InputEventKey:
        return OS.get_keycode_string(events[0].keycode)
    return "Unassigned"

func _on_key_button_pressed(action: String):
    _current_remapping = action
    _is_waiting_for_input = true
    remap_dialog.dialog_text = "Press any key to assign to %s" % action
    remap_dialog.popup_centered()
    set_process_input(true)

func _input(event):
    if not _is_waiting_for_input:
        return
    
    if event is InputEventKey and event.pressed and not event.echo:
        _assign_key(_current_remapping, event.keycode)
        _is_waiting_for_input = false
        remap_dialog.hide()
        set_process_input(false)
        _populate_action_list()  # Refresh UI

func _assign_key(action: String, keycode: int):
    # Remove existing key events for this action
    var existing = InputMap.action_get_events(action)
    for event in existing:
        if event is InputEventKey:
            InputMap.action_erase_event(action, event)
    
    # Add new key
    var new_event = InputEventKey.new()
    new_event.keycode = keycode
    InputMap.action_add_event(action, new_event)
    
    # Save to user config
    _save_key_mapping(action, keycode)

func _save_key_mapping(action: String, keycode: int):
    var config = ConfigFile.new()
    config.load("user://key_mappings.cfg")
    config.set_value("keyboard", action, keycode)
    config.save("user://key_mappings.cfg")

func _on_config_changed():
    _populate_action_list()
```

#### Configuration File Format
```ini
; user://key_mappings.cfg
[keyboard]
kb_left_punch=74      ; J key
kb_right_punch=76     ; L key
kb_left_hook=85       ; U key
kb_right_hook=79      ; O key
kb_left_uppercut=73   ; I key
kb_right_uppercut=75  ; K key
kb_guard=32           ; Space
kb_heavy_guard=16777237 ; Shift + Space
kb_dodge_left=65      ; A
kb_dodge_right=68     ; D
kb_lean_forward=87    ; W
kb_lean_back=83       ; S
kb_special=16777221   ; Enter
kb_pause=16777217     ; Escape

[accessibility]
sticky_keys=true
repeat_delay=0.5
repeat_rate=0.1
hold_to_toggle=true
```

### Sticky Keys Support

Sticky Keys allows users to press modifier keys (like Shift for heavy guard) sequentially rather than simultaneously.

```gdscript
# StickyKeysHandler.gd
class_name StickyKeysHandler
extends Node

@export var sticky_timeout: float = 2.0  # Seconds to hold sticky state

var _sticky_shift: bool = false
var _sticky_ctrl: bool = false
var _sticky_alt: bool = false
var _sticky_timer: float = 0.0

signal sticky_state_changed(modifier: String, active: bool)

func _ready():
    # Check system accessibility settings
    _load_sticky_keys_preference()

func _input(event: InputEvent):
    if not _is_sticky_keys_enabled():
        return
    
    if event is InputEventKey:
        _handle_sticky_key(event)

func _handle_sticky_key(event: InputEventKey):
    match event.keycode:
        KEY_SHIFT:
            if event.pressed and not event.echo:
                _toggle_sticky("shift")
        KEY_CTRL:
            if event.pressed and not event.echo:
                _toggle_sticky("ctrl")
        KEY_ALT:
            if event.pressed and not event.echo:
                _toggle_sticky("alt")
        _:
            # Any other key press consumes sticky modifiers
            if event.pressed:
                _apply_sticky_to_event(event)
                _clear_sticky_modifiers()

func _toggle_sticky(modifier: String):
    match modifier:
        "shift":
            _sticky_shift = !_sticky_shift
            sticky_state_changed.emit("shift", _sticky_shift)
        "ctrl":
            _sticky_ctrl = !_sticky_ctrl
            sticky_state_changed.emit("ctrl", _sticky_ctrl)
        "alt":
            _sticky_alt = !_sticky_alt
            sticky_state_changed.emit("alt", _sticky_alt)
    
    _sticky_timer = sticky_timeout
    _update_sticky_indicator()

func _apply_sticky_to_event(event: InputEventKey):
    if _sticky_shift:
        event.shift_pressed = true
    if _sticky_ctrl:
        event.ctrl_pressed = true
    if _sticky_alt:
        event.alt_pressed = true

func _clear_sticky_modifiers():
    _sticky_shift = false
    _sticky_ctrl = false
    _sticky_alt = false
    _update_sticky_indicator()

func _update_sticky_indicator():
    # Update UI indicator showing active sticky modifiers
    Events.sticky_keys_updated.emit(_sticky_shift, _sticky_ctrl, _sticky_alt)

func _process(delta: float):
    if _sticky_timer > 0:
        _sticky_timer -= delta
        if _sticky_timer <= 0:
            _clear_sticky_modifiers()

func _is_sticky_keys_enabled() -> bool:
    var config = ConfigFile.new()
    if config.load("user://accessibility.cfg") == OK:
        return config.get_value("accessibility", "sticky_keys", false)
    return false

func _load_sticky_keys_preference():
    # Check OS-level sticky keys on Windows
    if OS.has_feature("Windows"):
        # Could query Windows accessibility API
        pass
