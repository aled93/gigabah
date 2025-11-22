class_name PlayerSpawner
extends Node

@export var player_spawn_path: NodePath
@export var pawn_spawn_path: NodePath
@export var player_scene: PackedScene
@export var pawn_scene: PackedScene
@export var default_abilities: Array[PackedScene] = [
	preload("res://scenes/abilities/devball.tscn"),
	preload("res://scenes/abilities/inner_spirit.tscn"),
	preload("res://scenes/abilities/dash.tscn"),
	preload("res://scenes/abilities/jump.tscn"),
]

var _players: Dictionary[int, Player] = { }


func _ready() -> void:
	multiplayer.peer_connected.connect(spawn_player)
	multiplayer.peer_disconnected.connect(despawn_player)


func spawn_player(id: int) -> void:
	if !multiplayer.is_server():
		return

	var player := player_scene.instantiate() as Player
	player.name = str(id)
	player.peer_id = id # FIXME: multiplayer is null in setter

	_players[id] = player

	var pawn := _create_pawn_for_player(player)

	get_node(player_spawn_path).add_child(player)

	NetSync.set_visibility_for(id, player, true)
	player.pawn = pawn


func despawn_player(id: int) -> void:
	if !multiplayer.is_server():
		return

	var player := _players[id]
	player.queue_free()
	_players.erase(id)

	if is_instance_valid(player.pawn):
		player.pawn.queue_free()


func _create_pawn_for_player(player: Player) -> Hero:
	var pawn := pawn_scene.instantiate() as Hero
	pawn.name = "pawn_%d" % pawn.get_instance_id()

	# TODO: implement spawn points
	pawn.position.x = randf_range(-5, 5)
	pawn.position.y = 2.0
	pawn.position.z = randf_range(-10, 0)

	get_node(pawn_spawn_path).add_child(pawn)

	pawn.health.health_depleted.connect(_on_player_hp_depleted.bind(player))

	pawn.modifiers.add_modifier(HeroBaseModifier.new())

	var caster := pawn.caster
	for ability_scene: PackedScene in default_abilities:
		var ability := ability_scene.instantiate()
		caster.get_node(caster.abilities_container).add_child(ability)
		caster.add_ability(ability)

	return pawn


func _on_player_hp_depleted(player: Player) -> void:
	player.pawn.queue_free()

	await get_tree().create_timer(5.0).timeout

	var pawn := _create_pawn_for_player(player)
	player.pawn = pawn
