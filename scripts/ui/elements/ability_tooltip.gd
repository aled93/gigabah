class_name AbilityTooltip
extends TooltipPosition

@export var ability: Ability:
	set(val):
		ability = val
		call_deferred(&"_update_tooltip")

@onready var ability_name: Label = %AbilityName
@onready var description: RichTextLabel = %Description
@onready var cooldown: Label = %Cooldown


func _update_tooltip() -> void:
	if not ability:
		return

	var abil_name: String = ability.get_script().get_global_name()

	ability_name.text = "ability_" + abil_name
	description.text = "ability_description_" + abil_name
