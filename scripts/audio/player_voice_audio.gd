extends AudioAnimationLink

@export var animation_player: AnimationPlayer
@export var animation_tree: AnimationTree
@export var hero: Hero

@onready var cast_stream: AudioStream = load("res://assets/audio/sfx/player_cast_sfx.tres")
@onready var death_stream: AudioStream = load("res://assets/audio/sfx/player_death.wav")


func _ready() -> void:
	if multiplayer.is_server():
		return

	_create_cast_audio()
	_create_death_audio()


func _create_cast_audio() -> void:
	var animations_list: PackedStringArray = animation_player.get_animation_list()
	for animation_name in animations_list:
		if !animation_name.begins_with("Cast"):
			continue

		var animation: Animation = animation_player.get_animation(animation_name)
		add_keys_for_animation(animation, [0.1], "_play_cast_audio")

	# нужно включить в фильтр текущую ноду, иначе она будет отфильтрована,
	# и звуковой эффект не будет проигран
	var alive_node: AnimationNodeBlendTree = animation_tree.tree_root.get_node("Alive")
	var upper_body_oneshot_node: AnimationNodeOneShot = alive_node.get_node("UpperBodyCasts")
	upper_body_oneshot_node.set_filter_path("./" + name, true)


func _create_death_audio() -> void:
	hero.health.health_depleted.connect(_play_death_audio)


func _play_death_audio() -> void:
	AudioManagerScene.spawn_3d_audio(death_stream, global_position)


func _play_cast_audio() -> void:
	stream = cast_stream
	play()
