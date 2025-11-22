extends Node

const ADDRESS: String = "gigabuh.d.roddtech.ru"
const PORT: int = 25445

var local_peer: ENetMultiplayerPeer

signal _client_result(fail: bool)


## Start as server
func start_server(listen_addr: String = "*", listen_port: int = PORT) -> Error:
	local_peer = ENetMultiplayerPeer.new()
	local_peer.set_bind_ip(listen_addr)
	var res := local_peer.create_server(listen_port)
	match res:
		ERR_ALREADY_IN_USE:
			push_error("Unable to start server because peer already active")
			return res
		ERR_CANT_CREATE:
			push_error("Unable to start server: unknown reason")
			return res

	multiplayer.multiplayer_peer = local_peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("Server started and listening %s:%d" % [listen_addr, listen_port])

	return OK


## Start as client
func start_client(address: String = ADDRESS, port: int = PORT) -> bool:
	local_peer = ENetMultiplayerPeer.new()
	local_peer.create_client(address, port)
	multiplayer.multiplayer_peer = local_peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	print("Connecting to %s:%d..." % [address, port])
	return not await _client_result


## Client connection handlers
func _on_connected_to_server() -> void:
	print("Connected to server.")
	_client_result.emit(false)


func _on_connection_failed() -> void:
	print("Failed to connect to server.")
	_client_result.emit(true)

	if not OS.has_feature("dedicated_server"):
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_server_disconnected() -> void:
	print("Disconnected from server.")

	if not OS.has_feature("dedicated_server"):
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_peer_connected(peer_id: int) -> void:
	print("Peer %d connected" % peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("Peer %d disconnected" % peer_id)
