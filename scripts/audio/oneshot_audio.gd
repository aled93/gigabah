class_name OneShotAudio
extends AudioStreamPlayer3D

func _ready() -> void:
	finished.connect(_on_finished)
	play()


func _on_finished() -> void:
	queue_free()
