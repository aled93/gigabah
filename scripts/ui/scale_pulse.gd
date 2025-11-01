class_name ScalePulse
extends Node

@export var target_control: NodePath = ^".."
@export var scale_curve: Curve


func _process(_delta: float) -> void:
	if not scale_curve:
		return

	var control_node := get_node(target_control)
	if not control_node:
		return

	var control := control_node as Control
	if not control:
		return

	var t := Time.get_ticks_msec() / 1000.0
	var new_scale := scale_curve.sample(fmod(t, scale_curve.max_domain))

	control.scale = Vector2(new_scale, new_scale)
