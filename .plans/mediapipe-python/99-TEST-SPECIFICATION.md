# Test Specification: The "Truth"

**Version:** 1.0  
**Purpose:** Comprehensive test suite that MUST pass for project completion

---

## Test Categories

| Category | File Pattern | Count | Purpose |
|----------|--------------|-------|---------|
| Core Unit | `aerobeat-core/test/unit/*` | 3+ | Interface contracts |
| Provider Unit | `mediapipe/test/unit/*` | 5+ | Provider logic |
| Process Unit | `mediapipe/test/unit/*` | 4+ | Lifecycle management |
| Assembly Integration | `assembly/test/integration/*` | 4+ | 3-repo wiring |
| E2E Integration | `assembly/test/integration/*` | 3+ | Full pipeline |

---

## Core Unit Tests

### test_input_provider.gd

```gdscript
extends GutTest

func test_is_abstract_class():
    var p = AeroInputProvider.new()
    assert_null(p.get_left_hand_position())

func test_tracking_mode_enum():
    assert_eq(AeroInputProvider.TrackingMode.MODE_2D, 0)
    assert_eq(AeroInputProvider.TrackingMode.MODE_3D, 1)

func test_body_track_flags():
    assert_eq(AeroInputProvider.BodyTrackFlags.HEAD, 1)
    assert_eq(AeroInputProvider.BodyTrackFlags.LEFT_HAND, 2)
    assert_eq(AeroInputProvider.BodyTrackFlags.RIGHT_HAND, 4)
```

---

## Provider Unit Tests

### test_mediapipe_provider.gd

```gdscript
extends GutTest

var provider

func before_each():
    provider = MediaPipeProvider.new()
    add_child(provider)

func after_each():
    provider.queue_free()

func test_extends_aero_input_provider():
    assert_is(provider, AeroInputProvider)

func test_returns_null_when_no_data():
    assert_null(provider.get_left_hand_position())

func test_returns_vector2_in_2d_mode():
    provider.set_tracking_mode(AeroInputProvider.TrackingMode.MODE_2D)
    provider._on_pose_received([{"id": 15, "x": 0.5, "y": 0.5, "v": 0.99}])
    var pos = provider.get_left_hand_position()
    assert_is(pos, Vector2)

func test_returns_vector3_in_3d_mode():
    provider.set_tracking_mode(AeroInputProvider.TrackingMode.MODE_3D)
    provider._on_pose_received([{"id": 15, "x": 0.5, "y": 0.5, "z": 0.1, "v": 0.99}])
    var pos = provider.get_left_hand_position()
    assert_is(pos, Vector3)

func test_y_axis_is_flipped():
    provider.config = MediaPipeConfig.new()
    provider.config.flip_horizontal = false
    provider._on_pose_received([{"id": 0, "x": 0.5, "y": 0.2, "v": 0.99}])
    var pos = provider.get_head_position()
    assert_eq(pos.y, 0.8, "Y should be 1.0 - 0.2 = 0.8")

func test_horizontal_flip():
    provider.config = MediaPipeConfig.new()
    provider.config.flip_horizontal = true
    provider._on_pose_received([{"id": 0, "x": 0.2, "v": 0.99}])
    var pos = provider.get_head_position()
    assert_eq(pos.x, 0.8, "X should be flipped")

func test_is_tracking_false_when_no_data():
    assert_false(provider.is_tracking())

func test_is_tracking_true_after_data():
    provider._on_pose_received([{"id": 0, "v": 0.99}])
    assert_true(provider.is_tracking())
```

---

## Process Unit Tests

### test_mediapipe_process.gd

```gdscript
extends GutTest

var process
var config

func before_each():
    process = MediaPipeProcess.new()
    add_child(process)
    config = MediaPipeConfig.new()

func after_each():
    if process.is_running():
        process.stop()
    process.queue_free()

func test_find_python_returns_path():
    var path = process._find_python()
    assert_string_contains(path, "python")

func test_start_emits_signal():
    var called = false
    process.process_started.connect(func(): called = true)
    process.start(config)
    assert_true(called)

func test_is_running_after_start():
    process.start(config)
    assert_true(process.is_running())

func test_stop_emits_signal():
    process.start(config)
    var exit_code = -1
    process.process_stopped.connect(func(c): exit_code = c)
    process.stop()
    assert_eq(exit_code, 0)

func test_not_running_after_stop():
    process.start(config)
    process.stop()
    assert_false(process.is_running())
```

---

## Assembly Integration Tests

### test_assembly_integration.gd

```gdscript
extends GutTest

var main
var im

func before_each():
    main = preload("res://scenes/main.tscn").instantiate()
    add_child(main)
    im = main.get_node("InputManager")

func after_each():
    main.queue_free()

func test_main_scene_loads():
    assert_not_null(main)

func test_input_manager_present():
    assert_not_null(im)
    assert_is(im, InputManager)

func test_mediapipe_registered():
    assert_true(im.has_provider("mediapipe"))

func test_can_set_strategy():
    assert_true(im.set_strategy("mediapipe"))

func test_provider_set_after_strategy():
    im.set_strategy("mediapipe")
    assert_not_null(im.get_provider())

func test_provider_is_mediapipe():
    im.set_strategy("mediapipe")
    assert_is(im.get_provider(), MediaPipeProvider)
```

---

## E2E Integration Tests

### test_full_pipeline.gd

```gdscript
extends GutTest

var main
var im
var provider

func before_each():
    main = preload("res://scenes/main.tscn").instantiate()
    add_child(main)
    im = main.get_node("InputManager")

func after_each():
    main.queue_free()

func test_pipeline_initializes():
    im.set_strategy("mediapipe")
    var ok = im.initialize_camera()
    assert_true(ok)

func test_receives_position_data():
    im.set_strategy("mediapipe")
    im.initialize_camera()
    await wait_seconds(0.5)
    
    provider = im.get_provider()
    var pos = provider.get_left_hand_position()
    assert_not_null(pos)

func test_positions_normalized():
    im.set_strategy("mediapipe")
    im.initialize_camera()
    await wait_seconds(0.5)
    
    provider = im.get_provider()
    var pos = provider.get_left_hand_position()
    assert_between(pos.x, 0.0, 1.0)
    assert_between(pos.y, 0.0, 1.0)

func test_all_body_parts():
    im.set_strategy("mediapipe")
    im.initialize_camera()
    await wait_seconds(0.5)
    
    provider = im.get_provider()
    assert_not_null(provider.get_head_position())
    assert_not_null(provider.get_left_hand_position())
    assert_not_null(provider.get_right_hand_position())
    assert_not_null(provider.get_left_foot_position())
    assert_not_null(provider.get_right_foot_position())
```

---

## Running All Tests

```bash
# Run all tests in order

echo "=== Core Tests ==="
cd aerobeat-core/.testbed
godot --headless -s addons/gut/gut_cmdln.gd

echo "=== Provider Tests ==="
cd ../../aerobeat-input-mediapipe-python/.testbed
godot --headless -s addons/gut/gut_cmdln.gd

echo "=== Assembly Tests ==="
cd ../../aerobeat-assembly-community
godot --headless -s addons/gut/gut_cmdln.gd
```

---

## Test Coverage Requirements

| Module | Minimum Coverage |
|--------|------------------|
| Core interfaces | 100% (small API) |
| MediaPipe provider | 80% |
| Process management | 80% |
| Assembly integration | 70% |

---

## Failure Escalation

| Test Failure | Action |
|--------------|--------|
| Core unit test fails | Block all phases |
| Provider unit test fails | Block Phase 2+ |
| Process test fails | Block Phase 3+ |
| Assembly test fails | Block Phase 4+ |
| E2E test fails | Block completion |

---

*This is the "Truth" - if all tests pass, the project works.*
