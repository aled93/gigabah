extends Node

@export var dedicated_server_scene: PackedScene
@export var client_scene: PackedScene


func _ready() -> void:
	var next_scene: PackedScene

	if OS.has_feature("dedicated_server"):
		NetworkManager.start_server()
		next_scene = dedicated_server_scene
	else:
		next_scene = client_scene

	get_tree().call_deferred(&"change_scene_to_packed", next_scene)
