extends PlantBase
class_name ExplosionPlant

@export var explode_timer_path: NodePath = NodePath("ExplodeTimer")
@export var explosion_area_path: NodePath = NodePath("ExplosionArea")

var explode_timer: Timer
var explosion_area: Area2D

@export var explosion_damage: int = 1800

var exploded: bool = false
var start_explode_timer: bool = true

func _ready() -> void:
	super._ready()
	explosion_area = get_node_or_null(explosion_area_path) as Area2D
	explode_timer = get_node_or_null(explode_timer_path) as Timer
	exploded = false
	
	if explode_timer != null:
		if not explode_timer.timeout.is_connected(_on_explode_timer_timeout):
			explode_timer.timeout.connect(_on_explode_timer_timeout)
		if explode_timer.is_stopped() and start_explode_timer == true:
			explode_timer.start()
	else:
		push_warning("ExplosionPlant: missing ExplodeTimer")
		
	_bind_area_signals()

func _bind_area_signals() -> void:
	if explosion_area != null:
		explosion_area.monitoring = true
	else:
		push_warning("ExplosionPlant: missing ExplosionArea")


func _on_explode_timer_timeout() -> void:
	explode()
	
func explode(kill_type: StringName = "explode_kill") -> void:
	if exploded:
		return
	exploded = true
	# Apply damage/kill to all bodies in the blast area.
	var bodies: Array[Node2D] = []
	if explosion_area != null:
		bodies = explosion_area.get_overlapping_bodies()

	print(bodies.size())
	for body in bodies:
		_apply_explode_effect(body, kill_type)
	queue_free()
	

func _apply_explode_effect(body: Node, kill_type = "explode_kill") -> void:
	if body == null or not is_instance_valid(body):
		return
	if not _is_zombie(body):
		return
	
	var target_health := _resolve_health_from(body)
	if target_health != null:
		if target_health.hp > explosion_damage:
			if body.has_method("take_damage"):
				body.call("take_damage", explosion_damage)
			else:
				body.queue_free()
		else:
			if body.has_method(kill_type):	#if target have kill_type, implement that type
				body.call(kill_type)
				return
			else:
				target_health.hp = 0
				target_health.died.emit()
				return
	else:
		body.queue_free()


func _is_zombie(node: Node) -> bool:
	return node != null and (node.is_in_group("zombies") or node.is_in_group("enemies"))
	
	
func _resolve_health_from(node: Node) -> Health:
	# Common convention in this repo: a child named "Health" with scripts/components/health.gd
	var direct := node.get_node_or_null("Health")
	if direct is Health:
		return direct as Health

	# Generic search for any Health child.
	for child in node.get_children():
		if child is Health:
			return child as Health

	return null
