class_name GameUI
extends CanvasLayer

const OperationCatalog := preload("res://scripts/content/operation_catalog.gd")
const CreditsViewScript := preload("res://scripts/ui/credits_view.gd")
const MobileControlsScript := preload("res://scripts/ui/mobile_controls.gd")
const RunHudScript := preload("res://scripts/ui/run_hud.gd")
const OverlayViewScript := preload("res://scripts/ui/overlay_view.gd")

signal deploy_requested
signal new_game_requested
signal load_game_requested
signal options_requested
signal title_requested
signal slot_selected(slot: int, create_new: bool)
signal resume_requested
signal retry_requested
signal menu_requested
signal reset_requested
signal library_requested
signal loadout_requested
signal skills_requested
signal credits_finished
signal weapon_selected(id: String)
signal ability_selected(id: String)
signal skill_purchase_requested(id: String)
signal skills_respec_requested
signal operation_evolution_requested(id: String)
signal master_volume_changed(value: float)
signal mobile_input_changed(movement: Vector2)
signal mobile_ability_requested
signal mobile_pause_requested
signal continue_operation_requested
signal retreat_operation_requested

var hud
var title_screen: Control
var save_slot_screen: Control
var options_screen: Control
var hangar_screen: Control
var start_screen: Control
var loadout_screen: Control
var skill_tree_screen: Control
var credits_screen
var overlay
var start_flux_label: Label
var start_stats_label: Label
var start_mastery_label: Label
var hangar_slot_label: Label
var loadout_box: VBoxContainer
var loadout_slots_label: Label
var skill_flux_label: Label
var skill_tree_view: SkillTreeView
var save_slot_box: VBoxContainer
var save_slot_title: Label
var master_volume_slider: HSlider
var master_volume_value_label: Label
var cached_slot_summaries: Array[Dictionary] = []
var creating_new_slot := false
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
	_build_loadout_screen()
	_build_skill_tree_screen()
	overlay = OverlayViewScript.new()
	overlay.name = "OverlayView"
	overlay.operation_evolution_requested.connect(operation_evolution_requested.emit)
	overlay.menu_requested.connect(menu_requested.emit)
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
	save_slot_title.text = "NEW GAME" if create_new else "LOAD GAME"
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
	hangar_slot_label.text = "SAVE SLOT %02d" % profile.active_slot if profile.active_slot > 0 else "TEMPORARY PROFILE"
	start_flux_label.text = "◆  %d" % int(profile.data["flux"])
	start_stats_label.text = "BEST TIME  %s\nBEST LEVEL  %02d\nRUNS  %02d" % [_format_time(float(profile.data["best_time"])), int(profile.data["best_level"]), int(profile.data["runs"])]
	var equipped := profile.equipped_weapons()
	var weapon_names: Array[String] = []
	for weapon: String in equipped:
		weapon_names.append(WeaponCatalog.display_name(weapon))
	var ability_name := "VECTOR PARRY" if profile.equipped_ability() == "vector_parry" else "PHASE DASH"
	start_mastery_label.text = "%s\n\n%s\nMASTERY %02d" % ["\n".join(weapon_names), ability_name, profile.mastery_level(profile.equipped_ability())]


func show_credits() -> void:
	_hide_all_screens()
	credits_screen.visible = true
	credits_screen.start()


func show_loadout(profile: SaveProfile) -> void:
	_hide_all_screens()
	loadout_screen.visible = true
	loadout_slots_label.text = "WEAPON SLOTS  %d OF %d" % [profile.equipped_weapons().size(), profile.unlocked_weapon_slots()]
	_rebuild_loadout(profile)


func show_skill_tree(profile: SaveProfile) -> void:
	_hide_all_screens()
	skill_tree_screen.visible = true
	skill_flux_label.text = "FLUX  ◆ %d" % int(profile.data["flux"])
	skill_tree_view.rebuild(profile)


func show_run() -> void:
	_hide_all_screens()
	hud.visible = true
	hud.set_controls_active(mobile_controls_available)


func show_operation_evolution(session: RunSession, choices: Array[String]) -> void:
	hud.visible = true
	hud.set_controls_active(false)
	overlay.show_operation_evolution(session, choices)


func show_library(profile: SaveProfile) -> void:
	_hide_all_screens()
	overlay.show_library(profile)


func update_hud(session: RunSession, weapons: Dictionary, context_label: String = "", target_mode: String = "NEAREST") -> void:
	hud.update(session, weapons, context_label, target_mode)


func set_health(current: float, maximum: float) -> void:
	hud.set_health(current, maximum)


func set_dash(ratio: float) -> void:
	hud.set_dash(ratio)


func set_ability(id: String) -> void:
	hud.set_ability(id)


func show_operation_intermission(operation_id: String, session: RunSession, mission: Dictionary, mission_count: int) -> void:
	var body := "%s complete  •  Mission %d of %d\n%d hostiles destroyed  •  %d Flux at risk\n\nHull fully repaired. Upgrades preserved.\nContinue or retreat with %d%% of earned Flux." % [
		String(mission["name"]),
		session.completed_missions,
		mission_count,
		session.kills,
		session.flux,
		OperationCatalog.retreat_flux_percent(operation_id),
	]
	_show_message("%s — INTERMISSION" % OperationCatalog.display_name(operation_id), body, "CONTINUE", continue_operation_requested.emit, "RETREAT", retreat_operation_requested.emit)


func show_operation_end(operation_id: String, session: RunSession, banked_flux: int, completed: bool, defeated: bool) -> void:
	var title := "%s COMPLETE" % OperationCatalog.display_name(operation_id)
	if not completed:
		title = "SIGNAL LOST" if defeated else "OPERATION RETREATED"
	var recovery_percent := OperationCatalog.defeat_flux_percent(operation_id) if defeated else OperationCatalog.retreat_flux_percent(operation_id)
	var reward_note := "Full operation rewards secured." if completed else "Partial recovery secured  •  %d%% of earned Flux." % recovery_percent
	var body := "Completed %d of %d missions in %s\n%d hostiles destroyed  •  %d Flux banked\n\n%s\nMastery progress saved." % [
		session.completed_missions,
		OperationCatalog.missions(operation_id).size(),
		_format_time(session.elapsed),
		session.kills,
		banked_flux,
		reward_note,
	]
	_show_message(title, body, "PLAY AGAIN", retry_requested.emit, "BACK TO HANGAR", menu_requested.emit)


func show_operation_pause() -> void:
	hud.set_controls_active(false)
	_show_message("PAUSED", "Operation state is holding.", "RESUME", resume_requested.emit, "RETREAT", retreat_operation_requested.emit)


func show_reset_confirmation() -> void:
	_show_message("RESET PROFILE?", "This erases all Flux, mastery, records, and skill-tree progress.\nThis action cannot be undone.", "CANCEL", menu_requested.emit, "ERASE EVERYTHING", reset_requested.emit)


func show_banner(text: String, color: Color) -> void:
	hud.show_banner(text, color)


func _build_hud() -> void:
	hud = RunHudScript.new()
	hud.name = "RunHud"
	hud.mobile_input_changed.connect(mobile_input_changed.emit)
	hud.mobile_ability_requested.connect(mobile_ability_requested.emit)
	hud.mobile_pause_requested.connect(mobile_pause_requested.emit)
	add_child(hud)


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
		var fullscreen_hint := _add_menu_label(panel, "TAP TO ENTER FULLSCREEN", 11, Color(GamePalette.GREEN, 0.7), Vector2(0, 466))
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
	_add_control_row(controls, "MOVE", "WASD OR ARROW KEYS", 27)
	_add_control_row(controls, "TARGET", "AUTOMATIC", 82)
	_add_control_row(controls, "ABILITY", "SPACE", 137)
	_add_control_row(controls, "PAUSE", "ESC OR P", 192)


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
	hangar_slot_label = _add_menu_label(panel, "SAVE SLOT 01", 11, Color(GamePalette.GREEN, 0.72), Vector2(58, 96))
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
	var title_button := UIFactory.button("RETURN TO TITLE", Vector2(58, 436), Vector2(310, 42))
	title_button.name = "ReturnToTitleButton"
	title_button.pressed.connect(title_requested.emit)
	panel.add_child(title_button)

	var status_panel := UIFactory.panel(Vector2(470, 54), Vector2(430, 350), Color(GamePalette.GREEN, 0.22))
	panel.add_child(status_panel)
	_add_menu_label(status_panel, "FLUX", 11, Color(GamePalette.YELLOW, 0.64), Vector2(30, 28))
	start_flux_label = _add_menu_label(status_panel, "◆  0", 28, GamePalette.YELLOW, Vector2(27, 48))
	_add_menu_label(status_panel, "RECORD", 11, Color(GamePalette.CYAN, 0.58), Vector2(30, 112))
	start_stats_label = _add_menu_label(status_panel, "BEST TIME  00:00\nBEST LEVEL  01\nRUNS  00", 16, Color.WHITE, Vector2(29, 136))
	start_stats_label.add_theme_constant_override("line_spacing", 7)
	_add_menu_label(status_panel, "LOADOUT", 11, Color(GamePalette.GREEN, 0.58), Vector2(224, 112))
	start_mastery_label = _add_menu_label(status_panel, "PULSE CANNON\nPHASE DASH\nMASTERY 00", 13, Color(GamePalette.GREEN, 0.86), Vector2(223, 136))
	start_mastery_label.add_theme_constant_override("line_spacing", 10)
func _build_credits_screen() -> void:
	credits_screen = CreditsViewScript.new()
	credits_screen.name = "CreditsScreen"
	credits_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	credits_screen.finished.connect(credits_finished.emit)
	credits_screen.exit_requested.connect(credits_finished.emit)
	add_child(credits_screen)


func _build_loadout_screen() -> void:
	loadout_screen = Control.new()
	loadout_screen.name = "LoadoutScreen"
	loadout_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(loadout_screen)
	var panel := UIFactory.panel(Vector2(160, 55), Vector2(960, 610), Color(GamePalette.CYAN, 0.3))
	loadout_screen.add_child(panel)
	_add_menu_label(panel, "LOADOUT", 30, GamePalette.CYAN, Vector2(44, 30))
	loadout_slots_label = _add_menu_label(panel, "WEAPON SLOTS  1 OF 1", 16, GamePalette.YELLOW, Vector2(490, 43))
	loadout_slots_label.size = Vector2(245, 28)
	loadout_slots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var back := UIFactory.button("BACK TO HANGAR", Vector2(756, 26), Vector2(160, 50))
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
	skill_flux_label = _add_menu_label(panel, "FLUX  ◆ 0", 18, GamePalette.YELLOW, Vector2(500, 31))
	var back := UIFactory.button("BACK TO HANGAR", Vector2(772, 16), Vector2(150, 46))
	back.pressed.connect(menu_requested.emit)
	panel.add_child(back)
	var respec := UIFactory.button("RESPEC ALL", Vector2(34, 586), Vector2(170, 42))
	respec.name = "RespecSkillsButton"
	respec.pressed.connect(skills_respec_requested.emit)
	panel.add_child(respec)
	_add_menu_label(panel, "Respec refunds all Flux spent here.", 11, Color(GamePalette.CYAN, 0.65), Vector2(222, 596))
	skill_tree_view = SkillTreeView.new()
	skill_tree_view.name = "SkillGraph"
	skill_tree_view.position = Vector2(28, 76)
	skill_tree_view.size = Vector2(904, 500)
	skill_tree_view.purchase_requested.connect(skill_purchase_requested.emit)
	panel.add_child(skill_tree_view)


func _hide_all_screens() -> void:
	if is_instance_valid(hud):
		hud.set_controls_active(false)
	hud.visible = false
	title_screen.visible = false
	save_slot_screen.visible = false
	options_screen.visible = false
	hangar_screen.visible = false
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
			status = "BEST TIME %s  •  LEVEL %02d\nRUNS %02d  •  FLUX ◆ %d" % [
				_format_time(float(summary["best_time"])),
				int(summary["best_level"]),
				int(summary["runs"]),
				int(summary["flux"]),
			]
		var label := "SLOT %02d\n%s" % [slot, status]
		if creating_new_slot and exists:
			label = "SLOT %02d — OVERWRITE?\n%s" % [slot, status]
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
		var description_text := "%s\nMASTERY %02d  •  DAMAGE +%.1f%%" % [WeaponCatalog.display_name(weapon), profile.mastery_level(weapon), profile.mastery_bonus(weapon) * 100.0]
		if not unlocked:
			description_text = "%s\nNOT YET UNLOCKED" % WeaponCatalog.display_name(weapon)
		var description := UIFactory.label(description_text, 14, Color.WHITE if unlocked else Color(GamePalette.MAGENTA, 0.65))
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
	var caption := UIFactory.label("ACTIVE SKILL", 14, GamePalette.CYAN)
	caption.custom_minimum_size = Vector2(420, 52)
	ability_row.add_child(caption)
	for ability: String in ["dash", "vector_parry"]:
		var unlocked: bool = profile.is_discovered(ability)
		var selected: bool = profile.equipped_ability() == ability
		var button := UIFactory.button(("PHASE DASH" if ability == "dash" else "VECTOR PARRY") + "\nMASTERY %02d" % profile.mastery_level(ability), Vector2.ZERO, Vector2(215, 50))
		button.name = "AbilitySelect_" + ability
		button.custom_minimum_size = Vector2(215, 50)
		button.disabled = not unlocked or selected
		button.add_theme_font_size_override("font_size", 13)
		button.text = "VECTOR PARRY\nUNLOCKS AFTER STAGE 5" if not unlocked else button.text + (" ✓" if selected else "")
		button.pressed.connect(ability_selected.emit.bind(ability))
		ability_row.add_child(button)
	loadout_box.add_child(ability_row)


func _show_message(title_text: String, body_text: String, primary_text: String, primary_action: Callable, secondary_text: String, secondary_action: Callable) -> void:
	hud.set_controls_active(false)
	overlay.show_message(title_text, body_text, primary_text, primary_action, secondary_text, secondary_action)


func _format_time(value: float) -> String:
	return "%02d:%02d" % [int(value) / 60, int(value) % 60]
