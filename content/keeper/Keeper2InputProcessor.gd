extends "res://content/keeper/KeeperInputProcessor.gd"

var mineKeyDown: = false
var mineHold: = false
var mineKeyDownTime: = 0.0

var collectKeyDown: = false
var collectHold: = false
var collectKeyDownTime: = 0.0

func _process(delta):
	if collectKeyDown and not collectHold:
		collectKeyDownTime += delta
		if collectKeyDownTime > 0.3:
			keeper.collectHold()
			collectHold = true
	
	if mineKeyDown and not mineHold:
		mineKeyDownTime += delta
		if mineKeyDownTime > 0.3:
			keeper.ballHold()
			mineHold = true

func keeperKeyEvent(event, handled: bool):
	if pressed(event, "keeper2_gravityball"):
		mineKeyDown = true
	elif released(event, "keeper2_gravityball"):
		if mineKeyDown:
			mineKeyDownTime = 0.0
			mineKeyDown = false
			if mineHold:
				keeper.ballRelease()
				mineHold = false
			elif not handled:
				keeper.ballHit()
	elif pressed(event, "keeper2_gravitycollect"):
		collectKeyDown = true
	elif released(event, "keeper2_gravitycollect"):
		if collectKeyDown:
			collectKeyDownTime = 0.0
			collectKeyDown = false
			if collectHold:
				keeper.collectRelease()
				collectHold = false
			else:
				keeper.collectHit()
