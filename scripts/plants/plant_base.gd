extends StaticBody2D
class_name PlantBase

# Minimal, reusable interface for anything that can take damage.
# Zombies/projectiles can call `take_damage()` without needing to know plant internals.

@export var health_path: NodePath

@onready var health: Health = get_node_or_null(health_path) as Health

func _ready() -> void:
	if health == null and health_path != NodePath():
		push_warning("PlantBase: health_path is set but node is missing: %s" % [health_path])

func take_damage(amount: int) -> void:
	if health != null:
		health.damage(amount)
