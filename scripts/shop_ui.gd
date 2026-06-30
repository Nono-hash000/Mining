class_name ShopUI
extends CanvasLayer

const TOGGLE_KEY := KEY_P

const SLOT_SIZE := 24
const SLOT_SPACING := 2
const GRID_PADDING := 6

const PANEL_BG := Color(0.4, 0.4, 0.4, 1.0)
const PANEL_BORDER := Color(0.13, 0.13, 0.13, 1.0)
const DIM_BG := Color(0, 0, 0, 0.4)

var player: Player
var dim_background: ColorRect
var panel: PanelContainer
var item_list_vbox: VBoxContainer
var gold_label: Label
var is_open: bool = false

var shop_items: Array[OreData] = []

const PICKAXE_UPGRADE_COSTS = {
	2: 100,
	3: 250,
	4: 500
}

static func attach_to(target_player: Player, parent: Node, items: Array[OreData]) -> ShopUI:
	var ui := ShopUI.new()
	ui.shop_items = items
	parent.add_child(ui)
	ui.setup(target_player)
	return ui

func setup(target_player: Player) -> void:
	player = target_player
	_build_ui()
	_populate_shop()
	
	player.gold_changed.connect(_on_gold_changed)
	_on_gold_changed(player.gold)
	
	set_open(false)
	
	panel.reset_size()
	panel.set_anchors_preset(Control.PRESET_CENTER)

func _build_ui() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	dim_background = ColorRect.new()
	dim_background.color = DIM_BG
	dim_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim_background)
	
	panel = PanelContainer.new()
	dim_background.add_child(panel)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.set_border_width_all(2)
	style.border_color = PANEL_BORDER
	panel.add_theme_stylebox_override("panel", style)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", GRID_PADDING)
	margin.add_theme_constant_override("margin_right", GRID_PADDING)
	margin.add_theme_constant_override("margin_top", GRID_PADDING)
	margin.add_theme_constant_override("margin_bottom", GRID_PADDING)
	panel.add_child(margin)
	
	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 4)
	margin.add_child(main_vbox)
	
	var header := HBoxContainer.new()
	main_vbox.add_child(header)
	
	var title := Label.new()
	title.text = "Shop"
	title.add_theme_font_size_override("font_size", 10)
	header.add_child(title)
	
	gold_label = Label.new()
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gold_label.add_theme_font_size_override("font_size", 8)
	gold_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	header.add_child(gold_label)
	
	item_list_vbox = VBoxContainer.new()
	item_list_vbox.add_theme_constant_override("separation", 2)
	main_vbox.add_child(item_list_vbox)

func _populate_shop() -> void:
	for child in item_list_vbox.get_children():
		child.queue_free()
		
	# Render Ore items available to trade
	for item in shop_items:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		
		var icon_container := PanelContainer.new()
		icon_container.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		var slot_style := StyleBoxFlat.new()
		slot_style.bg_color = Color(0.25, 0.25, 0.25)
		icon_container.add_theme_stylebox_override("panel", slot_style)
		
		var icon := TextureRect.new()
		icon.texture = item.texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_container.add_child(icon)
		row.add_child(icon_container)
		
		var details_vbox := VBoxContainer.new()
		var name_label := Label.new()
		name_label.text = item.ore_name
		name_label.add_theme_font_size_override("font_size", 8)
		
		var price_label := Label.new()
		price_label.text = "Sell: " + str(item.value) + "G"
		price_label.add_theme_font_size_override("font_size", 7)
		price_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		
		details_vbox.add_child(name_label)
		details_vbox.add_child(price_label)
		row.add_child(details_vbox)
		
		var actions := HBoxContainer.new()
		actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.alignment = BoxContainer.ALIGNMENT_END
		
		var sell_btn := Button.new()
		sell_btn.text = "Sell"
		sell_btn.add_theme_font_size_override("font_size", 7)
		sell_btn.pressed.connect(func(): _on_sell_pressed(item))
		actions.add_child(sell_btn)
		
		row.add_child(actions)
		item_list_vbox.add_child(row)

	# Render Pickaxe Upgrade Option
	var next_tier = player.current_pickaxe_tier + 1
	if PICKAXE_UPGRADE_COSTS.has(next_tier):
		var upgrade_cost = PICKAXE_UPGRADE_COSTS[next_tier]
		
		var separator := HSeparator.new()
		item_list_vbox.add_child(separator)
		
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		
		var details_vbox := VBoxContainer.new()
		var upgrade_label := Label.new()
		upgrade_label.text = "Pickaxe Tier " + str(next_tier)
		upgrade_label.add_theme_font_size_override("font_size", 8)
		
		var cost_label := Label.new()
		cost_label.text = "Buy: " + str(upgrade_cost) + "G"
		cost_label.add_theme_font_size_override("font_size", 7)
		cost_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		
		details_vbox.add_child(upgrade_label)
		details_vbox.add_child(cost_label)
		row.add_child(details_vbox)
		
		var actions := HBoxContainer.new()
		actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.alignment = BoxContainer.ALIGNMENT_END
		
		var buy_btn := Button.new()
		buy_btn.text = "Upgrade"
		buy_btn.add_theme_font_size_override("font_size", 7)
		buy_btn.pressed.connect(func(): _on_upgrade_pressed(next_tier, upgrade_cost))
		actions.add_child(buy_btn)
		
		row.add_child(actions)
		item_list_vbox.add_child(row)
	else:
		var separator := HSeparator.new()
		item_list_vbox.add_child(separator)
		
		var maxed_label := Label.new()
		maxed_label.text = "Pickaxe Maxed Out!"
		maxed_label.add_theme_font_size_override("font_size", 8)
		maxed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_list_vbox.add_child(maxed_label)

func _on_sell_pressed(item: OreData) -> void:
	if player.inventory.has(item) and player.inventory[item] > 0:
		player.inventory[item] -= 1
		player.gold += item.value
		if player.inventory[item] <= 0:
			player.inventory.erase(item)
		player.ore_collected.emit(item, player.inventory.get(item, 0))

func _on_upgrade_pressed(tier: int, cost: int) -> void:
	if player.gold >= cost:
		player.gold -= cost
		player.current_pickaxe_tier = tier
		player.pickaxe_upgraded.emit(tier)
		_populate_shop()
		
		await get_tree().process_frame
		panel.reset_size()
		panel.set_anchors_preset(Control.PRESET_CENTER)

func _on_gold_changed(amount: int) -> void:
	gold_label.text = "Gold: " + str(amount)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == TOGGLE_KEY:
			set_open(not is_open)
			get_viewport().set_input_as_handled()

func set_open(value: bool) -> void:
	is_open = value
	dim_background.visible = is_open
