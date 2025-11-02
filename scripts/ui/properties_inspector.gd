class_name PropertiesInspector
extends Node

## export variables using `@export_custom(PropertiesInspector.PROPERTY_HINT_DONT_RENDER, "")`
## and this variable will not be visible in settings page
const PROPERTY_HINT_DONT_RENDER = PROPERTY_HINT_MAX + 1
const PROPERTY_HINT_CUSTOM_EDITOR = PROPERTY_HINT_MAX + 2

@export var properties_container: Container
## Label in property editor will have label with text prefixed with this prefix.
## Intended to automatically use localized name for property
@export var property_name_prefix := ""
## This string will be substituted with property type name (see function `_get_prop_type_name`),
## or with `hint_string` provided using `@export_custom` annotation, to get path to scene of
## editor for this property
@export var property_editor_scene_path_pattern := "res://scenes/ui/elements/property_editors/%s_editor.tscn"

var properties_source: Object
var value_changes: Dictionary[StringName, Variant] = { }

signal property_changed(editor: BaseOptionEditor, new_value: Variant)

var _editors: Dictionary[StringName, BaseOptionEditor] = { }


## Apply all changes made by property editors, `value_changes` will be cleared
func apply_changes() -> void:
	for prop_name: StringName in value_changes.keys():
		var value: Variant = value_changes[prop_name]
		properties_source.set(prop_name, value)

	value_changes.clear()


func get_property_editor(property_name: StringName) -> BaseOptionEditor:
	return _editors.get(property_name) as BaseOptionEditor


func _ready() -> void:
	call_deferred(&"_populate_option_editors")


func _push_values_to_editors() -> void:
	for child_idx: int in range(properties_container.get_child_count()):
		var editor := properties_container.get_child(child_idx) as BaseOptionEditor
		if not editor:
			continue

		var prop_name := editor.get_meta(&"prop_name") as StringName
		var prop_val: Variant = properties_source.get(prop_name)

		editor.set_property_value(prop_val)


func _pull_values_from_editors() -> void:
	for child_idx: int in range(properties_container.get_child_count()):
		var editor := properties_container.get_child(child_idx) as BaseOptionEditor
		if not editor:
			continue

		var prop_name := editor.get_meta(&"prop_name") as StringName
		var prop_new_val: Variant = editor.get_property_value()

		properties_source.set(prop_name, prop_new_val)


func _populate_option_editors() -> void:
	var container_stack: Array[Control] = []
	var cur_container := properties_container

	var props := properties_source.get_property_list()
	var own_properties := false
	for prop: Dictionary in props:
		if not own_properties:
			if (prop.usage & PROPERTY_USAGE_CATEGORY) == 0:
				continue
			elif (prop.hint_string as String).begins_with("res://"):
				own_properties = true

			continue

		if (prop.usage & PROPERTY_USAGE_GROUP) != 0:
			container_stack.push_back(cur_container)

			var scene_path := property_editor_scene_path_pattern % "group"
			var group_node := load(scene_path).instantiate() as Control

			var name_label := group_node.get_node_or_null("%Name")
			if name_label and name_label is Label:
				(name_label as Label).text = property_name_prefix + prop.name

			cur_container.add_child(group_node)

			var slot := group_node.get_node_or_null("%ItemsSlot")
			if slot:
				cur_container = slot
			else:
				cur_container = group_node

			continue

		if (prop.usage & PROPERTY_USAGE_STORAGE) == 0:
			continue

		if prop.hint == PROPERTY_HINT_DONT_RENDER:
			continue

		var prop_name := prop.name as StringName
		var prop_editor := _create_property_editor(prop)
		if not prop_editor:
			continue

		cur_container.add_child(prop_editor)

		var prop_value: Variant = properties_source.get(prop.name)

		prop_editor.set_meta(&"prop_name", prop_name)
		prop_editor.name = prop_name
		prop_editor.set_property_name(property_name_prefix + prop_name)
		prop_editor.set_property_value(prop_value)
		prop_editor.value_changed.connect(_on_editor_value_changed.bind(prop_editor))

		_editors[prop_name] = prop_editor


func _on_editor_value_changed(editor: BaseOptionEditor) -> void:
	var prop_name := editor.get_meta(&"prop_name") as StringName
	var new_val: Variant = editor.get_property_value()

	value_changes[prop_name] = new_val
	property_changed.emit(editor, new_val)


func _create_property_editor(prop: Dictionary) -> BaseOptionEditor:
	var editor_name := _get_prop_type_name(prop)
	if prop.hint == PROPERTY_HINT_CUSTOM_EDITOR:
		editor_name = prop.hint_string as String
	var scene_path: String = property_editor_scene_path_pattern % editor_name
	var control_scene := load(scene_path) as PackedScene
	if control_scene == null:
		return null

	var control := control_scene.instantiate()
	var option_editor := control as BaseOptionEditor
	if not option_editor:
		push_error(
			"scene root doesn't have attached script inherited " +
			"from 'BaseOptionEditor' (scene '%s')" % scene_path,
		)
		control.queue_free()
		return null

	return control


func _get_prop_type_name(prop: Dictionary) -> StringName:
	match prop.type:
		TYPE_OBJECT:
			return prop.class_name
		TYPE_NIL:
			return &"null"
		TYPE_BOOL:
			return &"bool"
		TYPE_INT:
			return &"int"
		TYPE_FLOAT:
			return &"float"
		TYPE_STRING:
			return &"string"
		TYPE_VECTOR2:
			return &"vector2"
		TYPE_VECTOR2I:
			return &"vector2i"
		TYPE_RECT2:
			return &"rect2"
		TYPE_RECT2I:
			return &"rect2i"
		TYPE_VECTOR3:
			return &"vector3"
		TYPE_VECTOR3I:
			return &"vector3i"
		TYPE_TRANSFORM2D:
			return &"transform2d"
		TYPE_VECTOR4:
			return &"vector4"
		TYPE_VECTOR4I:
			return &"vector4i"
		TYPE_PLANE:
			return &"plane"
		TYPE_QUATERNION:
			return &"quaternion"
		TYPE_AABB:
			return &"aabb"
		TYPE_BASIS:
			return &"basis"
		TYPE_TRANSFORM3D:
			return &"transform3d"
		TYPE_PROJECTION:
			return &"projection"
		TYPE_COLOR:
			return &"color"
		TYPE_STRING_NAME:
			return &"stringname"
		TYPE_NODE_PATH:
			return &"nodepath"
		TYPE_RID:
			return &"rid"
		TYPE_OBJECT:
			return &"object"
		TYPE_CALLABLE:
			return &"callable"
		TYPE_SIGNAL:
			return &"signal"
		TYPE_DICTIONARY:
			return &"dictionary"
		TYPE_ARRAY:
			return &"array"
		TYPE_PACKED_BYTE_ARRAY:
			return &"packedbytearray"
		TYPE_PACKED_INT32_ARRAY:
			return &"packedint32array"
		TYPE_PACKED_INT64_ARRAY:
			return &"packedint64array"
		TYPE_PACKED_FLOAT32_ARRAY:
			return &"packedfloat32array"
		TYPE_PACKED_FLOAT64_ARRAY:
			return &"packedfloat64array"
		TYPE_PACKED_STRING_ARRAY:
			return &"packedstringarray"
		TYPE_PACKED_VECTOR2_ARRAY:
			return &"packedvector2array"
		TYPE_PACKED_VECTOR3_ARRAY:
			return &"packedvector3array"
		TYPE_PACKED_COLOR_ARRAY:
			return &"packedcolorarray"
		TYPE_PACKED_VECTOR4_ARRAY:
			return &"packedvector4array"
		_:
			return &"???"
