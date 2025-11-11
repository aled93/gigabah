extends AudioAnimationLink

@export var animationPlayer: AnimationPlayer;

func _ready() -> void:
	if multiplayer.is_server():
		return
	
	_createWalkAudioTrack()
	_createLandAudioTrack()
	_createJumpAudioTrack()

func _createWalkAudioTrack() -> void:
	var walkAnimation: Animation = animationPlayer.get_animation("Walk")
	
	if !walkAnimation:
		push_error("Walk animation not found. Can't attach sfx")
	
	addKeysForAnimation(walkAnimation, [0.5, 1.1667])
	
func _createLandAudioTrack() -> void:
	var landAnimation: Animation = animationPlayer.get_animation("Land")
	
	if !landAnimation:
		push_error("Land animation not found. Can't attach sfx")
		
	addKeysForAnimation(landAnimation, [0.0])
	
func _createJumpAudioTrack() -> void:
	var animation: Animation = animationPlayer.get_animation("Jump")
	
	if !animation:
		push_error("jump animation not found. Can't attach sfx")
		
	addKeysForAnimation(animation, [0.0])
