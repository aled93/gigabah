class_name ModifiableFloat
extends ModifiableProperty

@export var min_value: float = -INF
@export var max_value: float = +INF


func get_property_type() -> Variant.Type:
	return TYPE_FLOAT


func get_default_value() -> Variant:
	return 0.0


func calculate_value(mods: Array[Modifier.PropertyMod]) -> Variant:
	var pre_add := 0.0
	var multiplier := 1.0
	var post_add := 0.0

	for mod: Modifier.PropertyMod in mods:
		match mod.kind:
			Modifier.ModifyKind.PRE_ADDITIVE:
				pre_add += mod.amount
			Modifier.ModifyKind.MULTIPLY:
				multiplier *= 1.0 + mod.amount
			Modifier.ModifyKind.POST_ADDITIVE:
				post_add += mod.amount

	return clampf(pre_add * multiplier + post_add, min_value, max_value)
