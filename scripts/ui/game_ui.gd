class_name GameUI
extends CanvasLayer

const MetaUpgradeData := preload("res://scripts/content/meta_upgrade_catalog.gd")

signal deploy_requested
signal resume_requested
signal abandon_requested
signal retry_requested
signal menu_requested
signal reset_requested
signal meta_upgrade_requested(id: String)
signal library_requested
signal upgrades_requested

var hud: Control
var start_screen: Control
var upgrade_screen: Control
var overlay: Control
var hp_bar: ProgressBar
var resonance_bar: ProgressBar
var dash_bar: ProgressBar
var time_label: Label
var stats_label: Label
var combo_label: Label
var weapon_label: Label
var evolution_label: Label
var behavior_profile_label: Label
var behavior_bars: Array[ProgressBar] = []
var banner_label: Label
var start_flux_label: Label
var start_stats_label: Label
var start_mastery_label: Label
var upgrade_flux_label: Label
var hangar_box: VBoxContainer
var banner_tween: Tween


func _ready() -> void:
	layer = 10
	_build_hud()
	_build_start_screen()
	_build_upgrade_screen()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)


func show_menu(profile: SaveProfile) -> void:
	hud.visible = false
	overlay.visible = false
	start_screen.visible = true
	upgrade_screen.visible = false
	start_flux_label.text = "◆  %d" % int(profile.data["flux"])
	start_stats_label.text = "BEST  %s\nLEVEL  %02d\nRUNS  %02d" % [_format_time(float(profile.data["best_time"])), int(profile.data["best_level"]), int(profile.data["runs"])]
	start_mastery_label.text = "PULSE %02d   ORBIT %02d\nARC %02d       NOVA %02d" % [profile.mastery_level("pulse"), profile.mastery_level("orbit"), profile.mastery_level("arc"), profile.mastery_level("nova")]


func show_upgrades(profile: SaveProfile) -> void:
	hud.visible = false
	overlay.visible = false
	start_screen.visible = false
	upgrade_screen.visible = true
	upgrade_flux_label.text = "◆  %d FLUX" % int(profile.data["flux"])
	_rebuild_hangar(profile)


func show_run() -> void:
	start_screen.visible = false
	upgrade_screen.visible = false
	overlay.visible = false
	hud.visible = true


func show_library(profile: SaveProfile) -> void:
	_clear_overlay()
	hud.visible = false
	start_screen.visible = false
	upgrade_screen.visible = false
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
	for i in LibraryCatalog.ORDER.size():
		var id: String = LibraryCatalog.ORDER[i]
		var column := i % 2
		var row := int(i / 2)
		_build_library_entry(panel, id, profile, Vector2(28 + column * 508, 88 + row * 158))


func _build_library_entry(parent: Control, id: String, profile: SaveProfile, position: Vector2) -> void:
	var definition := LibraryCatalog.definition(id)
	var discovered := profile.is_discovered(id)
	var border := Color(GamePalette.GREEN, 0.38) if discovered else Color(GamePalette.MAGENTA, 0.24)
	var card := UIFactory.panel(position, Vector2(490, 145), border)
	card.name = "LibraryEntry_" + id
	parent.add_child(card)
	var title_text := String(definition["name"]) if discovered else "UNDECODED %s" % definition["kind"]
	var title_color := GamePalette.GREEN if discovered else Color(GamePalette.MAGENTA, 0.72)
	var title := UIFactory.label(title_text, 17, title_color)
	title.position = Vector2(17, 11)
	card.add_child(title)
	var status := "DISCOVERED" if discovered else "LOCKED"
	if discovered and WeaponCatalog.ORDER.has(id):
		status += "  //  MASTERY %02d" % profile.mastery_level(id)
	var badge := UIFactory.label(status, 10, Color(title_color, 0.72))
	badge.position = Vector2(315, 15)
	badge.size = Vector2(155, 18)
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


func update_hud(session: RunSession, weapons: Dictionary) -> void:
	time_label.text = _format_time(session.elapsed)
	stats_label.text = "LEVEL %02d    ◆ %d    KILLS %d" % [session.level, session.flux, session.kills]
	combo_label.text = "CHAIN x%.1f" % session.combo
	combo_label.modulate = GamePalette.YELLOW if session.combo > 1.5 else Color(GamePalette.YELLOW, 0.55)
	resonance_bar.max_value = session.resonance_needed
	resonance_bar.value = session.resonance
	var names: Array[String] = ["PULSE %d" % int(weapons["pulse"]["level"])]
	for id in ["orbit", "arc", "nova"]:
		if int(weapons[id]["level"]) > 0:
			names.append("%s %d" % [String(id).to_upper(), int(weapons[id]["level"])])
	weapon_label.text = "  //  ".join(names)
	behavior_profile_label.text = "LIVE PROFILE  " + session.behavior.display_profile()
	var behavior_values := session.behavior.values()
	for i in behavior_bars.size():
		behavior_bars[i].value = (behavior_values[i] + 1.0) * 50.0
	if session.last_evolution.is_empty():
		evolution_label.text = "EVOLUTION  LISTENING TO COMBAT..."
	else:
		var mutation := EvolutionCatalog.definition(session.last_evolution)
		evolution_label.text = "EVOLUTION  %s  //  RANK %d" % [mutation["name"], int(session.evolutions[session.last_evolution])]


func set_health(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current


func set_dash(ratio: float) -> void:
	dash_bar.value = clampf(ratio, 0.0, 1.0) * 100.0


func show_evolution(mutation: Dictionary, profile_name: String) -> void:
	show_banner("%s  RANK %d  //  %s" % [mutation["name"], int(mutation["rank"]), profile_name], GamePalette.GREEN)


func show_pause() -> void:
	_show_message("PAUSED", "The swarm is suspended.", "RESUME", resume_requested.emit, "ABANDON RUN", abandon_requested.emit)


func show_run_end(defeated: bool, session: RunSession) -> void:
	var title := "SIGNAL LOST" if defeated else "RUN ABANDONED"
	var body := "%s survived  •  Level %d\n%d hostiles erased  •  %d Flux banked\n\nWeapon mastery recorded permanently." % [_format_time(session.elapsed), session.level, session.kills, session.flux]
	_show_message(title, body, "RUN AGAIN", retry_requested.emit, "RETURN TO HANGAR", menu_requested.emit)


func show_reset_confirmation() -> void:
	_show_message("RESET PROFILE?", "This erases all Flux, mastery, records, and upgrades.\nThis action cannot be undone.", "CANCEL", upgrades_requested.emit, "ERASE EVERYTHING", reset_requested.emit)


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
	_add_hud_caption("PHASE DASH", Vector2(895, 658), GamePalette.CYAN)
	weapon_label = UIFactory.label("PULSE I", 12, Color(GamePalette.CYAN, 0.8)); weapon_label.position = Vector2(55, 82); hud.add_child(weapon_label)
	evolution_label = UIFactory.label("EVOLUTION  LISTENING TO COMBAT...", 12, Color(GamePalette.GREEN, 0.78)); evolution_label.position = Vector2(55, 104); hud.add_child(evolution_label)
	_build_behavior_readout()
	banner_label = UIFactory.label("", 21, GamePalette.CYAN); banner_label.position = Vector2(0, 215); banner_label.size = Vector2(1280, 34); banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; hud.add_child(banner_label)


func _build_behavior_readout() -> void:
	var panel := UIFactory.panel(Vector2(827, 78), Vector2(399, 126), Color(GamePalette.GREEN, 0.28))
	hud.add_child(panel)
	behavior_profile_label = UIFactory.label("LIVE PROFILE  BALANCED", 11, Color(GamePalette.GREEN, 0.9))
	behavior_profile_label.position = Vector2(12, 8)
	panel.add_child(behavior_profile_label)
	var axes := [
		["ANCHORED", "ROAMING", GamePalette.CYAN],
		["CLOSE", "DISTANT", GamePalette.YELLOW],
		["FOCUS", "SPREAD", GamePalette.GREEN],
	]
	for i in axes.size():
		var y := 35.0 + i * 28.0
		var left := UIFactory.label(axes[i][0], 9, Color(axes[i][2], 0.7)); left.position = Vector2(12, y - 3.0); left.size = Vector2(67, 18); panel.add_child(left)
		var bar := UIFactory.progress_bar(Vector2(80, y), Vector2(235, 10), axes[i][2]); bar.value = 50.0; panel.add_child(bar); behavior_bars.append(bar)
		var midpoint := ColorRect.new(); midpoint.position = Vector2(197, y - 2.0); midpoint.size = Vector2(1, 14); midpoint.color = Color.WHITE; midpoint.modulate.a = 0.45; panel.add_child(midpoint)
		var right := UIFactory.label(axes[i][1], 9, Color(axes[i][2], 0.7)); right.position = Vector2(322, y - 3.0); right.size = Vector2(70, 18); panel.add_child(right)


func _add_hud_caption(text: String, position: Vector2, color: Color) -> void:
	var caption := UIFactory.label(text, 11, color)
	caption.position = position
	hud.add_child(caption)


func _build_start_screen() -> void:
	start_screen = Control.new()
	start_screen.name = "StartScreen"
	start_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(start_screen)
	var panel := UIFactory.panel(Vector2(160, 80), Vector2(960, 560), Color(GamePalette.CYAN, 0.25))
	start_screen.add_child(panel)
	_add_menu_label(panel, "// INCREMENTAL BULLET HELL", 13, Color(GamePalette.CYAN, 0.66), Vector2(58, 48))
	_add_menu_label(panel, "NEON REQUIEM", 52, GamePalette.CYAN, Vector2(53, 73))
	_add_menu_label(panel, "HOW YOU FIGHT BECOMES WHAT YOU ARE.", 15, Color.WHITE, Vector2(58, 143))
	var deploy := UIFactory.button("DEPLOY", Vector2(58, 216), Vector2(310, 64))
	deploy.name = "DeployButton"
	deploy.pressed.connect(deploy_requested.emit)
	panel.add_child(deploy)
	var upgrades := UIFactory.button("UPGRADES", Vector2(58, 296), Vector2(196, 54))
	upgrades.name = "UpgradesButton"
	upgrades.pressed.connect(upgrades_requested.emit)
	panel.add_child(upgrades)
	var library := UIFactory.button("LIBRARY", Vector2(270, 296), Vector2(98, 54))
	library.name = "LibraryButton"
	library.pressed.connect(library_requested.emit)
	panel.add_child(library)

	var status_panel := UIFactory.panel(Vector2(470, 54), Vector2(430, 350), Color(GamePalette.GREEN, 0.22))
	panel.add_child(status_panel)
	_add_menu_label(status_panel, "FLUX", 11, Color(GamePalette.YELLOW, 0.64), Vector2(30, 28))
	start_flux_label = _add_menu_label(status_panel, "◆  0", 28, GamePalette.YELLOW, Vector2(27, 48))
	_add_menu_label(status_panel, "RECORD", 11, Color(GamePalette.CYAN, 0.58), Vector2(30, 112))
	start_stats_label = _add_menu_label(status_panel, "BEST  00:00\nLEVEL  01\nRUNS  00", 16, Color.WHITE, Vector2(29, 136))
	start_stats_label.add_theme_constant_override("line_spacing", 7)
	_add_menu_label(status_panel, "MASTERY", 11, Color(GamePalette.GREEN, 0.58), Vector2(224, 112))
	start_mastery_label = _add_menu_label(status_panel, "PULSE 00   ORBIT 00\nARC 00       NOVA 00", 14, Color(GamePalette.GREEN, 0.86), Vector2(223, 136))
	start_mastery_label.add_theme_constant_override("line_spacing", 10)
	_add_menu_label(panel, "MOVE  WASD / ARROWS     AIM  MOUSE     DASH  SPACE     PAUSE  ESC / P", 12, Color(GamePalette.CYAN, 0.62), Vector2(58, 489))


func _build_upgrade_screen() -> void:
	upgrade_screen = Control.new()
	upgrade_screen.name = "UpgradeScreen"
	upgrade_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(upgrade_screen)
	var panel := UIFactory.panel(Vector2(160, 55), Vector2(960, 610), Color(GamePalette.GREEN, 0.3))
	upgrade_screen.add_child(panel)
	_add_menu_label(panel, "PERMANENT AUGMENTS", 30, GamePalette.CYAN, Vector2(44, 30))
	_add_menu_label(panel, "HANGAR", 11, Color(GamePalette.CYAN, 0.55), Vector2(47, 72))
	upgrade_flux_label = _add_menu_label(panel, "◆  0 FLUX", 20, GamePalette.YELLOW, Vector2(432, 39))
	var back := UIFactory.button("RETURN", Vector2(756, 26), Vector2(160, 50))
	back.name = "UpgradeReturnButton"
	back.pressed.connect(menu_requested.emit)
	panel.add_child(back)
	var divider := ColorRect.new()
	divider.position = Vector2(44, 94)
	divider.size = Vector2(872, 2)
	divider.color = Color(GamePalette.GREEN, 0.16)
	panel.add_child(divider)
	hangar_box = VBoxContainer.new()
	hangar_box.position = Vector2(44, 116)
	hangar_box.size = Vector2(872, 455)
	hangar_box.add_theme_constant_override("separation", 8)
	panel.add_child(hangar_box)


func _add_menu_label(parent: Control, text: String, size: int, color: Color, position: Vector2) -> Label:
	var node := UIFactory.label(text, size, color)
	node.position = position
	parent.add_child(node)
	return node


func _rebuild_hangar(profile: SaveProfile) -> void:
	for child: Node in hangar_box.get_children():
		child.queue_free()
	for definition: Dictionary in MetaUpgradeData.DEFINITIONS:
		var id := String(definition["id"])
		var level := profile.upgrade_level(id)
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(872, 62)
		var description := UIFactory.label("%s  %02d/%02d\n%s" % [definition["name"], level, SaveProfile.UPGRADE_MAX, definition["description"]], 14, Color.WHITE)
		description.custom_minimum_size = Vector2(680, 58)
		row.add_child(description)
		var buy := UIFactory.button("MAX" if level >= SaveProfile.UPGRADE_MAX else "◆ %d" % profile.upgrade_cost(id), Vector2.ZERO, Vector2(176, 48))
		buy.custom_minimum_size = Vector2(176, 48)
		buy.disabled = level >= SaveProfile.UPGRADE_MAX or int(profile.data["flux"]) < profile.upgrade_cost(id)
		buy.pressed.connect(meta_upgrade_requested.emit.bind(id))
		row.add_child(buy)
		hangar_box.add_child(row)
	var reset_button := Button.new()
	reset_button.text = "RESET SAVE DATA"
	reset_button.flat = true
	reset_button.add_theme_color_override("font_color", Color(GamePalette.MAGENTA, 0.65))
	reset_button.pressed.connect(show_reset_confirmation)
	hangar_box.add_child(reset_button)


func _show_message(title_text: String, body_text: String, primary_text: String, primary_action: Callable, secondary_text: String, secondary_action: Callable) -> void:
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
