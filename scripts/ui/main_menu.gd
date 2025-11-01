class_name MainMenu
extends Control

@export var game_scene: PackedScene
@export var settings_property_inspector: PropertiesInspector

@onready var settings_panel: Control = %SettingsPanel
@onready var settings_save_button: Button = %SaveButton


func _ready() -> void:
	settings_panel.visible = false

	settings_property_inspector.properties_source = GameSettings.instance
	settings_property_inspector.property_changed.connect(_on_settings_property_changed)

	settings_save_button.pressed.connect(_on_settings_save_pressed)
	settings_save_button.disabled = false


func _on_enter_game_pressed() -> void:
	NetworkManager.start_client()
	get_tree().change_scene_to_packed(game_scene)


func _on_settings_pressed() -> void:
	settings_panel.visible = not settings_panel.visible


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_settings_property_changed(_editor: BaseOptionEditor, _new_value: Variant) -> void:
	settings_save_button.disabled = false


func _on_settings_save_pressed() -> void:
	settings_property_inspector.apply_changes()
	settings_save_button.disabled = true
