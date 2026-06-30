extends Node2D

const FILL_PERCENTAGE: float = 0.20
const ROCK_SCENE = preload("res://scenes/rock.tscn")

const ROCK_DATA_POOL: Array[RockData] = [
	preload("res://data/rocks/stone.tres"),
	preload("res://data/rocks/iron.tres"),
]

@export var current_depth: int = 1

@onready var rock_container: Node2D = $RockContainer
@onready var ore_container: Node2D = $OreContainer
@onready var current_map: Node2D = $Map
@onready var player: Player = $Player

func _ready() -> void:
	_generate_rocks()
	_position_objects()
	
	# Attach UI Windows
	InventoryUI.attach_to(player, self)
	
	var tradeable_ores: Array[OreData] = [
		preload("res://data/ores/stone_ore.tres"),
		preload("res://data/ores/iron_ore.tres")
	]
	ShopUI.attach_to(player, self, tradeable_ores)

func _position_objects() -> void:
	var player_spawn: Marker2D = current_map.get_node("PlayerSpawn")
	player.reset(player_spawn.position)

func _generate_rocks() -> void:
	for child in rock_container.get_children():
		child.queue_free()
	
	var ground_layer: TileMapLayer = current_map.get_node("Ground")
	var props_layer: TileMapLayer = current_map.get_node("Props")
	var ground_cells := ground_layer.get_used_cells()
	var available_cells := []
	
	for cell in ground_cells:
		var tile_data = ground_layer.get_cell_tile_data(cell)
		if props_layer.get_cell_source_id(cell) != -1:
			continue
		if tile_data and tile_data.get_custom_data("can_spawn_rocks") == true:
			available_cells.append(cell)
	
	available_cells.shuffle()
	
	var num_rocks := int(available_cells.size() * FILL_PERCENTAGE)
	var eligible_pool := _get_eligible_rock_data()
	
	if eligible_pool.is_empty():
		push_warning("Level: no RockData")
		return
		
	var total_weight := 0
	for rock_data in eligible_pool:
		total_weight += rock_data.rarity
	
	for i in range(num_rocks):
		var cell = available_cells[i]
		var rock_data := _pick_weighted_rock_data(eligible_pool, total_weight)
		
		var rock = ROCK_SCENE.instantiate()
		rock.data = rock_data
		rock.ore_container = ore_container
		
		var local_pos = ground_layer.map_to_local(cell)
		rock.global_position = local_pos
		rock_container.add_child(rock)

func _get_eligible_rock_data() -> Array[RockData]:
	var eligible: Array[RockData] = []
	for rock_data in ROCK_DATA_POOL:
		if current_depth >= rock_data.min_depth:
			eligible.append(rock_data)
	return eligible

func _pick_weighted_rock_data(pool: Array[RockData], total_weight: int) -> RockData:
	var roll := randi_range(1, total_weight)
	var running_total := 0
	for rock_data in pool:
		running_total += rock_data.rarity
		if roll <= running_total:
			return rock_data
	return pool[-1]
