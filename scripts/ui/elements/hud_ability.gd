class_name HUDAbility
extends Node

@export var ability: Ability:
	set(val):
		if ability:
			_unlink_ability()

		ability = val

		if ability:
			_link_ability()
			_update_visual()
			call_deferred(&"_set_icon_texture")

@onready var ability_icon: TextureRect = %AbilityIcon
@onready var cooldown_bar: TextureProgressBar = %CooldownBar
@onready var cooldown_num: Label = %CooldownNumber

var _prev_cd := 0.0


func _link_ability() -> void:
	ability.icon_path_changed.connect(_set_icon_texture)


func _unlink_ability() -> void:
	ability.icon_path_changed.disconnect(_set_icon_texture)


func _set_icon_texture() -> void:
	var texture_path := ability.icon_path
	if texture_path.is_empty():
		ability_icon.texture = null
		return

	var res := load(texture_path)
	if not res or res is not Texture2D:
		ability_icon.texture = null
		return

	ability_icon.texture = res as Texture2D


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
