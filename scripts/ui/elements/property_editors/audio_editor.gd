class_name AudioEditor
extends BaseOptionEditor

@onready var _items_container: Container = %ItemsContainer
var _settings: Dictionary[StringName, AudioSettingsModel] = { }
var _editor_scene := preload("res://scenes/ui/elements/property_editors/audio_bus_editor.tscn")


func _init() -> void:
	var bus_count: int = AudioServer.get_bus_count()
	for bus_index: int in range(bus_count):
		var bus_name: String = AudioServer.get_bus_name(bus_index)
		var bus_settings: AudioSettingsModel = AudioSettingsModel.new()
		bus_settings.volume = AudioServer.get_bus_volume_linear(bus_index)
		bus_settings.muted = AudioServer.is_bus_mute(bus_index)
		_settings.set(bus_name, bus_settings)


func set_property_name(_prop_name: String) -> void:
	pass


func set_property_value(value: Variant) -> void:
	for bus_name: StringName in value as Dictionary[StringName, AudioSettingsModel]:
		_settings[bus_name] = value[bus_name]
	_populate_editors()


func get_property_value() -> Variant:
	return _settings


func _populate_editors() -> void:
	var bus_count: int = AudioServer.get_bus_count()
	for bus_index: int in range(bus_count):
		var bus_name: String = AudioServer.get_bus_name(bus_index)
		var bus_settings: AudioSettingsModel = _settings.get(bus_name)

		if !bus_settings:
			continue

		var editor := _editor_scene.instantiate() as AudioBusEditor
		_items_container.add_child(editor)

		editor.set_property_name("audio_bus_" + bus_name)
		editor.set_property_value(bus_settings)
		editor.value_changed.connect(_update_bus.bind(bus_name))


func _update_bus(bus_name: StringName) -> void:
	var bus_settings: AudioSettingsModel = _settings.get(bus_name)

	if !bus_settings:
		return

	var bus_index: int = AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		return

	AudioServer.set_bus_volume_db(bus_index, linear_to_db(bus_settings.volume))
	AudioServer.set_bus_mute(bus_index, bus_settings.muted)
	value_changed.emit()
