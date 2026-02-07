extends Node
## Test Runner - Executes all tests without GUT dependency
## Call run_all_tests() to execute test suite

var _test_scripts = [
	"res://test/test_phase5.gd"
]

func run_all_tests():
	print("\n========================================")
	print("    AeroBeat MediaPipe Test Suite")
	print("========================================\n")
	
	var total_passed = 0
	var total_failed = 0
	
	for script_path in _test_scripts:
		var result = _run_test_script(script_path)
		total_passed += result.passed
		total_failed += result.failed
	
	print("\n========================================")
	print("    Final Results")
	print("========================================")
	print("Total Passed: %d" % total_passed)
	print("Total Failed: %d" % total_failed)
	print("========================================\n")
	
	return total_failed == 0

func _run_test_script(script_path: String) -> Dictionary:
	var result = {"passed": 0, "failed": 0}
	
	if not FileAccess.file_exists(script_path):
		print("ERROR: Test script not found: %s" % script_path)
		result.failed += 1
		return result
	
	var script = load(script_path)
	if script == null:
		print("ERROR: Failed to load test script: %s" % script_path)
		result.failed += 1
		return result
	
	var instance = script.new()
	if instance.has_method("run_all_tests"):
		var success = instance.run_all_tests()
		if success:
			result.passed += 1
		else:
			result.failed += 1
	else:
		print("WARNING: Test script has no run_all_tests() method: %s" % script_path)
	
	return result

# Can be called from UI button or automatically
func _ready():
	# Uncomment to auto-run tests on scene start:
	# run_all_tests()
	pass
