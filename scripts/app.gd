extends Node

static var cmdline_arguments: Dictionary[String, Variant]

@export var dedicated_server_scene: PackedScene = preload("res://scenes/index.tscn")
@export var client_scene: PackedScene = preload("res://scenes/ui/main_menu.tscn")


static func _static_init() -> void:
	for arg: String in OS.get_cmdline_args():
		var parts := arg.split("=", true, 1)
		if parts.size() == 1:
			cmdline_arguments.set(parts[0], true)
			continue

		cmdline_arguments.set(parts[0], parts[1])


func _ready() -> void:
	get_tree().auto_accept_quit = false

	var next_scene: PackedScene

	if OS.has_feature("dedicated_server"):
		NetworkManager.start_server(cmdline_arguments.get("--listen-address", "*"))
		next_scene = dedicated_server_scene
	else:
		next_scene = client_scene

	print("next scene is %s" % next_scene)
	get_tree().call_deferred(&"change_scene_to_packed", next_scene)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			GameSettings.instance.save()

			get_tree().quit()
