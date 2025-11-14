class_name HeroBaseModifier
extends Modifier

func _modifier_start() -> void:
	modify_property(&"move_speed", 5.0)
	modify_property(&"turn_rate", 180.0)
	modify_property(&"hp_regen", 1.0)
