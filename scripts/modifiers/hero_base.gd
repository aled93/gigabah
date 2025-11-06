class_name HeroBaseModifier
extends Modifier

func _ready() -> void:
	modify_property(&"move_speed", 5.0)
	modify_property(&"turn_rate", 180.0)
