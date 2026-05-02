extends SimpleProjectile
class_name FrozenPea

func setup(direction: Vector2, new_speed: float, new_damage: int) -> void:
	super.setup(direction, new_speed, new_damage)
	
func _ready() -> void:
	super._ready()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func _on_body_entered(body: Node) -> void:
	if body != null and body.has_method("take_damage"):
		body.call("take_damage", damage)
		if body.has_method("chillable"):
			body.call("chillable")
			
		queue_free()
