extends SunProducer
class_name Sunflower

@export var glow_node_path: NodePath = NodePath("Sprite")

@onready var _glow_node: CanvasItem = get_node_or_null(glow_node_path) as CanvasItem
var _base_modulate: Color = Color.WHITE


func _ready() -> void:
	super._ready()
	if _glow_node != null:
		_base_modulate = _glow_node.modulate
	
func _on_glow() -> void:
	# Simple "ready" feedback: brighten shortly before producing sun.
	if _glow_node != null:
		_glow_node.modulate = _base_modulate * Color(1.25, 1.25, 1.25, 1.0)

func _on_produced() -> void:
	# Reset glow after production.
	if _glow_node != null:
		_glow_node.modulate = _base_modulate
