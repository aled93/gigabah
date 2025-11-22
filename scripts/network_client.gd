extends Node

class_name NetworkClient

static var local: NetworkClient

@export var input_controller: InputController

var peer_id: int:
	set(val):
		assert(peer_id == 0, "peer_id must be assigned only once")
		peer_id = val
		if multiplayer and peer_id == multiplayer.get_unique_id():
			local = self

var pawn: Hero:
	set(val):
		if pawn:
			_detach_pawn()

		if multiplayer.is_server():
			NetSync.set_visibility_for(peer_id, val, true)

		pawn = val

		if pawn:
			_attach_pawn()


func _enter_tree() -> void:
	if peer_id == multiplayer.get_unique_id():
		local = self
		push_warning("local=%s" % self)


func _attach_pawn() -> void:
	push_warning("attaching pawn %s" % pawn)

	pawn.input_controller = input_controller

	if self == local:
		if HeroHUD.instance:
			HeroHUD.instance.hero = pawn

		var cam := pawn.get_node("%Camera") as Camera3D
		if cam:
			cam.make_current()
			input_controller.camera = cam

	var netvis_area := pawn.get_node("%NetworkVisionArea3D") as NetworkVisionArea3D
	if netvis_area:
		netvis_area.vision_owner_peer_id = peer_id

	if multiplayer.is_server():
		NetSync.rpc_to_observing_peers(self, _rpc_attach_pawn, [pawn.get_path()])


func _detach_pawn() -> void:
	pawn.input_controller = null

	if self == local:
		if HeroHUD.instance:
			HeroHUD.instance.hero = null

		var cam := pawn.get_node("%Camera") as Camera3D
		if cam:
			cam.clear_current(false)

	var netvis_area := pawn.get_node("%NetworkVisionArea3D") as NetworkVisionArea3D
	if netvis_area:
		netvis_area.vision_owner_peer_id = 0

	if multiplayer.is_server():
		NetSync.rpc_to_observing_peers(self, _rpc_detach_pawn, [])


func network_serialize() -> Variant:
	return {
		&"peer_id": peer_id,
	}


func network_deserialize(data: Variant) -> void:
	peer_id = data.peer_id as int


@rpc("authority", "reliable")
func _rpc_attach_pawn(pawn_path: NodePath) -> void:
	var pawn_node := get_node(pawn_path)

	assert(is_instance_valid(pawn_node), "pawn_path pointing to invalid node")
	assert(pawn_node is Hero, "pawn_path not pointing to Hero node")

	pawn = pawn_node as Hero


@rpc("authority", "reliable")
func _rpc_detach_pawn() -> void:
	assert(is_instance_valid(pawn), "pawn already invalid")

	pawn = null
