extends Reference

class_name CONST

enum BUILD_TYPE{FULL, DEMO, PLAYTEST, EXHIBITION}

const DIRECTIONS: = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
const DIAGONALS: = [Vector2(1, 1), Vector2( - 1, 1), Vector2(1, - 1), Vector2( - 1, - 1)]

const LEFT: = "left"
const RIGHT: = "right"
const TOP: = "top"
const CENTER: = "center"
const LEFT_LOW: = "left_low"
const RIGHT_LOW: = "right_low"
const LEFT_HIGH: = "left_high"
const RIGHT_HIGH: = "right_high"

const MONSTER_SPAWN_FLY_TOP: = "fly_top_center"
const MONSTER_SPAWN_FLY_TOP_CORNER_LEFT: = "fly_top_corner_left"
const MONSTER_SPAWN_FLY_TOP_CORNER_RIGHT: = "fly_top_corner_right"
const MONSTER_SPAWN_FLY_LOW_LEFT: = "fly_low_left"
const MONSTER_SPAWN_FLY_HIGH_LEFT: = "fly_high_left"
const MONSTER_SPAWN_FLY_LOW_RIGHT: = "fly_low_right"
const MONSTER_SPAWN_FLY_HIGH_RIGHT: = "fly_high_right"
const MONSTER_SPAWN_FLY_LEFT: = "fly_onscreen_left"
const MONSTER_SPAWN_FLY_RIGHT: = "fly_onscreen_right"
const MONSTER_SPAWN_FLY_CENTER: = "fly_onscreen_center"

const BORDER: = "border"
const IRON: = "iron"
const WATER: = "water"
const SAND: = "sand"
const GADGET: = "gadget"
const RELIC: = "relic"
const NEST: = "nest"
const EGG: = "egg"
const SEED: = "seed"
const TREAT: = "treat"

const MONSTER_SMALL: = "small"
const MONSTER_MEDIUM: = "medium"
const MONSTER_LARGE: = "large"

const MAP_SMALL: = "map-small"
const MAP_MEDIUM: = "map-medium"
const MAP_LARGE: = "map-large"
const MAP_HUGE: = "map-huge"

const LOADOUT_DOME: = "dome"
const LOADOUT_KEEPER: = "keeper"
const LOADOUT_GAMEMODE: = "gamemode"
const LOADOUT_GADGET: = "gadget"

const LAYER_TILE_COLLISION = 0
const LAYER_DROP_COLLISION = 1
const LAYER_USABLES = 2
const LAYER_DROP_DOME_BORDER = 3
const LAYER_TUNNEL_PARTICLES = 4
const LAYER_CARRYABLES = 5
const LAYER_DOME_DROP = 6
const LAYER_WEAPONS = 7
const LAYER_MONSTER_PROJECTILES = 8
const LAYER_DOME_EXTERNAL = 9
const LAYER_LIFT_RIGID = 10
const LAYER_LIFT_KINEMATIC = 11
const LAYER_SWARM = 12
const LAYER_DRONES = 13
const LAYER_PLAYER = 14
const LAYER_TILE_COLLISION_GADGETS = 15
const LAYER_BACK_LAYER_COLLISIONS = 16
const LAYER_WEAPONS_ENVIRONMENT = 17
const LAYER_KEEPER_PROJECTILE = 20

const MODE_RELICHUNT = "relichunt"
const MODE_PRESTIGE = "prestige"
const MODE_COLONIZATION = "colonization"
const MODE_PRESTIGE_COBALT = "prestige-cobalt"
const MODE_PRESTIGE_COUNTDOWN = "prestige-countdown"
const MODE_PRESTIGE_MINER = "prestige-miner"

const DIFFICULTY_RELAXED = "difficulty-relaxed"
const DIFFICULTY_HARD = "difficulty-hard"
const DIFFICULTY_BRUTAL = "difficulty-brutal"
const DIFFICULTY_YAFI = "difficulty-yafi"

const TILE_OFFSET: = Vector2(0, 82)

const TUTORIAL_LISTENING: = 1
const TUTORIAL_DISPLAYING: = 2
const TUTORIAL_TIMEDOUT: = 3
const TUTORIAL_CONFIRMED: = 4

const PixelPerKilometer: = 0.00012

const PI_HALF: float = PI * 0.5
