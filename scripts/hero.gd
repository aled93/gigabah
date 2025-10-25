class_name Hero
extends CharacterBody3D

@export var SPEED: float = 5.0
@export var JUMP_VELOCITY: float = 4.5

@export var input_controller: InputController
@export var health: NetworkHP
@export var caster: Caster

signal jumped()
signal landed()

var _local_peer := true
var _prev_cast_mask := 0
var _prev_jump := false
var _prev_is_on_floor := false


func _ready() -> void:
	_local_peer = owner.name.to_int() == multiplayer.get_unique_id()

	if _local_peer and HeroHUD.instance:
		HeroHUD.instance.hero = self


func _exit_tree() -> void:
	if _local_peer and HeroHUD.instance and HeroHUD.instance.hero == self:
		HeroHUD.instance.hero = null


func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		if is_on_floor() and not _prev_is_on_floor:
			landed.emit()

		# Add the gravity.
		if is_on_floor():
			if input_controller.jump_input and not _prev_jump:
				velocity.y = JUMP_VELOCITY
				jumped.emit()

			_prev_jump = input_controller.jump_input
		else:
			velocity += get_gravity() * delta

		velocity.x = input_controller.move_direction.x * SPEED
		velocity.z = input_controller.move_direction.y * SPEED

		_prev_is_on_floor = is_on_floor()
		move_and_slide()


func _process(_delta: float) -> void:
	if multiplayer.is_server() and caster:
		var pressed_cast_mask := input_controller.cast_mask
		# var just_pressed_cast_mask := pressed_cast_mask & ~_prev_cast_mask
		_prev_cast_mask = pressed_cast_mask

		for cast_slot_idx: int in range(3):
			if (pressed_cast_mask & (1 << cast_slot_idx)) == 0:
				continue

			var ability := caster.get_ability(cast_slot_idx)
			if ability:
				_cast_ability(ability)


func _cast_ability(ability: Ability) -> void:
	var dir := Vector3(NAN, NAN, NAN)
	if not is_nan(input_controller.cursor_world_pos.x):
		dir = (input_controller.cursor_world_pos - global_position).normalized()

	ability.set_cast_targets(
		input_controller.cursor_world_pos,
		null,
		dir,
	)
	ability.cast()
