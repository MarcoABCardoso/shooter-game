class_name OverlayView
extends Control

const OperationEvolutionCatalog := preload("res://scripts/content/operation_evolution_catalog.gd")

signal operation_evolution_requested(id: String)
signal menu_requested


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func show_operation_evolution(session: RunSession, choices: Array[String]) -> void:
	clear()
	visible = true
	_add_shade(0.9)
	var panel := UIFactory.panel(Vector2(90, 55), Vector2(1100, 610), Color(GamePalette.GREEN, 0.48))
	add_child(panel)
	var title := UIFactory.label("RESONANCE TRANSFORMATION", 28, GamePalette.CYAN)
	title.position = Vector2(30, 20)
	panel.add_child(title)
	var subtitle := UIFactory.label("LEVEL %02d  •  CHOOSE THIS STAGE'S BUILD" % session.level, 12, Color(GamePalette.GREEN, 0.78))
	subtitle.position = Vector2(32, 58)
	subtitle.size = Vector2(1035, 24)
	panel.add_child(subtitle)
	var card_width := 490.0 if choices.size() <= 2 else 322.0
	var gap := 18.0
	var total_width := card_width * choices.size() + gap * maxi(0, choices.size() - 1)
	var start_x := (1100.0 - total_width) * 0.5
	for index: int in choices.size():
		var id := choices[index]
		var definition := OperationEvolutionCatalog.definition(id)
		var card := UIFactory.panel(Vector2(start_x + index * (card_width + gap), 125), Vector2(card_width, 300), Color(GamePalette.CYAN, 0.3))
		card.name = "EvolutionCard_" + id
		panel.add_child(card)
		var branch := UIFactory.label(String(definition["branch"]).to_upper() + " PATH", 11, Color(GamePalette.YELLOW, 0.75))
		branch.position = Vector2(20, 18)
		card.add_child(branch)
		var heading := UIFactory.label(String(definition["name"]), 22, GamePalette.CYAN)
		heading.position = Vector2(20, 48)
		heading.size = Vector2(card_width - 40, 34)
		card.add_child(heading)
		var description_text := String(definition["description"])
		var sentence_end := description_text.find(".")
		if sentence_end >= 0:
			description_text = description_text.left(sentence_end + 1)
		if description_text.length() > 82:
			description_text = description_text.left(79).strip_edges() + "…"
		var description := UIFactory.label(description_text, 15, Color.WHITE)
		description.position = Vector2(20, 94)
		description.size = Vector2(card_width - 40, 105)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(description)
		var choose := UIFactory.button("COMMIT", Vector2(20, 230), Vector2(card_width - 40, 48))
		choose.name = "EvolutionChoice_" + id
		choose.pressed.connect(operation_evolution_requested.emit.bind(id))
		card.add_child(choose)


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
	var subtitle := UIFactory.label("%d OF %d ENTRIES DISCOVERED" % [discovered_count, LibraryCatalog.ORDER.size()], 12, Color(GamePalette.CYAN, 0.62))
	subtitle.position = Vector2(30, 58)
	panel.add_child(subtitle)
	var back := UIFactory.button("BACK TO HANGAR", Vector2(850, 20), Vector2(180, 48))
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
	if not primary_text.is_empty():
		var primary := UIFactory.button(primary_text, Vector2(55, 250), Vector2(225, 55))
		primary.name = "ResultPrimaryButton"
		primary.pressed.connect(primary_action)
		message_panel.add_child(primary)
	var secondary_x := 187.0 if primary_text.is_empty() else 320.0
	var secondary := UIFactory.button(secondary_text, Vector2(secondary_x, 250), Vector2(225, 55))
	secondary.name = "ResultHangarButton" if primary_text.is_empty() else "ResultSecondaryButton"
	secondary.pressed.connect(secondary_action)
	message_panel.add_child(secondary)


func show_unlock_reveal(stage_title: String, equipment_id: String, summary: String, hangar_action: Callable) -> void:
	clear()
	visible = true
	_add_shade(0.93)
	var definition := LibraryCatalog.definition(equipment_id)
	var panel := UIFactory.panel(Vector2(250, 92), Vector2(780, 540), Color(GamePalette.YELLOW, 0.72))
	panel.name = "UnlockReveal"
	add_child(panel)
	var eyebrow := UIFactory.label(stage_title + "  •  ARSENAL SIGNAL RECOVERED", 13, Color(GamePalette.YELLOW, 0.82))
	eyebrow.position = Vector2(30, 24)
	eyebrow.size = Vector2(720, 24)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(eyebrow)
	var flare := Control.new()
	flare.name = "UnlockFlare"
	flare.position = Vector2(390, 128)
	panel.add_child(flare)
	for radius in [92.0, 70.0, 48.0]:
		var ring := UIFactory.panel(Vector2(-radius, -radius), Vector2(radius * 2.0, radius * 2.0), Color(GamePalette.CYAN, 0.18 + (92.0 - radius) * 0.006))
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flare.add_child(ring)
	var kind := UIFactory.label(String(definition.get("kind", "EQUIPMENT")), 12, GamePalette.GREEN)
	kind.position = Vector2(250, 82)
	kind.size = Vector2(280, 24)
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(kind)
	var name := UIFactory.label(String(definition.get("name", equipment_id.to_upper())), 38, Color.WHITE)
	name.name = "UnlockName"
	name.position = Vector2(40, 117)
	name.size = Vector2(700, 52)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(name)
	var role := UIFactory.label(String(definition.get("role", "")), 18, GamePalette.CYAN)
	role.position = Vector2(70, 184)
	role.size = Vector2(640, 30)
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(role)
	var mechanics := UIFactory.label(String(definition.get("mechanics", "")), 15, Color.WHITE)
	mechanics.position = Vector2(80, 230)
	mechanics.size = Vector2(620, 74)
	mechanics.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mechanics.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mechanics.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(mechanics)
	var secured := UIFactory.label(summary, 13, Color(GamePalette.GREEN, 0.78))
	secured.position = Vector2(70, 326)
	secured.size = Vector2(640, 58)
	secured.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	secured.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	secured.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(secured)
	var hangar := UIFactory.button("OPEN HANGAR", Vector2(260, 436), Vector2(260, 58))
	hangar.name = "UnlockHangarButton"
	hangar.pressed.connect(hangar_action)
	panel.add_child(hangar)


func clear() -> void:
	for child: Node in get_children():
		child.queue_free()


func _add_shade(alpha: float) -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.01, 0.04, alpha)
	add_child(shade)


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
		status = "MASTERY %02d" % profile.mastery_level(id)
	var badge := UIFactory.label(status, 10, Color(title_color, 0.72))
	badge.position = Vector2(292, 15)
	badge.size = Vector2(178, 18)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	card.add_child(badge)
	var body_text: String
	if discovered:
		body_text = "%s\n%s\n%s\nSource: %s" % [definition["role"], definition["mechanics"], definition.get("plans", ""), definition["acquisition"]]
	else:
		body_text = "Hint: %s" % definition["clue"]
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
