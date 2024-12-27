extends AudioStreamPlayer

export (float) var beginAt: = 1.0
export (float) var maximumAt: = 2.0
export (bool) var oneshot: = false

var baseVolume: float
var goalVolume: float
var shouldStop: = false
var oneshotDone: bool

func _ready():
	baseVolume = volume_db - 15
	volume_db = baseVolume
	
	if oneshot:
		connect("finished", self, "finishedPlay")

func roundStarts():
	oneshotDone = false

func update(current: float):
	if oneshot:
		if not oneshotDone and current > 0 and not playing:
			play()
		return 
	
	if current < beginAt:
		if playing:
			shouldStop = true
			goalVolume = baseVolume - 20
		return 
	elif not playing:
		shouldStop = false
		volume_db = baseVolume - 20
		play()
	
	var relativeVolume = clamp((1 + current - beginAt) / ((1 + maximumAt) - beginAt), 0.0, 1.0)
	goalVolume = baseVolume + 15 * relativeVolume

func _process(delta):
	if not playing:
		return 
	
	var deltaVolume = goalVolume - volume_db
	if abs(deltaVolume) > 0.2:
		volume_db += 30 * sign(deltaVolume) * delta
	elif shouldStop:
		stop()
		shouldStop = false

func finishedPlay():
	oneshotDone = true
