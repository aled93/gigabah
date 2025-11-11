class_name JumpingModifier
extends Modifier

var land_point: Vector3
var jump_height: float = 3.0
var duration: float = 1.0

var _t := 0.0
var _p0: Vector3
var _p1: Vector3
var _p2: Vector3


func _ready() -> void:
	modify_property(&"cant_move", true)
	modify_property(&"cant_turn", true)
	modify_property(&"cant_cast", true)

	_p0 = carrier.global_position
	_p2 = land_point
	_p1 = _p0 + (_p2 - _p0) * 0.5 + Vector3.UP * jump_height

	expire_time = duration


func _physics_process(delta: float) -> void:
	if _t + delta < 1.0:
		_t += delta
		carrier.global_position = Utils.quadratic_bezier_3d(_p0, _p1, _p2, _t)
	else:
		carrier.global_position = land_point
		queue_free()
