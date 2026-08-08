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
signal upgrade_selected(id: String)

var hud: Control
var menu: Control
var overlay: Control
var hp_bar: ProgressBar
var xp_bar: ProgressBar
var dash_bar: ProgressBar
var time_label: Label
var stats_label: Label
var combo_label: Label
var weapon_label: Label
var banner_label: Label
var menu_flux_label: Label
var menu_stats_label: Label
var menu_mastery_label: Label
var hangar_box: VBoxContainer
var banner_tween: Tween


func _ready() -> void:
	layer = 10
	_build_hud()
	_build_menu()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)


func show_menu(profile: SaveProfile) -> void:
	hud.visible = false
	overlay.visible = false
	menu.visible = true
	menu_flux_label.text = "◆  %d FLUX BANKED" % int(profile.data["flux"])
	menu_stats_label.text = "BEST  %s     LEVEL %d     RUNS %d" % [_format_time(float(profile.data["best_time"])), int(profile.data["best_level"]), int(profile.data["runs"])]
	menu_mastery_label.text = "MASTERY   PULSE %02d   ORBIT %02d   ARC %02d   NOVA %02d" % [profile.mastery_level("pulse"), profile.mastery_level("orbit"), profile.mastery_level("arc"), profile.mastery_level("nova")]
	_rebuild_hangar(profile)


func show_run() -> void:
	menu.visible = false
	overlay.visible = false
	hud.visible = true


func update_hud(session: RunSession, weapons: Dictionary) -> void:
	time_label.text = _format_time(session.elapsed)
	stats_label.text = "LEVEL %02d    ◆ %d    KILLS %d" % [session.level, session.flux, session.kills]
	combo_label.text = "CHAIN x%.1f" % session.combo
	combo_label.modulate = GamePalette.YELLOW if session.combo > 1.5 else Color(GamePalette.YELLOW, 0.55)
	xp_bar.max_value = session.xp_needed
	xp_bar.value = session.xp
	var names: Array[String] = ["PULSE %d" % int(weapons["pulse"]["level"])]
	for id in ["orbit", "arc", "nova"]:
		if int(weapons[id]["level"]) > 0:
			names.append("%s %d" % [String(id).to_upper(), int(weapons[id]["level"])])
	weapon_label.text = "  //  ".join(names)


func set_health(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current


func set_dash(ratio: float) -> void:
	dash_bar.value = clampf(ratio, 0.0, 1.0) * 100.0


func show_upgrade_choices(level: int, choices: Array[Dictionary]) -> void:
	_clear_overlay()
	overlay.visible = true
	var choice_panel := UIFactory.panel(Vector2(230, 118), Vector2(820, 485), Color(GamePalette.CYAN, 0.22))
	overlay.add_child(choice_panel)
	var title := UIFactory.label("RESONANCE LEVEL %02d" % level, 29, GamePalette.CYAN)
	title.position = Vector2(28, 23)
	choice_panel.add_child(title)
	var subtitle := UIFactory.label("CHOOSE ONE EVOLUTION", 14, Color(GamePalette.CYAN, 0.65))
	subtitle.position = Vector2(30, 65)
	choice_panel.add_child(subtitle)
	for i in choices.size():
		var choice: Dictionary = choices[i]
		var choice_button := Button.new()
		choice_button.position = Vector2(28 + i * 255, 112)
		choice_button.size = Vector2(235, 315)
		choice_button.text = "%s\n\n%s\n\n%s" % [choice["icon"], choice["name"], choice["description"]]
		choice_button.add_theme_font_size_override("font_size", 17)
		choice_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		choice_button.add_theme_stylebox_override("normal", UIFactory.style(Color("08172d"), Color(GamePalette.CYAN, 0.32), 2, 8))
		choice_button.add_theme_stylebox_override("hover", UIFactory.style(Color("102b42"), GamePalette.CYAN, 2, 8))
		choice_button.pressed.connect(upgrade_selected.emit.bind(String(choice["id"])))
		choice_panel.add_child(choice_button)


func show_pause() -> void:
	_show_message("PAUSED", "The swarm is suspended.", "RESUME", resume_requested.emit, "ABANDON RUN", abandon_requested.emit)


func show_run_end(defeated: bool, session: RunSession) -> void:
	var title := "SIGNAL LOST" if defeated else "RUN ABANDONED"
	var body := "%s survived  •  Level %d\n%d hostiles erased  •  %d Flux banked\n\nWeapon mastery recorded permanently." % [_format_time(session.elapsed), session.level, session.kills, session.flux]
	_show_message(title, body, "RUN AGAIN", retry_requested.emit, "RETURN TO HANGAR", menu_requested.emit)


func show_reset_confirmation() -> void:
	_show_message("RESET PROFILE?", "This erases all Flux, mastery, records, and upgrades.\nThis action cannot be undone.", "CANCEL", menu_requested.emit, "ERASE EVERYTHING", reset_requested.emit)


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
	xp_bar = UIFactory.progress_bar(Vector2(430, 681), Vector2(420, 9), GamePalette.GREEN); hud.add_child(xp_bar)
	dash_bar = UIFactory.progress_bar(Vector2(895, 681), Vector2(330, 9), GamePalette.CYAN); hud.add_child(dash_bar)
	_add_hud_caption("HULL", Vector2(55, 658), GamePalette.MAGENTA)
	_add_hud_caption("RESONANCE", Vector2(430, 658), GamePalette.GREEN)
	_add_hud_caption("PHASE DASH", Vector2(895, 658), GamePalette.CYAN)
	weapon_label = UIFactory.label("PULSE I", 12, Color(GamePalette.CYAN, 0.8)); weapon_label.position = Vector2(55, 82); hud.add_child(weapon_label)
	banner_label = UIFactory.label("", 21, GamePalette.CYAN); banner_label.position = Vector2(0, 100); banner_label.size = Vector2(1280, 34); banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; hud.add_child(banner_label)


func _add_hud_caption(text: String, position: Vector2, color: Color) -> void:
	var caption := UIFactory.label(text, 11, color)
	caption.position = position
	hud.add_child(caption)


func _build_menu() -> void:
	menu = Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu)
	var menu_panel := UIFactory.panel(Vector2(118, 86), Vector2(1044, 570), Color(GamePalette.CYAN, 0.25)); menu.add_child(menu_panel)
	_add_menu_label(menu_panel, "// INCREMENTAL BULLET HELL PROTOCOL", 13, Color(GamePalette.CYAN, 0.66), Vector2(45, 31))
	_add_menu_label(menu_panel, "NEON REQUIEM", 52, GamePalette.CYAN, Vector2(40, 51))
	_add_menu_label(menu_panel, "EVOLVE THE ARSENAL. OUTLIVE THE SIGNAL.", 16, Color.WHITE, Vector2(45, 118))
	menu_flux_label = _add_menu_label(menu_panel, "◆ 0 FLUX BANKED", 20, GamePalette.YELLOW, Vector2(46, 169))
	menu_stats_label = _add_menu_label(menu_panel, "BEST 00:00", 13, Color(GamePalette.CYAN, 0.7), Vector2(46, 207))
	var deploy := UIFactory.button("DEPLOY", Vector2(45, 254), Vector2(300, 58)); deploy.pressed.connect(deploy_requested.emit); menu_panel.add_child(deploy)
	_add_menu_label(menu_panel, "WASD / ARROWS  MOVE\nMOUSE  AIM\nSPACE  PHASE DASH\nESC / P  PAUSE\n\nWeapons fire automatically.", 15, Color(0.78, 0.9, 1.0), Vector2(47, 340))
	menu_mastery_label = _add_menu_label(menu_panel, "MASTERY   PULSE 00   ORBIT 00   ARC 00   NOVA 00", 12, Color(GamePalette.GREEN, 0.72), Vector2(47, 505))
	var divider := ColorRect.new(); divider.position = Vector2(400, 30); divider.size = Vector2(2, 510); divider.color = Color(GamePalette.CYAN, 0.14); menu_panel.add_child(divider)
	_add_menu_label(menu_panel, "HANGAR // PERMANENT AUGMENTS", 19, GamePalette.CYAN, Vector2(440, 32))
	_add_menu_label(menu_panel, "Spend banked Flux. Every augment has 10 ranks.", 13, Color(GamePalette.CYAN, 0.58), Vector2(441, 66))
	hangar_box = VBoxContainer.new(); hangar_box.position = Vector2(440, 108); hangar_box.size = Vector2(560, 405); hangar_box.add_theme_constant_override("separation", 8); menu_panel.add_child(hangar_box)


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
		row.custom_minimum_size = Vector2(540, 62)
		var description := UIFactory.label("%s  %02d/%02d\n%s" % [definition["name"], level, SaveProfile.UPGRADE_MAX, definition["description"]], 14, Color.WHITE)
		description.custom_minimum_size = Vector2(350, 58)
		row.add_child(description)
		var buy := UIFactory.button("MAX" if level >= SaveProfile.UPGRADE_MAX else "◆ %d" % profile.upgrade_cost(id), Vector2.ZERO, Vector2(155, 48))
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
