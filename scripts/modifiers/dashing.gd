class_name Dashing
extends Modifier

@export var direction := Vector3.FORWARD
@export var distance := 5.0
@export var speed := 25.0

var _traveled := 0.0


func _modifier_start() -> void:
	expire_time = distance / speed


func _physics_process(delta: float) -> void:
	var step_dist := speed

	carrier.velocity = direction.normalized() * step_dist
	carrier.move_and_slide()

	_traveled += step_dist * delta

	if _traveled >= distance:
		queue_free()
