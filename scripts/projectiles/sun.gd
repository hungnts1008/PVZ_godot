extends Area2D
class_name Sun

signal collected(amount: int)

@export var amount: int = 25

@export var rise_height: float = 25.0
@export var rise_duration: float = 0.20
@export var fall_distance: float = 70.0
@export var fall_duration: float = 0.60

@export var collect_fly_duration: float = 0.30
@export var lifetime_sec: float = 10.0

# Default target: main UI label location (no main edits needed)
@export var collect_target_path: NodePath = NodePath("/root/Main/UI/SunLabel")

var _life_left: float
var _spawn_tween: Tween
var _collect_tween: Tween
var _is_collected: bool = false


func _ready() -> void:
	_life_left = lifetime_sec
	input_pickable = true
	monitoring = true
	# Defer so spawners can set global_position after add_child().
	# Otherwise the tween may be computed from the default position and look like it "falls twice".
	call_deferred("_start_spawn_motion")


func setup(new_amount: int = 25, new_collect_target_path: NodePath = NodePath()) -> void:
	amount = new_amount
	if new_collect_target_path != NodePath():
		collect_target_path = new_collect_target_path


func _physics_process(delta: float) -> void:
	if _is_collected:
		return
	_life_left -= delta
	if _life_left <= 0.0:
		queue_free()

func _start_spawn_motion() -> void:
	if _is_collected:
		return
	if _spawn_tween != null and _spawn_tween.is_running():
		_spawn_tween.kill()

	var start_pos := global_position
	var rise_pos := start_pos + Vector2(0, -abs(rise_height))
	var fall_pos := rise_pos + Vector2(0, abs(fall_distance))

	_spawn_tween = create_tween()
	_spawn_tween.set_trans(Tween.TRANS_SINE)
	_spawn_tween.set_ease(Tween.EASE_OUT)
	_spawn_tween.tween_property(self, "global_position", rise_pos, max(rise_duration, 0.01))
	_spawn_tween.set_ease(Tween.EASE_IN)
	_spawn_tween.tween_property(self, "global_position", fall_pos, max(fall_duration, 0.01))

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _is_collected:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_collect()

func _collect() -> void:
	_is_collected = true
	monitoring = false
	input_pickable = false
	if _spawn_tween != null and _spawn_tween.is_running():
		_spawn_tween.kill()

	var target_world := _resolve_collect_target_world_position()
	_collect_tween = create_tween()
	_collect_tween.set_trans(Tween.TRANS_SINE)
	_collect_tween.set_ease(Tween.EASE_IN_OUT)
	_collect_tween.tween_property(self, "global_position", target_world, max(collect_fly_duration, 0.01))
	_collect_tween.finished.connect(_on_collect_arrived)

func _on_collect_arrived() -> void:
	_apply_resource_gain()
	collected.emit(amount)
	queue_free()

func _apply_resource_gain() -> void:
	var node := get_node_or_null(collect_target_path)
	if node is Label:
		var label := node as Label
		var text := label.text.strip_edges()
		var current := 0
		if text != "":
			current = int(text)
		label.text = str(current + amount)

func _resolve_collect_target_world_position() -> Vector2:
	var node := get_node_or_null(collect_target_path)
	if node == null:
		return global_position + Vector2(0, -80)
	if node is Node2D:
		return (node as Node2D).global_position
	if node is Control:
		return _canvas_to_world((node as Control).global_position)
	return global_position + Vector2(0, -80)

func _canvas_to_world(canvas_pos: Vector2) -> Vector2:
	# Approx conversion from viewport/canvas coordinates to world coordinates.
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return canvas_pos
	var viewport_size := get_viewport().get_visible_rect().size
	var delta_from_center := canvas_pos - (viewport_size * 0.5)
	return camera.get_screen_center_position() + (delta_from_center / camera.zoom)
