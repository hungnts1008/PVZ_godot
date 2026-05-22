extends ExplosionPlant
class_name CherryBomb

@export var left_cherry_path: NodePath = NodePath("Sprite/LeftCherry")
@export var right_cherry_path: NodePath = NodePath("Sprite/RightCherry")

# How much the cherries scale up before the explosion triggers.
@export var inflate_scale_multiplier: float = 1.25

var _left_cherry: Node2D
var _right_cherry: Node2D

var _left_base_scale: Vector2 = Vector2.ONE
var _right_base_scale: Vector2 = Vector2.ONE
var _inflate_tween: Tween


func _ready() -> void:
	# This scene overrides some exported paths with `null`. Restore safe defaults.
	if left_cherry_path == null or left_cherry_path == NodePath():
		left_cherry_path = NodePath("Sprite/LeftCherry")
	if right_cherry_path == null or right_cherry_path == NodePath():
		right_cherry_path = NodePath("Sprite/RightCherry")
	if explode_timer_path == null or explode_timer_path == NodePath():
		explode_timer_path = NodePath("ExplodeTimer")
	if explosion_area_path == null or explosion_area_path == NodePath():
		explosion_area_path = NodePath("ExplosionArea")

	_left_cherry = get_node_or_null(left_cherry_path) as Node2D
	_right_cherry = get_node_or_null(right_cherry_path) as Node2D

	if _left_cherry != null:
		_left_base_scale = _left_cherry.scale
	if _right_cherry != null:
		_right_base_scale = _right_cherry.scale

	super._ready()
	_start_inflate_animation()


func _start_inflate_animation() -> void:
	if _left_cherry == null and _right_cherry == null:
		return

	var duration := _get_explode_duration_seconds()
	if duration <= 0.0:
		return

	if _inflate_tween != null and is_instance_valid(_inflate_tween):
		_inflate_tween.kill()

	_inflate_tween = create_tween()
	_inflate_tween.set_trans(Tween.TRANS_SINE)
	_inflate_tween.set_ease(Tween.EASE_IN)

	if _left_cherry != null:
		_inflate_tween.tween_property(
			_left_cherry,
			"scale",
			_left_base_scale * inflate_scale_multiplier,
			duration
		)
	if _right_cherry != null:
		_inflate_tween.parallel().tween_property(
			_right_cherry,
			"scale",
			_right_base_scale * inflate_scale_multiplier,
			duration
		)


func _get_explode_duration_seconds() -> float:
	# Prefer remaining time if the timer is already running (e.g., autostart timer).
	if explode_timer != null:
		return explode_timer.time_left if explode_timer.time_left > 0.0 else explode_timer.wait_time
	return 0.0


func _on_explode_timer_timeout() -> void:
	# Keep ExplosionPlant behavior, but explicit override makes intent clear.
	explode("mine_kill")
	return
