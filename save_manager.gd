extends Node
## SaveManager — Centralized JSON persistence with timer-based auto-save.
## Registered as Autoload so any script can call SaveManager.save() / .load_data().

signal data_loaded
signal data_saved
signal points_changed(total_clicks: int, current_points: int)

const SAVE_PATH = "user://pata_dog_save.json"
const AUTO_SAVE_INTERVAL: float = 30.0  # seconds

# ─── Persisted Data ───────────────────────────────────────────

var total_clicks: int = 0
var current_points: int = 0
var unlocked_cosmetics: Array = ["default"]
var equipped_cosmetics: Dictionary = {
	"hat": "",
	"glasses": "",
	"bowtie": "",
	"necklace": "",
	"left_prop": "",
	"right_prop": ""
}
var sound_theme: int = 0
var part_transforms: Dictionary = {}
var custom_audio_paths: Array = []

var global_scale: float = 1.0

# ─── Internal ─────────────────────────────────────────────────

var _auto_save_timer: Timer = null
var _dirty: bool = false  # Track if data needs saving

func _ready() -> void:
	load_data()
	_setup_auto_save_timer()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()

# ─── Public API ───────────────────────────────────────────────

func increment_click() -> void:
	total_clicks += 1
	current_points += 1
	_dirty = true
	points_changed.emit(total_clicks, current_points)

func spend_points(amount: int) -> bool:
	if current_points >= amount:
		current_points -= amount
		_dirty = true
		points_changed.emit(total_clicks, current_points)
		return true
	return false

func add_points(amount: int) -> void:
	current_points += amount
	_dirty = true
	points_changed.emit(total_clicks, current_points)

func unlock_cosmetic(item_id: String) -> void:
	if not unlocked_cosmetics.has(item_id):
		unlocked_cosmetics.append(item_id)
		_dirty = true

func set_equipped(slot: String, item_id: String) -> void:
	equipped_cosmetics[slot] = item_id
	_dirty = true

func set_sound_theme(index: int) -> void:
	sound_theme = index
	_dirty = true

func save() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"total_clicks": total_clicks,
			"current_points": current_points,
			"unlocked_cosmetics": unlocked_cosmetics,
			"equipped_cosmetics": equipped_cosmetics,
			"sound_theme": sound_theme,
			"part_transforms": part_transforms,
			"custom_audio_paths": custom_audio_paths,
			"global_scale": global_scale
		}
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		_dirty = false
		data_saved.emit()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save()  # Create default save file
		data_loaded.emit()
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK and json.data is Dictionary:
			var data: Dictionary = json.data
			total_clicks = data.get("total_clicks", 0)
			current_points = data.get("current_points", 0)
			unlocked_cosmetics = data.get("unlocked_cosmetics", ["default"])
			sound_theme = data.get("sound_theme", 0)
			part_transforms = data.get("part_transforms", {})
			custom_audio_paths = data.get("custom_audio_paths", [])
			global_scale = float(data.get("global_scale", 1.0))
			var equipped = data.get("equipped_cosmetics", {})
			for slot in equipped_cosmetics.keys():
				if equipped.has(slot):
					equipped_cosmetics[slot] = equipped[slot]
	data_loaded.emit()

# ─── Auto-save Timer ─────────────────────────────────────────

func _setup_auto_save_timer() -> void:
	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
	_auto_save_timer.autostart = true
	_auto_save_timer.timeout.connect(_on_auto_save)
	add_child(_auto_save_timer)

func _on_auto_save() -> void:
	if _dirty:
		save()
