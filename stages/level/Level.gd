extends Node

var dome: Dome
var monsters: Monsters
var map
var world: Worldd
var keeper: Keeper
var tutorials
var mode
var hud
var stage

var initialized: = false

func clear():
	dome = null
	keeper = null
	monsters = null
	map = null
	hud = null
	stage = null
	world = null
	tutorials = null
	initialized = false

func domeId()->String:
	return dome.techId

func keeperId()->String:
	return keeper.techId

func keeperPosition()->Vector2:
	if keeper:
		return keeper.global_position
	else:
		return Vector2.ZERO

func addTutorial(parent, id):
	if tutorials:
		tutorials.addIfOpen(parent, id)
