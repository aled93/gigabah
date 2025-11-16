class_name AudioBusEditor
extends BaseOptionEditor

@onready var name_label: Label = get_node("%Name")
@onready var slider: HSlider = get_node("%Volume")
@onready var muted_check_button: CheckButton = get_node("%Muted")
var _settings: AudioSettingsModel


func _ready() -> void:
	slider.value_changed.connect(_slider_changed)
	muted_check_button.pressed.connect(_muted_changed)


func set_property_name(prop_name: String) -> void:
	if not name_label:
		name_label = get_node("%Name")
		if not name_label:
			return

	name_label.text = prop_name


func set_property_value(value: Variant) -> void:
	_settings = value as AudioSettingsModel
	_update_representation()


func get_property_value() -> Variant:
	return _settings


func _update_representation() -> void:
	slider.value = _settings.volume
	muted_check_button.button_pressed = !_settings.muted


func _slider_changed(value: float) -> void:
	_settings.volume = value
	value_changed.emit()


func _muted_changed() -> void:
	_settings.muted = !muted_check_button.button_pressed
	slider.editable = !_settings.muted
	value_changed.emit()
