extends Node2D

export (float) var minimumWorldVolume: = - 30.0

var runWorldAttenuation: = false

func init():
	Data.listen(self, "keeper.insidedome", true)

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"keeper.insidedome":
			var busIdx = AudioServer.get_bus_index(Audio.BUS_WORLD)
			var amplify: AudioEffectAmplify = AudioServer.get_bus_effect(busIdx, 0)
			var lowpass: AudioEffectLowPassFilter = AudioServer.get_bus_effect(busIdx, 1)
			if newValue:
				runWorldAttenuation = false
				amplify.volume_db = 0
				AudioServer.set_bus_effect_enabled(busIdx, 1, false)
			else:
				runWorldAttenuation = true
				lowpass.cutoff_hz = 2000
				lowpass.resonance = 0.5
				AudioServer.set_bus_effect_enabled(busIdx, 1, true)

func _process(delta):
	if Level.keeper and runWorldAttenuation:
		var amplify: AudioEffectAmplify = AudioServer.get_bus_effect(AudioServer.get_bus_index(Audio.BUS_WORLD), 0)
		var lowpass: AudioEffectLowPassFilter = AudioServer.get_bus_effect(AudioServer.get_bus_index(Audio.BUS_WORLD), 1)
		var a = $MineAttenuation.attenuate(Level.keeper.global_position.y)
		amplify.volume_db = a * minimumWorldVolume
		lowpass.cutoff_hz = 1500 - 1200 * a
