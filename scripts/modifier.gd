@abstract
class_name Modifier
extends Node

var carrier: Hero:
	set(val):
		assert(not carrier, "you can't just change modifier carrier, you need to create new modifier for the new carrier")
		carrier = val

var icon_path: String = "res://assets/textures/ui/modifier_icons/%s.png" % get_script().get_global_name():
	set(val):
		if val != icon_path:
			icon_path = val
			icon_path_changed.emit()

var expire_time := 0.0
var destroy_on_expire := false
var modified_properties: Dictionary[StringName, PropertyMod] = { }

signal property_mod_changed(property_name: StringName, mod: PropertyMod, modifier: Modifier)
signal icon_path_changed()


func modify_property(property_name: StringName, amount: Variant, kind: ModifyKind = ModifyKind.PRE_ADDITIVE) -> void:
	var changed := false
	var prop_mod: PropertyMod
	if property_name in modified_properties:
		prop_mod = modified_properties[property_name]
	else:
		prop_mod = PropertyMod.new()
		modified_properties[property_name] = prop_mod
		changed = true

	changed = changed or (amount != prop_mod.amount)
	changed = changed or (kind != prop_mod.kind)

	prop_mod.amount = amount
	prop_mod.kind = kind

	if changed:
		property_mod_changed.emit(property_name, prop_mod, self)


func _physics_process(delta: float) -> void:
	if expire_time > delta:
		expire_time -= delta
	else:
		expire_time = 0.0
		if destroy_on_expire:
			queue_free()


enum ModifyKind {
	PRE_ADDITIVE,
	MULTIPLY,
	POST_ADDITIVE,
}


class PropertyMod:
	var amount: Variant
	var kind: ModifyKind
