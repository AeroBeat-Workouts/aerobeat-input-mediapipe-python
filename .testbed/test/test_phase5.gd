extends RefCounted
## Standalone tests for Phase 5 integration
## Runs without GUT addon - uses simple assertions

const MAIN_SCENE_PATH = "res://addons/aerobeat-assembly-community/scenes/main.tscn"
const MOCK_SERVER_PATH = "res://python_mediapipe/main.py"
const BUILD_SCRIPT_PATH = "res://addons/aerobeat-assembly-community/build-test.sh"

var _tests_passed = 0
var _tests_failed = 0

func run_all_tests():
	print("\n=== Running Phase 5 Integration Tests ===\n")
	
	test_main_scene_exists()
	test_mock_server_exists()
	test_build_script_exists()
	
	print("\n=== Test Results ===")
	print("Passed: %d" % _tests_passed)
	print("Failed: %d" % _tests_failed)
	print("====================\n")
	
	return _tests_failed == 0

func test_main_scene_exists():
	print("Test: Main scene exists...")
	if FileAccess.file_exists(MAIN_SCENE_PATH):
		print("  ✓ PASS: Main scene found at %s" % MAIN_SCENE_PATH)
		_tests_passed += 1
	else:
		print("  ✗ FAIL: Main scene not found at %s" % MAIN_SCENE_PATH)
		_tests_failed += 1

func test_mock_server_exists():
	print("Test: Mock server exists...")
	if FileAccess.file_exists(MOCK_SERVER_PATH):
		print("  ✓ PASS: Mock server found at %s" % MOCK_SERVER_PATH)
		_tests_passed += 1
	else:
		print("  ✗ FAIL: Mock server not found at %s" % MOCK_SERVER_PATH)
		_tests_failed += 1

func test_build_script_exists():
	print("Test: Build script exists...")
	if FileAccess.file_exists(BUILD_SCRIPT_PATH):
		print("  ✓ PASS: Build script found at %s" % BUILD_SCRIPT_PATH)
		_tests_passed += 1
	else:
		print("  ✗ FAIL: Build script not found at %s" % BUILD_SCRIPT_PATH)
		_tests_failed += 1

# Run tests when this script is loaded
func _init():
	# Don't auto-run in editor - let user call run_all_tests()
	pass
