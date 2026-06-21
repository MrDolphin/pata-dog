extends Node2D

@onready var tail_joint = $Mascot/TailJoint
@onready var tail = $Mascot/TailJoint/Tail
@onready var body_joint = $Mascot/BodyJoint
@onready var body = $Mascot/BodyJoint/Body
@onready var head_joint = $Mascot/BodyJoint/HeadJoint
@onready var head = $Mascot/BodyJoint/HeadJoint/Head
@onready var left_paw_joint = $Mascot/LeftPawJoint
@onready var left_paw_up = $Mascot/LeftPawJoint/LeftPawUp
@onready var left_paw_down = $Mascot/LeftPawJoint/LeftPawDown
@onready var right_paw_joint = $Mascot/RightPawJoint
@onready var right_paw_up = $Mascot/RightPawJoint/RightPawUp
@onready var right_paw_down = $Mascot/RightPawJoint/RightPawDown

@onready var hat_slot = $Mascot/BodyJoint/HeadJoint/HatSlot
@onready var glasses_slot = $Mascot/BodyJoint/HeadJoint/GlassesSlot
@onready var bowtie_slot = $Mascot/BodyJoint/BowtieSlot
@onready var left_prop_slot = $Mascot/LeftPawJoint/PropSlot
@onready var right_prop_slot = $Mascot/RightPawJoint/PropSlot

@onready var toggle_editor_btn = $UI/FloatingWidget/WidgetPanel/HBox/ToggleEditorBtn
@onready var editor_panel = $UI/FloatingWidget/EditorPanel
@onready var global_scale_slider = $UI/FloatingWidget/EditorPanel/VBoxContainer/GlobalScaleHBox/GlobalScaleSlider
@onready var style_option = $UI/FloatingWidget/EditorPanel/VBoxContainer/StyleHBox/StyleOption
@onready var camera = $Camera2D
@onready var sound_option = $UI/FloatingWidget/EditorPanel/VBoxContainer/SoundThemeHBox/SoundOption
@onready var part_option = $UI/FloatingWidget/EditorPanel/VBoxContainer/TabContainer/PaintTab/PaintVBox/PartHBox/PartOption
@onready var canvas = $UI/FloatingWidget/EditorPanel/VBoxContainer/TabContainer/PaintTab/PaintVBox/CanvasContainer/Canvas
@onready var brush_color_btn = $UI/FloatingWidget/EditorPanel/VBoxContainer/TabContainer/PaintTab/PaintVBox/BrushControl/BrushColor
@onready var brush_size_slider = $UI/FloatingWidget/EditorPanel/VBoxContainer/TabContainer/PaintTab/PaintVBox/BrushControl/BrushSize
@onready var clear_btn = $UI/FloatingWidget/EditorPanel/VBoxContainer/TabContainer/PaintTab/PaintVBox/ActionButtons/ClearBtn
@onready var save_btn = $UI/FloatingWidget/EditorPanel/VBoxContainer/TabContainer/PaintTab/PaintVBox/ActionButtons/SaveBtn
@onready var import_btn = $UI/FloatingWidget/EditorPanel/VBoxContainer/TabContainer/PaintTab/PaintVBox/ImportButtons/ImportBtn
@onready var file_dialog = $UI/FileDialog
@onready var joint_handle = $UI/JointHandle
@onready var scale_x_slider = $UI/FloatingWidget/EditorPanel/VBoxContainer/TabContainer/PaintTab/PaintVBox/TransformControl/ScaleHBox/ScaleXSlider
@onready var scale_y_slider = $UI/FloatingWidget/EditorPanel/VBoxContainer/TabContainer/PaintTab/PaintVBox/TransformControl/ScaleHBox/ScaleYSlider
@onready var rot_slider = $UI/FloatingWidget/EditorPanel/VBoxContainer/TabContainer/PaintTab/PaintVBox/TransformControl/RotHBox/RotSlider
@onready var off_x_slider = $UI/FloatingWidget/EditorPanel/VBoxContainer/TabContainer/PaintTab/PaintVBox/TransformControl/OffHBox/OffXSlider
@onready var off_y_slider = $UI/FloatingWidget/EditorPanel/VBoxContainer/TabContainer/PaintTab/PaintVBox/TransformControl/OffHBox/OffYSlider

@onready var floating_widget = $UI/FloatingWidget
@onready var widget_panel = $UI/FloatingWidget/WidgetPanel
@onready var keystrokes_label = $UI/FloatingWidget/WidgetPanel/HBox/KeystrokesLabel
@onready var chest_bubble = $UI/FloatingWidget/ChestBubble
@onready var chest_count_label = $UI/FloatingWidget/ChestBubble/VBox/Count
@onready var chest_button = $UI/FloatingWidget/ChestBubble/ChestButton

@onready var unlock_popup = $UI/UnlockPopup
@onready var unlock_item_icon = $UI/UnlockPopup/CenterContainer/PopupPanel/VBox/ItemIcon
@onready var unlock_item_name = $UI/UnlockPopup/CenterContainer/PopupPanel/VBox/ItemName
@onready var chest_particles = $ChestParticles
@onready var wardrobe_grid = $UI/FloatingWidget/EditorPanel/VBoxContainer/TabContainer/WardrobeTab/VBox/WardrobeGrid

@onready var import_audio_btn = $UI/FloatingWidget/EditorPanel/VBoxContainer/TabContainer/AudioTab/ImportAudioBtn
@onready var clear_audio_btn = $UI/FloatingWidget/EditorPanel/VBoxContainer/TabContainer/AudioTab/ClearAudioBtn
@onready var audio_list = $UI/FloatingWidget/EditorPanel/VBoxContainer/TabContainer/AudioTab/AudioList
var audio_file_dialog: FileDialog = null

var use_left_paw = true
var excitement = 0.0
var dragging_joint = false

var dragging_window = false
var drag_offset = Vector2.ZERO

var part_nodes = []
var current_style = "cute"

var left_paw_tween: Tween = null
var right_paw_tween: Tween = null
var head_tween: Tween = null
var body_tween: Tween = null
var chest_shake_tween: Tween = null
var context_menu: PopupMenu = null

var cosmetics_manager = null

func _ready():
	get_tree().get_root().transparent_bg = true
	get_window().transparent = true
	get_window().transparent_bg = true
	floating_widget.transparent = true
	floating_widget.transparent_bg = true
	get_viewport().transparent_bg = true
	
	# Instantiate cosmetics manager locally
	cosmetics_manager = preload("res://cosmetics_manager.gd").new()
	add_child(cosmetics_manager)
	
	var slots = {
		"hat": hat_slot,
		"glasses": glasses_slot,
		"bowtie": bowtie_slot,
		"left_prop": left_prop_slot,
		"right_prop": right_prop_slot
	}
	if has_node("Mascot/BodyJoint/NecklaceSlot"):
		slots["necklace"] = $Mascot/BodyJoint/NecklaceSlot
	
	cosmetics_manager.setup_slots(slots)
	cosmetics_manager.slots_updated.connect(_populate_wardrobe_ui)
	
	# Connect global hook signal
	GlobalHookManager.global_key_pressed.connect(_on_global_key_pressed)
	
	_update_mouse_passthrough()
	
	# Connect SaveManager signals
	SaveManager.points_changed.connect(_on_points_changed)
	SaveManager.data_loaded.connect(_on_data_loaded)
	
	# Initialize paw state
	_reset_paws()
	
	# Setup Paint Editor nodes
	part_nodes = [head, body, left_paw_up, left_paw_down, right_paw_up, right_paw_down, tail]
	
	style_option.add_item("可爱风格 (Cute)")
	style_option.add_item("鬼畜风格 (Bizarre)")
	style_option.item_selected.connect(_on_style_selected)
	
	for t_name in SoundManager.get_theme_names():
		sound_option.add_item(t_name)
	sound_option.selected = SaveManager.sound_theme
	SoundManager.set_theme(SaveManager.sound_theme)
	sound_option.item_selected.connect(_on_sound_theme_selected)
	
	part_option.add_item("头部 (Head)")
	part_option.add_item("身体 (Body)")
	part_option.add_item("左爪-起 (Left Paw Up)")
	part_option.add_item("左爪-落 (Left Paw Down)")
	part_option.add_item("右爪-起 (Right Paw Up)")
	part_option.add_item("右爪-落 (Right Paw Down)")
	part_option.add_item("尾巴 (Tail)")
	part_option.item_selected.connect(_on_part_selected)
	
	global_scale_slider.value_changed.connect(_on_global_scale_changed)
	
	toggle_editor_btn.pressed.connect(_on_toggle_editor_btn_pressed)
	brush_color_btn.color_changed.connect(_on_brush_color_changed)
	brush_size_slider.value_changed.connect(_on_brush_size_changed)
	clear_btn.pressed.connect(_on_clear_btn_pressed)
	save_btn.pressed.connect(_on_save_btn_pressed)
	import_btn.pressed.connect(_on_import_btn_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	
	widget_panel.gui_input.connect(_on_widget_panel_gui_input)
	editor_panel.gui_input.connect(_on_widget_panel_gui_input)

	floating_widget.position = get_window().position + Vector2i(get_window().size.x - 180, get_window().size.y - 140)

	SaveManager.load_data()
	get_window().files_dropped.connect(_on_files_dropped)
	joint_handle.gui_input.connect(_on_joint_handle_gui_input)
	
	scale_x_slider.value_changed.connect(_on_transform_changed.bind("scale_x"))
	scale_y_slider.value_changed.connect(_on_transform_changed.bind("scale_y"))
	rot_slider.value_changed.connect(_on_transform_changed.bind("rot"))
	off_x_slider.value_changed.connect(_on_transform_changed.bind("off_x"))
	off_y_slider.value_changed.connect(_on_transform_changed.bind("off_y"))
	
	canvas.set_brush_color(brush_color_btn.color)
	canvas.set_brush_size(brush_size_slider.value)
	
	chest_button.pressed.connect(_on_chest_button_pressed)
	
	audio_file_dialog = FileDialog.new()
	$UI.add_child(audio_file_dialog)
	audio_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	audio_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	audio_file_dialog.use_native_dialog = true
	audio_file_dialog.filters = ["*.wav, *.ogg ; Audio Files"]
	audio_file_dialog.files_selected.connect(_on_audio_files_selected)
	
	import_audio_btn.pressed.connect(func(): audio_file_dialog.popup_centered(Vector2(600,400)))
	clear_audio_btn.pressed.connect(_on_clear_audio)
	
	context_menu = PopupMenu.new()
	context_menu.add_item("最小化 (Minimize)", 0)
	context_menu.add_item("退出 (Exit)", 1)
	context_menu.id_pressed.connect(_on_context_menu_id_pressed)
	$UI.add_child(context_menu)
	
	_on_part_selected(0)
	
	# Load initial data state
	if SaveManager.total_clicks > 0 or SaveManager.current_points > 0:
		_on_data_loaded()

func _process(delta):
	excitement = max(0.0, excitement - delta * 2.0)
	var time = Time.get_ticks_msec() / 1000.0
	
	if current_style == "cute":
		var speed = 5.0 + excitement * 15.0
		tail_joint.rotation = -0.5 + sin(time * speed) * (0.2 + excitement * 0.5)
		
		body_joint.rotation = lerp_angle(body_joint.rotation, 0.0, delta * 15.0)
		body_joint.position.y = lerp(body_joint.position.y, 350.0 + sin(time * 3.0) * 4.0, delta * 10.0)
		body_joint.position.x = lerp(body_joint.position.x, 400.0, delta * 10.0)
		
		head_joint.rotation = lerp_angle(head_joint.rotation, sin(time * 2.0) * 0.05, delta * 10.0)
		head_joint.position = lerp(head_joint.position, Vector2(0, -100), delta * 10.0)
		
		tail.scale = lerp(tail.scale, Vector2.ONE, delta * 10.0)
		
	else: # bizarre style
		var speed = 25.0 + excitement * 50.0
		tail_joint.rotation = -0.5 + sin(time * speed) * (0.8 + excitement * 1.5) + randf_range(-0.1, 0.1)
		tail.scale = Vector2(1.0, 1.0) + Vector2(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))
		
		body_joint.rotation = lerp_angle(body_joint.rotation, randf_range(-0.2, 0.2), delta * 40.0)
		body_joint.position = Vector2(400, 350) + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		
		head_joint.rotation = lerp_angle(head_joint.rotation, sin(time * 60.0) * 0.2 + randf_range(-0.1, 0.1), delta * 40.0)
		head_joint.position = Vector2(0, -100) + Vector2(randf_range(-15, 15), randf_range(-15, 15))

	if editor_panel.visible:
		joint_handle.visible = true
		var active_joint = _get_current_joint()
		if active_joint:
			joint_handle.global_position = active_joint.global_position - joint_handle.size / 2.0
	else:
		joint_handle.visible = false

# ─── Input Handling ───────────────────────────────────────────

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if editor_panel.visible and event.position.x > editor_panel.position.x and event.position.y > editor_panel.position.y:
				pass # Ignore drag if clicking on the panel (though editor_panel is on WidgetWindow now, this is for safety)
			else:
				dragging_window = true
				drag_offset = get_viewport().get_mouse_position()
				_trigger_alternate_wave(false)
		else:
			dragging_window = false
			
	if event is InputEventMouseMotion and dragging_window:
		DisplayServer.window_set_position(DisplayServer.window_get_position() + Vector2i(event.position - drag_offset))
		return
		
	if dragging_joint:
		return
		
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
				_bark()
			else:
				_trigger_alternate_wave(true)
	
	elif event is InputEventMouseButton and not dragging_window:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				context_menu.position = Vector2i(get_viewport().get_mouse_position()) + DisplayServer.window_get_position()
				context_menu.popup()

func _on_context_menu_id_pressed(id: int):
	if id == 0:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	elif id == 1:
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)

func _on_global_key_pressed():
	if not get_window().has_focus():
		_trigger_alternate_wave(true)

func _trigger_alternate_wave(is_keyboard: bool = true):
	SaveManager.increment_click()
	
	if is_keyboard:
		SoundManager.play_click(excitement)
	else:
		SoundManager.play_tap(excitement)
		
	if use_left_paw:
		_paw_down("left")
	else:
		_paw_down("right")
	use_left_paw = !use_left_paw

func _bark():
	SaveManager.increment_click()
	SoundManager.play_bark(excitement)
	_paw_down("both")

func _add_excitement():
	excitement = min(1.0, excitement + 0.15)

# ─── Animations ───────────────────────────────────────────────

func _paw_down(side):
	_add_excitement()
	if current_style == "cute":
		_paw_down_cute(side)
	else:
		_paw_down_bizarre(side)

func _paw_down_cute(side):
	if side == "left" or side == "both":
		left_paw_up.visible = false
		left_paw_down.visible = true
		
		if left_paw_tween: left_paw_tween.kill()
		left_paw_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		left_paw_tween.tween_property(left_paw_joint, "rotation", 0.4, 0.08)
		left_paw_tween.tween_property(left_paw_joint, "rotation", 0.0, 0.12).set_delay(0.05)
		left_paw_tween.finished.connect(func(): 
			left_paw_up.visible = true
			left_paw_down.visible = false
		)
		
		if head_tween: head_tween.kill()
		head_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		head_tween.tween_property(head_joint, "rotation", -0.15, 0.08)
		head_tween.tween_property(head_joint, "rotation", 0.0, 0.12)
		
	if side == "right" or side == "both":
		right_paw_up.visible = false
		right_paw_down.visible = true
		
		if right_paw_tween: right_paw_tween.kill()
		right_paw_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		right_paw_tween.tween_property(right_paw_joint, "rotation", -0.4, 0.08)
		right_paw_tween.tween_property(right_paw_joint, "rotation", 0.0, 0.12).set_delay(0.05)
		right_paw_tween.finished.connect(func(): 
			right_paw_up.visible = true
			right_paw_down.visible = false
		)
		
		if head_tween: head_tween.kill()
		head_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		head_tween.tween_property(head_joint, "rotation", 0.15, 0.08)
		head_tween.tween_property(head_joint, "rotation", 0.0, 0.12)

	if body_tween: body_tween.kill()
	body_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	body_tween.tween_property(body_joint, "position:y", 355.0, 0.05)
	body_tween.tween_property(body_joint, "position:y", 350.0, 0.1)

func _paw_down_bizarre(side):
	if side == "left" or side == "both":
		left_paw_up.visible = false
		left_paw_down.visible = true
		
		if left_paw_tween: left_paw_tween.kill()
		left_paw_tween = create_tween().set_parallel(true)
		left_paw_tween.tween_property(left_paw_joint, "rotation", 1.8, 0.05)
		left_paw_tween.tween_property(left_paw_joint, "scale", Vector2(2.5, 0.4), 0.05)
		
		var t2 = create_tween().set_parallel(true)
		t2.tween_property(left_paw_joint, "rotation", 0.0, 0.08).set_delay(0.06)
		t2.tween_property(left_paw_joint, "scale", Vector2(1.0, 1.0), 0.08).set_delay(0.06)
		t2.finished.connect(func(): 
			left_paw_up.visible = true
			left_paw_down.visible = false
		)
		
	if side == "right" or side == "both":
		right_paw_up.visible = false
		right_paw_down.visible = true
		
		if right_paw_tween: right_paw_tween.kill()
		right_paw_tween = create_tween().set_parallel(true)
		right_paw_tween.tween_property(right_paw_joint, "rotation", -1.8, 0.05)
		right_paw_tween.tween_property(right_paw_joint, "scale", Vector2(2.5, 0.4), 0.05)
		
		var t2 = create_tween().set_parallel(true)
		t2.tween_property(right_paw_joint, "rotation", 0.0, 0.08).set_delay(0.06)
		t2.tween_property(right_paw_joint, "scale", Vector2(1.0, 1.0), 0.08).set_delay(0.06)
		t2.finished.connect(func(): 
			right_paw_up.visible = true
			right_paw_down.visible = false
		)

	if head_tween: head_tween.kill()
	head_tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	head_tween.tween_property(head_joint, "rotation", randf_range(-PI * 1.5, PI * 1.5), 0.05)
	head_tween.tween_property(head_joint, "rotation", 0.0, 0.1)
	
	body_joint.position = Vector2(400, 350) + Vector2(randf_range(-25, 25), randf_range(-25, 25))
	body_joint.rotation = randf_range(-0.4, 0.4)

func _reset_paws():
	left_paw_up.visible = true
	left_paw_down.visible = false
	right_paw_up.visible = true
	right_paw_down.visible = false
	
	if left_paw_tween: left_paw_tween.kill()
	if right_paw_tween: right_paw_tween.kill()
	
	left_paw_joint.rotation = 0.0
	left_paw_joint.scale = Vector2.ONE
	right_paw_joint.rotation = 0.0
	right_paw_joint.scale = Vector2.ONE

# ─── UI & Events ──────────────────────────────────────────────

func _on_data_loaded():
	global_scale_slider.set_value_no_signal(SaveManager.global_scale)
	camera.zoom = Vector2(SaveManager.global_scale, SaveManager.global_scale)

	cosmetics_manager.update_slot_textures()
	_on_points_changed(SaveManager.total_clicks, SaveManager.current_points)
	_populate_wardrobe_ui()
	
	for idx in range(part_nodes.size()):
		var part_key = str(idx)
		if SaveManager.part_transforms.has(part_key):
			var t_data = SaveManager.part_transforms[part_key]
			var node = part_nodes[idx]
			node.scale = Vector2(t_data.get("scale_x", 1.0), t_data.get("scale_y", 1.0))
			node.rotation_degrees = t_data.get("rot", 0.0)
			node.position = Vector2(t_data.get("off_x", 0.0), t_data.get("off_y", 0.0))
			
	if SaveManager.custom_audio_paths.size() > 0:
		SoundManager.load_custom_audio(SaveManager.custom_audio_paths)
	_update_audio_list()

func _on_audio_files_selected(paths: PackedStringArray):
	for p in paths:
		if not SaveManager.custom_audio_paths.has(p):
			SaveManager.custom_audio_paths.append(p)
	SaveManager.save()
	SoundManager.load_custom_audio(SaveManager.custom_audio_paths)
	_update_audio_list()

func _on_clear_audio():
	SaveManager.custom_audio_paths.clear()
	SaveManager.save()
	SoundManager.load_custom_audio([])
	_update_audio_list()

func _update_audio_list():
	audio_list.clear()
	for p in SaveManager.custom_audio_paths:
		audio_list.add_item(p.get_file())

func _on_points_changed(total: int, current: int):
	keystrokes_label.text = str(total)
	var available_chests = SaveManager.current_points / cosmetics_manager.CHEST_COST
	if available_chests > 0 and cosmetics_manager.has_locked_items():
		chest_bubble.visible = true
		chest_count_label.text = str(available_chests)
		_start_chest_shake()
	else:
		chest_bubble.visible = false
		if chest_shake_tween:
			chest_shake_tween.kill()
		chest_bubble.rotation = 0.0
	_update_mouse_passthrough()

func _start_chest_shake():
	if chest_shake_tween and chest_shake_tween.is_valid():
		return
	chest_shake_tween = create_tween().set_loops()
	chest_shake_tween.tween_property(chest_bubble, "rotation", 0.08, 0.05)
	chest_shake_tween.tween_property(chest_bubble, "rotation", -0.08, 0.1).set_delay(0.05)
	chest_shake_tween.tween_property(chest_bubble, "rotation", 0.0, 0.05).set_delay(0.15)
	chest_shake_tween.tween_interval(1.5)

func _on_chest_button_pressed():
	if SaveManager.current_points < cosmetics_manager.CHEST_COST: return
	
	var item_unlocked = cosmetics_manager.try_open_chest()
	if item_unlocked != "":
		SaveManager.spend_points(cosmetics_manager.CHEST_COST)
		var db = cosmetics_manager.get_db()
		var item_name = db[item_unlocked]["name"]
		var tex_path = "res://assets/cosmetics/" + item_unlocked + ".png"
		_show_unlock_popup(item_name, tex_path)
	else:
		_show_unlock_popup("所有饰品已解锁", "")
		
	chest_particles.restart()
	chest_particles.emitting = true
	SoundManager.play_tap(0.5)
	SoundManager.play_click(0.5)
	
	_on_points_changed(SaveManager.total_points, SaveManager.current_points)
	_populate_wardrobe_ui()

func _show_unlock_popup(text_msg: String, texture_path: String):
	unlock_item_name.text = "NEW ITEM: " + text_msg
	if texture_path != "" and ResourceLoader.exists(texture_path):
		unlock_item_icon.texture = load(texture_path)
	else:
		unlock_item_icon.texture = null
		
	unlock_popup.visible = true
	unlock_popup.modulate.a = 0.0
	var popup_panel = unlock_popup.get_node("CenterContainer/PopupPanel")
	popup_panel.scale = Vector2.ZERO
	popup_panel.pivot_offset = popup_panel.custom_minimum_size / 2.0
	
	var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(unlock_popup, "modulate:a", 1.0, 0.2)
	t.parallel().tween_property(popup_panel, "scale", Vector2.ONE, 0.4)
	
	t.tween_interval(1.5)
	t.tween_property(unlock_popup, "modulate:a", 0.0, 0.3)
	t.finished.connect(func():
		unlock_popup.visible = false
	)

func _populate_wardrobe_ui():
	for child in wardrobe_grid.get_children():
		child.queue_free()
		
	var unequip_btn = Button.new()
	unequip_btn.text = "❌ 脱下全部"
	unequip_btn.pressed.connect(func():
		cosmetics_manager.unequip_all()
	)
	wardrobe_grid.add_child(unequip_btn)
	
	var db = cosmetics_manager.get_db()
	for item_id in db.keys():
		var btn = Button.new()
		var item_data = db[item_id]
		var is_unlocked = SaveManager.unlocked_cosmetics.has(item_id)
		
		if is_unlocked:
			var is_equipped = cosmetics_manager.is_equipped(item_id)
			if is_equipped:
				btn.text = "👑 " + item_data["name"]
				btn.modulate = Color.GREEN
			else:
				btn.text = item_data.get("icon", "") + " " + item_data["name"]
				
			btn.pressed.connect(func():
				cosmetics_manager.toggle_equip(item_id)
			)
		else:
			btn.text = "🔒 未解锁"
			btn.disabled = true
			
		wardrobe_grid.add_child(btn)

# ─── Editor Canvas Handlers ───────────────────────────────────

func _on_toggle_editor_btn_pressed():
	editor_panel.visible = !editor_panel.visible
	var current_pos = floating_widget.position
	if editor_panel.visible:
		toggle_editor_btn.text = "❌"
		floating_widget.size = Vector2i(350, 750)
		floating_widget.position = current_pos - Vector2i(0, 750 - 120)
		_on_part_selected(part_option.selected)
	else:
		toggle_editor_btn.text = "≡"
		floating_widget.size = Vector2i(160, 120)
		floating_widget.position = current_pos + Vector2i(0, 750 - 120)
	_update_mouse_passthrough()

var widget_dragging = false
var widget_drag_offset = Vector2i()

func _on_widget_panel_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			widget_dragging = true
			widget_drag_offset = DisplayServer.mouse_get_position() - floating_widget.position
		else:
			widget_dragging = false
	elif event is InputEventMouseMotion and widget_dragging:
		floating_widget.position = DisplayServer.mouse_get_position() - widget_drag_offset

func _on_style_selected(index):
	current_style = "cute" if index == 0 else "bizarre"

func _on_global_scale_changed(value):
	camera.zoom = Vector2(value, value)
	SaveManager.global_scale = value
	SaveManager.save()
	_update_mouse_passthrough()

func _on_sound_theme_selected(index: int):
	SoundManager.set_theme(index)
	SaveManager.set_sound_theme(index)
	SaveManager.save()
	SoundManager.play_click()

func _on_part_selected(index):
	var selected_node = part_nodes[index]
	var part_key = str(index)
	var t_data = SaveManager.part_transforms.get(part_key, {"scale_x":1, "scale_y":1, "rot":0, "off_x":0, "off_y":0})
	scale_x_slider.set_value_no_signal(t_data.get("scale_x", 1.0))
	scale_y_slider.set_value_no_signal(t_data.get("scale_y", 1.0))
	rot_slider.set_value_no_signal(t_data.get("rot", 0.0))
	off_x_slider.set_value_no_signal(t_data.get("off_x", 0.0))
	off_y_slider.set_value_no_signal(t_data.get("off_y", 0.0))
	
	canvas.clear_canvas()
	if selected_node.texture:
		var img = selected_node.texture.get_image()
		if img:
			img.convert(Image.FORMAT_RGBA8)
			img.resize(canvas.canvas_width, canvas.canvas_height, Image.INTERPOLATE_LANCZOS)
			canvas.image = img
			canvas._update_texture()

func _update_mouse_passthrough():
	# Main Window
	var s = SaveManager.global_scale
	var rect = Rect2(150 * s, 150 * s, 500 * s, 400 * s)
	var main_poly = PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y)
	])
	get_window().mouse_passthrough_polygon = main_poly
	
	# Widget Window
	var widget_poly = PackedVector2Array()
	if editor_panel.visible:
		widget_poly.append(Vector2(0, 0))
		widget_poly.append(Vector2(350, 0))
		widget_poly.append(Vector2(350, 750))
		widget_poly.append(Vector2(0, 750))
	else:
		if chest_bubble.visible:
			widget_poly.append(Vector2(0, 0))
			widget_poly.append(Vector2(160, 0))
			widget_poly.append(Vector2(160, 120))
			widget_poly.append(Vector2(0, 120))
		else:
			widget_poly.append(Vector2(0, 80))
			widget_poly.append(Vector2(160, 80))
			widget_poly.append(Vector2(160, 120))
			widget_poly.append(Vector2(0, 120))
	floating_widget.mouse_passthrough_polygon = widget_poly


func _on_transform_changed(value: float, type: String):
	var idx = part_option.selected
	var selected_node = part_nodes[idx]
	var part_key = str(idx)
	var t_data = SaveManager.part_transforms.get(part_key, {"scale_x":1, "scale_y":1, "rot":0, "off_x":0, "off_y":0}).duplicate()
	
	if type == "scale_x":
		t_data["scale_x"] = value
		selected_node.scale.x = value
	elif type == "scale_y":
		t_data["scale_y"] = value
		selected_node.scale.y = value
	elif type == "rot":
		t_data["rot"] = value
		selected_node.rotation_degrees = value
	elif type == "off_x":
		t_data["off_x"] = value
		selected_node.position.x = value
	elif type == "off_y":
		t_data["off_y"] = value
		selected_node.position.y = value
		
	SaveManager.part_transforms[part_key] = t_data
	SaveManager.save()

func _on_brush_color_changed(color):
	canvas.set_brush_color(color)

func _on_brush_size_changed(value):
	canvas.set_brush_size(value)

func _on_clear_btn_pressed():
	canvas.clear_canvas()

func _on_save_btn_pressed():
	var drawn_img = canvas.get_drawn_image()
	var img_dup = Image.create_from_data(drawn_img.get_width(), drawn_img.get_height(), drawn_img.has_mipmaps(), drawn_img.get_format(), drawn_img.get_data())
	var tex = ImageTexture.create_from_image(img_dup)
	var selected_node = part_nodes[part_option.selected]
	selected_node.texture = tex

func _on_import_btn_pressed():
	file_dialog.popup_centered()

func _on_file_selected(path: String):
	_load_image_to_part(path)

func _on_files_dropped(files: PackedStringArray):
	if files.size() > 0:
		_load_image_to_part(files[0])

func _load_image_to_part(path: String):
	var loaded_img = Image.load_from_file(path)
	if loaded_img:
		loaded_img.convert(Image.FORMAT_RGBA8)
		var tex = ImageTexture.create_from_image(loaded_img)
		var selected_node = part_nodes[part_option.selected]
		selected_node.texture = tex
		
		canvas.clear_canvas()
		var img_for_canvas = Image.create_from_data(loaded_img.get_width(), loaded_img.get_height(), loaded_img.has_mipmaps(), loaded_img.get_format(), loaded_img.get_data())
		img_for_canvas.resize(canvas.canvas_width, canvas.canvas_height, Image.INTERPOLATE_LANCZOS)
		canvas.image = img_for_canvas
		canvas._update_texture()

func _get_current_joint() -> Node2D:
	var idx = part_option.selected
	match idx:
		0: return head_joint
		1: return body_joint
		2, 3: return left_paw_joint
		4, 5: return right_paw_joint
		6: return tail_joint
	return null

func _on_joint_handle_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging_joint = true
			else:
				dragging_joint = false
	elif event is InputEventMouseMotion and dragging_joint:
		var active_joint = _get_current_joint()
		if active_joint:
			active_joint.global_position = get_global_mouse_position()
