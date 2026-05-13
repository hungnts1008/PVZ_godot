extends Node
class_name DamageStages

@export var health_path: NodePath
@export var sprite_path: NodePath

@export var thresholds: Array[float] = []

# If you use Sprite2D: set textures per stage (size should be thresholds.size() + 1)
@export var stage_textures: Array[Texture2D] = []

# If you use AnimatedSprite2D: set animation per stage (size should be thresholds.size() + 1)
@export var stage_animations: Array[StringName] = []

var _health: Health
var _sprite: Node
var _stage: int = -1

func _ready() -> void:
	_health = _resolve_health()
	_sprite = _resolve_sprite()

	if _health == null:
		push_warning("DamageStages: missing Health (set health_path or place Health as sibling/child)")
		return
	_stage = 0
	_health.damaged.connect(_on_health_changed)
	_health.died.connect(_on_health_died)
	_update_visual(_health.hp)


func _resolve_health() -> Health:
	if health_path != NodePath():
		return get_node_or_null(health_path) as Health

	# Convenience fallback: search parent children for first Health
	var parent := get_parent()
	if parent != null:
		for child in parent.get_children():
			if child is Health:
				return child
	return null


func _resolve_sprite() -> Node:
	if sprite_path != NodePath():
		return get_node_or_null(sprite_path)

	# Convenience fallback: search parent for a Sprite2D/AnimatedSprite2D
	var parent := get_parent()
	if parent != null:
		for child in parent.get_children():
			if child is Sprite2D or child is AnimatedSprite2D:
				return child
	return null


func _on_health_changed(_amount: int, current_hp: int) -> void:
	_update_visual(current_hp)


func _on_health_died() -> void:
	_update_visual(0)


func _update_visual(current_hp: int) -> void:
	if _health == null:
		return

	var ratio := 0.0
	if _health.max_hp > 0:
		ratio = float(current_hp) / float(_health.max_hp)
	
	var new_stage := _compute_stage(ratio)
	if new_stage == _stage:
		return

	_stage = new_stage
	_apply_stage(_stage)


func _compute_stage(hp_ratio: float) -> int:
	var stage := 0
	for t in thresholds:
		if hp_ratio <= t:
			stage += 1
	return stage


func _apply_stage(stage: int) -> void:
	if _sprite == null:
		return

	if _sprite is Sprite2D:
		var sprite2d := _sprite as Sprite2D
		if stage_textures.size() == 0:
			return
		var index : int = clamp(stage, 0, stage_textures.size() - 1)
		sprite2d.texture = stage_textures[index]
		return

	if _sprite is AnimatedSprite2D:
		var animated := _sprite as AnimatedSprite2D
		if stage_animations.size() == 0:
			return
		var index : int = clamp(stage, 0, stage_animations.size() - 1)
		var anim := stage_animations[index]
		if anim != StringName() and animated.sprite_frames != null and animated.sprite_frames.has_animation(anim):
			animated.play(anim)
		return
