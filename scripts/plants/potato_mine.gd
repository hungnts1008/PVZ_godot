extends ExplosionPlant
class_name PotatoMine

@export var sprite1_path: NodePath = NodePath("Sprite1")
@export var sprite2_path: NodePath = NodePath("Sprite2")
@export var grow_timer_path: NodePath = NodePath("GrowTimer")
@export var bulb_path: NodePath = NodePath("Sprite2/Bulb")

@export var near_area_path: NodePath = NodePath("NearArea")
@export var trigger_area_path: NodePath = NodePath("TriggerArea")

@export var blink_anim_slow: StringName = &"blink_slow"
@export var blink_anim_fast: StringName = &"blink_fast"

var _sprite1: Node2D
var _sprite2: Node2D
var _grow_timer: Timer
var _bulb: AnimatedSprite2D

var _near_area: Area2D
var _trigger_area: Area2D

var _armed: bool = false
var _near_zombies: Dictionary = {}


func _ready() -> void:

	_sprite1 = get_node_or_null(sprite1_path) as Node2D
	_sprite2 = get_node_or_null(sprite2_path) as Node2D
	_grow_timer = get_node_or_null(grow_timer_path) as Timer
	_bulb = get_node_or_null(bulb_path) as AnimatedSprite2D

	_near_area = get_node_or_null(near_area_path) as Area2D
	_trigger_area = get_node_or_null(trigger_area_path) as Area2D

	if _sprite1 != null:
		_sprite1.visible = true
	if _sprite2 != null:
		_sprite2.visible = false

	_armed = false
	start_explode_timer = false

	if _grow_timer != null:
		if not _grow_timer.timeout.is_connected(_on_grow_timer_timeout):
			_grow_timer.timeout.connect(_on_grow_timer_timeout)
		if _grow_timer.is_stopped():
			_grow_timer.start()
	else:
		push_warning("PotatoMine: missing GrowTimer")

	super._ready()
	_update_bulb_blink_animation()

	if not explode_timer.is_stopped():
		explode_timer.stop()


func _bind_area_signals() -> void:
	if _near_area != null:
		_near_area.monitoring = true
		if not _near_area.body_entered.is_connected(_on_near_body_entered):
			_near_area.body_entered.connect(_on_near_body_entered)
		if not _near_area.body_exited.is_connected(_on_near_body_exited):
			_near_area.body_exited.connect(_on_near_body_exited)

	if _trigger_area != null:
		_trigger_area.monitoring = true
		if not _trigger_area.body_entered.is_connected(_on_trigger_body_entered):
			_trigger_area.body_entered.connect(_on_trigger_body_entered)
	else:
		push_warning("PotatoMine: missing TriggerArea")
	super._bind_area_signals()


func _on_explode_timer_timeout() -> void:
	explode("mine_kill")
	
	
func _on_grow_timer_timeout() -> void:
	_arm()


func _arm() -> void:
	if _armed:
		return
	_armed = true

	if _sprite1 != null:
		_sprite1.visible = false
	if _sprite2 != null:
		_sprite2.visible = true

	_update_bulb_blink_animation(true)
	# If a zombie entered TriggerArea while we were still growing, body_entered
	# already fired and was ignored. Check overlaps after arming to explode reliably.
	call_deferred("_explode_if_zombie_already_in_trigger")


func _explode_if_zombie_already_in_trigger() -> void:
	if exploded or not _armed:
		return
	if _trigger_area == null:
		return
	# Requires monitoring=true; we set it in _bind_area_signals().
	for body in _trigger_area.get_overlapping_bodies():
		if _is_zombie(body):
			explode_timer.start()
			return


func _on_near_body_entered(body: Node) -> void:
	if _is_zombie(body):
		_near_zombies[body.get_instance_id()] = body
		_update_bulb_blink_animation()


func _on_near_body_exited(body: Node) -> void:
	if body == null:
		return
	var id := body.get_instance_id()
	if _near_zombies.has(id):
		_near_zombies.erase(id)
		_update_bulb_blink_animation()


func _on_trigger_body_entered(body: Node) -> void:
	if not _armed or exploded:
		return
	if not _is_zombie(body):
		return
	explode()


func _update_bulb_blink_animation(force_restart: bool = false) -> void:
	if _bulb == null:
		return
	if not _armed:
		return
	if _bulb.sprite_frames == null:
		return

	_cleanup_near_cache()
	var any_near := _near_zombies.size() > 0
	var desired := blink_anim_fast if any_near else blink_anim_slow
	if desired == StringName():
		return
	if not _bulb.sprite_frames.has_animation(desired):
		return
	if force_restart or (not _bulb.is_playing()) or _bulb.animation != desired:
		_bulb.play(desired)


func _cleanup_near_cache() -> void:
	# Remove invalid instances to keep size() accurate.
	var to_remove: Array[int] = []
	for id in _near_zombies.keys():
		var n: Node = _near_zombies[id]
		if n == null or not is_instance_valid(n):
			to_remove.append(id)
	for id in to_remove:
		_near_zombies.erase(id)
