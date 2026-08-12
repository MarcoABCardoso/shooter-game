class_name OperationCatalog
extends RefCounted

const ORDER: Array[String] = ["signal_hold", "drift_cache", "relay_breach", "overseer_lock"]
const SECTOR_ID := "sector_1"
const SECTOR_NAME := "NULL MERIDIAN"
const RETREAT_FLUX_RATIO := 0.75
const DEFEAT_FLUX_RATIO := 0.5

const DEFINITIONS := {
	"signal_hold": {
		"name": "SIGNAL HOLD",
		"description": "Hold a captured carrier long enough to pin its frequency.",
		"required": true,
		"prerequisites": [],
		"route_position": Vector2(0.14, 0.34),
		"first_clear_flux": 60,
		"first_clear_discoveries": [],
		"completion_copy": "The carrier exposes two paths deeper into the Null Meridian.",
		"mission": {
			"id": "contact_line",
			"name": "SIGNAL HOLD",
			"rhythm": "SIGNAL DEFENSE",
			"lifecycle": "objective_sequence",
			"encounter_id": "defense_swarm",
			"music": &"combat",
			"time_limit": 180.0,
			"objectives": [
				{
					"name": "CAPTURE THE CARRIER",
					"lifecycle": "signal_defense",
					"arena_rect": Rect2(54.0, 76.0, 1172.0, 590.0),
					"objective_position": Vector2(640.0, 360.0),
					"objective_radius": 118.0,
					"hold_duration": 18.0,
					"decay_rate": 0.18,
				},
				{
					"name": "TRACE THE SIGNAL",
					"approach_name": "FOLLOW THE SIGNAL",
					"lifecycle": "signal_defense",
					"arena_rect": Rect2(1974.0, 76.0, 1172.0, 590.0),
					"objective_position": Vector2(2560.0, 238.0),
					"objective_radius": 112.0,
					"hold_duration": 20.0,
					"decay_rate": 0.18,
				},
				{
					"name": "PIN THE FREQUENCY",
					"approach_name": "PURSUE THE CARRIER",
					"lifecycle": "signal_defense",
					"arena_rect": Rect2(3894.0, 76.0, 1172.0, 590.0),
					"objective_position": Vector2(4480.0, 452.0),
					"objective_radius": 106.0,
					"hold_duration": 22.0,
					"decay_rate": 0.18,
				},
			],
		},
	},
	"drift_cache": {
		"name": "DRIFT CACHE",
		"description": "Anchor beside an exposed cache while flankers cross the open grid.",
		"required": false,
		"prerequisites": ["signal_hold"],
		"route_position": Vector2(0.50, 0.76),
		"first_clear_flux": 100,
		"first_clear_discoveries": ["vector_parry"],
		"completion_copy": "Recovered counterfire telemetry unlocks Vector Parry.",
		"mission": {
			"id": "drift_cache",
			"name": "DRIFT CACHE",
			"rhythm": "SIGNAL DEFENSE",
			"lifecycle": "objective_sequence",
			"encounter_id": "cache_pressure",
			"music": &"breach",
			"time_limit": 165.0,
			"objectives": [
				{
					"name": "SECURE THE APPROACH",
					"lifecycle": "signal_defense",
					"arena_rect": Rect2(54.0, 76.0, 1172.0, 590.0),
					"objective_position": Vector2(820.0, 248.0),
					"objective_radius": 112.0,
					"hold_duration": 22.0,
					"decay_rate": 0.20,
				},
				{
					"name": "EXTRACT THE CACHE",
					"approach_name": "ENTER THE DRIFT",
					"lifecycle": "signal_defense",
					"arena_rect": Rect2(1974.0, 76.0, 1172.0, 590.0),
					"objective_position": Vector2(2938.0, 514.0),
					"objective_radius": 104.0,
					"hold_duration": 26.0,
					"decay_rate": 0.22,
				},
			],
		},
	},
	"relay_breach": {
		"name": "RELAY BREACH",
		"description": "Breach successive links until the Overseer's cage collapses.",
		"required": true,
		"prerequisites": ["signal_hold"],
		"route_position": Vector2(0.50, 0.34),
		"first_clear_flux": 70,
		"first_clear_discoveries": [],
		"completion_copy": "The cage falls. The Overseer can no longer hide its lock.",
		"mission": {
			"id": "relay_cage",
			"name": "RELAY BREACH",
			"rhythm": "BREACH",
			"lifecycle": "objective_sequence",
			"encounter_id": "relay_breach",
			"music": &"breach",
			"time_limit": 210.0,
			"objectives": [
				{
					"name": "BREAK THE OUTER LINK",
					"lifecycle": "relay_breach",
					"arena_rect": Rect2(54.0, 76.0, 1172.0, 590.0),
					"relay_positions": [Vector2(290.0, 238.0), Vector2(290.0, 500.0)],
				},
				{
					"name": "SEVER THE CROSS LINK",
					"approach_name": "FOLLOW THE BROKEN LINK",
					"lifecycle": "relay_breach",
					"arena_rect": Rect2(1974.0, 76.0, 1172.0, 590.0),
					"relay_positions": [Vector2(2560.0, 238.0), Vector2(2560.0, 500.0)],
				},
				{
					"name": "COLLAPSE THE CAGE",
					"approach_name": "ENTER THE INNER CAGE",
					"lifecycle": "relay_breach",
					"arena_rect": Rect2(3894.0, 76.0, 1172.0, 590.0),
					"relay_positions": [Vector2(4480.0, 238.0), Vector2(4480.0, 500.0)],
					"reinforcements": [
						{"kind": "carrier", "position": Vector2(4820.0, 360.0)},
					],
				},
			],
		},
	},
	"overseer_lock": {
		"name": "OVERSEER LOCK",
		"description": "Read the Overseer's arrays and exploit its exposed core.",
		"required": true,
		"prerequisites": ["relay_breach"],
		"route_position": Vector2(0.86, 0.34),
		"first_clear_flux": 120,
		"first_clear_discoveries": ["orbit", "arc", "nova", "gravity_tether"],
		"completion_copy": "The Overseer's armory yields three weapon signals and a Gravity Tether. The lock remains available for build trials.",
		"mission": {
			"id": "overseer_lock",
			"name": "OVERSEER LOCK",
			"rhythm": "BOSS",
			"lifecycle": "boss",
			"encounter_id": "overseer_lock",
			"music": &"combat",
			"time_limit": 180.0,
			"arena_rect": Rect2(54.0, 76.0, 1172.0, 590.0),
		},
	},
}


static func definition(id: String) -> Dictionary:
	return DEFINITIONS.get(id, {})


static func display_name(id: String) -> String:
	return String(definition(id).get("name", "UNKNOWN STAGE"))


static func mission(id: String, index: int = 0) -> Dictionary:
	if index != 0:
		return {}
	return definition(id).get("mission", {})


static func mission_arenas(id: String) -> Array[Rect2]:
	var result: Array[Rect2] = []
	var selected_mission := mission(id)
	for value: Variant in selected_mission.get("objectives", []):
		if not (value is Dictionary):
			continue
		var arena_rect: Rect2 = (value as Dictionary).get("arena_rect", Rect2())
		if arena_rect.has_area() and not result.has(arena_rect):
			result.append(arena_rect)
	if result.is_empty():
		var arena_rect: Rect2 = selected_mission.get("arena_rect", Rect2())
		if arena_rect.has_area():
			result.append(arena_rect)
	return result


static func is_unlocked(id: String, stage_clears: Dictionary) -> bool:
	if not DEFINITIONS.has(id):
		return false
	for prerequisite: String in definition(id).get("prerequisites", []):
		if int(stage_clears.get(prerequisite, 0)) <= 0:
			return false
	return true


static func unlock_requirement_text(id: String) -> String:
	var prerequisites: Array = definition(id).get("prerequisites", [])
	if prerequisites.is_empty():
		return "AVAILABLE"
	var names: Array[String] = []
	for prerequisite: String in prerequisites:
		names.append(display_name(prerequisite))
	return "CLEAR " + " + ".join(names)


static func first_clear_flux(id: String) -> int:
	return maxi(0, int(definition(id).get("first_clear_flux", 0)))


static func first_clear_discoveries(id: String) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in definition(id).get("first_clear_discoveries", []):
		result.append(String(value))
	return result


static func sector_completed(stage_clears: Dictionary) -> bool:
	return int(stage_clears.get("overseer_lock", 0)) > 0


static func retreat_flux(id: String, earned_flux: int) -> int:
	return maxi(0, int(floor(earned_flux * RETREAT_FLUX_RATIO))) if DEFINITIONS.has(id) else 0


static func defeat_flux(id: String, earned_flux: int) -> int:
	return maxi(0, int(floor(earned_flux * DEFEAT_FLUX_RATIO))) if DEFINITIONS.has(id) else 0


static func retreat_flux_percent(id: String) -> int:
	return int(round(RETREAT_FLUX_RATIO * 100.0)) if DEFINITIONS.has(id) else 0


static func defeat_flux_percent(id: String) -> int:
	return int(round(DEFEAT_FLUX_RATIO * 100.0)) if DEFINITIONS.has(id) else 0
