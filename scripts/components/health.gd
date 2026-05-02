extends Node
class_name Health

signal damaged(amount: int, current_hp: int)
signal died

@export var max_hp: int = 100:
	set(value):
		max_hp = max(value, 1)
		hp = clamp(hp, 0, max_hp)

@export var hp: int = 100:
	set(value):
		hp = clamp(value, 0, max_hp)
		if hp == 0:
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
