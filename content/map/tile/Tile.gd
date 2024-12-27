extends StaticBody2D

signal destroyed

export (String) var type: = ""
var max_health: int
var layer: int
var hardness: int
var health: float
var richness: float
var coord: Vector2
var biome: String
var last_damage_from: Vector2
var hasRoots: = false

onready var res_sprite = $ResourceSprite

func _ready():
	var baseHealth: float = Data.of("map.tileBaseHealth")
	
	var forceMultiplier: = 0.0
	if type != "special":
		match type:
			"border":
				res_sprite.queue_free()
			"dirt":
				res_sprite.hide()
				set_meta("destructable", true)
				initResourceSprite(Vector2(5, 0))
			CONST.IRON:
				set_meta("destructable", true)
				res_sprite.flip_h = randf() > 0.5
				initResourceSprite(Vector2(2, 11))
				baseHealth += Data.of("map.ironAdditionalHealth")
			CONST.SAND:
				set_meta("destructable", true)
				res_sprite.flip_h = randf() > 0.5
				initResourceSprite(Vector2(2, 3))
				baseHealth += Data.of("map.sandAdditionalHealth")
			CONST.WATER:
				set_meta("destructable", true)
				res_sprite.flip_h = randf() > 0.5
				initResourceSprite(Vector2(2, 7))
				baseHealth += Data.of("map.waterAdditionalHealth")
			CONST.GADGET:
				set_meta("destructable", true)
				initResourceSprite(Vector2(4, 1))
				baseHealth += Data.of("map.gadgetAdditionalHealth")
				forceMultiplier = 1.0
			CONST.RELIC:
				set_meta("destructable", true)
				initResourceSprite(Vector2(4, 2))
				baseHealth += Data.of("map.relicAdditionalHealth")
				forceMultiplier = 1.0
			CONST.NEST:
				set_meta("destructable", true)
				initResourceSprite(Vector2(5, 0))
				forceMultiplier = 1.0
	
	var healthMultiplier: float = Data.of("map.tileHealthBaseMultiplier")
	if forceMultiplier != 0.0:
		health *= forceMultiplier
	else:
		match int(hardness):
			0:
				healthMultiplier *= Data.of("map.hardnessMultiplier0")
			1:
				healthMultiplier *= Data.of("map.hardnessMultiplier1")
			2:
				healthMultiplier *= Data.of("map.hardnessMultiplier2")
			3:
				healthMultiplier *= Data.of("map.hardnessMultiplier3")
			4:
				healthMultiplier *= Data.of("map.hardnessMultiplier4")
	
	healthMultiplier *= (pow(Data.of("map.tileHealthMultiplierPerLayer"), layer))
	
	max_health = max(1, round(healthMultiplier * baseHealth))
	if hasRoots:
		max_health *= 5
	health = max_health
	
	Style.init(res_sprite)
	










func initResourceSprite(v: Vector2):

	res_sprite.set_frame_coords(v)

func hit(dir: Vector2, dmg: float):
	if health <= 0 or hardness == 5:
		
		return 
	
	var previous_health = health
	if hasRoots:
		health -= min(dmg, max_health * 0.1)
	else:
		health -= dmg
	
	apply_damage_to_shader(health, previous_health, dir)

	if health <= 0:
		last_damage_from = dir
		res_sprite.modulate = Color(3, 3, 3, 1)
		$Tween.interpolate_callback(self, 0.02, "emit_signal", "destroyed")
		$Tween.start()

		GameWorld.incrementRunStat("tiles_destroyed")
		return 
	
	
	var factor = 0.2 + dmg / 5.0
	var mod = max(1.0, 1.5 * factor)
	

	$Tween.interpolate_property(res_sprite, "modulate", Color(mod, mod, mod, 1), Color.white, 0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.start()








func root():
	if hasRoots:
		return 
	
	var s = Sprite.new()
	s.texture = preload("res://content/gadgets/mineraltree/wurzeltile.png")
	s.z_index = 1
	s.flip_h = randf() > 0.5
	s.flip_v = randf() > 0.5
	add_child(s)
	hasRoots = true

func queue_free():
	.queue_free()
	var particles = Data.TILE_BREAK_PARTICLES.instance()
	particles.biome_color = Level.map.getBiomeColorByCoord(coord)
	particles.direction = last_damage_from
	particles.type = type
	particles.position = position
	get_parent().add_child(particles)

func relativeHealth()->float:
	return float(health / max_health)

func apply_damage_to_shader(health, previous_health, direction):
	var proportional_damage = clamp(1 - health / max_health, 0, 1)
	var hit_power = (previous_health - health) / max_health
	Level.map.addTileDamage(hit_power, proportional_damage, direction, position)

func deactivateCollision():
	$CollisionShape2D.disabled = true

func serialize()->Dictionary:
	var data = {
		"type": type, 
		"max_health": max_health, 
		"layer": layer, 
		"hardness": hardness, 
		"health": health, 
		"richness": richness, 
		"coord": var2str(coord), 
		"biome": biome, 
		"last_damage_from": var2str(last_damage_from), 
		"hasRoots": hasRoots, 
	}

	return data
	
func deserialize(data: Dictionary):
	if data["hasRoots"]:
		root()
	type = data["type"]
	max_health = data["max_health"]
	layer = data["layer"]
	hardness = data["hardness"]
	health = data.health
	richness = data["richness"]
	coord = str2var(data["coord"])
	biome = data["biome"]
	last_damage_from = str2var(data["last_damage_from"])
