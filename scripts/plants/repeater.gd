extends PlantBase
class_name Repeater

@export var shoot_timer_path: NodePath = NodePath("ShootTimer")
@export var burst_timer_path: NodePath = NodePath("BurstTimer")
@export var muzzle_path: NodePath = NodePath("PeaPosition")

@export var projectile_scene: PackedScene = preload("res://Projectiles/pea.tscn")
@export var projectile_speed: float = 450.0
@export var projectile_damage: int = 20

@onready var shoot_timer: ShootTimer = get_node_or_null(shoot_timer_path) as ShootTimer
@onready var burst_timer: Timer = get_node_or_null(burst_timer_path) as Timer
@onready var muzzle: Marker2D = get_node_or_null(muzzle_path) as Marker2D

var _burst_pending: bool = false

func _ready() -> void:
	super._ready()
	if shoot_timer == null:
		push_warning("Repeater: shoot_timer_path is invalid")
		return
	if burst_timer == null:
		push_warning("Repeater: burst_timer_path is invalid")
		return
	if muzzle == null:
		push_warning("Repeater: muzzle_path is invalid")
		return
	shoot_timer.shoot_requested.connect(_on_shoot_requested)
	burst_timer.one_shot = true
	burst_timer.timeout.connect(_on_burst_timeout)

func _on_shoot_requested(_target: Node2D) -> void:
	# Repeater fires 2 peas in a quick burst.
	print("Shooting")
	_shoot(Vector2.RIGHT)
	_burst_pending = true
	if not burst_timer.is_stopped():
		burst_timer.stop()
	burst_timer.start()

func _on_burst_timeout() -> void:
	if not _burst_pending:
		return
	_burst_pending = false
	_shoot(Vector2.RIGHT)

func _shoot(direction: Vector2) -> void:
	if projectile_scene == null:
		push_warning("Repeater: projectile_scene is not set")
		return

	var projectile := projectile_scene.instantiate() as Node
	if projectile == null:
		return

	get_tree().current_scene.add_child(projectile)		#add pea to the main scene
	if projectile is Node2D:
		(projectile as Node2D).global_position = muzzle.global_position

	if projectile.has_method("setup"):
		projectile.call("setup", direction.normalized(), projectile_speed, projectile_damage)
