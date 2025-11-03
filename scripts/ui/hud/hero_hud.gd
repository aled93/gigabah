class_name HeroHUD
extends Node

static var instance: HeroHUD

@export var ability_icon_scene: PackedScene = preload("res://scenes/ui/elements/hero_hud_ability.tscn")

@export var hero: Hero:
	set(val):
		if hero:
			_unlink_hero()
		hero = val
		if hero:
			_link_hero()

@onready var abilities_bar: Container = %AbilitiesBar
@onready var health_bar: TextureProgressBar = %HealthBar
@onready var health_num: Label = %HealthNumber

var _ability_icon_map: Dictionary[Ability, HUDAbility] = { }


func _ready() -> void:
	instance = self


func _unlink_hero() -> void:
	if hero.caster:
		hero.caster.ability_added.disconnect(_on_ability_added)
		hero.caster.ability_removed.disconnect(_on_ability_removed)

	for icon: HUDAbility in _ability_icon_map.values():
		icon.queue_free()
	_ability_icon_map.clear()


func _link_hero() -> void:
	if hero.caster:
		for i: int in range(hero.caster.get_ability_count()):
			_on_ability_added(i)

		hero.caster.ability_added.connect(_on_ability_added)
		hero.caster.ability_removed.connect(_on_ability_removed)


func _on_ability_added(ability_index: int) -> void:
	var ability := hero.caster.get_ability(ability_index)
	var hud_ability := ability_icon_scene.instantiate() as HUDAbility

	abilities_bar.add_child(hud_ability)
	_ability_icon_map[ability] = hud_ability
	hud_ability.ability = ability


func _on_ability_removed(ability: Ability) -> void:
	var hud_ability: HUDAbility = _ability_icon_map.get(ability)
	if not hud_ability:
		return

	hud_ability.queue_free()


func _update_visual(_delta: float) -> void:
	if not hero:
		return

	if hero.health:
		health_bar.max_value = hero.health.max_health
		health_bar.value = hero.health.current_health
		health_num.text = "%d/%d" % [hero.health.current_health, hero.health.max_health]


func _process(delta: float) -> void:
	_update_visual(delta)
