class_name App
extends Node

static var cmdline_arguments: Dictionary[String, Variant]

@export var dedicated_server_scene: PackedScene
@export var client_scene: PackedScene


static func _static_init() -> void:
	for arg: String in OS.get_cmdline_args():
		var parts := arg.split("=", true, 1)
		if parts.size() == 1:
			cmdline_arguments.set(parts[0], true)
			continue

		cmdline_arguments.set(parts[0], parts[1])


func _ready() -> void:
	var next_scene: PackedScene

	if OS.has_feature("dedicated_server"):
		NetworkManager.start_server()
		next_scene = dedicated_server_scene
	else:
		next_scene = client_scene

	get_tree().call_deferred(&"change_scene_to_packed", next_scene)
