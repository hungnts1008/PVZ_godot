extends Timer
class_name ShootTimer

signal shoot_requested(target: Node2D)

@export var detector_path: NodePath

var _detector: Node = null
var _current_target: Node2D = null

func _ready() -> void:
	timeout.connect(_on_timeout)
	_bind_detector()

func _bind_detector() -> void:
	if detector_path == NodePath():
		return
	_detector = get_node_or_null(detector_path)
	if _detector == null:
		push_warning("ShootTimer: detector_path does not exist: %s" % [detector_path])
		return
	if _detector.has_signal("target_changed"):
		_detector.connect("target_changed", Callable(self, "_on_target_changed"))
	else:
		push_warning("ShootTimer: detector has no signal 'target_changed'")

func _on_target_changed(_old_target: Node2D, new_target: Node2D) -> void:
	_current_target = new_target
	if _current_target != null:
		if is_stopped():
			start()
	else:
		stop()

func _on_timeout() -> void:
	if _current_target == null:
		return
	if not is_instance_valid(_current_target):
		_current_target = null
		stop()
		return
	shoot_requested.emit(_current_target)
