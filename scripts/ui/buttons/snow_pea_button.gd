extends TextureButton

signal plant_selected(data)

var plant_data = {
	"name": "snow_pea",
	"cost": 175
}

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	emit_signal("plant_selected", plant_data)
	print("button clicked: snow_pea")
	
