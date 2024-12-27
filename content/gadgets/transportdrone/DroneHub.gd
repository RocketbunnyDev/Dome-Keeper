extends Node2D

var startPointOffsets: = [Vector2(), Vector2(0, GameWorld.TILE_SIZE), Vector2(0, - GameWorld.TILE_SIZE), Vector2(GameWorld.TILE_SIZE, 0), Vector2( - GameWorld.TILE_SIZE, 0)]

var cooldown: float

func _ready():
	for drone in get_tree().get_nodes_in_group("transport_drones"):
		assignDrone(drone)
	
	add_to_group("dronehub")

func assignDrone(drone):
	if drone.hasDroneHub:
		return 
	
	drone.hasDroneHub = true
	drone.connect("request_path_home", self, "assignDronePathHome", [drone])

func _process(delta):
	if cooldown > 0.0:
		cooldown -= delta
		return 
	cooldown = 1.0
	
	var waitingDrones: = []
	var targettedDrops: = []
	for drone in get_tree().get_nodes_in_group("transport_drones"):
		if drone.state == 0:
			waitingDrones.append(drone)
		
		if drone.targettedDrop:
			targettedDrops.append(drone.targettedDrop)
	
	if waitingDrones.size() == 0:
		return 
	
	var drone = waitingDrones.front()
	
	var drops = []
	for drop in get_tree().get_nodes_in_group("drops"):
		if drop.carryableType != "resource":
			continue
		
		if not drone.canTransport(drop):
			continue
		
		if targettedDrops.has(drop):
			continue
		
		if drop.linear_velocity.length() > 5:
			continue
		
		drops.append(drop)
	
	drops.sort_custom(self, "sortByDistance")
	
	for i in min(waitingDrones.size(), drops.size()):
		var drop = drops[i]
		var dronePos = waitingDrones[i].global_position
		var path = tryFindPath(dronePos, drop.global_position)
		if path and not path.empty():
			if path[0] == Vector2(0, - 1):
				path.insert(0, Vector2(0, - 3))
			for j in path.size():
				path[j] = path[j] * GameWorld.TILE_SIZE + CONST.TILE_OFFSET
			waitingDrones[i].targetDrop(drop, path)

func assignDronePathHome(drone):
	var path = tryFindPath(drone.global_position, Vector2(0, - 1) * GameWorld.TILE_SIZE + CONST.TILE_OFFSET)
	if path and not path.empty():
		path.append(Vector2(0, - 5))
		for j in path.size():
			path[j] = path[j] * GameWorld.TILE_SIZE + CONST.TILE_OFFSET
		drone.setPathHome(path)

func tryFindPath(startPos, endPos):
	for offset in startPointOffsets:
		var path = Level.map.findPath(startPos + offset, endPos)
		if path:
			return path
	return null

func sortByDistance(a, b):
	return (a.global_position - global_position).length() < (b.global_position - global_position).length()
