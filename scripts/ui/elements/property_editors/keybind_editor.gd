class_name KeybindEditor
extends BaseOptionEditor

@onready var name_label: Label = get_node("%Name")
@onready var bind_a_button: Button = get_node("%BindA")
@onready var bind_b_button: Button = get_node("%BindB")

var _all_binds: Array[InputEvent]

signal _any_input_pressed(event: InputEvent)


func _ready() -> void:
	bind_a_button.pressed.connect(_on_bind_button_pressed.bind(bind_a_button, 0))
	bind_b_button.pressed.connect(_on_bind_button_pressed.bind(bind_b_button, 1))


func set_property_name(prop_name: String) -> void:
	if not name_label:
		name_label = get_node("%Name")
		if not name_label:
			return

	name_label.text = prop_name


func set_property_value(value: Variant) -> void:
	_all_binds = value as Array

	bind_a_button.text = _input_event_to_localization_key(_all_binds[0] if _all_binds.size() >= 1 else null)
	bind_b_button.text = _input_event_to_localization_key(_all_binds[1] if _all_binds.size() >= 2 else null)


func get_property_value() -> Variant:
	return _all_binds


func _input(event: InputEvent) -> void:
	if event.is_pressed() and event is not InputEventMouseMotion:
		_any_input_pressed.emit(event)


func _on_bind_button_pressed(bind_button: Button, index: int) -> void:
	var new_bind := await _any_input_pressed as InputEvent
	get_viewport().set_input_as_handled()
	_all_binds[index] = new_bind

	bind_button.text = _input_event_to_localization_key(new_bind)
	bind_button.button_pressed = false

	value_changed.emit()


func _input_event_to_localization_key(ev: InputEvent) -> String:
	match ev:
		null:
			return "input_event_none"
		_ when ev is InputEventKey:
			var key_ev := ev as InputEventKey
			return OS.get_keycode_string(key_ev.physical_keycode)
		_ when ev is InputEventMouseButton:
			var mouse_ev := ev as InputEventMouseButton
			return "input_event_mouse_button%d" % mouse_ev.button_index
		_ when ev is InputEventJoypadButton:
			var joy_btn_ev := ev as InputEventJoypadButton
			return "input_event_gamepad_button" + String.num_uint64(joy_btn_ev.button_index)
		_ when ev is InputEventJoypadMotion:
			var joy_motion_ev := ev as InputEventJoypadMotion

			var key: String
			var bidir_axis := false
			match joy_motion_ev.axis:
				JOY_AXIS_LEFT_X:
					key = "input_event_gamepad_left_stick_x"
					bidir_axis = true
				JOY_AXIS_LEFT_Y:
					key = "input_event_gamepad_left_stick_y"
					bidir_axis = true
				JOY_AXIS_RIGHT_X:
					key = "input_event_gamepad_right_stick_x"
					bidir_axis = true
				JOY_AXIS_RIGHT_Y:
					key = "input_event_gamepad_right_stick_y"
					bidir_axis = true
				JOY_AXIS_TRIGGER_LEFT:
					key = "input_event_gamepad_left_trigger"
				JOY_AXIS_TRIGGER_RIGHT:
					key = "input_event_gamepad_right_trigger"
				_:
					key = "axis%d" % joy_motion_ev.axis

			if bidir_axis:
				if joy_motion_ev.axis_value < 0.0:
					key += "_negative"
				elif joy_motion_ev.axis_value > 0.0:
					key += "_positive"

			return key
		_:
			return "input_event_unknown"
