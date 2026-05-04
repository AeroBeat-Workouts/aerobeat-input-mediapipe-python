extends "res://addons/gut/test.gd"

const InputProviderAdapterScript = preload("res://addons/aerobeat-input-mediapipe-python/src/input_provider.gd")

func test_input_provider_adapter_reports_explicit_provider_id() -> void:
	var provider = add_child_autoqfree(InputProviderAdapterScript.new())
	assert_eq(provider.get_provider_id(), "mediapipe_python")

func test_input_provider_adapter_reports_boxing_velocity_and_lower_body_capabilities() -> void:
	var provider = add_child_autoqfree(InputProviderAdapterScript.new())
	assert_true(provider.has_capability(provider.Capability.GESTURE_RECOGNITION))
	assert_true(provider.has_capability(provider.Capability.VELOCITY))
	assert_true(provider.has_capability(provider.Capability.LOWER_BODY))

func test_input_provider_adapter_reemits_flow_signals_from_provider() -> void:
	var adapter = add_child_autoqfree(InputProviderAdapterScript.new())
	adapter._ensure_provider()
	var flow_calls: Array = []
	adapter.swing_left.connect(func(placement: StringName, direction: StringName) -> void:
		flow_calls.append([String(placement), String(direction)])
	)
	adapter._provider.swing_left.emit(&"left", &"up")
	assert_eq(flow_calls, [["left", "up"]])

func test_input_provider_adapter_reemits_boxing_signals_from_provider() -> void:
	var adapter = add_child_autoqfree(InputProviderAdapterScript.new())
	adapter._ensure_provider()
	var punch_calls: Array = []
	adapter.punch_left.connect(func(power: float) -> void:
		punch_calls.append(power)
	)
	adapter._provider.punch_left.emit(0.75)
	assert_eq(punch_calls, [0.75])
