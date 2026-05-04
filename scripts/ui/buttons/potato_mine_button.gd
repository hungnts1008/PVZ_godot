extends TextureButton

signal plant_selected(data)

var plant_data = {
	"name": "potato_mine",
	"cost": 25
}

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	emit_signal("plant_selected", plant_data)
	print("button clicked: potato_mine")
	
