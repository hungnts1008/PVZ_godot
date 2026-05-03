extends RayCast2D
class_name TargetDetectorRayCast2D

signal target_changed(old_target: Node2D, new_target: Node2D)

@export var required_group: StringName = &"enemies"
@export var ray_length: float = 2000.0

var target: Node2D = null

func _ready() -> void:
	if target_position == Vector2.ZERO:
		target_position = Vector2(ray_length, 0)
	enabled = true

func _physics_process(_delta: float) -> void:
	var new_target: Node2D = null

	if enabled:
		# RayCast2D updates in physics frames, but forcing update keeps it deterministic
		# if the plant is spawned mid-frame.
		force_raycast_update()
		if is_colliding():
			print("colliding")
			var collider := get_collider()
			if collider is CharacterBody2D:
				var collider_2d: CharacterBody2D = collider
				if required_group == StringName() or collider_2d.is_in_group(required_group):
					print("shooting")
					new_target = collider_2d
	
	if new_target != target:
		var old := target
		target = new_target
		target_changed.emit(old, target)
