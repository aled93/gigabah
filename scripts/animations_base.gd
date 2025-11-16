extends Node

## Speed (in m/s) of walking animation when foots on floor not slides
const WALK_ANIM_SPEED = 5.0

@export var input_controller: InputController
@export var hero: Hero
@export var caster: Caster
@export var animation_tree: AnimationTree


func _ready() -> void:
	if !multiplayer.is_server():
		return

	caster.start_casting.connect(_on_caster_start_casting)


func _process(_delta: float) -> void:
	if !multiplayer.is_server():
		return

	animation_tree.set(
		&"parameters/Alive/BodyBottomGraph/WalkBlend/blend_position",
		hero.velocity.length() / WALK_ANIM_SPEED,
	)
	animation_tree.set(
		&"parameters/Alive/BodyBottomGraph/conditions/grounded",
		hero.is_on_floor(),
	)


func _on_caster_start_casting(_ability: Ability) -> void:
	_set_tree_param(
		&"parameters/Alive/UpperBodyCastAnim/transition_request",
		"Cast1" if Time.get_ticks_msec() % 2 == 0 else "Cast2",
	)
	_set_tree_param(
		&"parameters/Alive/UpperBodyCasts/request",
		AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE,
	)


## intended to use to request one shot animations because NetworkSynchronizer
## can skip window when `*/request` is set and before it unsets by tree
func _set_tree_param(param: StringName, value: Variant) -> void:
	NetSync.rpc_to_observing_peers(owner, _rpc_set_tree_param, [param, value])


@rpc("authority", "reliable", "call_local")
func _rpc_set_tree_param(param: StringName, value: Variant) -> void:
	animation_tree.set(param, value)
