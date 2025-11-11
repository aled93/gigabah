class_name Jump
extends Ability

var ground_impact_scene := preload("res://scenes/vfx/abilities/vfx_ground_impact.tscn")


func _get_cast_method() -> CastMethod:
	return Ability.CastMethod.POINT


func _cast() -> CastResult:
	if not _has_target_point():
		return CastResult.ERROR_NO_TARGET

	var modifier := JumpingModifier.new()
	modifier.jump_height = 15.0
	modifier.land_point = _target_point
	modifier.duration = 2.0
	caster.hero.modifiers.add_modifier(modifier)

	cooldown = 5.0

	return CastResult.OK
