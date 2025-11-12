class_name GameSettings
extends Resource

const PATH = "user://settings.tres"

static var instance: GameSettings:
	get:
		if instance:
			return instance

		if not ResourceLoader.exists(PATH, "GameSettings"):
			instance = GameSettings.new()
		else:
			print("loading game settings from '%s'" % ProjectSettings.globalize_path(PATH))
			instance = ResourceLoader.load(
				PATH,
				"LauncherPreferences",
				ResourceLoader.CACHE_MODE_REUSE,
			) as GameSettings
			instance._post_load()

		return instance

@export_group("user")
@export var user_display_name: String

@export_group("keybindings")
@export_custom(PropertiesInspector.PROPERTY_HINT_CUSTOM_EDITOR, "keybindings")
# used only for persistance of input map, don't use directly
var _input_action_events: Dictionary[StringName, Array]

@export_group("audio")
@export_custom(PropertiesInspector.PROPERTY_HINT_CUSTOM_EDITOR, "audio")
var audio_settings: Dictionary[StringName, AudioSettingsModel]


func _init() -> void:
	# pull defaults of input bindings
	for action: StringName in InputMap.get_actions():
		if not action.begins_with("ui_"):
			_input_action_events.set(action, InputMap.action_get_events(action))


func _post_load() -> void:
	apply_input_action_events()
	apply_audio_settings()


func save() -> void:
	print("saving game settings to '%s'" % ProjectSettings.globalize_path(PATH))
	ResourceSaver.save(self, PATH, ResourceSaver.FLAG_NONE)


func apply_input_action_events() -> void:
	for action: StringName in _input_action_events.keys():
		InputMap.action_erase_events(action)
		for event: InputEvent in _input_action_events[action]:
			InputMap.action_add_event(action, event)


func apply_audio_settings() -> void:
	for bus_name: StringName in audio_settings:
		var bus_index: int = AudioServer.get_bus_index(bus_name)

		if bus_index == -1:
			continue

		var bus_settings: AudioSettingsModel = audio_settings.get(bus_name)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(bus_settings.volume))
		AudioServer.set_bus_mute(bus_index, bus_settings.muted)
