extends TextureButton

signal plant_selected(data)

var plant_data = {
	"name": "sun_flower",
	"cost": 50
}

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	emit_signal("plant_selected", plant_data)
	print("button clicked: sun_flower")
	
