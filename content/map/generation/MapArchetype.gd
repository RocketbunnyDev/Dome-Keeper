extends Resource

class_name MapArchetype

export (Vector3) var viabilityLargeRange: Vector3
export (Vector3) var viabilitySmallRange: Vector3
export (Vector3) var biomeNoiseRange: Vector3

export (bool) var generateResources: = true

export (int) var width: = 80
export (int) var depth: = 40

export (OpenSimplexNoise) var viability_large_noise: OpenSimplexNoise
export (OpenSimplexNoise) var viability_small_noise: OpenSimplexNoise
export (OpenSimplexNoise) var biome_noise: OpenSimplexNoise
export (OpenSimplexNoise) var hardness_noise: OpenSimplexNoise

export (float) var biome_depth_scale: = 0.08
export (float) var biome_distance_scale: = 20.0
export (float) var biome_noise_strength: = 0.2
export (float) var biome_start: = 0.5

export (float) var viability_large_noise_strength: = 60.0
export (float) var viability_small_noise_strength: = 10.0
export (float) var viability_base: = 110.0

export (float) var viability_thin_top_length: = 10.0
export (float) var viability_thin_top_width: = 22.0
export (float) var viability_thin_top_strength: = 200.0

export (float) var viability_stop_depth_factor: = 0.1
export (float) var viability_stop_width_factor: = 0.07000000000000001

export (float) var keep_core_strength: = 1.5
export (float) var keep_core_falloff_y: = 0.9

export (float) var stop_depth_at_fraction: = 0.5
export (float) var stop_depth_factor: = 10.0
export (float) var stop_depth_exponent: = 2.0

export (float) var stop_width_at_fraction: = 10.0
export (float) var stop_width_factor: = 10.0
export (float) var stop_width_exponent: = 2.0

export (float) var entry_tightening_until: = 0.6
export (float) var entry_tightening_y_exp: = 3.0
export (float) var entry_tightening_x_exp: = 2.0

export (float) var thin_top_factor: = 30.0

export (float) var hardness_scale: = 5.0
export (float) var hardness_offset: = 0.0
export (int) var hardness_min: = 0
export (int) var hardness_max: = 5

export (float) var iron_cluster_rate: = 10.0
export (float) var water_rate: = 8.0
export (float) var cobalt_rate: = 8.0

export (float) var iron_cluster_removal_rate: = 0.2
export (float) var water_removal_rate: = 0.2
export (float) var cobalt_removal_rate: = 0.2

export (float) var iron_cluster_size_base: = 1.5
export (float) var iron_cluster_size_per_y: = 0.2
export (float) var iron_cluster_size_randomness: = 0.02

export (int) var relics: = 1
export (int) var relic_switches: = 2
export (Vector2) var relic_switch_distance_range: = Vector2(10, 20)
export (Vector2) var relic_switch_angle_range_pi: = Vector2( - 0.2, 0.2)
export (int) var relic_depth_step: = 12

export (int) var gadgets: = 3
export (int) var gadget_first_depth: = 15
export (int) var gadget_depth_step: = 17

func init():
	if viabilityLargeRange:
		var factor = rand_range( - 1.0, 1.0)
		factor = sign(factor) * pow(randf(), viabilityLargeRange.z)
		viability_large_noise_strength = viabilityLargeRange.x - viabilityLargeRange.y * 0.5 + factor * viabilityLargeRange.y
	
	if viabilitySmallRange:
		var factor = rand_range( - 1.0, 1.0)
		factor = sign(factor) * pow(randf(), viabilitySmallRange.z)
		viability_small_noise_strength = viabilitySmallRange.x - viabilitySmallRange.y * 0.5 + factor * viabilitySmallRange.y
	
	if biomeNoiseRange:
		var factor = rand_range( - 1.0, 1.0)
		factor = sign(factor) * pow(randf(), biomeNoiseRange.z)
		biome_noise_strength = biomeNoiseRange.x - biomeNoiseRange.y * 0.5 + factor * biomeNoiseRange.y

func setNoise():
	viability_large_noise = preload("res://content/map/generation/viability_large_noise.tres")
	viability_small_noise = preload("res://content/map/generation/viability_small_noise.tres")
	hardness_noise = preload("res://content/map/generation/hardness_noise.tres")
	biome_noise = preload("res://content/map/generation/biome_noise.tres")
