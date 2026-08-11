class_name OverlayView
extends Control

signal run_upgrade_requested(weapon: String, dimension: String)
signal menu_requested


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func show_run_upgrade(session: RunSession, weapons: Dictionary) -> void:
	clear()
	visible = true
	_add_shade(0.88)
	var panel := UIFactory.panel(Vector2(90, 48), Vector2(1100, 624), Color(GamePalette.GREEN, 0.46))
	add_child(panel)
	var title := UIFactory.label("RESONANCE LEVEL %02d // CHOOSE EVOLUTION" % session.level, 28, GamePalette.CYAN)
	title.position = Vector2(30, 20)
	panel.add_child(title)
	var plural := "S" if session.pending_levels != 1 else ""
	var pending := UIFactory.label("%d CHOICE%s PENDING  //  EVERY AVAILABLE PATH IS SHOWN" % [session.pending_levels, plural], 11, Color(GamePalette.GREEN, 0.72))
	pending.position = Vector2(33, 57)
	panel.add_child(pending)
	var equipped: Array[String] = []
	for weapon: String in WeaponCatalog.ORDER:
		if int(weapons[weapon]["level"]) > 0:
			equipped.append(weapon)
	var gap := 14.0
	var card_width := minf(330.0, (1040.0 - gap * maxi(0, equipped.size() - 1)) / maxf(1.0, equipped.size()))
	var total_width := card_width * equipped.size() + gap * maxi(0, equipped.size() - 1)
	var start_x := (1100.0 - total_width) * 0.5
	for index: int in equipped.size():
		_build_run_upgrade_column(panel, equipped[index], session, Vector2(start_x + index * (card_width + gap), 92), Vector2(card_width, 495))


func show_library(profile: SaveProfile) -> void:
	clear()
	visible = true
	_add_shade(0.9)
	var panel := UIFactory.panel(Vector2(110, 45), Vector2(1060, 630), Color(GamePalette.CYAN, 0.38))
	add_child(panel)
	var title := UIFactory.label("ARSENAL LIBRARY", 30, GamePalette.CYAN)
	title.position = Vector2(28, 19)
	panel.add_child(title)
	var discovered_count := 0
	for id: String in LibraryCatalog.ORDER:
		if profile.is_discovered(id):
			discovered_count += 1
	var subtitle := UIFactory.label("%d / %d SIGNALS DECODED" % [discovered_count, LibraryCatalog.ORDER.size()], 12, Color(GamePalette.CYAN, 0.62))
	subtitle.position = Vector2(30, 58)
	panel.add_child(subtitle)
	var back := UIFactory.button("RETURN", Vector2(870, 20), Vector2(160, 48))
	back.pressed.connect(menu_requested.emit)
	panel.add_child(back)
	var scroll := ScrollContainer.new()
	scroll.name = "LibraryScroll"
	scroll.position = Vector2(28, 88)
	scroll.size = Vector2(1004, 515)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var grid := GridContainer.new()
	grid.name = "LibraryGrid"
	grid.columns = 2
	grid.custom_minimum_size = Vector2(988, 0)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 13)
	scroll.add_child(grid)
	for id: String in LibraryCatalog.ORDER:
		_build_library_entry(grid, id, profile)


func show_message(title_text: String, body_text: String, primary_text: String, primary_action: Callable, secondary_text: String, secondary_action: Callable) -> void:
	clear()
	visible = true
	_add_shade(0.82)
	var message_panel := UIFactory.panel(Vector2(340, 176), Vector2(600, 370), Color(GamePalette.MAGENTA, 0.4))
	add_child(message_panel)
	var title := UIFactory.label(title_text, 32, GamePalette.CYAN)
	title.position = Vector2(32, 35)
	title.size = Vector2(536, 45)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_panel.add_child(title)
	var body := UIFactory.label(body_text, 16, Color.WHITE)
	body.position = Vector2(35, 102)
	body.size = Vector2(530, 110)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_panel.add_child(body)
	var primary := UIFactory.button(primary_text, Vector2(55, 250), Vector2(225, 55))
	primary.pressed.connect(primary_action)
	message_panel.add_child(primary)
	var secondary := UIFactory.button(secondary_text, Vector2(320, 250), Vector2(225, 55))
	secondary.pressed.connect(secondary_action)
	message_panel.add_child(secondary)


func clear() -> void:
	for child: Node in get_children():
		child.queue_free()


func _add_shade(alpha: float) -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.01, 0.04, alpha)
	add_child(shade)


func _build_run_upgrade_column(parent: Control, weapon: String, session: RunSession, position: Vector2, size: Vector2) -> void:
	var card := UIFactory.panel(position, size, Color(GamePalette.CYAN, 0.30))
	card.name = "RunUpgradeColumn_" + weapon
	parent.add_child(card)
	var heading := UIFactory.label(WeaponCatalog.display_name(weapon), 18, GamePalette.CYAN)
	heading.position = Vector2(18, 16)
	heading.size = Vector2(size.x - 36, 28)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(heading)
	var mastery := UIFactory.label("RUN LEVELS SHAPE THIS WEAPON ONLY", 9, Color(GamePalette.GREEN, 0.62))
	mastery.position = Vector2(12, 48)
	mastery.size = Vector2(size.x - 24, 20)
	mastery.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(mastery)
	var dimensions: Array = RunUpgradeCatalog.choices_for(weapon)
	for choice_index: int in dimensions.size():
		var dimension := String(dimensions[choice_index])
		var definition := RunUpgradeCatalog.definition(weapon, dimension)
		var rank := session.weapon_upgrade_rank(weapon, dimension)
		var capped := rank >= RunUpgradeCatalog.MAX_RANK
		var suffix := "  //  MAX" if capped else ""
		var text := "%s\n%s\nRANK %d/%d%s" % [definition["name"], definition["description"], rank, RunUpgradeCatalog.MAX_RANK, suffix]
		var button := UIFactory.button(text, Vector2(15, 82 + choice_index * 128), Vector2(size.x - 30, 106))
		button.name = "RunUpgrade_%s_%s" % [weapon, dimension]
		button.add_theme_font_size_override("font_size", 13)
		button.disabled = capped
		button.pressed.connect(run_upgrade_requested.emit.bind(weapon, dimension))
		card.add_child(button)


func _build_library_entry(parent: Control, id: String, profile: SaveProfile) -> void:
	var definition := LibraryCatalog.definition(id)
	var discovered := profile.is_discovered(id)
	var border := Color(GamePalette.GREEN, 0.38) if discovered else Color(GamePalette.MAGENTA, 0.24)
	var card := UIFactory.panel(Vector2.ZERO, Vector2(488, 145), border)
	card.name = "LibraryEntry_" + id
	card.custom_minimum_size = Vector2(488, 145)
	parent.add_child(card)
	var title_text := String(definition["name"]) if discovered else "UNDECODED %s" % definition["kind"]
	var title_color := GamePalette.GREEN if discovered else Color(GamePalette.MAGENTA, 0.72)
	var title := UIFactory.label(title_text, 17, title_color)
	title.position = Vector2(17, 11)
	card.add_child(title)
	var status := "DISCOVERED" if discovered else "LOCKED"
	if discovered and profile.data["mastery_xp"].has(id):
		status += "  //  MASTERY %02d" % profile.mastery_level(id)
	var badge := UIFactory.label(status, 10, Color(title_color, 0.72))
	badge.position = Vector2(292, 15)
	badge.size = Vector2(178, 18)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	card.add_child(badge)
	var body_text: String
	if discovered:
		body_text = "%s\n%s\nACQUIRE  //  %s" % [definition["role"], definition["mechanics"], definition["acquisition"]]
	else:
		body_text = "ACQUISITION CLUE  //  %s" % definition["clue"]
	var body := RichTextLabel.new()
	body.text = body_text
	body.position = Vector2(18, 42)
	body.size = Vector2(454, 91)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.fit_content = false
	body.scroll_active = false
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_font_size_override("normal_font_size", 11)
	body.add_theme_color_override("default_color", Color(0.78, 0.9, 1.0) if discovered else Color(0.65, 0.68, 0.78))
	card.add_child(body)
