extends Node


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

	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
