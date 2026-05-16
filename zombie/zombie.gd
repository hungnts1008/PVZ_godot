extends CharacterBody2D
class_name Zombie

enum State { WALK, ATTACK, DEAD }

@export var health_path: NodePath = NodePath("Health")
@export var sprite_path: NodePath = NodePath("AnimatedSprite2D")
@export var attack_timer_path: NodePath = NodePath("Timer")

@export var move_speed: float = 30.0
@export var max_hp: int = 100
@export var attack_damage: int = 20
@export var attack_interval: float = 1.0
@export var damage_animation_threshold: float = 0.5

@export var walk_animation: StringName = &"walk"
@export var attack_animation: StringName = &"attack"
@export var damaged_walk_animation: StringName = &""
@export var damaged_attack_animation: StringName = &""

@onready var health: Health = get_node_or_null(health_path) as Health
@onready var sprite: AnimatedSprite2D = get_node_or_null(sprite_path) as AnimatedSprite2D
@onready var attack_timer: Timer = get_node_or_null(attack_timer_path) as Timer

var _state: State = State.WALK
var _attack_target: Object	 = null


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("zombies")

	if health != null:
		health.max_hp = max_hp
		health.hp = max_hp
		health.died.connect(_on_health_died)
	else:
		push_warning("Zombie: missing Health node")

	if attack_timer == null:
		attack_timer = Timer.new()
		attack_timer.name = "Timer"
		add_child(attack_timer)

	attack_timer.one_shot = false
	attack_timer.wait_time = max(attack_interval, 0.1)
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	_sync_animation(true)


func _physics_process(_delta: float) -> void:
	if _state == State.DEAD:
		return

	if _is_target_valid(_attack_target):
		velocity = Vector2.ZERO
		_set_state(State.ATTACK)
	else:
		_set_attack_target(_find_attack_target())
		if _is_target_valid(_attack_target):
			velocity = Vector2.ZERO
			_set_state(State.ATTACK)
		else:
			_set_attack_target(null)
			velocity = Vector2.LEFT * move_speed
			_set_state(State.WALK)

	move_and_slide()

	if _state == State.ATTACK and _is_target_valid(_attack_target):
		if attack_timer.is_stopped():
			attack_timer.start()
	else:
		attack_timer.stop()


func take_damage(amount: int) -> void:
	if amount <= 0 or _state == State.DEAD:
		return

	if health != null:
		health.damage(amount)


func _find_attack_target() -> Object:
	for index in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(index)
		if collision == null:
			continue

		var body: Object = collision.get_collider()
		if body != null and body.has_method("take_damage"):
			return body

	return null


func _on_attack_timer_timeout() -> void:
	if _state == State.DEAD or not _is_target_valid(_attack_target):
		_set_attack_target(null)
		return

	_attack_target.call("take_damage", attack_damage)


func _set_attack_target(target: Object) -> void:
	_attack_target = target

	var target_node: Node = target as Node
	if target_node == null:
		return

	if not target_node.tree_exited.is_connected(_on_attack_target_tree_exited):
		target_node.tree_exited.connect(_on_attack_target_tree_exited, CONNECT_ONE_SHOT)


func _on_attack_target_tree_exited() -> void:
	_attack_target = null


func _on_health_died() -> void:
	if _state == State.DEAD:
		return

	_state = State.DEAD
	attack_timer.stop()
	queue_free()


func _set_state(new_state: State) -> void:
	if _state == new_state or _state == State.DEAD:
		_sync_animation(false)
		return

	_state = new_state
	_sync_animation(false)


func _sync_animation(force_restart: bool) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return

	var desired_animation := _get_desired_animation()
	if desired_animation == StringName():
		return

	if not sprite.sprite_frames.has_animation(desired_animation):
		return

	if force_restart or sprite.animation != desired_animation:
		sprite.play(desired_animation)


func _get_desired_animation() -> StringName:
	var damaged := health != null and health.max_hp > 0 and float(health.hp) <= float(health.max_hp) * damage_animation_threshold

	if _state == State.ATTACK:
		if damaged and damaged_attack_animation != StringName():
			return damaged_attack_animation
		return attack_animation

	if damaged and damaged_walk_animation != StringName():
		return damaged_walk_animation

	return walk_animation


func _is_target_valid(target: Object) -> bool:
	return target != null and is_instance_valid(target) and target.has_method("take_damage")
