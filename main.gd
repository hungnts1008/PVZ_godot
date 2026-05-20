extends Node

const COLS := 9
const ROWS := 5

# Tune these values in case your lawn art shifts.
@export var grid_origin := Vector2(235.0, 165.0)
@export var cell_size := Vector2(105.0, 95.0)

var selected_plant_data: Dictionary = {}
var occupied_cells: Dictionary = {}
var plant_scenes := {
	"sun_flower": preload("res://Plant/sunflower.tscn"),
	"pea_shooter": preload("res://Plant/peashooter.tscn"),
	"wall_nut": preload("res://Plant/wall_nut.tscn"),
	"cherry_bomb": preload("res://Plant/cherry_bomb.tscn"),
	"snow_pea": preload("res://Plant/snow_pea.tscn"),
	"repeater": preload("res://Plant/repeater.tscn"),
	"chomper": preload("res://Plant/chomper.tscn"),
		"potato_mine": preload("res://Plant/potato_mine.tscn")
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var screen_size = get_viewport().get_visible_rect().size 
	var bg = $Arena/Sprite2D 
	var bg_size = bg.region_rect.size
	var cam = $Arena/Camera2D 
	
	var zoom_x = screen_size.x / bg_size.x 
	var zoom_y = screen_size.y / bg_size.y
	var zoom = max(zoom_x,zoom_y) 
	#zoom = round(zoom * 10) / 10
	cam.zoom = Vector2(zoom, zoom)

	_connect_shop_buttons()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return

	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return

	if selected_plant_data.is_empty():
		return

	var mouse_world :Vector2 = $Arena/Camera2D.get_global_mouse_position()
	if not _is_inside_lawn(mouse_world):
		return

	var cell := _world_to_cell(mouse_world)
	if not _is_cell_inside(cell):
		return

	if occupied_cells.has(cell):
		var existing_entry: Object = occupied_cells.get(cell, null)
		if existing_entry == null or not is_instance_valid(existing_entry):
			occupied_cells.erase(cell)
		else:
			print("Cell already occupied: ", cell)
			return

	_spawn_selected_plant(cell)


func _connect_shop_buttons() -> void:
	var shop_row := $UI/Shop/ShopPanel/HBoxContainer
	for button in shop_row.get_children():
		if button.has_signal("plant_selected"):
			button.plant_selected.connect(_on_plant_selected)


func _on_plant_selected(data: Dictionary) -> void:
	selected_plant_data = data
	print("Selected plant:", selected_plant_data)


func _spawn_selected_plant(cell: Vector2i) -> void:
	var plant_name :String = selected_plant_data.get("name", "")
	if plant_name == "":
		return

	if not plant_scenes.has(plant_name):
		push_warning("No scene mapped for plant: %s" % plant_name)
		return

	var plant_scene: PackedScene = plant_scenes[plant_name]
	var plant_instance := plant_scene.instantiate() as Node2D
	if plant_instance == null:
		push_warning("Failed to instantiate plant: %s" % plant_name)
		return

	plant_instance.global_position = _cell_to_world(cell)
	$Arena.add_child(plant_instance)
	plant_instance.tree_exited.connect(_on_plant_tree_exited.bind(cell, plant_instance), CONNECT_ONE_SHOT)

	occupied_cells[cell] = plant_instance
	selected_plant_data = {}


func _on_plant_tree_exited(cell: Vector2i, plant_instance: Node2D) -> void:
	if not occupied_cells.has(cell):
		return

	var current_entry: Object = occupied_cells.get(cell, null)
	if current_entry == plant_instance:
		occupied_cells.erase(cell)


func _world_to_cell(world_pos: Vector2) -> Vector2i:
	var local := world_pos - grid_origin
	return Vector2i(floor(local.x / cell_size.x), floor(local.y / cell_size.y))


func _cell_to_world(cell: Vector2i) -> Vector2:
	return grid_origin + Vector2(cell.x * cell_size.x, cell.y * cell_size.y) + (cell_size * 0.5)


func _is_cell_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLS and cell.y >= 0 and cell.y < ROWS


func _is_inside_lawn(world_pos: Vector2) -> bool:
	var lawn_size := Vector2(COLS * cell_size.x, ROWS * cell_size.y)
	var lawn_rect := Rect2(grid_origin, lawn_size)
	return lawn_rect.has_point(world_pos)
