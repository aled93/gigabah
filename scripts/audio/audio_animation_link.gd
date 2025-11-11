class_name AudioAnimationLink
extends AudioStreamPlayer3D

func addKeysForAnimation(animation: Animation, keys: Array[float], method: String = "play") -> void:
	var audioTrackIndex: int = animation.add_track(Animation.TYPE_METHOD)
	# Почему-то метод ищется в ноде PlayerModel, но скрипт прикреплён к аудиопотоку.
	# Из-за этого путь "." не работает
	animation.track_set_path(audioTrackIndex, "./" + name)
	
	for key in keys:
		animation.track_insert_key(audioTrackIndex, key, {
			"method": method,
			"args": [],
		}, 0)
