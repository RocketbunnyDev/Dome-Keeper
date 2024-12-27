extends Node

var FOCUS_MODULATE = Color(1.8, 1.8, 1.4)
const TILE_COVER_MODULATE = Color(0.3, 0.3, 0.3)

var STRUCT_DARK: = Color("544E68")
var STRUCT_BRIGHT: = Color("8D697A")

var LIVE: = Color("FFAA5E")
var LIVE_BRIGHT: = Color("FFD4A3")

const keeper_highlight: = Vector2(6, 2)

var OVERLAY_COLOR_IN: = Color("BB12121A")
var OVERLAY_COLOR_OUT: = Color(0.0, 0.0, 0.0, 0.0)

var FONT_COLOR_WARNING: = Color("#CB4548")
var FONT_COLOR_HIGHLIGHT: = Color("#FFD4A3")

const colors_r: = 32
const colors_b: = 12
const r_step: = 8
const b_step: = 20
const paletteColorSize: = Vector2(10, 10)

var theme: = preload("res://gui/theme.tres")
var spriteShader: = preload("res://systems/style/materials/sprite_palette.tres")
var additionalShaders: = [preload("res://content/map/tile/tile_break_particle_material.tres")]
var palette
var colorData: Dictionary = {}
var paletteId: = "1_1"

var styledGradients: = []

func _ready():
	setPalette(paletteId)

func setPalette(paletteId: String, forceReload: = false):
	styledGradients = []
	
	Logger.info("setting palette to " + paletteId)
	var palettePath = "res://systems/style/palettes/palette_" + str(paletteId) + ".png"
	if forceReload:
		var image = Image.new()
		var err = image.load(palettePath)
		if err == OK:
			palette = ImageTexture.new()
			palette.create_from_image(image, 0)
	else:
		palette = load(palettePath)
	spriteShader.set_shader_param("palette", palette)
	self.paletteId = paletteId
	
	for s in additionalShaders:
		s.set_shader_param("palette", palette)
	
	readColors(palettePath)
	

	
	for node in get_tree().get_nodes_in_group("styleShaderCallback"):
		node.material.set_shader_param("palette", palette)
		
	for node in get_tree().get_nodes_in_group("styleCpuGradientCallback"):
		updateGradient(node.color_ramp)
	
	for node in get_tree().get_nodes_in_group("styleGradientCallback"):
		updateGradient(node.process_material.color_ramp.get_gradient())
		
	for node in get_tree().get_nodes_in_group("styleModulateCallback"):
		node.modulate = mapColor(node.modulate)
		
	for node in get_tree().get_nodes_in_group("colorRectCallback"):
		node.color = mapColor(node.color)
		
	for node in get_tree().get_nodes_in_group("styleParticleColorCallback"):
		node.process_material.color = mapColor(node.process_material.color)
	
	for node in get_tree().get_nodes_in_group("styleLabelCallback"):
		node.set("custom_colors/font_color", mapColor(node.get("custom_colors/font_color")))
	
	for node in get_tree().get_nodes_in_group("styleRichLabelCallback"):
		node.set("custom_colors/default_color", mapColor(node.get("custom_colors/default_color")))
	
	for node in get_tree().get_nodes_in_group("styleLineCallback"):
		if node.default_color:
			node.default_color = mapColor(node.default_color)
		if node.material:
			node.material.set_shader_param("palette", palette)
	



func readColors(palettePath: String):
	var tex = load(palettePath)
	var image = tex.get_data()
	
	image.lock()
	for i_b in colors_b:
		for i_r in colors_r:
			var key = Vector2(i_r, i_b)
			var color = image.get_pixelv(paletteColorSize * key + paletteColorSize * 0.5)
			if color != Color.white and color != Color.black:
				colorData[key] = color
	colorData[Vector2(32, 12)] = Color.white
	image.unlock()

func init(node):
	if node.is_in_group("styled") or node.is_in_group("unstyled"):
		return 
	
	if (node is Sprite or node is AnimatedSprite or node is TileMap):
		if node.material:
			if node.material is ShaderMaterial and node.material.get_shader_param("palette") != null:
				node.material.set_shader_param("palette", palette)
				node.add_to_group("styleShaderCallback")
				node.add_to_group("styled")
		else:
			node.material = spriteShader
		if node.modulate != Color.white:
			node.modulate = mapColor(node.modulate)
			node.add_to_group("styleModulateCallback")
			node.add_to_group("styled")
	elif node is CPUParticles2D:
		if node.color_ramp:
			if not styledGradients.has(node.color_ramp):
				updateGradient(node.color_ramp)
				node.add_to_group("styleCpuGradientCallback")
				node.add_to_group("styled")
				styledGradients.append(node.color_ramp)
		elif node.color:
			node.color = mapColor(node.color)
	elif node is Particles2D and node.process_material:
		if node.process_material.get("color_ramp"):
			if not styledGradients.has(node.process_material.color_ramp):
				var gradient = node.process_material.color_ramp.get_gradient()
				updateGradient(gradient)
				node.add_to_group("styleGradientCallback")
				node.add_to_group("styled")
				styledGradients.append(node.process_material.color_ramp)
		elif node.process_material.get("color"):
			node.process_material.color = mapColor(node.process_material.color)
			node.add_to_group("styleParticleColorCallback")
			node.add_to_group("styled")
	elif node is TextureRect:
		if node.material:
			node.material.set_shader_param("palette", palette)
			node.add_to_group("styleShaderCallback")
			node.add_to_group("styled")
		else:
			node.material = spriteShader
	elif node is PanelContainer or node is Panel or node is BaseButton or node is Separator or node is Range or node is HSeparator or node is VSeparator or node is OptionButton or node is Popup:
		node.material = spriteShader
	elif node is ColorRect:
		if not node.color.is_equal_approx(OVERLAY_COLOR_IN):
			node.color = mapColor(node.color)
			node.add_to_group("colorRectCallback")
			node.add_to_group("styled")
	elif node is Label:
		var c = node.get("custom_colors/font_color")
		if c:
			node.set("custom_colors/font_color", mapColor(c))
			node.add_to_group("styleLabelCallback")
			node.add_to_group("styled")
	elif node is RichTextLabel:
		var c = node.get("custom_colors/default_color")
		if c:
			node.set("custom_colors/default_color", mapColor(c))
			node.add_to_group("styleRichLabelCallback")
			node.add_to_group("styled")
	if node is Line2D:
		node.add_to_group("styleLineCallback")
		node.add_to_group("styled")
		if node.material:
			node.material.set_shader_param("palette", palette)
			node.default_color = Color.white
		elif node.texture:
			node.material = spriteShader
		if not node.default_color.is_equal_approx(Color.white):
			node.default_color = mapColor(node.default_color)
	
	for n in node.get_children():
		init(n)

func mapColor(c: Color)->Color:
	var r = round(c.r * (255.0 / r_step))
	var b = round(c.b * (255.0 / b_step))
	var key = Vector2(r, b)
	if colorData.has(key):
		var map = colorData.get(key)
		return Color(map.r, map.g, map.b, c.a)
	else:

		return c

func updateGradient(gradient: Gradient):
	for i in range(0, gradient.colors.size()):
		gradient.set_color(i, mapColor(gradient.colors[i]))

func getColor(key: Vector2)->Color:
	return colorData.get(key, Color.white)
