extends Node
## CosmeticsManager — Cosmetics database, slot management, gacha logic.
## Not an autoload; instantiated by main scene and given slot node references.

signal item_unlocked(item_id: String, item_name: String)
signal slots_updated
signal all_items_unlocked

# ─── Cosmetics Database ──────────────────────────────────────

const COSMETICS_DB: Dictionary = {
	"hat_red": {"name": "红帽子", "slot": "hat", "icon": "🎩", "scale": Vector2(0.25, 0.25), "offset": Vector2(0, -50)},
	"hat_crown": {"name": "金皇冠", "slot": "hat", "icon": "👑", "scale": Vector2(0.2, 0.2), "offset": Vector2(0, -60)},
	"glasses_cool": {"name": "太阳镜", "slot": "glasses", "icon": "🕶️", "scale": Vector2(0.2, 0.2), "offset": Vector2(0, -10)},
	"accessory_bowtie": {"name": "小领结", "slot": "bowtie", "icon": "🎀", "scale": Vector2(0.15, 0.15), "offset": Vector2(0, 30)},
	"accessory_necklace": {"name": "铃铛项圈", "slot": "necklace", "icon": "🔔", "scale": Vector2(0.2, 0.2), "offset": Vector2(0, 10)},
	"prop_mic": {"name": "麦克风", "slot": "left_prop", "icon": "🎤", "scale": Vector2(0.25, 0.25), "offset": Vector2(0, -20)},
}

const CHEST_COST: int = 10

# ─── Slot Node References (set by main.gd) ───────────────────

var slot_nodes: Dictionary = {}  # { "hat": Sprite2D, "glasses": Sprite2D, ... }

# ─── Public API ───────────────────────────────────────────────

func setup_slots(nodes: Dictionary) -> void:
	slot_nodes = nodes

func get_db() -> Dictionary:
	return COSMETICS_DB

func try_open_chest() -> String:
	## Attempt to open a chest. Returns unlocked item_id or "" if all unlocked.
	## Caller must check SaveManager.current_points >= CHEST_COST before calling.
	var locked_items: Array = []
	for item_id in COSMETICS_DB.keys():
		if not SaveManager.unlocked_cosmetics.has(item_id):
			locked_items.append(item_id)

	if locked_items.size() > 0:
		var unlocked_id = locked_items[randi() % locked_items.size()]
		SaveManager.unlock_cosmetic(unlocked_id)
		item_unlocked.emit(unlocked_id, COSMETICS_DB[unlocked_id]["name"])
		return unlocked_id
	else:
		SaveManager.add_points(500)
		all_items_unlocked.emit()
		return ""

func toggle_equip(item_id: String) -> void:
	var item_data = COSMETICS_DB.get(item_id, null)
	if not item_data:
		return
	var slot_key: String = item_data["slot"]

	# Props can go in either paw
	if slot_key == "left_prop":
		if SaveManager.equipped_cosmetics["left_prop"] == item_id:
			SaveManager.set_equipped("left_prop", "")
			SaveManager.set_equipped("right_prop", item_id)
		elif SaveManager.equipped_cosmetics["right_prop"] == item_id:
			SaveManager.set_equipped("right_prop", "")
		else:
			SaveManager.set_equipped("left_prop", item_id)
	else:
		if SaveManager.equipped_cosmetics[slot_key] == item_id:
			SaveManager.set_equipped(slot_key, "")
		else:
			SaveManager.set_equipped(slot_key, item_id)

	update_slot_textures()
	SaveManager.save()

func unequip_all() -> void:
	for slot in SaveManager.equipped_cosmetics.keys():
		SaveManager.set_equipped(slot, "")
	update_slot_textures()
	SaveManager.save()

func update_slot_textures() -> void:
	for slot_key in slot_nodes.keys():
		var item_name: String = SaveManager.equipped_cosmetics.get(slot_key, "")
		var node: Sprite2D = slot_nodes.get(slot_key, null)
		if not node:
			continue
		if item_name == "":
			node.texture = null
		else:
			var file_path = "res://assets/cosmetics/" + item_name + ".png"
			if ResourceLoader.exists(file_path):
				node.texture = load(file_path)
				var db_item = COSMETICS_DB.get(item_name, null)
				if db_item:
					node.scale = db_item.get("scale", Vector2.ONE)
					node.position = db_item.get("offset", Vector2.ZERO)
			else:
				node.texture = null
	slots_updated.emit()

func is_equipped(item_id: String) -> bool:
	var item_data = COSMETICS_DB.get(item_id, null)
	if not item_data:
		return false
	var slot_key: String = item_data["slot"]
	if slot_key == "left_prop":
		return SaveManager.equipped_cosmetics["left_prop"] == item_id or \
			   SaveManager.equipped_cosmetics["right_prop"] == item_id
	return SaveManager.equipped_cosmetics.get(slot_key, "") == item_id

func has_locked_items() -> bool:
	for item_id in COSMETICS_DB.keys():
		if not SaveManager.unlocked_cosmetics.has(item_id):
			return true
	return false
