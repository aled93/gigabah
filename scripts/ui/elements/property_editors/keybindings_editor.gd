class_name KeybindingsEditor
extends BaseOptionEditor

@onready var _items_container: Container = %ItemsContainer
var _bindings_dict: Dictionary[StringName, Array]
var _editor_scene := preload("res://scenes/ui/elements/property_editors/keybind_editor.tscn")


func set_property_name(_prop_name: String) -> void:
	pass


func set_property_value(value: Variant) -> void:
	_bindings_dict = value as Dictionary
	_populate_editors()


func get_property_value() -> Variant:
	return _bindings_dict


func _populate_editors() -> void:
	for action: StringName in _bindings_dict.keys():
		if action.begins_with("ui_"):
			# lil hacky, but godot 4.5.1 doesn't have method to get
			# what is builtin action and what isn't
			continue

		var events := _bindings_dict[action] as Array
		var editor := _editor_scene.instantiate() as KeybindEditor
		_items_container.add_child(editor)

		editor.set_property_name("input_action_" + action)
		editor.set_property_value(events)
		editor.value_changed.connect(_on_keybind_property_changed.bind(editor, action))


func _on_keybind_property_changed(editor: KeybindEditor, action: StringName) -> void:
	print("keybind for %s changed to %s" % [action, editor.get_property_value()])
	value_changed.emit()
