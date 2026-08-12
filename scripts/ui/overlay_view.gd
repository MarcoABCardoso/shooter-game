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
	var subtitle := UIFactory.label("LEVEL %02d  •  BASELINE POWER INCREASED AUTOMATICALLY\nChoose a behavior. The commitment lasts for this stage." % session.level, 12, Color(GamePalette.GREEN, 0.78))
	subtitle.position = Vector2(32, 58)
	subtitle.size = Vector2(1035, 48)
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
		var description := UIFactory.label(String(definition["description"]), 15, Color.WHITE)
		description.position = Vector2(20, 94)
		description.size = Vector2(card_width - 40, 82)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(description)
		var future := UIFactory.label("VISIBLE NEXT STEP\n" + String(definition["future"]), 11, Color(GamePalette.GREEN, 0.68))
		future.position = Vector2(20, 184)
		future.size = Vector2(card_width - 40, 48)
		card.add_child(future)
		var choose := UIFactory.button("COMMIT", Vector2(20, 242), Vector2(card_width - 40, 44))
		choose.name = "EvolutionChoice_" + id
		choose.pressed.connect(operation_evolution_requested.emit.bind(id))
		card.add_child(choose)
	var tree_note := UIFactory.label("MASTERY REVEALS THE SECOND FOLLOW-UP FOR EACH NAMED BUILD", 12, Color(GamePalette.CYAN, 0.65))
	tree_note.position = Vector2(28, 520)
	tree_note.size = Vector2(1044, 30)
	tree_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(tree_note)


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
