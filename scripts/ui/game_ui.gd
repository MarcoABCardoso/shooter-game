class_name GameUI
extends CanvasLayer

const MobileControlsScript := preload("res://scripts/ui/mobile_controls.gd")
const StageCatalog := preload("res://scripts/content/stage_catalog.gd")
const StageGraphViewScript := preload("res://scripts/ui/stage_graph_view.gd")
const CreditsViewScript := preload("res://scripts/ui/credits_view.gd")

signal deploy_requested
signal stage_selected(id: String)
signal new_game_requested
signal load_game_requested
signal options_requested
signal title_requested
signal slot_selected(slot: int, create_new: bool)
signal resume_requested
signal abandon_requested
signal retry_requested
signal menu_requested
signal reset_requested
signal library_requested
signal loadout_requested
signal skills_requested
signal credits_requested
signal credits_finished
signal weapon_selected(id: String)
signal ability_selected(id: String)
signal skill_purchase_requested(id: String)
signal skills_respec_requested
signal run_upgrade_requested(weapon: String, dimension: String)
signal master_volume_changed(value: float)
signal mobile_input_changed(movement: Vector2)
signal mobile_ability_requested
signal mobile_pause_requested

var hud: Control
var title_screen: Control
var save_slot_screen: Control
var options_screen: Control
var hangar_screen: Control
var start_screen: Control
var stage_select_screen: Control
var loadout_screen: Control
var skill_tree_screen: Control
var credits_screen
var overlay: Control
var hp_bar: ProgressBar
var resonance_bar: ProgressBar
var dash_bar: ProgressBar
var ability_caption: Label
var time_label: Label
var stats_label: Label
var combo_label: Label
var weapon_label: Label
var evolution_label: Label
var banner_label: Label
var start_flux_label: Label
var start_stats_label: Label
var start_mastery_label: Label
var hangar_slot_label: Label
var hangar_credits_button: Button
var stage_graph_view
var loadout_box: VBoxContainer
var loadout_slots_label: Label
var skill_flux_label: Label
var skill_tree_view: SkillTreeView
var banner_tween: Tween
var save_slot_box: VBoxContainer
var save_slot_title: Label
var master_volume_slider: HSlider
var master_volume_value_label: Label
var cached_slot_summaries: Array[Dictionary] = []
var creating_new_slot := false
var mobile_controls
var mobile_controls_available := false


func _ready() -> void:
	layer = 10
	mobile_controls_available = MobileControlsScript.should_be_available()
	_build_hud()
	_build_title_screen()
	_build_save_slot_screen()
	_build_options_screen()
	_build_hangar_screen()
	_build_credits_screen()
	_build_stage_select_screen()
	_build_loadout_screen()
	_build_skill_tree_screen()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)


func _input(event: InputEvent) -> void:
	if not OS.has_feature("web") or not mobile_controls_available:
		return
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		return
	var pressed := false
	if event is InputEventScreenTouch:
		pressed = event.pressed
	elif event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if pressed:
		# Browsers only permit fullscreen while handling a user activation event.
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func show_title() -> void:
	_hide_all_screens()
	title_screen.visible = true


func show_save_slots(create_new: bool, summaries: Array) -> void:
	_hide_all_screens()
	save_slot_screen.visible = true
	creating_new_slot = create_new
	cached_slot_summaries.clear()
	for summary: Variant in summaries:
		if summary is Dictionary:
			cached_slot_summaries.append(summary.duplicate(true))
	save_slot_title.text = "SELECT SLOT // NEW GAME" if create_new else "SELECT SLOT // LOAD GAME"
	_rebuild_save_slots()


func show_options() -> void:
	_hide_all_screens()
	options_screen.visible = true
	master_volume_slider.grab_focus()


func set_master_volume(value: float) -> void:
	var percentage := roundf(clampf(value, 0.0, 1.0) * 100.0)
	master_volume_slider.set_value_no_signal(percentage)
	_update_master_volume_label(percentage)


func show_menu(profile: SaveProfile) -> void:
	_hide_all_screens()
	hangar_screen.visible = true
	hangar_slot_label.text = "ACTIVE SAVE // SLOT %02d" % profile.active_slot if profile.active_slot > 0 else "ACTIVE SAVE // UNSLOTTED"
	start_flux_label.text = "◆  %d" % int(profile.data["flux"])
	start_stats_label.text = "BEST  %s\nLEVEL  %02d\nRUNS  %02d" % [_format_time(float(profile.data["best_time"])), int(profile.data["best_level"]), int(profile.data["runs"])]
	var equipped := profile.equipped_weapons()
	start_mastery_label.text = "%s\nACTIVE  %s  //  M%02d" % [" + ".join(equipped).to_upper(), profile.equipped_ability().replace("_", " ").to_upper(), profile.mastery_level(profile.equipped_ability())]
	hangar_credits_button.visible = profile.stage_cleared("stage_5")


func show_credits() -> void:
	_hide_all_screens()
	credits_screen.visible = true
	credits_screen.start()


func show_stage_select(profile: SaveProfile) -> void:
	_hide_all_screens()
	stage_select_screen.visible = true
	_rebuild_stage_select(profile)


func show_loadout(profile: SaveProfile) -> void:
	_hide_all_screens()
	loadout_screen.visible = true
	loadout_slots_label.text = "WEAPON SLOTS  %d / %d" % [profile.equipped_weapons().size(), profile.unlocked_weapon_slots()]
	_rebuild_loadout(profile)


func show_skill_tree(profile: SaveProfile) -> void:
	_hide_all_screens()
	skill_tree_screen.visible = true
	skill_flux_label.text = "◆ %d FLUX" % int(profile.data["flux"])
	skill_tree_view.rebuild(profile)


func show_run() -> void:
	_hide_all_screens()
	hud.visible = true
	mobile_controls.set_controls_active(mobile_controls_available)


func show_run_upgrade(session: RunSession, weapons: Dictionary) -> void:
	_clear_overlay()
	hud.visible = true
	mobile_controls.set_controls_active(false)
	overlay.visible = true
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.01, 0.04, 0.88)
	overlay.add_child(shade)
	var panel := UIFactory.panel(Vector2(90, 48), Vector2(1100, 624), Color(GamePalette.GREEN, 0.46))
	overlay.add_child(panel)
	var title := UIFactory.label("RESONANCE LEVEL %02d // CHOOSE EVOLUTION" % session.level, 28, GamePalette.CYAN)
	title.position = Vector2(30, 20)
	panel.add_child(title)
	var pending := UIFactory.label("%d CHOICE%s PENDING  //  EVERY AVAILABLE PATH IS SHOWN" % [session.pending_levels, "S" if session.pending_levels != 1 else ""], 11, Color(GamePalette.GREEN, 0.72))
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
	for index in equipped.size():
		_build_run_upgrade_column(panel, equipped[index], session, Vector2(start_x + index * (card_width + gap), 92), Vector2(card_width, 495))


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
	for choice_index in dimensions.size():
		var dimension := String(dimensions[choice_index])
		var definition := RunUpgradeCatalog.definition(weapon, dimension)
		var rank := session.weapon_upgrade_rank(weapon, dimension)
		var capped := rank >= RunUpgradeCatalog.MAX_RANK
		var text := "%s\n%s\nRANK %d/%d%s" % [definition["name"], definition["description"], rank, RunUpgradeCatalog.MAX_RANK, "  //  MAX" if capped else ""]
		var button := UIFactory.button(text, Vector2(15, 82 + choice_index * 128), Vector2(size.x - 30, 106))
		button.name = "RunUpgrade_%s_%s" % [weapon, dimension]
		button.add_theme_font_size_override("font_size", 13)
		button.disabled = capped
		button.pressed.connect(run_upgrade_requested.emit.bind(weapon, dimension))
		card.add_child(button)


func show_library(profile: SaveProfile) -> void:
	_clear_overlay()
	_hide_all_screens()
	overlay.visible = true
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.01, 0.04, 0.9)
	overlay.add_child(shade)
	var panel := UIFactory.panel(Vector2(110, 45), Vector2(1060, 630), Color(GamePalette.CYAN, 0.38))
	overlay.add_child(panel)
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


func update_hud(session: RunSession, weapons: Dictionary, stage_id: String = "stage_1") -> void:
	time_label.text = _format_time(session.elapsed)
	stats_label.text = "LEVEL %02d    ◆ %d    KILLS %d" % [session.level, session.flux, session.kills]
	combo_label.text = "CHAIN x%.1f" % session.combo
	combo_label.modulate = GamePalette.YELLOW if session.combo > 1.5 else Color(GamePalette.YELLOW, 0.55)
	resonance_bar.max_value = session.resonance_needed
	resonance_bar.value = session.resonance
	var names: Array[String] = []
	for id in WeaponCatalog.ORDER:
		if int(weapons[id]["level"]) > 0:
			names.append(String(id).to_upper())
	weapon_label.text = "  //  ".join(names)
	evolution_label.text = "%s  //  FLUX BANKS AT RUN END" % StageCatalog.display_name(stage_id)


func set_health(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current


func set_dash(ratio: float) -> void:
	dash_bar.value = clampf(ratio, 0.0, 1.0) * 100.0


func set_ability(id: String) -> void:
	ability_caption.text = "VECTOR PARRY" if id == "vector_parry" else "PHASE DASH"


func show_stage_clear(stage_id: String, session: RunSession, first_clear: bool, first_clear_bonus: int) -> void:
	var reward_line := "STAGE REWARDS ALREADY SECURED"
	if first_clear:
		reward_line = "FIRST CLEAR // +%d BONUS FLUX" % first_clear_bonus
		if stage_id == "stage_1":
			reward_line += "\nUNLOCKED // ORBIT BLADES"
		elif stage_id == "stage_5":
			reward_line += "\nUNLOCKED // SECOND WEAPON SLOT + VECTOR PARRY"
	var total_banked := session.flux + first_clear_bonus
	var body := "Deployment complete  •  Level %d\n%d hostiles erased  •  %d Flux banked\n\n%s" % [session.level, session.kills, total_banked, reward_line]
	_show_message("%s CLEARED" % StageCatalog.display_name(stage_id), body, "RETURN TO HANGAR", menu_requested.emit, "RUN AGAIN", retry_requested.emit)


func show_pause() -> void:
	mobile_controls.set_controls_active(false)
	_show_message("PAUSED", "The swarm is suspended.", "RESUME", resume_requested.emit, "ABANDON RUN", abandon_requested.emit)


func show_run_end(defeated: bool, session: RunSession) -> void:
	mobile_controls.set_controls_active(false)
	var title := "SIGNAL LOST" if defeated else "RUN ABANDONED"
	var body := "%s survived  •  Level %d\n%d hostiles erased  •  %d Flux banked\n\nWeapon mastery recorded permanently." % [_format_time(session.elapsed), session.level, session.kills, session.flux]
	_show_message(title, body, "RUN AGAIN", retry_requested.emit, "RETURN TO HANGAR", menu_requested.emit)


func show_reset_confirmation() -> void:
	_show_message("RESET PROFILE?", "This erases all Flux, mastery, records, and skill-tree progress.\nThis action cannot be undone.", "CANCEL", menu_requested.emit, "ERASE EVERYTHING", reset_requested.emit)


func show_banner(text: String, color: Color) -> void:
	if is_instance_valid(banner_tween):
		banner_tween.kill()
	banner_label.text = text
	banner_label.modulate = color
	banner_tween = create_tween()
	banner_tween.tween_interval(1.8)
	banner_tween.tween_property(banner_label, "modulate:a", 0.0, 0.6)
	banner_tween.tween_callback(_clear_banner)


func _clear_banner() -> void:
	banner_label.text = ""
	banner_label.modulate.a = 1.0


func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hud)
	var top := ColorRect.new()
	top.position = Vector2(54, 18)
	top.size = Vector2(1172, 48)
	top.color = Color(GamePalette.INK, 0.86)
	hud.add_child(top)
	time_label = UIFactory.label("00:00", 22, GamePalette.CYAN); time_label.position = Vector2(18, 9); top.add_child(time_label)
	stats_label = UIFactory.label("LEVEL 01    ◆ 0", 16, Color.WHITE); stats_label.position = Vector2(145, 13); top.add_child(stats_label)
	combo_label = UIFactory.label("CHAIN x1.0", 16, GamePalette.YELLOW); combo_label.position = Vector2(945, 13); top.add_child(combo_label)
	hp_bar = UIFactory.progress_bar(Vector2(55, 677), Vector2(330, 15), GamePalette.MAGENTA); hud.add_child(hp_bar)
	resonance_bar = UIFactory.progress_bar(Vector2(430, 681), Vector2(420, 9), GamePalette.GREEN); hud.add_child(resonance_bar)
	dash_bar = UIFactory.progress_bar(Vector2(895, 681), Vector2(330, 9), GamePalette.CYAN); hud.add_child(dash_bar)
	_add_hud_caption("HULL", Vector2(55, 658), GamePalette.MAGENTA)
	_add_hud_caption("RESONANCE", Vector2(430, 658), GamePalette.GREEN)
	ability_caption = _add_hud_caption("PHASE DASH", Vector2(895, 658), GamePalette.CYAN)
	weapon_label = UIFactory.label("PULSE I", 12, Color(GamePalette.CYAN, 0.8)); weapon_label.position = Vector2(55, 82); hud.add_child(weapon_label)
	evolution_label = UIFactory.label("HANGAR BUILD ACTIVE", 12, Color(GamePalette.GREEN, 0.78)); evolution_label.position = Vector2(55, 104); hud.add_child(evolution_label)
	banner_label = UIFactory.label("", 21, GamePalette.CYAN); banner_label.position = Vector2(0, 215); banner_label.size = Vector2(1280, 34); banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; hud.add_child(banner_label)
	mobile_controls = MobileControlsScript.new()
	mobile_controls.name = "MobileControls"
	mobile_controls.input_changed.connect(mobile_input_changed.emit)
	mobile_controls.ability_requested.connect(mobile_ability_requested.emit)
	mobile_controls.pause_requested.connect(mobile_pause_requested.emit)
	hud.add_child(mobile_controls)
	mobile_controls.set_controls_active(false)


func _add_hud_caption(text: String, position: Vector2, color: Color) -> Label:
	var caption := UIFactory.label(text, 11, color)
	caption.position = position
	hud.add_child(caption)
	return caption


func _build_title_screen() -> void:
	title_screen = Control.new()
	title_screen.name = "TitleScreen"
	title_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(title_screen)
	var panel := UIFactory.panel(Vector2(340, 85), Vector2(600, 550), Color(GamePalette.CYAN, 0.3))
	title_screen.add_child(panel)
	var title := _add_menu_label(panel, "NEON REQUIEM", 52, GamePalette.CYAN, Vector2(0, 65))
	title.size = Vector2(600, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tagline := _add_menu_label(panel, "HOW YOU FIGHT BECOMES WHAT YOU ARE.", 14, Color.WHITE, Vector2(0, 132))
	tagline.size = Vector2(600, 28)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var new_game := UIFactory.button("NEW GAME", Vector2(145, 220), Vector2(310, 58))
	new_game.name = "NewGameButton"
	new_game.pressed.connect(new_game_requested.emit)
	panel.add_child(new_game)
	var load_game := UIFactory.button("LOAD GAME", Vector2(145, 296), Vector2(310, 58))
	load_game.name = "LoadGameButton"
	load_game.pressed.connect(load_game_requested.emit)
	panel.add_child(load_game)
	var options := UIFactory.button("OPTIONS", Vector2(145, 372), Vector2(310, 58))
	options.name = "OptionsButton"
	options.pressed.connect(options_requested.emit)
	panel.add_child(options)
	if OS.has_feature("web") and mobile_controls_available:
		var fullscreen_hint := _add_menu_label(panel, "TAP ANYWHERE FOR FULLSCREEN", 11, Color(GamePalette.GREEN, 0.7), Vector2(0, 466))
		fullscreen_hint.size = Vector2(600, 24)
		fullscreen_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _build_save_slot_screen() -> void:
	save_slot_screen = Control.new()
	save_slot_screen.name = "SaveSlotScreen"
	save_slot_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(save_slot_screen)
	var panel := UIFactory.panel(Vector2(250, 70), Vector2(780, 580), Color(GamePalette.GREEN, 0.3))
	save_slot_screen.add_child(panel)
	save_slot_title = _add_menu_label(panel, "SELECT SLOT", 30, GamePalette.CYAN, Vector2(40, 32))
	var back := UIFactory.button("BACK", Vector2(580, 25), Vector2(160, 50))
	back.name = "SaveSlotBackButton"
	back.pressed.connect(title_requested.emit)
	panel.add_child(back)
	save_slot_box = VBoxContainer.new()
	save_slot_box.position = Vector2(40, 105)
	save_slot_box.size = Vector2(700, 405)
	save_slot_box.add_theme_constant_override("separation", 15)
	panel.add_child(save_slot_box)


func _build_options_screen() -> void:
	options_screen = Control.new()
	options_screen.name = "OptionsScreen"
	options_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(options_screen)
	var panel := UIFactory.panel(Vector2(250, 70), Vector2(780, 580), Color(GamePalette.CYAN, 0.3))
	options_screen.add_child(panel)
	_add_menu_label(panel, "OPTIONS", 34, GamePalette.CYAN, Vector2(42, 32))
	var back := UIFactory.button("BACK", Vector2(580, 25), Vector2(160, 50))
	back.name = "OptionsBackButton"
	back.pressed.connect(title_requested.emit)
	panel.add_child(back)
	_add_menu_label(panel, "AUDIO", 15, Color(GamePalette.GREEN, 0.8), Vector2(44, 102))
	var audio_panel := UIFactory.panel(Vector2(40, 132), Vector2(700, 92), Color(GamePalette.CYAN, 0.22))
	panel.add_child(audio_panel)
	var volume_caption := _add_menu_label(audio_panel, "MASTER VOLUME", 14, Color(GamePalette.CYAN, 0.72), Vector2(24, 30))
	volume_caption.size = Vector2(175, 30)
	master_volume_slider = HSlider.new()
	master_volume_slider.name = "MasterVolumeSlider"
	master_volume_slider.position = Vector2(205, 22)
	master_volume_slider.size = Vector2(380, 42)
	master_volume_slider.min_value = 0.0
	master_volume_slider.max_value = 100.0
	master_volume_slider.step = 1.0
	master_volume_slider.value = 100.0
	master_volume_slider.tooltip_text = "Adjusts music and sound effects"
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	audio_panel.add_child(master_volume_slider)
	master_volume_value_label = _add_menu_label(audio_panel, "100%", 16, Color.WHITE, Vector2(595, 29))
	master_volume_value_label.size = Vector2(80, 30)
	master_volume_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_add_menu_label(panel, "CONTROLS", 15, Color(GamePalette.GREEN, 0.8), Vector2(44, 252))
	var controls := UIFactory.panel(Vector2(40, 282), Vector2(700, 248), Color(GamePalette.GREEN, 0.2))
	panel.add_child(controls)
	_add_control_row(controls, "MOVE", "WASD / ARROW KEYS", 27)
	_add_control_row(controls, "TARGET", "AUTOMATIC", 82)
	_add_control_row(controls, "ABILITY", "SPACE", 137)
	_add_control_row(controls, "PAUSE", "ESC / P", 192)


func _on_master_volume_changed(value: float) -> void:
	_update_master_volume_label(value)
	master_volume_changed.emit(value / 100.0)


func _update_master_volume_label(value: float) -> void:
	master_volume_value_label.text = "%d%%" % int(roundf(value))


func _add_control_row(parent: Control, action: String, binding: String, y: float) -> void:
	var action_label := _add_menu_label(parent, action, 14, Color(GamePalette.CYAN, 0.68), Vector2(30, y))
	action_label.size = Vector2(250, 30)
	var binding_label := _add_menu_label(parent, binding, 18, Color.WHITE, Vector2(280, y - 3))
	binding_label.size = Vector2(380, 32)
	binding_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _build_hangar_screen() -> void:
	hangar_screen = Control.new()
	hangar_screen.name = "HangarScreen"
	hangar_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hangar_screen)
	start_screen = hangar_screen
	var panel := UIFactory.panel(Vector2(160, 80), Vector2(960, 560), Color(GamePalette.CYAN, 0.25))
	hangar_screen.add_child(panel)
	_add_menu_label(panel, "HANGAR", 36, GamePalette.CYAN, Vector2(58, 48))
	hangar_slot_label = _add_menu_label(panel, "ACTIVE SAVE // SLOT 01", 11, Color(GamePalette.GREEN, 0.72), Vector2(58, 96))
	_add_menu_label(panel, "PREPARE YOUR SHIP FOR THE NEXT SIGNAL.", 13, Color(GamePalette.CYAN, 0.66), Vector2(58, 119))
	var deploy := UIFactory.button("DEPLOY", Vector2(58, 216), Vector2(310, 64))
	deploy.name = "DeployButton"
	deploy.pressed.connect(deploy_requested.emit)
	panel.add_child(deploy)
	var loadout := UIFactory.button("LOADOUT", Vector2(58, 296), Vector2(150, 54))
	loadout.name = "LoadoutButton"
	loadout.pressed.connect(loadout_requested.emit)
	panel.add_child(loadout)
	var skills := UIFactory.button("SKILL TREE", Vector2(218, 296), Vector2(150, 54))
	skills.name = "SkillTreeButton"
	skills.pressed.connect(skills_requested.emit)
	panel.add_child(skills)
	var reset := UIFactory.button("RESET PROFILE", Vector2(58, 366), Vector2(150, 54))
	reset.name = "ResetProfileButton"
	reset.pressed.connect(show_reset_confirmation)
	panel.add_child(reset)
	var library := UIFactory.button("LIBRARY", Vector2(218, 366), Vector2(150, 54))
	library.name = "LibraryButton"
	library.pressed.connect(library_requested.emit)
	panel.add_child(library)
	var title_button := UIFactory.button("SAVE & RETURN TO TITLE", Vector2(58, 436), Vector2(310, 42))
	title_button.name = "ReturnToTitleButton"
	title_button.pressed.connect(title_requested.emit)
	panel.add_child(title_button)

	var status_panel := UIFactory.panel(Vector2(470, 54), Vector2(430, 350), Color(GamePalette.GREEN, 0.22))
	panel.add_child(status_panel)
	_add_menu_label(status_panel, "FLUX", 11, Color(GamePalette.YELLOW, 0.64), Vector2(30, 28))
	start_flux_label = _add_menu_label(status_panel, "◆  0", 28, GamePalette.YELLOW, Vector2(27, 48))
	_add_menu_label(status_panel, "RECORD", 11, Color(GamePalette.CYAN, 0.58), Vector2(30, 112))
	start_stats_label = _add_menu_label(status_panel, "BEST  00:00\nLEVEL  01\nRUNS  00", 16, Color.WHITE, Vector2(29, 136))
	start_stats_label.add_theme_constant_override("line_spacing", 7)
	_add_menu_label(status_panel, "LOADOUT", 11, Color(GamePalette.GREEN, 0.58), Vector2(224, 112))
	start_mastery_label = _add_menu_label(status_panel, "PULSE\nACTIVE  DASH  //  M00", 13, Color(GamePalette.GREEN, 0.86), Vector2(223, 136))
	start_mastery_label.add_theme_constant_override("line_spacing", 10)
	hangar_credits_button = UIFactory.button("CREDITS", Vector2(470, 420), Vector2(430, 58))
	hangar_credits_button.name = "CreditsButton"
	hangar_credits_button.visible = false
	hangar_credits_button.pressed.connect(credits_requested.emit)
	panel.add_child(hangar_credits_button)


func _build_credits_screen() -> void:
	credits_screen = CreditsViewScript.new()
	credits_screen.name = "CreditsScreen"
	credits_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	credits_screen.finished.connect(credits_finished.emit)
	credits_screen.exit_requested.connect(credits_finished.emit)
	add_child(credits_screen)


func _build_stage_select_screen() -> void:
	stage_select_screen = Control.new()
	stage_select_screen.name = "StageSelectScreen"
	stage_select_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(stage_select_screen)
	var panel := UIFactory.panel(Vector2(120, 42), Vector2(1040, 636), Color(GamePalette.GREEN, 0.30))
	stage_select_screen.add_child(panel)
	_add_menu_label(panel, "VECTOR ROUTE", 32, GamePalette.CYAN, Vector2(38, 25))
	var back := UIFactory.button("BACK", Vector2(850, 22), Vector2(150, 48))
	back.name = "StageSelectBackButton"
	back.pressed.connect(menu_requested.emit)
	panel.add_child(back)
	stage_graph_view = StageGraphViewScript.new()
	stage_graph_view.name = "StageGraph"
	stage_graph_view.position = Vector2(55, 90)
	stage_graph_view.size = Vector2(930, 510)
	stage_graph_view.stage_selected.connect(stage_selected.emit)
	panel.add_child(stage_graph_view)


func _rebuild_stage_select(profile: SaveProfile) -> void:
	stage_graph_view.rebuild(profile)


func _build_loadout_screen() -> void:
	loadout_screen = Control.new()
	loadout_screen.name = "LoadoutScreen"
	loadout_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(loadout_screen)
	var panel := UIFactory.panel(Vector2(160, 55), Vector2(960, 610), Color(GamePalette.CYAN, 0.3))
	loadout_screen.add_child(panel)
	_add_menu_label(panel, "LOADOUT", 30, GamePalette.CYAN, Vector2(44, 30))
	loadout_slots_label = _add_menu_label(panel, "WEAPON SLOTS  1 / 1", 16, GamePalette.YELLOW, Vector2(490, 43))
	loadout_slots_label.size = Vector2(245, 28)
	loadout_slots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var back := UIFactory.button("RETURN", Vector2(756, 26), Vector2(160, 50))
	back.name = "LoadoutReturnButton"
	back.pressed.connect(menu_requested.emit)
	panel.add_child(back)
	loadout_box = VBoxContainer.new()
	loadout_box.position = Vector2(44, 95)
	loadout_box.size = Vector2(872, 475)
	loadout_box.add_theme_constant_override("separation", 10)
	panel.add_child(loadout_box)


func _build_skill_tree_screen() -> void:
	skill_tree_screen = Control.new()
	skill_tree_screen.name = "SkillTreeScreen"
	skill_tree_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(skill_tree_screen)
	var panel := UIFactory.panel(Vector2(160, 35), Vector2(960, 650), Color(GamePalette.GREEN, 0.3))
	skill_tree_screen.add_child(panel)
	_add_menu_label(panel, "SKILL TREE", 30, GamePalette.CYAN, Vector2(34, 22))
	skill_flux_label = _add_menu_label(panel, "◆ 0 FLUX", 18, GamePalette.YELLOW, Vector2(500, 31))
	var back := UIFactory.button("RETURN", Vector2(772, 16), Vector2(150, 46))
	back.pressed.connect(menu_requested.emit)
	panel.add_child(back)
	var respec := UIFactory.button("RESPEC ALL", Vector2(34, 586), Vector2(170, 42))
	respec.name = "RespecSkillsButton"
	respec.pressed.connect(skills_respec_requested.emit)
	panel.add_child(respec)
	_add_menu_label(panel, "Full Flux refund. Nodes may have multiple ranks; gates use stage clears and native mastery.", 11, Color(GamePalette.CYAN, 0.65), Vector2(222, 596))
	skill_tree_view = SkillTreeView.new()
	skill_tree_view.name = "SkillGraph"
	skill_tree_view.position = Vector2(28, 76)
	skill_tree_view.size = Vector2(904, 500)
	skill_tree_view.purchase_requested.connect(skill_purchase_requested.emit)
	panel.add_child(skill_tree_view)


func _hide_all_screens() -> void:
	if is_instance_valid(mobile_controls):
		mobile_controls.set_controls_active(false)
	hud.visible = false
	title_screen.visible = false
	save_slot_screen.visible = false
	options_screen.visible = false
	hangar_screen.visible = false
	stage_select_screen.visible = false
	loadout_screen.visible = false
	skill_tree_screen.visible = false
	credits_screen.stop()
	credits_screen.visible = false
	overlay.visible = false


func _rebuild_save_slots() -> void:
	for child: Node in save_slot_box.get_children():
		child.queue_free()
	for summary: Dictionary in cached_slot_summaries:
		var slot := int(summary["slot"])
		var exists := bool(summary["exists"])
		var status := "EMPTY SLOT"
		if exists:
			status = "BEST %s   //   LEVEL %02d   //   RUNS %02d   //   ◆ %d" % [
				_format_time(float(summary["best_time"])),
				int(summary["best_level"]),
				int(summary["runs"]),
				int(summary["flux"]),
			]
		var label := "SLOT %02d\n%s" % [slot, status]
		if creating_new_slot and exists:
			label = "SLOT %02d // OVERWRITE\n%s" % [slot, status]
		var button := UIFactory.button(label, Vector2.ZERO, Vector2(700, 112))
		button.name = "SaveSlot%dButton" % slot
		button.custom_minimum_size = Vector2(700, 112)
		button.disabled = not creating_new_slot and not exists
		button.pressed.connect(_request_slot.bind(slot, exists))
		save_slot_box.add_child(button)


func _request_slot(slot: int, exists: bool) -> void:
	if creating_new_slot and exists:
		_show_message(
			"OVERWRITE SLOT %02d?" % slot,
			"All progress in this slot will be permanently replaced.",
			"CANCEL",
			_restore_save_slots,
			"OVERWRITE",
			slot_selected.emit.bind(slot, true)
		)
		return
	slot_selected.emit(slot, creating_new_slot)


func _restore_save_slots() -> void:
	show_save_slots(creating_new_slot, cached_slot_summaries)


func _add_menu_label(parent: Control, text: String, size: int, color: Color, position: Vector2) -> Label:
	var node := UIFactory.label(text, size, color)
	node.position = position
	parent.add_child(node)
	return node


func _rebuild_loadout(profile: SaveProfile) -> void:
	for child: Node in loadout_box.get_children():
		child.queue_free()
	for weapon: String in WeaponCatalog.ORDER:
		var row := HBoxContainer.new()
		row.name = "LoadoutRow_" + weapon
		row.custom_minimum_size = Vector2(872, 62)
		var unlocked := profile.is_discovered(weapon)
		var equipped := profile.equipped_weapons().has(weapon)
		var description := UIFactory.label("%s\nMASTERY %02d  //  DAMAGE +%.1f%%" % [WeaponCatalog.display_name(weapon), profile.mastery_level(weapon), profile.mastery_bonus(weapon) * 100.0], 14, Color.WHITE if unlocked else Color(GamePalette.MAGENTA, 0.65))
		description.custom_minimum_size = Vector2(650, 58)
		row.add_child(description)
		var select := UIFactory.button("LOCKED" if not unlocked else ("EQUIPPED" if equipped else "EQUIP"), Vector2.ZERO, Vector2(205, 50))
		select.name = "WeaponSelect_" + weapon
		select.custom_minimum_size = Vector2(205, 50)
		select.disabled = not unlocked or (equipped and profile.equipped_weapons().size() <= 1)
		select.pressed.connect(weapon_selected.emit.bind(weapon))
		row.add_child(select)
		loadout_box.add_child(row)
	var divider := HSeparator.new()
	loadout_box.add_child(divider)
	var ability_row := HBoxContainer.new()
	ability_row.name = "ActiveSkillLoadout"
	var caption := UIFactory.label("ACTIVE SKILL  //  SPACE", 14, GamePalette.CYAN)
	caption.custom_minimum_size = Vector2(420, 52)
	ability_row.add_child(caption)
	for ability: String in ["dash", "vector_parry"]:
		var unlocked: bool = profile.is_discovered(ability)
		var selected: bool = profile.equipped_ability() == ability
		var button := UIFactory.button(("PHASE DASH" if ability == "dash" else "VECTOR PARRY") + "  M%02d" % profile.mastery_level(ability), Vector2.ZERO, Vector2(215, 50))
		button.name = "AbilitySelect_" + ability
		button.custom_minimum_size = Vector2(215, 50)
		button.disabled = not unlocked or selected
		button.text = "LOCKED // STAGE 5" if not unlocked else button.text + (" ✓" if selected else "")
		button.pressed.connect(ability_selected.emit.bind(ability))
		ability_row.add_child(button)
	loadout_box.add_child(ability_row)


func _show_message(title_text: String, body_text: String, primary_text: String, primary_action: Callable, secondary_text: String, secondary_action: Callable) -> void:
	mobile_controls.set_controls_active(false)
	_clear_overlay()
	overlay.visible = true
	var shade := ColorRect.new(); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); shade.color = Color(0.0, 0.01, 0.04, 0.82); overlay.add_child(shade)
	var message_panel := UIFactory.panel(Vector2(340, 176), Vector2(600, 370), Color(GamePalette.MAGENTA, 0.4)); overlay.add_child(message_panel)
	var title := UIFactory.label(title_text, 32, GamePalette.CYAN); title.position = Vector2(32, 35); title.size = Vector2(536, 45); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; message_panel.add_child(title)
	var body := UIFactory.label(body_text, 16, Color.WHITE); body.position = Vector2(35, 102); body.size = Vector2(530, 110); body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; message_panel.add_child(body)
	var primary := UIFactory.button(primary_text, Vector2(55, 250), Vector2(225, 55)); primary.pressed.connect(primary_action); message_panel.add_child(primary)
	var secondary := UIFactory.button(secondary_text, Vector2(320, 250), Vector2(225, 55)); secondary.pressed.connect(secondary_action); message_panel.add_child(secondary)


func _clear_overlay() -> void:
	for child: Node in overlay.get_children():
		child.queue_free()


func _format_time(value: float) -> String:
	return "%02d:%02d" % [int(value) / 60, int(value) % 60]
