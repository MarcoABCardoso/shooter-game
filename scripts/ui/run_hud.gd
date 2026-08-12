class_name RunHud
extends Control

const MobileControlsScript := preload("res://scripts/ui/mobile_controls.gd")
const OperationEvolutionCatalog := preload("res://scripts/content/operation_evolution_catalog.gd")

signal mobile_input_changed(movement: Vector2)
signal mobile_ability_requested
signal mobile_pause_requested

var hp_bar: ProgressBar
var resonance_bar: ProgressBar
var dash_bar: ProgressBar
var ability_caption: Label
var time_label: Label
var stats_label: Label
var combo_label: Label
var weapon_label: Label
var evolution_label: Label
var target_mode_label: Label
var banner_label: Label
var mobile_controls
var banner_tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


func set_controls_active(value: bool) -> void:
	mobile_controls.set_controls_active(value)


func update(session: RunSession, weapons: Dictionary, context_label: String, target_mode: String = "NEAREST") -> void:
	time_label.text = _format_time(session.elapsed)
	stats_label.text = "LEVEL %02d     FLUX ◆ %d     KILLS %d" % [session.level, session.flux, session.kills]
	combo_label.text = "COMBO ×%.1f" % session.combo
	combo_label.modulate = GamePalette.YELLOW if session.combo > 1.5 else Color(GamePalette.YELLOW, 0.55)
	resonance_bar.max_value = session.resonance_needed
	resonance_bar.value = session.resonance
	var names: Array[String] = []
	for id: String in WeaponCatalog.ORDER:
		if int(weapons[id]["level"]) > 0:
			names.append(id.to_upper())
	weapon_label.text = "  •  ".join(names)
	target_mode_label.text = "Q  TARGET: %s" % target_mode
	target_mode_label.modulate = GamePalette.YELLOW if target_mode == "RANGED THREATS" else GamePalette.CYAN
	var build := OperationEvolutionCatalog.build_name(session.operation_evolutions)
	var build_name := "  •  " + build if not build.is_empty() else ""
	evolution_label.text = context_label + build_name


func set_health(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current


func set_dash(ratio: float) -> void:
	dash_bar.value = clampf(ratio, 0.0, 1.0) * 100.0


func set_ability(id: String) -> void:
	ability_caption.text = String(LibraryCatalog.definition(id).get("name", "PHASE DASH"))


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


func _build() -> void:
	var top := ColorRect.new()
	top.position = Vector2(54, 18)
	top.size = Vector2(1172, 48)
	top.color = Color(GamePalette.INK, 0.86)
	add_child(top)
	time_label = UIFactory.label("00:00", 22, GamePalette.CYAN)
	time_label.position = Vector2(18, 9)
	top.add_child(time_label)
	stats_label = UIFactory.label("LEVEL 01     FLUX ◆ 0     KILLS 0", 16, Color.WHITE)
	stats_label.position = Vector2(145, 13)
	top.add_child(stats_label)
	combo_label = UIFactory.label("COMBO ×1.0", 16, GamePalette.YELLOW)
	combo_label.position = Vector2(945, 13)
	top.add_child(combo_label)

	hp_bar = UIFactory.progress_bar(Vector2(55, 677), Vector2(330, 15), GamePalette.MAGENTA)
	add_child(hp_bar)
	resonance_bar = UIFactory.progress_bar(Vector2(430, 681), Vector2(420, 9), GamePalette.GREEN)
	add_child(resonance_bar)
	dash_bar = UIFactory.progress_bar(Vector2(895, 681), Vector2(330, 9), GamePalette.CYAN)
	add_child(dash_bar)
	_add_caption("HULL", Vector2(55, 658), GamePalette.MAGENTA)
	_add_caption("RESONANCE", Vector2(430, 658), GamePalette.GREEN)
	ability_caption = _add_caption("PHASE DASH", Vector2(895, 658), GamePalette.CYAN)
	weapon_label = UIFactory.label("PULSE CANNON", 12, Color(GamePalette.CYAN, 0.8))
	weapon_label.position = Vector2(55, 82)
	add_child(weapon_label)
	var target_panel := UIFactory.panel(Vector2(920, 78), Vector2(305, 44), Color(GamePalette.YELLOW, 0.34))
	target_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(target_panel)
	target_mode_label = UIFactory.label("Q  TARGET: NEAREST", 14, GamePalette.CYAN)
	target_mode_label.name = "TargetModeCue"
	target_mode_label.position = Vector2(14, 10)
	target_mode_label.size = Vector2(278, 24)
	target_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_panel.add_child(target_mode_label)
	evolution_label = UIFactory.label("READY FOR DEPLOYMENT", 12, Color(GamePalette.GREEN, 0.78))
	evolution_label.position = Vector2(55, 104)
	add_child(evolution_label)
	banner_label = UIFactory.label("", 21, GamePalette.CYAN)
	banner_label.position = Vector2(0, 170)
	banner_label.size = Vector2(1280, 34)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(banner_label)

	mobile_controls = MobileControlsScript.new()
	mobile_controls.name = "MobileControls"
	mobile_controls.input_changed.connect(mobile_input_changed.emit)
	mobile_controls.ability_requested.connect(mobile_ability_requested.emit)
	mobile_controls.pause_requested.connect(mobile_pause_requested.emit)
	add_child(mobile_controls)
	mobile_controls.set_controls_active(false)


func _add_caption(text: String, position: Vector2, color: Color) -> Label:
	var caption := UIFactory.label(text, 11, color)
	caption.position = position
	add_child(caption)
	return caption


func _format_time(value: float) -> String:
	return "%02d:%02d" % [int(value) / 60, int(value) % 60]
