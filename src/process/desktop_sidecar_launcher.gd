class_name DesktopSidecarLauncher
extends RefCounted

const STATE_DIRNAME := "aerobeat-sidecar"

static func get_state_dir() -> String:
	var state_dir := ProjectSettings.globalize_path("user://").path_join(STATE_DIRNAME)
	DirAccess.make_dir_recursive_absolute(state_dir)
	return state_dir

static func build_state_paths(label: String) -> Dictionary:
	var safe_label := label.to_lower().replace(" ", "-")
	var nonce := "%d-%d" % [Time.get_unix_time_from_system(), randi()]
	var state_dir := get_state_dir()
	return {
		"pid_file": state_dir.path_join("%s-%s.pid" % [safe_label, nonce]),
		"log_file": state_dir.path_join("%s-%s.log" % [safe_label, nonce]),
	}

static func read_pid_file(path: String) -> int:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file:
		var content: String = file.get_as_text().strip_edges()
		file.close()
		if content.is_valid_int():
			return content.to_int()
	return -1

static func cleanup_state_file(path: String) -> void:
	if not path.is_empty() and FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

static func shell_quote(value: String) -> String:
	return "'%s'" % value.replace("'", "'\"'\"'")

static func _join_command(command: String, args: PackedStringArray) -> String:
	var parts := PackedStringArray([shell_quote(command)])
	for arg in args:
		parts.append(shell_quote(arg))
	return " ".join(parts)

static func launch_detached(context: Node, label: String, command: String, args: PackedStringArray, options: Dictionary = {}) -> Dictionary:
	var state_paths := build_state_paths(label)
	var info: Dictionary = {
		"ok": false,
		"strategy": "",
		"pid": -1,
		"process_group_id": -1,
		"pid_file": state_paths.get("pid_file", ""),
		"log_file": state_paths.get("log_file", ""),
		"platform": OS.get_name(),
		"validated_on_host": false,
		"notes": PackedStringArray(),
	}

	var working_directory := String(options.get("working_directory", "")).strip_edges()
	var redirect_to_log := bool(options.get("redirect_to_log", false))
	var log_file := String(info.get("log_file", ""))
	var prelaunch_commands: PackedStringArray = options.get("prelaunch_commands", PackedStringArray())

	match OS.get_name():
		"Linux":
			var shell_parts := PackedStringArray()
			for command_part in prelaunch_commands:
				shell_parts.append(command_part)
			if not working_directory.is_empty():
				shell_parts.append("cd %s" % shell_quote(working_directory))

			var launch_command := "setsid nohup %s" % _join_command(command, args)
			if redirect_to_log:
				launch_command += " > %s 2>&1" % shell_quote(log_file)
			else:
				launch_command += " > /dev/null 2>&1"
			launch_command += " & PGID=$!"
			shell_parts.append(launch_command)
			shell_parts.append("echo $PGID > %s" % shell_quote(String(info.get("pid_file", ""))))
			shell_parts.append("wait $PGID")
			shell_parts.append("rm -f %s" % shell_quote(String(info.get("pid_file", ""))))

			var shell_command := "; ".join(shell_parts)
			var shell_pid := OS.create_process("/bin/bash", PackedStringArray(["-c", shell_command]))
			if shell_pid <= 0:
				info["notes"] = PackedStringArray(["Linux shell launch failed before sidecar startup."])
				return info

			await context.get_tree().create_timer(float(options.get("startup_probe_delay_sec", 0.2))).timeout
			var pgid := read_pid_file(String(info.get("pid_file", "")))
			if pgid <= 0:
				pgid = shell_pid
				var notes: PackedStringArray = info.get("notes", PackedStringArray())
				notes.append("Linux sidecar launch kept the shell PID because the PGID file was not ready yet.")
				info["notes"] = notes

			info["ok"] = true
			info["strategy"] = "linux-shell-process-group"
			info["pid"] = shell_pid
			info["process_group_id"] = pgid
			info["validated_on_host"] = true
			return info
		"macOS":
			var mac_pid := OS.create_process(command, args)
			if mac_pid <= 0:
				return info
			info["ok"] = true
			info["strategy"] = "macos-direct-pid"
			info["pid"] = mac_pid
			info["notes"] = PackedStringArray([
				"macOS launch currently uses a direct detached PID strategy.",
				"Process-group isolation and teardown parity are scaffolded but not validated on this Linux host.",
			])
			return info
		"Windows":
			var windows_pid := OS.create_process(command, args)
			if windows_pid <= 0:
				return info
			info["ok"] = true
			info["strategy"] = "windows-direct-pid"
			info["pid"] = windows_pid
			info["notes"] = PackedStringArray([
				"Windows launch currently uses a direct detached PID strategy.",
				"taskkill-based teardown is scaffolded but not validated on this Linux host.",
			])
			return info
		_:
			info["notes"] = PackedStringArray(["Unsupported host platform for desktop sidecar launch: %s" % OS.get_name()])
			return info

static func _linux_process_group_has_live_members(group_id: int) -> bool:
	if group_id <= 0:
		return false

	var output: Array = []
	var exit_code := OS.execute("ps", PackedStringArray(["-o", "stat=", "-g", str(group_id)]), output, true)
	if exit_code != 0:
		return false

	for line_variant in output:
		var state := String(line_variant).strip_edges()
		if state.is_empty():
			continue
		if not state.begins_with("Z"):
			return true
	return false

static func is_process_alive(info: Dictionary) -> bool:
	var pid := int(info.get("pid", -1))
	if pid <= 0:
		return false

	match String(info.get("strategy", "")):
		"linux-shell-process-group":
			var pgid := int(info.get("process_group_id", -1))
			if pgid <= 0:
				return OS.is_process_running(pid)
			return _linux_process_group_has_live_members(pgid)
		"macos-direct-pid":
			var mac_output: Array = []
			var mac_exit := OS.execute("/bin/kill", PackedStringArray(["-0", str(pid)]), mac_output, true)
			return mac_exit == 0
		"windows-direct-pid":
			var tasklist_output: Array = []
			OS.execute("tasklist", PackedStringArray(["/FI", "PID eq %d" % pid]), tasklist_output, true)
			return tasklist_output.size() > 0 and tasklist_output[0].contains(str(pid))
		_:
			return OS.is_process_running(pid)

static func terminate(context: Node, info: Dictionary, termination_timeout_ms: int = 2000) -> Dictionary:
	var pid := int(info.get("pid", -1))
	var result: Dictionary = {
		"stopped": false,
		"strategy": String(info.get("strategy", "")),
		"notes": PackedStringArray(),
	}

	if pid <= 0:
		cleanup_state_file(String(info.get("pid_file", "")))
		result["stopped"] = true
		return result

	match String(info.get("strategy", "")):
		"linux-shell-process-group":
			var pgid := int(info.get("process_group_id", -1))
			var group_id := pgid if pgid > 0 else pid
			var output: Array = []
			OS.execute("/bin/kill", PackedStringArray(["-TERM", "-" + str(group_id)]), output, true)
			var elapsed := 0
			while elapsed < termination_timeout_ms:
				await context.get_tree().create_timer(0.1).timeout
				elapsed += 100
				if not is_process_alive(info):
					cleanup_state_file(String(info.get("pid_file", "")))
					result["stopped"] = true
					return result

			OS.execute("/bin/kill", PackedStringArray(["-KILL", "-" + str(group_id)]), output, true)
			var kill_elapsed := 0
			while kill_elapsed < 2500:
				await context.get_tree().create_timer(0.1).timeout
				kill_elapsed += 100
				if not is_process_alive(info):
					cleanup_state_file(String(info.get("pid_file", "")))
					result["stopped"] = true
					return result
			cleanup_state_file(String(info.get("pid_file", "")))
			result["stopped"] = not is_process_alive(info)
			if not bool(result.get("stopped", false)):
				var notes: PackedStringArray = result.get("notes", PackedStringArray())
				notes.append("Linux process-group teardown could not confirm termination after SIGKILL.")
				result["notes"] = notes
			return result
		"macos-direct-pid":
			var mac_output: Array = []
			OS.execute("/bin/kill", PackedStringArray(["-TERM", str(pid)]), mac_output, true)
			var mac_elapsed := 0
			while mac_elapsed < termination_timeout_ms:
				await context.get_tree().create_timer(0.1).timeout
				mac_elapsed += 100
				if not is_process_alive(info):
					cleanup_state_file(String(info.get("pid_file", "")))
					result["stopped"] = true
					return result
			OS.execute("/bin/kill", PackedStringArray(["-KILL", str(pid)]), mac_output, true)
			await context.get_tree().create_timer(0.25).timeout
			cleanup_state_file(String(info.get("pid_file", "")))
			result["stopped"] = not is_process_alive(info)
			var mac_notes: PackedStringArray = result.get("notes", PackedStringArray())
			mac_notes.append("macOS teardown is scaffolded with PID-targeted kill commands and remains unvalidated on this Linux host.")
			result["notes"] = mac_notes
			return result
		"windows-direct-pid":
			var windows_output: Array = []
			OS.execute("taskkill", PackedStringArray(["/PID", str(pid), "/T"]), windows_output, true)
			var win_elapsed := 0
			while win_elapsed < termination_timeout_ms:
				await context.get_tree().create_timer(0.1).timeout
				win_elapsed += 100
				if not is_process_alive(info):
					cleanup_state_file(String(info.get("pid_file", "")))
					result["stopped"] = true
					return result
			OS.execute("taskkill", PackedStringArray(["/PID", str(pid), "/T", "/F"]), windows_output, true)
			await context.get_tree().create_timer(0.25).timeout
			cleanup_state_file(String(info.get("pid_file", "")))
			result["stopped"] = not is_process_alive(info)
			var win_notes: PackedStringArray = result.get("notes", PackedStringArray())
			win_notes.append("Windows teardown is scaffolded with taskkill and remains unvalidated on this Linux host.")
			result["notes"] = win_notes
			return result
		_:
			cleanup_state_file(String(info.get("pid_file", "")))
			result["notes"] = PackedStringArray(["No platform-aware launch strategy was recorded for this sidecar process."])
			return result

static func terminate_sync(info: Dictionary, options: Dictionary = {}) -> Dictionary:
	var pid := int(info.get("pid", -1))
	var allow_kill_escalation := bool(options.get("allow_kill_escalation", true))
	var result: Dictionary = {
		"stopped": false,
		"strategy": String(info.get("strategy", "")),
	}
	if pid <= 0:
		cleanup_state_file(String(info.get("pid_file", "")))
		result["stopped"] = true
		return result

	match String(info.get("strategy", "")):
		"linux-shell-process-group":
			var group_id := int(info.get("process_group_id", -1))
			if group_id <= 0:
				group_id = pid
			var output: Array = []
			OS.execute("/bin/kill", PackedStringArray(["-TERM", "-" + str(group_id)]), output, true)
			OS.delay_msec(300)
			if allow_kill_escalation and is_process_alive(info):
				OS.execute("/bin/kill", PackedStringArray(["-KILL", "-" + str(group_id)]), output, true)
				OS.delay_msec(100)
		"macos-direct-pid":
			var mac_output: Array = []
			OS.execute("/bin/kill", PackedStringArray(["-TERM", str(pid)]), mac_output, true)
			OS.delay_msec(300)
			if allow_kill_escalation and is_process_alive(info):
				OS.execute("/bin/kill", PackedStringArray(["-KILL", str(pid)]), mac_output, true)
				OS.delay_msec(100)
		"windows-direct-pid":
			var windows_output: Array = []
			OS.execute("taskkill", PackedStringArray(["/PID", str(pid), "/T"]), windows_output, true)
			OS.delay_msec(300)
			if allow_kill_escalation and is_process_alive(info):
				OS.execute("taskkill", PackedStringArray(["/PID", str(pid), "/T", "/F"]), windows_output, true)
				OS.delay_msec(100)

	cleanup_state_file(String(info.get("pid_file", "")))
	result["stopped"] = not is_process_alive(info)
	return result
