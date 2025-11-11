class_name MainMenu
extends Control

@export var game_scene: PackedScene
@export var settings_property_inspector: PropertiesInspector

@onready var settings_panel: Control = %SettingsPanel
@onready var settings_save_button: Button = %SaveButton

signal hide_requested()


func set_as_ingame(ingame: bool) -> void:
	get_tree().set_group(&"ingame_only", "visible", ingame)
	get_tree().set_group(&"not_ingame_only", "visible", not ingame)


func _ready() -> void:
	settings_panel.visible = false

	settings_property_inspector.properties_source = GameSettings.instance
	settings_property_inspector.property_changed.connect(_on_settings_property_changed)

	settings_save_button.pressed.connect(_on_settings_save_pressed)
	settings_save_button.disabled = false

	set_as_ingame(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_down"):
		if not get_viewport().gui_get_focus_owner():
			var focusable := find_next_valid_focus()
			if focusable:
				focusable.grab_focus()
				get_viewport().set_input_as_handled()


func _on_enter_game_pressed() -> void:
	var join_addr: Variant = App.cmdline_arguments.get("--join-address")
	if join_addr is String:
		NetworkManager.start_client(join_addr as String)
	else:
		NetworkManager.start_client()
	get_tree().change_scene_to_packed(game_scene)


func _on_hide_menu_pressed() -> void:
	hide_requested.emit()


func _on_settings_pressed() -> void:
	settings_panel.visible = not settings_panel.visible

	var focusable := settings_panel.find_next_valid_focus()
	if focusable:
		focusable.call_deferred(&"grab_focus")


func _on_quit_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _on_settings_property_changed(_editor: BaseOptionEditor, _new_value: Variant) -> void:
	settings_save_button.disabled = false


func _on_settings_save_pressed() -> void:
	settings_property_inspector.apply_changes()
	GameSettings.instance.apply_input_action_events()
	GameSettings.instance.apply_audio_settings()
	settings_save_button.disabled = true
