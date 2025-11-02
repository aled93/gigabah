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

		return instance

@export_group("user")
@export var user_display_name: String

@export_group("keybindings")
@export_custom(PropertiesInspector.PROPERTY_HINT_CUSTOM_EDITOR, "keybindings")
var input_action_events: Dictionary[StringName, Array]


func _init() -> void:
	# pull defaults of input bindings
	for action: StringName in InputMap.get_actions():
		input_action_events.set(action, InputMap.action_get_events(action))


func save() -> void:
	print("saving game settings to '%s'" % ProjectSettings.globalize_path(PATH))
	ResourceSaver.save(self, PATH, ResourceSaver.FLAG_NONE)
