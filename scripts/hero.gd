class_name Hero
extends CharacterBody3D

@export var input_controller: InputController
@export var health: NetworkHP
@export var caster: Caster
@export var modifiers: Modifiers
@export var model: Node3D

var facing_angle: float:
	get:
		return -model.global_rotation.y - PI * 0.5
	set(val):
		var new_rot := model.global_rotation
		new_rot.y = -val - PI * 0.5
		model.global_rotation = new_rot

var desired_facing_angle: float:
	set(val):
		desired_facing_angle = Utils.cycle_float(val, -PI, PI)

var _local_peer := true
var _prev_cast_mask := 0
var _prev_is_on_floor := false
var _hp_regen_accum := 0.0

@onready var _prop_move_speed := modifiers.get_float_property(&"move_speed")
@onready var _prop_reverse_speed_factor := modifiers.get_float_property(&"reverse_speed_factor")
@onready var _prop_turn_rate := modifiers.get_float_property(&"turn_rate")
@onready var _prop_cant_move := modifiers.get_bool_property(&"cant_move")
@onready var _prop_cant_turn := modifiers.get_bool_property(&"cant_turn")
@onready var _prop_cant_cast := modifiers.get_bool_property(&"cant_cast")
@onready var _prop_hp_regen := modifiers.get_float_property(&"hp_regen")


func _ready() -> void:
	_local_peer = owner.name.to_int() == multiplayer.get_unique_id()

	if _local_peer and HeroHUD.instance:
		HeroHUD.instance.hero = self


func _exit_tree() -> void:
	if _local_peer and HeroHUD.instance and HeroHUD.instance.hero == self:
		HeroHUD.instance.hero = null


func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		# Add the gravity.
		velocity += get_gravity() * delta

		if _prop_cant_move.final_value or input_controller.move_direction.is_zero_approx():
			if is_on_floor():
				velocity = Vector3.ZERO
		else:
			var speed := _prop_move_speed.final_value

			var input_dir_ang := input_controller.move_direction.angle()
			var ang_diff := Utils.cycle_float(input_dir_ang - facing_angle, -PI, PI)
			if absf(ang_diff) > PI * 0.5:
				speed *= _prop_reverse_speed_factor.final_value

			velocity.x = input_controller.move_direction.x * speed
			velocity.z = input_controller.move_direction.y * speed

		_prev_is_on_floor = is_on_floor()
		move_and_slide()

		# regen hp
		_hp_regen_accum += _prop_hp_regen.final_value * delta
		var regened_hp_int := int(floor(_hp_regen_accum))
		if regened_hp_int >= 1:
			health.heal(regened_hp_int)
			_hp_regen_accum -= float(regened_hp_int)


func _process(delta: float) -> void:
	if multiplayer.is_server():
		if not input_controller.move_direction.is_zero_approx():
			desired_facing_angle = input_controller.move_direction.angle()

		# turning
		if not _prop_cant_turn.final_value:
			var ang_diff := desired_facing_angle - facing_angle
			ang_diff = Utils.cycle_float(ang_diff, -PI, PI)
			var max_turn_ang := _prop_turn_rate.final_value * delta
			if absf(ang_diff) <= max_turn_ang:
				facing_angle = desired_facing_angle
			else:
				var turn_ang := max_turn_ang * signf(ang_diff)
				facing_angle += turn_ang

		# casting
		if caster:
			var pressed_cast_mask := input_controller.cast_mask
			# var just_pressed_cast_mask := pressed_cast_mask & ~_prev_cast_mask
			_prev_cast_mask = pressed_cast_mask

			for cast_slot_idx: int in range(3):
				if (pressed_cast_mask & (1 << cast_slot_idx)) == 0:
					continue

				var ability := caster.get_ability(cast_slot_idx)
				if ability and not _prop_cant_cast.final_value:
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
