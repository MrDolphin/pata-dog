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

@onready var toggle_editor_btn = $UI/ToggleEditorBtn
@onready var editor_panel = $UI/EditorPanel
@onready var style_option = $UI/EditorPanel/VBoxContainer/StyleHBox/StyleOption
@onready var part_option = $UI/EditorPanel/VBoxContainer/PartHBox/PartOption
@onready var canvas = $UI/EditorPanel/VBoxContainer/CanvasContainer/Canvas
@onready var brush_color_btn = $UI/EditorPanel/VBoxContainer/BrushControl/BrushColor
@onready var brush_size_slider = $UI/EditorPanel/VBoxContainer/BrushControl/BrushSize
@onready var clear_btn = $UI/EditorPanel/VBoxContainer/ActionButtons/ClearBtn
@onready var save_btn = $UI/EditorPanel/VBoxContainer/ActionButtons/SaveBtn
@onready var import_btn = $UI/EditorPanel/VBoxContainer/ImportButtons/ImportBtn
@onready var file_dialog = $UI/FileDialog

var use_left_paw = true
var excitement = 0.0

var dragging_window = false
var drag_offset = Vector2.ZERO

var part_nodes = []
var current_style = "cute"

func _ready():
	_reset_paws()
	get_viewport().transparent_bg = true
	
	part_nodes = [
		head,
		body,
		left_paw_up,
		left_paw_down,
		right_paw_up,
		right_paw_down,
		tail
	]
	
	# Populate Style option
	style_option.add_item("可爱风格 (Cute)")
	style_option.add_item("鬼畜风格 (Bizarre)")
	style_option.item_selected.connect(_on_style_selected)
	
	# Populate Part option
	part_option.add_item("头部 (Head)")
	part_option.add_item("身体 (Body)")
	part_option.add_item("左爪-起 (Left Paw Up)")
	part_option.add_item("左爪-落 (Left Paw Down)")
	part_option.add_item("右爪-起 (Right Paw Up)")
	part_option.add_item("右爪-落 (Right Paw Down)")
	part_option.add_item("尾巴 (Tail)")
	part_option.item_selected.connect(_on_part_selected)
	
	# Connect UI controls
	toggle_editor_btn.pressed.connect(_on_toggle_editor_btn_pressed)
	brush_color_btn.color_changed.connect(_on_brush_color_changed)
	brush_size_slider.value_changed.connect(_on_brush_size_changed)
	clear_btn.pressed.connect(_on_clear_btn_pressed)
	save_btn.pressed.connect(_on_save_btn_pressed)
	import_btn.pressed.connect(_on_import_btn_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	
	get_window().files_dropped.connect(_on_files_dropped)
	
	# Initialize brush
	canvas.set_brush_color(brush_color_btn.color)
	canvas.set_brush_size(brush_size_slider.value)
	
	# Load head default (empty) to canvas
	_on_part_selected(0)

func _process(delta):
	excitement = max(0.0, excitement - delta * 2.0)
	var time = Time.get_ticks_msec() / 1000.0
	var speed = 5.0 + excitement * 15.0
	tail_joint.rotation = -0.5 + sin(time * speed) * (0.2 + excitement * 0.5)
	
	# 让整个身体做极其轻微的回弹晃动
	body_joint.rotation = lerp_angle(body_joint.rotation, 0.0, delta * 15.0)

func _input(event):
	# 窗口拖拽
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		if event.pressed:
			dragging_window = true
			drag_offset = get_viewport().get_mouse_position()
		else:
			dragging_window = false
			
	if event is InputEventMouseMotion and dragging_window:
		DisplayServer.window_set_position(DisplayServer.window_get_position() + Vector2i(event.position - drag_offset))
		return
		
	# 键盘检测
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
				_bark()
				_paw_down("both")
			else:
				if use_left_paw:
					_paw_down("left")
				else:
					_paw_down("right")
				use_left_paw = !use_left_paw
				_tap_sound()
				_add_excitement()
		elif not event.pressed:
			_reset_paws()
	
	# 鼠标左右键检测
	elif event is InputEventMouseButton and not dragging_window:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_paw_down("left")
				_tap_sound()
				_add_excitement()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_paw_down("right")
				_tap_sound()
				_add_excitement()
		else:
			if event.button_index == MOUSE_BUTTON_LEFT:
				left_paw_up.visible = true
				left_paw_down.visible = false
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				right_paw_up.visible = true
				right_paw_down.visible = false
				
	# 鼠标移动时微晃身体
	elif event is InputEventMouseMotion:
		body_joint.rotation = clamp(event.relative.x * 0.005, -0.2, 0.2)

func _paw_down(side):
	if side == "left" or side == "both":
		left_paw_up.visible = false
		left_paw_down.visible = true
	if side == "right" or side == "both":
		right_paw_up.visible = false
		right_paw_down.visible = true
	
	body_joint.rotation = randf_range(-0.1, 0.1)

func _reset_paws():
	left_paw_up.visible = true
	left_paw_down.visible = false
	right_paw_up.visible = true
	right_paw_down.visible = false

func _add_excitement():
	excitement = min(1.0, excitement + 0.1)

# Editor Event Handlers
func _on_toggle_editor_btn_pressed():
	editor_panel.visible = !editor_panel.visible
	if editor_panel.visible:
		toggle_editor_btn.text = "❌ 关闭配置"
		# Preload current active part to canvas when opening
		_on_part_selected(part_option.selected)
	else:
		toggle_editor_btn.text = "⚙️ 配置桌宠"

func _on_style_selected(index):
	current_style = "cute" if index == 0 else "bizarre"

func _on_part_selected(index):
	var selected_node = part_nodes[index]
	canvas.clear_canvas()
	if selected_node.texture:
		var img = selected_node.texture.get_image()
		if img:
			# Ensure image format is correct for updating
			img.convert(Image.FORMAT_RGBA8)
			img.resize(canvas.canvas_width, canvas.canvas_height, Image.INTERPOLATE_LANCZOS)
			canvas.image = img
			canvas._update_texture()

func _on_brush_color_changed(color):
	canvas.set_brush_color(color)

func _on_brush_size_changed(value):
	canvas.set_brush_size(value)

func _on_clear_btn_pressed():
	canvas.clear_canvas()

func _on_save_btn_pressed():
	var drawn_img = canvas.get_drawn_image()
	# Save a duplicate to avoid editing the reference directly
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
		# Update sprite texture
		var tex = ImageTexture.create_from_image(loaded_img)
		var selected_node = part_nodes[part_option.selected]
		selected_node.texture = tex
		
		# Also update drawing canvas image with imported texture
		canvas.clear_canvas()
		var img_for_canvas = Image.create_from_data(loaded_img.get_width(), loaded_img.get_height(), loaded_img.has_mipmaps(), loaded_img.get_format(), loaded_img.get_data())
		img_for_canvas.resize(canvas.canvas_width, canvas.canvas_height, Image.INTERPOLATE_LANCZOS)
		canvas.image = img_for_canvas
		canvas._update_texture()

func _tap_sound():
	pass

func _bark():
	pass
