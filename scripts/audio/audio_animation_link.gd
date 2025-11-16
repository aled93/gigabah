class_name AudioAnimationLink
extends AudioStreamPlayer3D

func add_keys_for_animation(animation: Animation, keys: Array[float], method: String = "play") -> void:
	var audio_track_index: int = animation.add_track(Animation.TYPE_METHOD)
	# Почему-то метод ищется в ноде PlayerModel, но скрипт прикреплён к аудиопотоку.
	# Из-за этого путь "." не работает
	animation.track_set_path(audio_track_index, "./" + name)

	for key in keys:
		animation.track_insert_key(
			audio_track_index,
			key,
			{
				"method": method,
				"args": [],
			},
			0,
		)
