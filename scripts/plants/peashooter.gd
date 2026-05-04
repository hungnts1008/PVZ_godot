extends PlantBase
class_name Peashooter

@export var shoot_timer_path: NodePath = NodePath("ShootTimer")
@export var muzzle_path: NodePath = NodePath("PeaPosition")

@export var projectile_scene: PackedScene = preload("res://scenes/projectiles/pea.tscn")
@export var projectile_speed: float = 450.0
@export var projectile_damage: int = 20

@onready var shoot_timer: ShootTimer = get_node_or_null(shoot_timer_path) as ShootTimer
@onready var muzzle: Marker2D = get_node_or_null(muzzle_path) as Marker2D

var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	super._ready()
	input_pickable = true
	if shoot_timer == null:
		push_warning("Peashooter: shoot_timer_path is invalid")
		return
	if muzzle == null:
		push_warning("Peashooter: muzzle_path is invalid")
		return
	shoot_timer.shoot_requested.connect(_on_shoot_requested)

func _on_shoot_requested(_target: Node2D) -> void:
	# Peashooter in PVZ just shoots straight in its lane; target is informational.
	_shoot(Vector2.RIGHT)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	# Drag with left mouse button.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_is_dragging = event.pressed
		if _is_dragging:
			_drag_offset = global_position - get_global_mouse_position()
		return

func _process(_delta: float) -> void:
	if _is_dragging:
		global_position = get_global_mouse_position() + _drag_offset

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
