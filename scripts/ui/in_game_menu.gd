extends CanvasLayer

var main_menu: MainMenu


func _ready() -> void:
	# adding main_menu as child in design time makes circular dependency
	main_menu = load("res://scenes/ui/main_menu.tscn").instantiate() as MainMenu
	add_child(main_menu)
	main_menu.set_as_ingame(true)
	main_menu.hide_requested.connect(_on_hide_requested)

	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_in_game_menu"):
		visible = not visible


func _on_hide_requested() -> void:
	visible = false
