extends Control

@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var auto_start_manager: Node = get_node_or_null("AutoStartManager")

func _ready() -> void:
	if auto_start_manager == null:
		push_error("[install_progress] AutoStartManager node not found")
		return

	# Connect to AutoStartManager signals
	auto_start_manager.installation_progress.connect(_on_installation_progress)
	auto_start_manager.installation_complete.connect(_on_installation_complete)
	auto_start_manager.server_started.connect(_on_server_started)
	
	# Check current state
	_check_and_start()

func _check_and_start() -> void:
	if auto_start_manager.check_mediapipe_installed():
		status_label.text = "MediaPipe found! Starting server..."
		progress_bar.value = 100
		auto_start_manager.start_server()
	else:
		status_label.text = "MediaPipe not found. Installing..."
		auto_start_manager.install_dependencies()

func _on_installation_progress(percent: int, message: String) -> void:
	progress_bar.value = percent
	status_label.text = message

func _on_installation_complete(success: bool) -> void:
	if success:
		status_label.text = "Installation complete! Starting server..."
		auto_start_manager.start_server()
	else:
		status_label.text = "Installation failed. Please check your internet connection."

func _on_server_started() -> void:
	status_label.text = "Server running! You can close this window."
	# Optionally hide progress bar or show a "connected" indicator

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Graceful shutdown - stop server before closing
		if auto_start_manager:
			auto_start_manager.stop_server()
		get_tree().quit()
