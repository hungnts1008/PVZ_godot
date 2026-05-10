extends PlantBase
class_name SunProducer

@export var sun_timer_path: NodePath = NodePath("SunTimer")
@export var sun_position_path: NodePath = NodePath("SunPosition")
@export var glow_timer_path: NodePath = NodePath("GlowTimer")

@export var sun_scene: PackedScene = preload("res://Projectiles/sun.tscn")
@export var sun_amount: int = 25

@onready var sun_timer: Timer = get_node_or_null(sun_timer_path) as Timer
@onready var sun_position: Marker2D = get_node_or_null(sun_position_path) as Marker2D
@onready var glow_timer: Timer = get_node_or_null(glow_timer_path) as Timer

var _glow_lead_time: float = 0.0

func _ready() -> void:
	super._ready()
	if sun_timer == null:
		push_warning("SunProducer: sun_timer_path is invalid: %s" % [sun_timer_path])
		return
	if sun_position == null:
		push_warning("SunProducer: sun_position_path is invalid: %s" % [sun_position_path])
		return

	sun_timer.timeout.connect(_on_sun_timer_timeout)
	if glow_timer != null:
		_glow_lead_time = glow_timer.wait_time
		glow_timer.one_shot = true
		glow_timer.timeout.connect(_on_glow_timer_timeout)

	_start_cycle()

func _start_cycle() -> void:
	if sun_timer.is_stopped():
		sun_timer.start()
	_schedule_glow()

func _schedule_glow() -> void:
	# Fire glow shortly before the next sun is produced.
	# Uses the cached GlowTimer.wait_time as the "lead time" (seconds before production).
	if glow_timer == null:
		return
	if sun_timer.is_stopped():
		return

	var lead_time := _glow_lead_time
	var delay := sun_timer.time_left - lead_time
	if delay < 0.01:
		delay = 0.01
	if not glow_timer.is_stopped():
		glow_timer.stop()
	glow_timer.start(delay)
	# Reset wait_time so designer value stays stable for future runs/inspector.
	glow_timer.wait_time = _glow_lead_time

func _on_glow_timer_timeout() -> void:
	_on_glow()

func _on_sun_timer_timeout() -> void:
	_produce_sun()
	_on_produced()
	_schedule_glow()

func _produce_sun() -> void:	
	if sun_scene == null:
		push_warning("SunProducer: sun_scene is not set")
		return

	var sun := sun_scene.instantiate() as Node
	if sun == null:
		return

	get_tree().current_scene.add_child(sun)
	if sun is Node2D:
		(sun as Node2D).global_position = sun_position.global_position
	if sun.has_method("setup"):
		sun.call("setup", sun_amount)

# Hooks for subclasses
func _on_glow() -> void: 
	pass

func _on_produced() -> void: 
	pass
