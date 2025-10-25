@abstract
class_name Ability
extends Node

var caster: Caster
var cooldown: float:
	set(val):
		var started := cooldown == 0.0 and val > 0.0
		cooldown = max(0.0, val)
		if started:
			cooldown_start.emit()
			_sync_cd()

## Point in global space where caster pointing his cursor. Can be all NANs
## if cursor pointing not terrain or in UI
var _target_point: Vector3
## Node3D that caster pointing with his cursor. Can be null
var _target_node: Node3D
## Unit vector of direction relative caster towards cursor
var _target_direction: Vector3

## When cooldown value changed from zero to positive value
signal cooldown_start()
## When cooldown value become zero
signal cooldown_end()
signal start_casting()
signal succesfully_casted()


@abstract func _get_cast_method() -> CastMethod


## Overridable, don't call super it's placeholder
func _cast_notarget() -> CastResult:
	return CastResult.ERROR_ABILITY_NOT_NOTARGET

## Overridable, don't call super it's placeholder
# func _cast_targeted(_target: Node) -> CastResult:
# 	return CastResult.ABILITY_NOT_TARGETED


## Overridable, don't call super it's placeholder
func _cast_in_direction(_dir: Vector3) -> CastResult:
	return CastResult.ERROR_ABILITY_NOT_DIRECTIONAL


func cast_notarget() -> CastResult:
	var err := _is_castable()
	if err:
		return err

	_pre_cast()

	err = _cast_notarget()
	if err:
		return err

	_post_cast()

	return CastResult.OK

# func cast_targeted(target: Node) -> CastResult:
# 	var err := _is_castable()
# 	if err:
# 		return err

# 	_pre_cast()

# 	err = _cast_targeted(target)
# 	if err:
# 		return err

# 	_post_cast()

# 	return CastResult.OK


func cast_in_direction(dir: Vector3) -> CastResult:
	var err := _is_castable()
	if err:
		return err

	_pre_cast()

	err = _cast_in_direction(dir)
	if err:
		return err

	_post_cast()

	return CastResult.OK


func _is_castable() -> CastResult:
	if not caster:
		return CastResult.ERROR_NO_CASTER

	if cooldown > 0.0:
		return CastResult.ERROR_ON_COOLDOWN

	return CastResult.OK


func _pre_cast() -> void:
	caster._cast_started(self)
	start_casting.emit()


func _post_cast() -> void:
	caster._cast_done(self)
	succesfully_casted.emit()


func _process(delta: float) -> void:
	if cooldown > delta:
		cooldown -= delta
	else:
		cooldown = 0.0
		cooldown_end.emit()


func _sync_cd() -> void:
	if is_multiplayer_authority():
		NetSync.rpc_to_observing_peers(self, _rpc_sync_cd, [cooldown])


@rpc("authority", "call_remote", "reliable")
func _rpc_sync_cd(cd: float) -> void:
	cooldown = cd


enum CastResult {
	OK,
	ERROR_NO_CASTER,
	ERROR_ON_COOLDOWN,
	ERROR_ABILITY_NOT_NOTARGET,
	ERROR_ABILITY_NOT_TARGETED,
	ERROR_ABILITY_NOT_DIRECTIONAL,
	ERROR_TARGET_IS_FAR,
}

enum CastMethod {
	NO_TARGET,
	# TARGETED,
	DIRECTIONAL,
}
