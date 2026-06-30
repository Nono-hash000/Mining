class_name InventoryUI
extends CanvasLayer

const TOGGLE_KEY := KEY_I

const COLUMNS := 9
const SLOT_SIZE := 48
const SLOT_SPACING := 4
const GRID_PADDING := 10
const ICON_PADDING := 6

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

var slots: Dictionary = {}

static func attach_to(target_player: Player, parent: Node) -> InventoryUI:
	var ui := InventoryUI.new()
	parent.add_child(ui)
	ui.setup(target_player)
	return ui

func setup(target_player: Player) -> void:
	player = target_player
	_build_ui()
	_populate_from_existing_inventory()
	player.ore_collected.connect(_on_ore_collected)
	set_open(false)

func _build_ui() -> void:
	layer = 10
	
	dim_background = ColorRect.new()
	dim_background.color = DIM_BG
	dim_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim_background)
	
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", GRID_PADDING)
	margin.add_theme_constant_override("margin_right", GRID_PADDING)
	margin.add_theme_constant_override("margin_top", GRID_PADDING)
	margin.add_theme_constant_override("margin_bottom", GRID_PADDING)
	panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	
	var title := Label.new()
	title.text = "Inventory"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	
	grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", SLOT_SPACING)
	grid.add_theme_constant_override("v_separation", SLOT_SPACING)
	vbox.add_child(grid)
	
	dim_background.add_child(panel)
	panel.set_deferred("position", panel.position)

func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_color = PANEL_BORDER_DARK
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style

func _make_slot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = SLOT_BG
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = SLOT_BORDER
	return style

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == TOGGLE_KEY:
			set_open(not is_open)
			get_viewport().set_input_as_handled()

func set_open(value: bool) -> void:
	is_open = value
	dim_background.visible = is_open

func _populate_from_existing_inventory() -> void:
	for ore_name in player.inventory.keys():
		_update_slot(ore_name, player.inventory[ore_name])

func _on_ore_collected(ore_data: OreData, new_count: int) -> void:
	_update_slot(ore_data.ore_name, new_count, ore_data.texture)

func _update_slot(ore_name: String, count: int, texture: Texture2D = null) -> void:
	if not slots.has(ore_name):
		slots[ore_name] = _create_slot(texture)
		
	var slot_data: Dictionary = slots[ore_name]
	var icon: TextureRect = slot_data["icon"]
	if texture:
		icon.texture = texture
	var count_label: Label = slot_data["count_label"]
	count_label.text = str(count)
	count_label.visible = count > 1

func _create_slot(texture: Texture2D) -> Dictionary:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	slot.add_theme_stylebox_override("panel", _make_slot_style())
	
	var icon := TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(SLOT_SIZE - ICON_PADDING * 2, SLOT_SIZE - ICON_PADDING * 2)
	icon.set_anchors_preset(Control.PRESET_CENTER)
	
	var icon_margin := MarginContainer.new()
	icon_margin.add_theme_constant_override("margin_left", ICON_PADDING)
	icon_margin.add_theme_constant_override("margin_right", ICON_PADDING)
	icon_margin.add_theme_constant_override("margin_top", ICON_PADDING)
	icon_margin.add_theme_constant_override("margin_bottom", ICON_PADDING)
	icon_margin.add_child(icon)
	slot.add_child(icon_margin)
	
	var count_label := Label.new()
	count_label.add_theme_font_size_override("font_size", 13)
	count_label.add_theme_color_override("font_color", TEXT_COLOR)
	count_label.add_theme_color_override("font_outline_color", COUNT_OUTLINE)
	count_label.add_theme_constant_override("outline_size", 3)
	count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count_label.position -= Vector2(4, 4)
	count_label.visible = false
	slot.add_child(count_label)
	
	grid.add_child(slot)
	
	return {"slot": slot, "icon": icon, "count_label": count_label}
