extends Node

@export var grid_origin: Vector2 = Vector2(240, 180)
@export var cell_size: Vector2 = Vector2(100, 100)
@export var grid_columns: int = 9
@export var grid_rows: int = 5

var _selected_plant_key: String = ""
var _occupied_tiles: Dictionary = {}

var _plant_scenes := {
	"pea_shooter": preload("res://scenes/plants/peashooter.tscn"),
	"sun_flower": preload("res://scenes/plants/sunflower.tscn"),
	"wall_nut": preload("res://scenes/plants/wall_nut.tscn"),
	"cherry_bomb": preload("res://scenes/plants/cherry_bomb.tscn"),
	"snow_pea": preload("res://scenes/plants/snow_pea.tscn"),
	"repeater": preload("res://scenes/plants/repeater.tscn"),
	"chomper": preload("res://scenes/plants/chomper.tscn"),
	"potato_mine": preload("res://scenes/plants/potato_mine_1.tscn")
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var screen_size = get_viewport().get_visible_rect().size 
	var bg = $Arena/Sprite2D 
	var bg_size = bg.texture.get_size() * bg.scale 
	var cam = $Arena/Camera2D 
	
	var zoom_x = screen_size.x / bg_size.x 
	var zoom = zoom_x 
	zoom = round(zoom * 10) / 10
	
	cam.zoom = Vector2(zoom, zoom*1.1) 
	bg.position.y = 98

	_connect_shop_buttons()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _selected_plant_key == "":
			return
		if _is_mouse_over_ui():
			return
		_try_place_selected()

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _connect_shop_buttons() -> void:
	var buttons := [
		$UI/Shop/ShopPanel/HBoxContainer/SunFlowerButton,
		$UI/Shop/ShopPanel/HBoxContainer/PeaShooterButton,
		$UI/Shop/ShopPanel/HBoxContainer/WallNutButton,
		$UI/Shop/ShopPanel/HBoxContainer/CherryBombButton,
		$UI/Shop/ShopPanel/HBoxContainer/SnowPeaButton,
		$UI/Shop/ShopPanel/HBoxContainer/RepeaterButton,
		$UI/Shop/ShopPanel/HBoxContainer/ChomperButton,
		$UI/Shop/ShopPanel/HBoxContainer/PotatoMineButton
	]
	for button in buttons:
		if button.has_signal("plant_selected"):
			button.plant_selected.connect(_on_plant_selected)

func _on_plant_selected(data: Dictionary) -> void:
	_selected_plant_key = data.get("name", "")
	print("selected plant: %s" % [_selected_plant_key])

func _try_place_selected() -> void:
	var world_pos = _get_mouse_world_position()
	var local = world_pos - grid_origin
	var col = int(floor(local.x / cell_size.x))
	var row = int(floor(local.y / cell_size.y))
	if col < 0 or row < 0 or col >= grid_columns or row >= grid_rows:
		return
	var key = Vector2i(col, row)
	if _occupied_tiles.has(key):
		return
	var plant_scene: PackedScene = _plant_scenes.get(_selected_plant_key, null)
	if plant_scene == null:
		return
	var plant = plant_scene.instantiate()
	$Arena.add_child(plant)
	if plant is Node2D:
		plant.global_position = grid_origin + Vector2((col + 0.5) * cell_size.x, (row + 0.5) * cell_size.y)
	_occupied_tiles[key] = true

func _get_mouse_world_position() -> Vector2:
	var cam := $Arena/Camera2D
	if cam != null:
		return cam.get_global_mouse_position()
	return get_viewport().get_mouse_position()

func _is_mouse_over_ui() -> bool:
	return get_viewport().gui_get_hovered_control() != null
