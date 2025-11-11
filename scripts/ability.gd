@abstract
class_name Ability
extends Node

const ICON_PATH_PATTERN = "res://assets/textures/ui/ability_icons/%s.png"

var caster: Caster
var cooldown: float:
	set(val):
		var started := cooldown == 0.0 and val > 0.0
		cooldown = max(0.0, val)
		if started:
			cooldown_start.emit()
			_sync_cd()
var icon_path: String = ICON_PATH_PATTERN % get_script().get_global_name():
	set(val):
		if val != icon_path:
			icon_path = val
			icon_path_changed.emit()

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
## Emits before calling ability's _cast
signal start_casting()
## Emits after calling ability's _cast and it returned no error
signal succesfully_casted()
signal icon_path_changed()


## How this ability can be casted. Currently game expects that
## result of this function will be same all the time.
@abstract func _get_cast_method() -> CastMethod


## Main function of ability. Called when all checks done like cooldown,
## validating target, caster status.
@abstract func _cast() -> CastResult


func cast() -> CastResult:
	var res := _is_castable()
	if res:
		return res

	_pre_cast()

	res = _cast()
	if res != CastResult.OK:
		return res

	_post_cast()

	return CastResult.OK


func set_cast_targets(
		point: Vector3,
		node: Node3D,
		direction: Vector3,
) -> void:
	_target_point = point
	_target_node = node
	_target_direction = direction


func _has_target_point() -> bool:
	return not is_nan(_target_point.x)


func _has_target_node() -> bool:
	return true if _target_node else false


func _has_target_direction() -> bool:
	return not is_nan(_target_direction.x)


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
	ERROR_NO_TARGET,
	ERROR_TARGET_IS_FAR,
}

enum CastMethod {
	NO_TARGET,
	TARGETED,
	DIRECTIONAL,
	POINT,
}
