extends AudioAnimationLink

@export var animationPlayer: AnimationPlayer;
@export var animationTree: AnimationTree;
@export var hero: Hero;

@onready var castStream: AudioStream = load("res://assets/audio/sfx/player_cast_sfx.tres");
@onready var deathStream: AudioStream = load("res://assets/audio/sfx/player_death.wav");

func _ready() -> void:
	if multiplayer.is_server():
		return
		
	_createCastAudio()
	_createDeathAudio()
		
func _createCastAudio() -> void:
	var animationsList: PackedStringArray = animationPlayer.get_animation_list()
	for animationName in animationsList:
		if !animationName.begins_with("Cast"):
			continue
		
		var animation: Animation = animationPlayer.get_animation(animationName)
		addKeysForAnimation(animation, [0.1], "_playCastAudio")
	
	# нужно включить в фильтр текущую ноду, иначе она будет отфильтрована, 
	# и звуковой эффект не будет проигран
	var aliveNode: AnimationNodeBlendTree = animationTree.tree_root.get_node("Alive")
	var upperBodyOneShotNode: AnimationNodeOneShot = aliveNode.get_node("UpperBodyCasts")
	upperBodyOneShotNode.set_filter_path("./" + name, true)

func _createDeathAudio() -> void:
	hero.health.health_depleted.connect(_playDeathAudio)
	
func _playDeathAudio() -> void:
	stream = deathStream
	play()

func _playCastAudio() -> void:
	stream = castStream
	play()
