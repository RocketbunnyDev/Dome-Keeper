extends InputProcessor

signal escape

var subProcessors: = []
var subProcessorsByPlayer: = {}

var childDevice: = - 1

func becameLeaf():
	for s in subProcessors:
		if childDevice == - 1 or s.device == childDevice:
			s.becameLeaf()

func notLeaf():
	childDevice = child.device
	for s in subProcessors:
		if childDevice == - 1 or s.device == childDevice:
			s.notLeaf()

func handleStart():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() != subProcessors.size():
		Logger.error("MultiplayerInput internal error - player and processor count does not match")
		return 
	for i in range(0, subProcessors.size()):
		subProcessorsByPlayer[players[i]] = subProcessors[i]
		subProcessors[i].player = players[i]

func getPlayer(event):
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 1:
		return players.front()
	else:
		var deviceId: = getDeviceIndex(event)
		for i in range(0, GameWorld.playerInputMap.size()):
			if deviceId == GameWorld.playerInputMap[i]:
				return players[i]
	print("ERROR: device mapping for player failed")
	return null

func keyEvent(event)->bool:
	var player = getPlayer(event)
	if player:
		return subProcessorsByPlayer[player].keyEvent(event)
	return false

func stick_move(event: InputEventJoypadMotion)->bool:
	var player = getPlayer(event)
	if player:
		return subProcessorsByPlayer[player].stick_move(event)
	return false
