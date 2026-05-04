extends "res://addons/gut/test.gd"

const InputProviderAdapterScript = preload("res://addons/aerobeat-input-mediapipe-python/src/input_provider.gd")

func test_input_provider_adapter_reports_explicit_provider_id() -> void:
	var provider = add_child_autoqfree(InputProviderAdapterScript.new())
	assert_eq(provider.get_provider_id(), "mediapipe_python")

func test_input_provider_adapter_reports_velocity_capability() -> void:
	var provider = add_child_autoqfree(InputProviderAdapterScript.new())
	assert_true(provider.has_capability(provider.Capability.VELOCITY))
	assert_true(provider.has_capability(provider.Capability.LOWER_BODY))
