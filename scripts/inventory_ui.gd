class_name InventoryUI
extends CanvasLayer

const TOGGLE_KEY := KEY_I

const COLUMNS := 9
const TOTAL_SLOTS := 27
const MAX_STACK_SIZE := 64
const SLOT_SIZE := 24
const SLOT_SPACING := 2
const GRID_PADDING := 6
const ICON_PADDING := 2

const PANEL_BG := Color(0.51, 0.51, 0.51, 1.0)
const PANEL_BORDER_DARK := Color(0.13, 0.13, 0.13, 1.0)
const PANEL_BORDER_LIGHT := Color(0.85, 0.85, 0.85, 1.0)
const SLOT_BG := Color(0.35, 0.35, 0.35, 1.0)
const SLOT_BORDER := Color(0.13, 0.13, 0.13, 1.0)
const DIM_BG := Color(0, 0, 0 ,0.55)
const TEXT_COLOR := Color.WHITE
const COUNT_OUTLINE := Color.BLACK

var player: Player
var dim_background: ColorRect
var panel: PanelContainer
var grid: GridContainer
var is_open: bool = false

var slot_nodes: Array[Dictionary] = []

var _cached_panel_style: StyleBoxFlat
var _cached_slot_style: StyleBoxFlat

static func attach_to(target_player: Player, parent: Node) -> InventoryUI:
	var ui := InventoryUI.new()
	parent.add_child(ui)
	ui.setup(target_player)
	return ui

func setup(target_player: Player) -> void:
	player = target_player
	
	_cached_panel_style = _make_panel_style()
	_cached_slot_style = _make_slot_style()
	
	_build_ui()
	_create_empty_grid()
	_populate_from_existing_inventory()
	
	if not player.ore_collected.is_connected(_on_ore_collected):
		player.ore_collected.connect(_on_ore_collected)
	
	set_open(false)
	
	panel.reset_size()
	panel.set_anchors_preset(Control.PRESET_CENTER)

func _build_ui() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
	dim_background = ColorRect.new()
	dim_background.color = DIM_BG
	dim_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim_background)
	
	panel = PanelContainer.new()
	dim_background.add_child(panel) 
	
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_theme_stylebox_override("panel", _cached_panel_style)
	
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", GRID_PADDING)
	margin.add_theme_constant_override("margin_right", GRID_PADDING)
	margin.add_theme_constant_override("margin_top", GRID_PADDING)
	margin.add_theme_constant_override("margin_bottom", GRID_PADDING)
	panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)
	
	var title := Label.new()
	title.text = "Inventory"
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(title)
	
	grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", SLOT_SPACING)
	grid.add_theme_constant_override("v_separation", SLOT_SPACING)
	vbox.add_child(grid)

func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.set_border_width_all(2)
	style.border_color = PANEL_BORDER_DARK
	style.set_corner_radius_all(1)
	return style

func _make_slot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = SLOT_BG
	style.set_border_width_all(1)
	style.border_color = SLOT_BORDER
	return style

func _create_empty_grid() -> void:
	for i in range(TOTAL_SLOTS):
		var slot_data = _create_slot_node()
		slot_nodes.append(slot_data)
		_clear_slot_visuals(i)

func _create_slot_node() -> Dictionary:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	slot.add_theme_stylebox_override("panel", _cached_slot_style)
	
	var icon_margin := MarginContainer.new()
	icon_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_margin.add_theme_constant_override("margin_left", ICON_PADDING)
	icon_margin.add_theme_constant_override("margin_right", ICON_PADDING)
	icon_margin.add_theme_constant_override("margin_top", ICON_PADDING)
	icon_margin.add_theme_constant_override("margin_bottom", ICON_PADDING)
	icon_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	slot.add_child(icon_margin)
	
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_PASS
	icon_margin.add_child(icon)
	
	var label_margin := MarginContainer.new()
	label_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	label_margin.add_theme_constant_override("margin_right", 2)
	label_margin.add_theme_constant_override("margin_bottom", 1)
	label_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	slot.add_child(label_margin)
	
	var count_label := Label.new()
	count_label.add_theme_font_size_override("font_size", 8)
	count_label.add_theme_color_override("font_color", TEXT_COLOR)
	count_label.add_theme_color_override("font_outline_color", COUNT_OUTLINE)
	count_label.add_theme_constant_override("outline_size", 2)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label_margin.add_child(count_label)
	
	grid.add_child(slot)
	
	return {
		"slot": slot,
		"icon": icon,
		"count_label": count_label,
		"item_resource": null,
		"current_count": 0
	}

func _clear_slot_visuals(index: int) -> void:
	var slot_data = slot_nodes[index]
	slot_data["item_resource"] = null
	slot_data["current_count"] = 0
	slot_data["icon"].texture = null
	slot_data["count_label"].text = ""
	slot_data["count_label"].visible = false

func _on_ore_collected(_ore_data: OreData, _total_player_count: int) -> void:
	_populate_from_existing_inventory()

func _populate_from_existing_inventory() -> void:
	for i in range(TOTAL_SLOTS):
		_clear_slot_visuals(i)
	
	var current_slot_index := 0
	for ore_data: OreData in player.inventory.keys():
		var total_count: int = player.inventory[ore_data]
		
		while total_count > 0 and current_slot_index < TOTAL_SLOTS:
			var batch = min(total_count, MAX_STACK_SIZE)
			var slot = slot_nodes[current_slot_index]
			
			slot["item_resource"] = ore_data
			slot["current_count"] = batch
			slot["icon"].texture = ore_data.texture
			slot["count_label"].text = str(batch)
			slot["count_label"].visible = batch > 1
			
			total_count -= batch
			current_slot_index += 1

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == TOGGLE_KEY:
			set_open(not is_open)
			get_viewport().set_input_as_handled()

func set_open(value: bool) -> void:
	is_open = value
	dim_background.visible = is_open
