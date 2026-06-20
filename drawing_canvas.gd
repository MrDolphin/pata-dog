extends Control
class_name DrawingCanvas

@export var canvas_width: int = 256
@export var canvas_height: int = 256

var brush_color: Color = Color.BLACK
var brush_size: float = 12.0
var drawing: bool = false
var last_mouse_pos: Vector2 = Vector2.ZERO

var image: Image
var texture: ImageTexture
var texture_rect: TextureRect

func _ready():
	custom_minimum_size = Vector2(canvas_width, canvas_height)
	
	# Checkerboard background (for visual transparency indication)
	var bg_panel = ColorRect.new()
	bg_panel.color = Color(0.2, 0.2, 0.2, 1.0)
	bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_panel)
	
	# Transparent image to draw on
	image = Image.create(canvas_width, canvas_height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0)) # transparent
	
	texture = ImageTexture.create_from_image(image)
	
	texture_rect = TextureRect.new()
	texture_rect.texture = texture
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(texture_rect)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drawing = true
				var pos = _get_canvas_pos(event.position)
				last_mouse_pos = pos
				draw_brush_point(pos)
				_update_texture()
			else:
				drawing = false
				
	elif event is InputEventMouseMotion and drawing:
		var pos = _get_canvas_pos(event.position)
		draw_brush_line(last_mouse_pos, pos)
		last_mouse_pos = pos
		_update_texture()

func _get_canvas_pos(gui_pos: Vector2) -> Vector2:
	# Map GUI coordinate to Image coordinate
	var scale_x = float(canvas_width) / size.x
	var scale_y = float(canvas_height) / size.y
	return Vector2(gui_pos.x * scale_x, gui_pos.y * scale_y)

func draw_brush_point(pos: Vector2):
	var radius = brush_size / 2.0
	var cx = int(pos.x)
	var cy = int(pos.y)
	
	# Draw circle
	for x in range(cx - int(radius), cx + int(radius) + 1):
		for y in range(cy - int(radius), cy + int(radius) + 1):
			if x >= 0 and x < canvas_width and y >= 0 and y < canvas_height:
				if Vector2(x - cx, y - cy).length() <= radius:
					image.set_pixel(x, y, brush_color)

func draw_brush_line(from: Vector2, to: Vector2):
	var dist = from.distance_to(to)
	var steps = int(dist)
	if steps < 1:
		draw_brush_point(to)
		return
	
	# Interpolate to make smooth strokes
	for i in range(steps + 1):
		var t = float(i) / steps
		var point = from.lerp(to, t)
		draw_brush_point(point)

func _update_texture():
	texture.update(image)

func clear_canvas():
	image.fill(Color(0, 0, 0, 0))
	_update_texture()

func set_brush_color(color: Color):
	brush_color = color

func set_brush_size(size_val: float):
	brush_size = size_val

func get_drawn_image() -> Image:
	return image

func load_external_image(img_path: String) -> bool:
	var loaded_img = Image.load_from_file(img_path)
	if loaded_img:
		loaded_img.resize(canvas_width, canvas_height, Image.INTERPOLATE_LANCZOS)
		image = loaded_img
		_update_texture()
		return true
	return false
