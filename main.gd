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

var use_left_paw = true
var excitement = 0.0

var dragging_window = false
var drag_offset = Vector2.ZERO

func _ready():
	_reset_paws()
	get_viewport().transparent_bg = true

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


func _tap_sound():
	pass

func _bark():
	pass
