extends PlantBase
class_name Peashooter

@export var shoot_timer_path: NodePath = NodePath("ShootTimer")
@export var muzzle_path: NodePath = NodePath("PeaPosition")

@export var projectile_scene: PackedScene = preload("res://Projectiles/pea.tscn")
@export var projectile_speed: float = 450.0
@export var projectile_damage: int = 20

@onready var shoot_timer: ShootTimer = get_node_or_null(shoot_timer_path) as ShootTimer
@onready var muzzle: Marker2D = get_node_or_null(muzzle_path) as Marker2D

func _ready() -> void:
	super._ready()
	if shoot_timer == null:
		push_warning("Peashooter: shoot_timer_path is invalid")
		return
	if muzzle == null:
		push_warning("Peashooter: muzzle_path is invalid")
		return
	shoot_timer.shoot_requested.connect(_on_shoot_requested)

func _on_shoot_requested(_target: Node2D) -> void:
	# Peashooter in PVZ just shoots straight in its lane; target is informational.
	print("shooting")
	_shoot(Vector2.RIGHT)

func _shoot(direction: Vector2) -> void:
	if projectile_scene == null:
		push_warning("Peashooter: projectile_scene is not set")
		return

	var projectile := projectile_scene.instantiate() as Node
	if projectile == null:
		return

	get_tree().current_scene.add_child(projectile)		#add pea to the main scene
	if projectile is Node2D:
		(projectile as Node2D).global_position = muzzle.global_position

	if projectile.has_method("setup"):
		projectile.call("setup", direction.normalized(), projectile_speed, projectile_damage)
