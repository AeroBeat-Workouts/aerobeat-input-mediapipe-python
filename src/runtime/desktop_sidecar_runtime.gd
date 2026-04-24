class_name DesktopSidecarRuntime
extends RefCounted

const RUNTIME_CONTRACT_VERSION := "unified-desktop-runtime-v1"
const RUNTIME_SCHEMA_VERSION := 1
const RUNTIME_MANIFEST_FILENAME := "runtime-manifest.json"
const RUNTIME_SENTINEL_FILENAME := ".runtime-ready"
const RUNTIME_ENTRYPOINT := "python_mediapipe/main.py"
const SUPPORTED_DESKTOP_PLATFORM_KEYS := ["linux-x64", "macos-x64", "windows-x64"]

static func get_package_root(owner_script_path: String) -> String:
	var candidate := owner_script_path.get_base_dir()
	for _i in range(6):
		var entrypoint := candidate.path_join("python_mediapipe").path_join("main.py")
		if FileAccess.file_exists(ProjectSettings.globalize_path(entrypoint)):
			return candidate
		candidate = candidate.get_base_dir()
	return owner_script_path.get_base_dir()

static func resolve_package_path(owner_script_path: String, relative_path: String) -> String:
	return get_package_root(owner_script_path).path_join(relative_path)

static func get_sidecar_assets_dir(owner_script_path: String) -> String:
	return ProjectSettings.globalize_path(resolve_package_path(owner_script_path, "python_mediapipe/assets"))

static func get_sidecar_runtimes_dir(owner_script_path: String) -> String:
	return ProjectSettings.globalize_path(resolve_package_path(owner_script_path, "python_mediapipe/assets/runtimes"))

static func get_requirements_path(owner_script_path: String) -> String:
	return ProjectSettings.globalize_path(resolve_package_path(owner_script_path, "python_mediapipe/requirements.txt"))

static func is_mobile_platform() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios")

static func is_desktop_platform() -> bool:
	return OS.get_name() in ["Linux", "macOS", "Windows"]

static func get_runtime_mode() -> String:
	if OS.has_feature("template") and not OS.has_feature("editor"):
		return "release"
	return "dev"

static func get_platform_arch_key() -> String:
	if OS.has_feature("x86_64"):
		return "x64"
	if OS.has_feature("arm64"):
		return "arm64"
	if OS.has_feature("x86_32"):
		return "x86"

	var processor_name := OS.get_processor_name().to_lower().strip_edges()
	if processor_name.contains("x86_64") or processor_name.contains("amd64") or processor_name.contains("x64"):
		return "x64"
	if processor_name.contains("aarch64") or processor_name.contains("arm64"):
		return "arm64"
	if processor_name.contains("i386") or processor_name.contains("i686") or processor_name.contains("x86"):
		return "x86"
	return "unknown"

static func get_desktop_platform_key() -> String:
	if not is_desktop_platform() or is_mobile_platform():
		return ""

	var os_key := ""
	match OS.get_name():
		"Linux":
			os_key = "linux"
		"macOS":
			os_key = "macos"
		"Windows":
			os_key = "windows"
		_:
			return ""

	var platform_key := "%s-%s" % [os_key, get_platform_arch_key()]
	if not SUPPORTED_DESKTOP_PLATFORM_KEYS.has(platform_key):
		return ""
	return platform_key

static func get_sidecar_runtime_root(owner_script_path: String) -> String:
	var platform_key := get_desktop_platform_key()
	if platform_key.is_empty():
		return ""
	return get_sidecar_runtimes_dir(owner_script_path).path_join(platform_key)

static func get_sidecar_runtime_manifest_path(owner_script_path: String) -> String:
	var runtime_root := get_sidecar_runtime_root(owner_script_path)
	if runtime_root.is_empty():
		return ""
	return runtime_root.path_join(RUNTIME_MANIFEST_FILENAME)

static func get_sidecar_runtime_sentinel_path(owner_script_path: String) -> String:
	var runtime_root := get_sidecar_runtime_root(owner_script_path)
	if runtime_root.is_empty():
		return ""
	return runtime_root.path_join(RUNTIME_SENTINEL_FILENAME)

static func get_sidecar_python_path(owner_script_path: String) -> String:
	var runtime_root := get_sidecar_runtime_root(owner_script_path)
	if runtime_root.is_empty():
		return ""

	var platform_key := get_desktop_platform_key()
	if platform_key.begins_with("windows-"):
		return runtime_root.path_join("venv").path_join("Scripts").path_join("python.exe")
	return runtime_root.path_join("venv").path_join("bin").path_join("python")

static func get_expected_runtime_python_relpath() -> String:
	var platform_key := get_desktop_platform_key()
	if platform_key.begins_with("windows-"):
		return "venv/Scripts/python.exe"
	return "venv/bin/python"

static func get_runtime_prepare_command_hint(owner_script_path: String, runtime_mode: String = "") -> String:
	var platform_key := get_desktop_platform_key()
	if platform_key.is_empty():
		platform_key = "<platform>"
	var mode := runtime_mode if not runtime_mode.is_empty() else get_runtime_mode()
	return "python3 python_mediapipe/prepare_runtime.py --platform %s --mode %s --create-venv --validate" % [platform_key, mode]

static func read_json_file(path: String) -> Variant:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null

	var text := file.get_as_text()
	file.close()
	return JSON.parse_string(text)

static func is_runtime_manifest_mode_acceptable(manifest_mode: String, expected_mode: String) -> bool:
	if expected_mode == "release":
		return manifest_mode == "release"
	return manifest_mode == "dev" or manifest_mode == "release"

static func get_required_model_name(model_complexity: int) -> String:
	match model_complexity:
		2:
			return "pose_landmarker_heavy.task"
		1:
			return "pose_landmarker_full.task"
		_:
			return "pose_landmarker_lite.task"

static func get_model_asset_path(owner_script_path: String, model_name: String) -> String:
	return ProjectSettings.globalize_path(resolve_package_path(owner_script_path, "python_mediapipe/assets/models/" + model_name))

static func validate_runtime(owner_script_path: String, required_model_name: String = "") -> Dictionary:
	var errors := PackedStringArray()
	var result: Dictionary = {
		"valid": false,
		"platform_key": get_desktop_platform_key(),
		"runtime_mode": get_runtime_mode(),
		"runtime_root": get_sidecar_runtime_root(owner_script_path),
		"python_path": get_sidecar_python_path(owner_script_path),
		"errors": errors,
	}

	if is_mobile_platform():
		errors.append("Mobile platforms stay on the native MediaPipe path; the desktop Python runtime contract is intentionally excluded here.")
		return result

	if not is_desktop_platform():
		errors.append("Unsupported host platform for the desktop MediaPipe sidecar: %s" % OS.get_name())
		return result

	if String(result.get("platform_key", "")).is_empty():
		errors.append("Could not derive a supported desktop runtime platform key for OS=%s arch=%s" % [OS.get_name(), get_platform_arch_key()])
		return result

	if String(result.get("runtime_root", "")).is_empty() or not DirAccess.dir_exists_absolute(String(result.get("runtime_root", ""))):
		errors.append("Missing sidecar runtime root: %s" % result.get("runtime_root", ""))
		errors.append("Prepare it first with: %s" % get_runtime_prepare_command_hint(owner_script_path, String(result.get("runtime_mode", ""))))
		return result

	var manifest_path := get_sidecar_runtime_manifest_path(owner_script_path)
	var sentinel_path := get_sidecar_runtime_sentinel_path(owner_script_path)
	if not FileAccess.file_exists(manifest_path):
		errors.append("Missing sidecar runtime manifest: %s" % manifest_path)
	if not FileAccess.file_exists(sentinel_path):
		errors.append("Missing sidecar runtime sentinel: %s" % sentinel_path)
	if not FileAccess.file_exists(String(result.get("python_path", ""))):
		errors.append("Missing sidecar runtime Python executable: %s" % result.get("python_path", ""))
	if errors.size() > 0:
		errors.append("Repair or regenerate the runtime with: %s" % get_runtime_prepare_command_hint(owner_script_path, String(result.get("runtime_mode", ""))))
		return result

	var manifest_data = read_json_file(manifest_path)
	if typeof(manifest_data) != TYPE_DICTIONARY:
		errors.append("Unreadable sidecar runtime manifest JSON: %s" % manifest_path)
		return result

	var sentinel_data = read_json_file(sentinel_path)
	if typeof(sentinel_data) != TYPE_DICTIONARY:
		errors.append("Unreadable sidecar runtime sentinel JSON: %s" % sentinel_path)
		return result

	var manifest: Dictionary = manifest_data
	var sentinel: Dictionary = sentinel_data
	var expected_mode := String(result.get("runtime_mode", ""))
	var expected_platform_key := String(result.get("platform_key", ""))
	var expected_python_relpath := get_expected_runtime_python_relpath()

	if manifest.get("contract_version", "") != RUNTIME_CONTRACT_VERSION:
		errors.append("Runtime contract_version mismatch: expected %s, got %s" % [RUNTIME_CONTRACT_VERSION, manifest.get("contract_version", "<missing>")])
	if int(manifest.get("schema_version", -1)) != RUNTIME_SCHEMA_VERSION:
		errors.append("Runtime schema_version mismatch: expected %d, got %s" % [RUNTIME_SCHEMA_VERSION, str(manifest.get("schema_version", "<missing>"))])
	if String(manifest.get("platform_key", "")) != expected_platform_key:
		errors.append("Runtime platform_key mismatch: expected %s, got %s" % [expected_platform_key, manifest.get("platform_key", "<missing>")])

	var manifest_mode := String(manifest.get("mode", ""))
	if not is_runtime_manifest_mode_acceptable(manifest_mode, expected_mode):
		errors.append("Runtime mode mismatch: expected %s-compatible runtime, got %s" % [expected_mode, manifest_mode if not manifest_mode.is_empty() else "<missing>"])

	if String(manifest.get("entrypoint", "")) != RUNTIME_ENTRYPOINT:
		errors.append("Runtime entrypoint mismatch: expected %s, got %s" % [RUNTIME_ENTRYPOINT, manifest.get("entrypoint", "<missing>")])
	if String(manifest.get("python_executable", "")) != expected_python_relpath:
		errors.append("Runtime python_executable mismatch: expected %s, got %s" % [expected_python_relpath, manifest.get("python_executable", "<missing>")])

	if String(sentinel.get("platform_key", "")) != expected_platform_key:
		errors.append("Runtime sentinel platform_key mismatch: expected %s, got %s" % [expected_platform_key, sentinel.get("platform_key", "<missing>")])
	if String(sentinel.get("contract_version", "")) != RUNTIME_CONTRACT_VERSION:
		errors.append("Runtime sentinel contract_version mismatch: expected %s, got %s" % [RUNTIME_CONTRACT_VERSION, sentinel.get("contract_version", "<missing>")])

	var model_assets = manifest.get("model_assets", [])
	if typeof(model_assets) != TYPE_ARRAY or model_assets.is_empty():
		errors.append("Runtime manifest missing model_assets inventory")
	else:
		var required_model_present := required_model_name.is_empty()
		for model_variant in model_assets:
			if typeof(model_variant) != TYPE_DICTIONARY:
				errors.append("Runtime manifest has malformed model_assets entry: %s" % str(model_variant))
				continue
			var model_entry: Dictionary = model_variant
			var relative_path := String(model_entry.get("relative_path", ""))
			if relative_path.is_empty():
				errors.append("Runtime manifest has model_assets entry without relative_path")
				continue
			var absolute_path := ProjectSettings.globalize_path("res://../" + relative_path)
			if not FileAccess.file_exists(absolute_path):
				errors.append("Required model asset listed in runtime manifest is missing: %s" % absolute_path)
			if String(model_entry.get("filename", "")) == required_model_name:
				required_model_present = true
		if not required_model_present:
			errors.append("Runtime manifest is missing the required model asset entry for %s" % required_model_name)

	if not required_model_name.is_empty():
		var required_model_path := get_model_asset_path(owner_script_path, required_model_name)
		if not FileAccess.file_exists(required_model_path):
			errors.append("Missing MediaPipe model asset: %s (expected at %s)" % [required_model_name, required_model_path])

	result["valid"] = errors.is_empty()
	return result
