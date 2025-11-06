@abstract
class_name Modifier
extends Node

var carrier: Hero:
	set(val):
		assert(not carrier, "you can't just change modifier carrier, you need to create new modifier for the new carrier")
		carrier = val
var expire_time := 0.0
var destroy_on_expire := false

signal property_mod_changed(property_name: StringName, mod: PropertyMod, modifier: Modifier)

var _modified_properties: Dictionary[StringName, PropertyMod] = { }


func modify_property(property_name: StringName, amount: Variant, kind: ModifyKind = ModifyKind.PRE_ADDITIVE) -> void:
	var changed := false
	var prop_mod: PropertyMod
	if property_name in _modified_properties:
		prop_mod = _modified_properties[property_name]
	else:
		prop_mod = PropertyMod.new()
		_modified_properties[property_name] = prop_mod
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
