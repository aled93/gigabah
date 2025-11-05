extends Node

var _netnode_by_instid: Dictionary[int, _NetworkNodeInfo] = { }
var _netnode_by_netid: Dictionary[int, _NetworkNodeInfo] = { }

signal spawned(node: Node)
signal despawning(node: Node)


## Set visibility of node for specific peer.
##
## Note: you can't disable visibility for node owner
func set_visibility_for(peer_id: int, node: Node, visibility: bool) -> VisibilityError:
	if not node.is_multiplayer_authority():
		push_error("only node authority can change visibility of the node")
		return VisibilityError.NOT_ALLOWED
	if peer_id < 1:
		push_error("invalid peer_id %d" % peer_id)
		return VisibilityError.WRONG_PEER_ID
	if node.get_multiplayer_authority() == peer_id:
		push_error("authority can't change visibility for itself")
		return VisibilityError.WRONG_PEER_ID
	if node.name.validate_node_name() != node.name:
		push_error(
			"node name '%s' contains invalid characters " % node.name +
			"(see `StringName.validate_node_name`)",
		)
		return VisibilityError.INVALID_NODE_NAME

	var net_node := _get_netnode_by_instance_id(node.get_instance_id())
	if !net_node:
		if node.scene_file_path.is_empty():
			return VisibilityError.ONLY_INSTANTIATED_NODES_SUPPORTED

		if visibility:
			net_node = _NetworkNodeInfo.new(node, _alloc_network_id(node))
			net_node.peers_vision.push_back(peer_id)
			_register_tracking_node(net_node)
			_on_start_tracking_node(node, net_node)
			_on_peer_got_vision(node, net_node, peer_id)
	else:
		if visibility and peer_id not in net_node.peers_vision:
			net_node.peers_vision.append(peer_id)
			_on_peer_got_vision(node, net_node, peer_id)
		elif !visibility and peer_id in net_node.peers_vision:
			var idx: int = net_node.peers_vision.find(peer_id)
			if idx >= 0:
				Utils.array_erase_replacing(net_node.peers_vision, idx)
			_on_peer_lost_vision(net_node, peer_id)

		for other_net_node: _NetworkNodeInfo in net_node.inherited_vision_nodes:
			var need_set := visibility and peer_id not in other_net_node.peers_vision
			need_set = need_set or (not visibility and peer_id in other_net_node.peers_vision)
			# if here to prevent recursive call
			if need_set:
				set_visibility_for(peer_id, other_net_node.node, visibility)

	return VisibilityError.OK


func set_visibility_batch(peer_ids: PackedInt64Array, node: Node, visibility: bool) -> VisibilityError:
	for peer_id: int in peer_ids:
		var res := set_visibility_for(peer_id, node, visibility)
		if res != VisibilityError.OK:
			return res

	return VisibilityError.OK


## Copy all observing peers from `source_node` to `target_node`.
## All players who has network vision on source node will
## also get vision over target node. This is one shot action.
func inherit_visibility(source_node: Node, target_node: Node, continously: bool = false) -> void:
	if not is_instance_valid(source_node):
		push_error("source_node is invalid instance")
		return

	if not is_instance_valid(target_node):
		push_error("target_node is invalid instance")
		return

	if source_node == target_node:
		push_error("attempt to inherit vision from itself")
		return

	var net_node := _get_netnode_by_instance_id(source_node.get_instance_id())
	if not net_node:
		if not continously:
			push_warning("attempt to inherit network visibility from non networked node")
			return

		net_node = _NetworkNodeInfo.new(source_node, _alloc_network_id(source_node))
		_register_tracking_node(net_node)
		_on_start_tracking_node(source_node, net_node)

	if continously:
		var target_net_node := _get_netnode_by_instance_id(target_node.get_instance_id())
		if not target_net_node:
			target_net_node = _NetworkNodeInfo.new(target_node, _alloc_network_id(target_node))
			_register_tracking_node(target_net_node)
			_on_start_tracking_node(target_node, target_net_node)

		net_node.inherited_vision_nodes.push_back(target_net_node)

	for peer_id: int in net_node.peers_vision:
		set_visibility_for(peer_id, target_node, true)


func is_visible_for(peer_id: int, node: Node) -> bool:
	if not is_multiplayer_authority():
		push_warning("non authority doesn't have visibility knowledge")
		return false

	# owner always see its own nodes
	if node.get_multiplayer_authority() == peer_id:
		return true

	var net_node := _get_netnode_by_instance_id(node.get_instance_id())
	if !net_node:
		return false

	return peer_id in net_node.peers_vision


## Returns number of peers can see node, excluding owner
func get_peers_have_vision_count(node: Node) -> int:
	var net_node := _get_netnode_by_instance_id(node.get_instance_id())
	if net_node:
		return net_node.peers_vision.size()
	return 0


## Get Nth peer id that can see node or -1 if index out of bounds
func get_peer_have_vision(node: Node, index: int) -> int:
	var net_node := _get_netnode_by_instance_id(node.get_instance_id())
	if net_node:
		if index >= 0 && index < net_node.peers_vision.size():
			return net_node.peers_vision[index]

	return -1


func get_all_peers_have_vision(node: Node) -> PackedInt64Array:
	var net_node := _get_netnode_by_instance_id(node.get_instance_id())
	if net_node:
		return PackedInt64Array(net_node.peers_vision)

	return PackedInt64Array()


## Send rpc only to those peers who have network vision over `observable_node`.
## Only server can do this because only server knows who observes node.
func rpc_to_observing_peers(observable_node: Node, rpc_func: Callable, rpc_args: Array) -> void:
	if not multiplayer.is_server():
		assert(false, "attempt to broadcast rpc to observable peers on client")
		return

	var net_node := _get_netnode_by_instance_id(observable_node.get_instance_id())
	if not net_node:
		# node aren't observed by anyone
		return

	for peer_id: int in net_node.peers_vision:
		var args := [peer_id]
		args.append_array(rpc_args)
		rpc_func.rpc_id.callv(args)


func _get_netnode_by_instance_id(node_instance_id: int) -> _NetworkNodeInfo:
	return _netnode_by_instid.get(node_instance_id)


func _get_netnode_by_netid(network_id: int) -> _NetworkNodeInfo:
	for net_node: _NetworkNodeInfo in _netnode_by_instid.values():
		if net_node.network_id == network_id:
			return net_node

	return null


func _register_tracking_node(net_node: _NetworkNodeInfo) -> void:
	_netnode_by_instid[net_node.node.get_instance_id()] = net_node
	_netnode_by_netid[net_node.network_id] = net_node
	net_node.debug_name = net_node.node.to_string()


func _unregsiter_tracking_node(net_node: _NetworkNodeInfo) -> void:
	_netnode_by_instid.erase(net_node.node_instance_id)
	_netnode_by_netid.erase(net_node.network_id)


func _enter_tree() -> void:
	if is_multiplayer_authority():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	# dirty hack to unset all MultiplayerSynchronizers public_visibility to false
	# TODO: find better solution that not relies on human actions like disabling
	#       public_visibility manually for every synchornizer
	# this fixes case when a node with MultiplayerSynchronizers is spawned
	# but doesn't immediatly become networked via NetSync, so the synchronizers
	# may have public_visibility==true, in such case, if they fail to
	# find a remote counterpart, they stop working entirely
	get_tree().node_added.connect(_on_tree_node_added)


func _exit_tree() -> void:
	if is_multiplayer_authority():
		multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)


func _on_tree_node_added(node: Node) -> void:
	if node is MultiplayerSynchronizer:
		_handle_synchronizer(node as MultiplayerSynchronizer)

	for child: Node in node.find_children("", "MultiplayerSynchronizer", true, false):
		_handle_synchronizer(child as MultiplayerSynchronizer)


func _handle_synchronizer(syncer: MultiplayerSynchronizer) -> void:
	syncer.public_visibility = false


func _on_peer_disconnected(peer_id: int) -> void:
	_iter_all_node_instance_ids_peer_see(
		peer_id,
		func(_node_id: int, net_node: _NetworkNodeInfo) -> void:
			var peer_vis_idx: int = net_node.peers_vision.find(peer_id)
			if peer_vis_idx >= 0:
				Utils.array_erase_replacing(net_node.peers_vision, peer_vis_idx)
	)


func _on_tracking_node_exited_tree(net_node: _NetworkNodeInfo) -> void:
	# defer network cleanup to allow other listeners of `exiting_tree` of this node
	# do their things
	_stop_track_node(net_node)
	_unregsiter_tracking_node(net_node)


func _stop_track_node(net_node: _NetworkNodeInfo) -> void:
	for peer_id: int in net_node.peers_vision:
		_on_peer_lost_vision(net_node, peer_id)

	_release_network_id(net_node.network_id)


func _on_start_tracking_node(node: Node, net_node: _NetworkNodeInfo) -> void:
	net_node.synchronizers.assign(
		node.find_children("", "MultiplayerSynchronizer", true, true),
	)

	for syncer: MultiplayerSynchronizer in net_node.synchronizers:
		syncer.public_visibility = false
	# syncer.set_visibility_for(0, false)

	node.tree_exited.connect(
		_on_tracking_node_exited_tree.bind(net_node),
		CONNECT_ONE_SHOT,
	)


## called only on owner side
func _on_peer_got_vision(node: Node, net_node: _NetworkNodeInfo, peer_id: int) -> void:
	for syncer: MultiplayerSynchronizer in net_node.synchronizers:
		syncer.set_visibility_for(peer_id, true)

	var pos: Vector3 = Vector3.ZERO
	if node.is_inside_tree():
		var node3d: Node3D = node as Node3D
		if node3d:
			pos = node3d.global_position
		else:
			var node2d: Node2D = node as Node2D
			if node2d:
				pos = Vector3(node2d.global_position.x, node2d.global_position.y, 0)

	var spawn_path := node.get_path()
	_rpc_spawn.rpc_id(peer_id, node.scene_file_path, spawn_path, pos, net_node.network_id, null)


## called only on owner side
## not called when peer disconnects (see _on_peer_disconnected)
func _on_peer_lost_vision(net_node: _NetworkNodeInfo, peer_id: int) -> void:
	for syncer: MultiplayerSynchronizer in net_node.synchronizers:
		syncer.set_visibility_for(peer_id, false)

	_rpc_despawn.rpc_id(peer_id, net_node.network_id)


func _try_get_scene_path(node: Node) -> String:
	return node.scene_file_path


## callback: func(node_id: int, net_node: _NetworkNodeInfo)
func _iter_all_node_instance_ids_peer_see(peer_id: int, callback: Callable) -> void:
	for node_id: int in _netnode_by_instid.keys():
		var net_node: _NetworkNodeInfo = _netnode_by_instid[node_id]
		if peer_id in net_node.peers_vision:
			callback.call(node_id, net_node)


func _alloc_network_id(node: Node) -> int:
	return node.get_instance_id()


func _release_network_id(_network_id: int) -> void:
	pass


@rpc("reliable")
func _rpc_spawn(scene_path: String, spawn_path: NodePath, pos: Vector3, network_id: int, data: Variant = null) -> void:
	var last_name_idx := spawn_path.get_name_count() - 1
	var spawn_target_path := spawn_path.slice(0, last_name_idx)
	var spawn_name := spawn_path.get_name(last_name_idx)
	var spawn_target: Node = get_node(spawn_target_path)
	if !spawn_target:
		push_error("spawn_path pointing to invalid node")
		return

	var existing_node: Node = spawn_target.find_child(spawn_name, false, true)
	if existing_node:
		push_error("authority sent rpc to spawn node with name that already occupied in spawn_path by %s" % existing_node)
		return

	var node: Node
	if data != null:
		node = MultiplayerCustomSpawn.try_custom_spawn(spawn_target, scene_path, data)
		push_error("got rpc spawn with custom data, but failed to find and call custom_function in spawn target")
	if not is_instance_valid(node):
		node = (load(scene_path) as PackedScene).instantiate()

	node.name = spawn_name

	var net_node: _NetworkNodeInfo = _NetworkNodeInfo.new(node, network_id)
	_register_tracking_node(net_node)

	spawn_target.add_child(node)

	var node3d: Node3D = node as Node3D
	if node3d:
		node3d.global_position = pos
	else:
		var node2d: Node2D = node as Node2D
		if node2d:
			node2d.global_position = Vector2(pos.x, pos.y)

	spawned.emit(node)


@rpc("reliable")
func _rpc_despawn(network_id: int) -> void:
	var net_node := _get_netnode_by_netid(network_id)
	if !is_instance_valid(net_node.node):
		push_error("authority sent despawn rpc, but local tracking node is invalid (node: %s)" % net_node.debug_name)
		_unregsiter_tracking_node(net_node)
		return

	_unregsiter_tracking_node(net_node)
	despawning.emit(net_node.node)
	net_node.node.queue_free()


class _NetworkNodeInfo:
	var node: Node
	# storing as well for cases where node already freed
	var node_instance_id: int
	var network_id: int
	var peers_vision: PackedInt64Array = []
	var synchronizers: Array[MultiplayerSynchronizer] = []
	var debug_name: String
	var inherited_vision_nodes: Array[_NetworkNodeInfo] = []


	func _init(nod: Node, net_id: int) -> void:
		self.node = nod
		self.node_instance_id = nod.get_instance_id()
		self.network_id = net_id


enum VisibilityError {
	OK,
	NOT_SPAWNED_BY_ADVANCED_SPAWNER,
	CORRUPTED_META,
	ONLY_INSTANTIATED_NODES_SUPPORTED,
	NOT_ALLOWED,
	WRONG_PEER_ID,
	INVALID_NODE_NAME,
}
