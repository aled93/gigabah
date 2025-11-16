extends AudioAnimationLink

@export var animation_player: AnimationPlayer


func _ready() -> void:
	if multiplayer.is_server():
		return

	_create_walk_audio_track()
	_create_land_audio_track()
	_create_jump_audio_track()


func _create_walk_audio_track() -> void:
	var animation: Animation = animation_player.get_animation("Walk")

	if !animation:
		push_error("Walk animation not found. Can't attach sfx")

	add_keys_for_animation(animation, [0.5, 1.1667])


func _create_land_audio_track() -> void:
	var animation: Animation = animation_player.get_animation("Land")

	if !animation:
		push_error("Land animation not found. Can't attach sfx")

	add_keys_for_animation(animation, [0.0])


func _create_jump_audio_track() -> void:
	var animation: Animation = animation_player.get_animation("Jump")

	if !animation:
		push_error("jump animation not found. Can't attach sfx")

	add_keys_for_animation(animation, [0.0])
