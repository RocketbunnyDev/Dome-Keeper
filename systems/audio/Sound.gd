extends AudioStreamPlayer




















export (float, 0, 6, 0.1) var randomVolume: = 3.0
export (float, 0.0, 1.0, 0.01) var randomPitch: = 0.1
export (float) var maxAudibleDistance: = 0.0
export (float) var minAudibleDistance: = 0.0
export (float) var fadeInTime: = 0.0
export (float) var fadeOutTime: = 0.0
export (Array, AudioStream) var streams
export (bool) var removeAfterPlaying: = false
export (bool) var loop: = false
export (float) var doppler: = 0.0

var basePitch: float
var baseVolume: float
var fadeVolume: float = 0
var additionalVolume: float = 0
var additionalPitch: float = 0
var dopplerPitch: float = 0
var initialized: = false
var shouldPlay: = false
var attenuate: = false
var FadeTween: Tween
var simulatedPosition: Vector2 = Vector2.INF

func _ready():
	if not initialized:
		baseVolume = volume_db
		basePitch = pitch_scale
		initialized = true
		if maxAudibleDistance == 0:
			
			set_process(false)
			attenuate = false
		else:
			attenuate = true
		
		if fadeInTime > 0.0 or fadeOutTime > 0.0:
			FadeTween = Tween.new()
			add_child(FadeTween)
	if autoplay:
		play()

func play(from_position: float = 0.0):
	var goalVolume = baseVolume + additionalVolume
	
	updatePitch()
	
	
	if randomVolume > 0.0:
		goalVolume += - randomVolume + 2 * randomVolume * randf()
	
	
	if streams.size() > 0:
		stream = streams[randi() % streams.size()]
	
	
	if fadeInTime > 0.0 and not shouldPlay:
		FadeTween.stop_all()
		FadeTween.remove_all()
		if attenuate:
			fadeVolume = - 50
			FadeTween.interpolate_property(self, "fadeVolume", - 50, goalVolume, fadeInTime)
		else:
			volume_db = - 50
			FadeTween.interpolate_property(self, "volume_db", - 50, goalVolume, fadeInTime)
		FadeTween.start()
	else:
		volume_db = goalVolume
	
	if not attenuate:
		
		.play(from_position)
	
	shouldPlay = true
	for c in get_children():
		if c is AudioStreamPlayer:
			c.play()

func updatePitch():
	if randomPitch > 0.0:
		pitch_scale = basePitch + dopplerPitch + additionalPitch + - randomPitch + 2 * randomPitch * randf()
	else:
		pitch_scale = basePitch + dopplerPitch + additionalPitch

func updateVolume()->float:
	if attenuate:
		var attenuation = getAttenuation()
		volume_db = baseVolume - 30 * (attenuation) + fadeVolume + additionalVolume
		return attenuation
	else:
		volume_db = baseVolume + fadeVolume + additionalVolume
		if randomVolume > 0.0:
			volume_db += - randomVolume + 2 * randomVolume * randf()
		return 0.0


func _process(delta):
	if not shouldPlay:
		return 
	
	var attenuation = updateVolume()
	
	if attenuation == 0 and playing:
		.stop()
		.seek( - 1)
		return 
	elif attenuation > 0 and not playing and shouldPlay:
		.play()
	
	if doppler > 0.0:
		var parent = get_parent()
		var keeperDelta = Level.keeper.global_position - parent.global_position
		var dot = parent.linear_velocity.normalized().dot(keeperDelta.normalized())
		dopplerPitch = doppler * dot * (1.0 - attenuation)
		updatePitch()

func getAttenuation()->float:
	var pos: Vector2
	if simulatedPosition == Vector2.INF:
		var parentNode2D = get_parent()
		for _i in 5:
			if parentNode2D is Node2D:
				break
			else:
				parentNode2D = parentNode2D.get_parent()
		pos = parentNode2D.global_position
	else:
		pos = simulatedPosition
	
	var attenuation = min(1.0, max(0.001, (Level.keeperPosition() - pos).length() - minAudibleDistance) / maxAudibleDistance)
	return attenuation

func stop(noFade: = false):
	if fadeOutTime == 0.0 or noFade:
		.stop()
		.seek( - 1)
		if removeAfterPlaying:
			queue_free()
	else:
		FadeTween.stop_all()
		FadeTween.remove_all()
		if attenuate:
			fadeVolume = - 50
			FadeTween.interpolate_property(self, "fadeVolume", fadeVolume, - 50, fadeOutTime)
		else:
			FadeTween.interpolate_property(self, "volume_db", volume_db, - 50, fadeOutTime)
		FadeTween.interpolate_callback(self, fadeOutTime, "stop", true)
		FadeTween.start()
	shouldPlay = false
	
	for c in get_children():
		if c is AudioStreamPlayer:
			c.stop()

func _on_Sound_finished():
	if removeAfterPlaying:
		queue_free()
		shouldPlay = false
	elif not loop:
		shouldPlay = false
	else:
		updatePitch()

func playDelayed(delay: float):
	if delay > 0.0:
		var timer = Timer.new()
		timer.wait_time = delay
		add_child(timer)
		timer.start()
		timer.connect("timeout", self, "play")
		timer.connect("timeout", timer, "queue_free")
	else:
		play()

func setSimulatedPosition(pos: Vector2):
	simulatedPosition = pos
	for c in get_children():
		if c is AudioStreamPlayer:
			c.setSimulatedPosition(pos)

func setAdditionalPitch(p: float):
	if p == additionalPitch:
		return 
	
	additionalPitch = p
	updatePitch()

func setAdditionalVolume(v: float):
	if v == additionalVolume:
		return 
	
	additionalVolume = v
	updateVolume()
	for c in get_children():
		if c is AudioStreamPlayer:
			c.setAdditionalVolume(v)
