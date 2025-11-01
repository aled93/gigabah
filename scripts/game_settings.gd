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


func save() -> void:
	print("saving game settings to '%s'" % ProjectSettings.globalize_path(PATH))
	ResourceSaver.save(self, PATH, ResourceSaver.FLAG_NONE)
