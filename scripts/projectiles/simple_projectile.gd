extends Area2D
class_name SimpleProjectile

@export var speed: float = 450.0
@export var damage: int = 20
@export var lifetime_sec: float = 5.0

var _direction: Vector2 = Vector2.RIGHT
var _life_left: float

func setup(direction: Vector2, new_speed: float, new_damage: int) -> void:
	_direction = direction.normalized() if direction.length() > 0.0 else Vector2.RIGHT
	speed = new_speed
	damage = new_damage

func _ready() -> void:
	_life_left = lifetime_sec
	body_entered.connect(_on_body_entered)
	monitoring = true

func _physics_process(delta: float) -> void:
	global_position += _direction * speed * delta
	_life_left -= delta
	if _life_left <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	# Keep this decoupled: call a conventional method if it exists.
	if body != null and body.has_method("take_damage"):
		body.call("take_damage", damage)
		queue_free()
