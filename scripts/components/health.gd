extends Node
class_name Health

signal damaged(amount: int, current_hp: int)
signal died

var _death_emit_queued: bool = false

@export var max_hp: int = 100:
	set(value):
		max_hp = max(value, 1)
		hp = clamp(hp, 0, max_hp)

@export var hp: int = 100:
	set(value):
		var previous_hp := hp
		hp = clamp(value, 0, max_hp)
		# If hp is set to 0 during scene instantiation (Inspector), listeners may not
		# be connected yet. Defer emission so consumers like PlantBase can connect in _ready().
		if previous_hp > 0 and hp == 0:
			_queue_died_emit()


func _queue_died_emit() -> void:
	if _death_emit_queued:
		return
	_death_emit_queued = true
	call_deferred("_emit_died_if_still_dead")


func _emit_died_if_still_dead() -> void:
	_death_emit_queued = false
	if hp <= 0:
		died.emit()

func damage(amount: int) -> void:
	if amount <= 0 or hp == 0:
		return
	hp = max(hp - amount, 0)
	damaged.emit(amount, hp)

func heal(amount: int) -> void:
	if amount <= 0 or hp == max_hp:
		return
	hp = min(hp + amount, max_hp)
