extends Node
class_name ZombieSpawner

@export var arena_background_path: NodePath = NodePath("../Arena/Sprite2D")
@export var spawn_point_path: NodePath = NodePath("../Arena/ZombieSpawnerPoint")
@onready var spawn_point: Node2D = get_node_or_null(spawn_point_path)
@export var spawn_padding: float = 94
@export var lane_count: int = 5
@export var lane_top_padding: float = 84.0
@export var lane_bottom_padding: float = 84.0

@export var initial_wave_delay: float = 0
@export var wave_pause_min: float = 8.0
@export var wave_pause_max: float = 14.0
@export var spawn_gap_min: float = 1.5
@export var spawn_gap_max: float = 3.0
@export var max_active_zombies: int = 8

@export var regular_zombie_scene: PackedScene = preload("res://zombie/regular_zombie.tscn")
@export var flag_zombie_scene: PackedScene = preload("res://zombie/flag_zombie.tscn")
@export var cone_zombie_scene: PackedScene = preload("res://zombie/cone_head_zombie.tscn")
@export var bucket_zombie_scene: PackedScene = preload("res://zombie/bucket_head_zombie.tscn")

var _background: Sprite2D = null
var _spawn_timer: Timer = null
var _rng := RandomNumberGenerator.new()
var _lane_positions: Array[float] = []
var _wave_index: int = 0
var _remaining_in_wave: int = 0
var _active_zombies: int = 0


func _ready() -> void:
	_rng.randomize()
	_background = get_node_or_null(arena_background_path) as Sprite2D

	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = true
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)

	_rebuild_lane_positions()
	_start_wave(initial_wave_delay)


func _rebuild_lane_positions() -> void:
	_lane_positions.clear()
	var count : int = max(lane_count, 1)

	if _background == null or _background.texture == null:
		for index in count:
			_lane_positions.append(180.0 + float(index) * 100.0)
		return

	var bg_size := _background.texture.get_size() * _background.scale
	if _background.region_enabled:
		bg_size = _background.region_rect.size * _background.scale

	var start_y := _background.global_position.y + lane_top_padding
	var usable_height : float = max(bg_size.y - lane_top_padding - lane_bottom_padding, 1.0)
	var step : float = usable_height / float(count)

	for index in count:
		_lane_positions.append(start_y + step * (float(index) + 0.5))


func _start_wave(delay: float) -> void:
	_remaining_in_wave = _wave_size_for(_wave_index)
	_spawn_timer.start(max(delay, 0.05))


func _on_spawn_timer_timeout() -> void:
	if _remaining_in_wave <= 0:
		_wave_index += 1
		_start_wave(_rng.randf_range(wave_pause_min, wave_pause_max))
		return

	if _active_zombies >= max_active_zombies:
		_spawn_timer.start(0.5)
		return

	_spawn_one()
	_remaining_in_wave -= 1

	if _remaining_in_wave > 0:
		_spawn_timer.start(_rng.randf_range(spawn_gap_min, spawn_gap_max))
	else:
		_wave_index += 1
		_spawn_timer.start(_rng.randf_range(wave_pause_min, wave_pause_max))


func _spawn_one() -> void:
	var zombie_scene := _pick_zombie_scene()
	if zombie_scene == null:
		push_warning("ZombieSpawner: no zombie scene assigned")
		return

	var zombie := zombie_scene.instantiate() as Node2D
	if zombie == null:
		return

	var root := get_tree().current_scene
	if root == null:
		root = get_tree().root

	root.add_child(zombie)
	zombie.global_position = Vector2(_spawn_x(), _pick_lane_y())
	zombie.tree_exited.connect(_on_spawned_zombie_exited)
	_active_zombies += 1


func _spawn_x() -> float:
	if spawn_point != null:
		prints("not null")
		return spawn_point.global_position.x + spawn_padding
	else:
		prints("null")
	if _background == null or _background.texture == null:
		return 1600.0
	
	var bg_size := _background.texture.get_size() * _background.scale
	if _background.region_enabled:
		bg_size = _background.region_rect.size * _background.scale
		
	return _background.global_position.x + bg_size.x + spawn_padding


func _pick_lane_y() -> float:
	if _lane_positions.is_empty():
		return 200.0

	return _lane_positions[_rng.randi_range(0, _lane_positions.size() - 1)]


func _pick_zombie_scene() -> PackedScene:
	var roll := _rng.randf()

	if _wave_index < 2:
		return regular_zombie_scene

	if _wave_index < 4:
		if roll < 0.7 or flag_zombie_scene == null:
			return regular_zombie_scene
		return flag_zombie_scene

	if _wave_index < 7:
		if roll < 0.45 or regular_zombie_scene == null:
			return regular_zombie_scene
		if roll < 0.75 or cone_zombie_scene == null:
			return flag_zombie_scene if flag_zombie_scene != null else regular_zombie_scene
		return cone_zombie_scene

	if roll < 0.35 or regular_zombie_scene == null:
		return regular_zombie_scene
	if roll < 0.6 and flag_zombie_scene != null:
		return flag_zombie_scene
	if roll < 0.85 and cone_zombie_scene != null:
		return cone_zombie_scene
	return bucket_zombie_scene if bucket_zombie_scene != null else cone_zombie_scene if cone_zombie_scene != null else regular_zombie_scene


func _wave_size_for(wave_index: int) -> int:
	return clamp(3 + wave_index, 3, 18)


func _on_spawned_zombie_exited() -> void:
	_active_zombies = max(_active_zombies - 1, 0)
