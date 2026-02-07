class_name MediaPipeConfig
extends Resource

@export var camera_id: int = 0
@export var udp_port: int = 4242
@export var detection_confidence: float = 0.5
@export var tracking_confidence: float = 0.5
@export var model_complexity: int = 1
@export var flip_horizontal: bool = true
@export var smoothing_factor: float = 0.3
@export var min_visibility: float = 0.5
@export var track_head: bool = true
@export var track_left_hand: bool = true
@export var track_right_hand: bool = true
@export var track_left_foot: bool = false
@export var track_right_foot: bool = false
