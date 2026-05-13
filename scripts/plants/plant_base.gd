extends StaticBody2D
class_name PlantBase

# Minimal, reusable interface for anything that can take damage.
# Zombies/projectiles can call `take_damage()` without needing to know plant internals.

@export var health_path: NodePath
@export var auto_find_health: bool = true
@export var free_on_death: bool = true

var health: Health

func _ready() -> void:
	health = _resolve_health()
	if health == null:
		if health_path != NodePath():
			push_warning("PlantBase: health_path is set but node is missing: %s" % [health_path])
		return

	if free_on_death and not health.died.is_connected(_on_health_died):
		health.died.connect(_on_health_died)

func take_damage(amount: int) -> void:
	if health != null:
		health.damage(amount)

func _resolve_health() -> Health:
	if health_path != NodePath():
		return get_node_or_null(health_path) as Health

	if not auto_find_health:
		return null

	for child in get_children():
		if child is Health:
			return child

	return null

func _on_health_died() -> void:
	queue_free()
