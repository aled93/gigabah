class_name HUDAbility
extends Node

@export var ability: Ability:
	set(val):
		ability = val
		_update_visual()

@onready var ability_icon: TextureRect = %AbilityIcon
@onready var cooldown_bar: TextureProgressBar = %CooldownBar
@onready var cooldown_num: Label = %CooldownNumber

var _prev_cd := 0.0


func _update_visual() -> void:
	if not ability or multiplayer.is_server():
		return

	var cd := ability.cooldown
	if cd > _prev_cd:
		cooldown_bar.max_value = cd
	_prev_cd = cd

	if cd > 0.0:
		cooldown_bar.value = ability.cooldown
		cooldown_num.text = Utils.get_human_readable_duration_short(cd)

		cooldown_bar.visible = true
		cooldown_num.visible = true
	else:
		cooldown_bar.visible = false
		cooldown_num.visible = false


func _process(_delta: float) -> void:
	_update_visual()
