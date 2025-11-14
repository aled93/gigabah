class_name AudioManager
extends Node3D

var audio_counter_dict: Dictionary[AudioStream, int] = {}
@export var audio_limit_dict: Dictionary[AudioStream, int] = {}

func _ready() -> void:
	child_entered_tree.connect(print)
	if !multiplayer.is_server():
		return
	
	set_multiplayer_authority(1)
	print("is multiplayer authority: ", is_multiplayer_authority())
	multiplayer.peer_connected.connect(_register_peer)
	multiplayer.peer_disconnected.connect(_unregister_peer)
	print("Audio manager is ready")


func spawn_3d_audio(source: Node3D, stream: AudioStream) -> void:
	if !multiplayer.is_server():
		return
		
	print("spawn 3d")
	if !_has_open_limit(stream):
		print("limit reached")
		return
		
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.set_multiplayer_authority(1)
	player.stream = stream
	player.volume_linear = 1.0
	player.position = source.global_position
	_add_count(stream)
	player.finished.connect(_sub_count.bind(stream), CONNECT_ONE_SHOT)
	player.finished.connect(player.queue_free, CONNECT_ONE_SHOT)
	var synchronizer: MultiplayerSynchronizer = MultiplayerSynchronizer.new()
	synchronizer.replication_config = SceneReplicationConfig.new()
	synchronizer.replication_config.add_property("%s.playing" % player.name)
	player.add_child(synchronizer)
	add_child(player)
	NetSync.inherit_visibility(source, player, true)
	player.play()

func _has_open_limit(stream: AudioStream) -> bool:
	var count: int =audio_counter_dict.get(stream, 0)
	var limit: int = audio_limit_dict.get(stream, 5)
	return count < limit

func _add_count(stream: AudioStream) -> void:
	audio_counter_dict.set(stream, audio_counter_dict.get(stream, 0) + 1)
	
func _sub_count(stream: AudioStream) -> void:
	audio_counter_dict.set(stream, audio_counter_dict.get(stream, 0) - 1)
	
func _register_peer(id: int) -> void:
	print("is multiplayer authority: ", is_multiplayer_authority())
	print("is_server: ", multiplayer.is_server())
	NetSync.set_visibility_for(id, self, true)
	
func _unregister_peer(id: int) -> void:
	NetSync.set_visibility_for(id, self, false)
