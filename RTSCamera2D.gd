class_name RTSCamera2D extends Camera2D

@export_group("Zoom", "ZOOM_")
# These control the maximum zoom in and out levels. This means a maximum zoom in of 2x and a zoom out of 100x (0.01)
@export_range(0, 5, 0.01, "suffix:times", "hide_slider") var ZOOM_MAX: float = 2.0
@export_range(0, 5, 0.01, "suffix:times", "hide_slider") var ZOOM_MIN: float = 0.01
@export var ZOOM_SPEED: float = 0.03
@export_range(0, 2, 0.1, "suffix:seconds") var ZOOM_TWEEN_DURATION : float = 0.3

# Zoom X and Y should be uniform so we only take the X.
# This controls our active zoom level for tweening
var zoom_level = zoom.x
var zoom_tween: Tween = null

@export_group("Pan", "PAN_")
# This controls how quickly we pan when using the keyboard (this scales based on zoom level).
@export_range(0, 50, 1) var PAN_KEYBOARD_MOVEMENT_SPEED: float = 10.0
# This controls how quickly we lerp to the new location based on where the mouse is on zoom in
@export var PAN_ZOOM_SPEED: float = 30.0
# What ratio of the mouse movement is translated into PAN movement? Increasing this increases the
# sensitivity of the mouse movement.
@export_range(1, 5, 0.5, "suffix:ratio") var PAN_MOUSE_MOVEMENT_RATIO: float = 2.0

# Manage our mouse panning variables
var PAN_MOUSE_ACTIVE: bool = false
var PAN_MOUSE_POSITION: Vector2 = Vector2.ZERO

func _get_relative_pan_speed():
	return PAN_KEYBOARD_MOVEMENT_SPEED / zoom_level

func _set_zoom_level(value: float) -> void:
	# We limit the value between `min_zoom` and `max_zoom`
	zoom_level = clamp(value, ZOOM_MIN, ZOOM_MAX)
	# Then, we ask the tween node to animate the camera's `zoom` property from its current value
	# to the target zoom level.
	zoom_tween = create_tween()
	zoom_tween.tween_property(
		self,
		"zoom",
		Vector2(zoom_level, zoom_level),
		ZOOM_TWEEN_DURATION
	# Easing out means we start fast and slow down as we reach the target value.
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _set_zoom_location(delta):
	# Pan speed is used to determine who quickly we zoom into the new location
	position = position.lerp(get_global_mouse_position(), delta * PAN_ZOOM_SPEED)

func _input(event):
	# If we have a left mouse click and drag, we want to capture the relative movement so we can pan
	if event is InputEventMouseButton:
		if event.button_index == 1:
			PAN_MOUSE_POSITION = get_global_mouse_position()
			PAN_MOUSE_ACTIVE = event.pressed
	elif event is InputEventMouseMotion:
		if PAN_MOUSE_ACTIVE:
			position += (PAN_MOUSE_POSITION - get_global_mouse_position()) * PAN_MOUSE_MOVEMENT_RATIO
			PAN_MOUSE_POSITION = get_global_mouse_position()

func _physics_process(delta):
	# When we zoom in and out, we want to zoom centered on where the mouse pointer is. This means
	# shifting the view window towards the mouse position
	if Input.is_action_just_pressed("ZOOM_OUT"):
		_set_zoom_level(zoom_level - ZOOM_SPEED)
		_set_zoom_location(delta)
		
	if Input.is_action_just_pressed("ZOOM_IN"):
		_set_zoom_level(zoom_level + ZOOM_SPEED)
		_set_zoom_location(delta)

	# We also want to support window movement using the keyboard shortcuts
	if Input.is_action_pressed("UP"):
		position.y -= _get_relative_pan_speed()
	if Input.is_action_pressed("DOWN"):
		position.y += _get_relative_pan_speed()
	if Input.is_action_pressed("LEFT"):
		position.x -= _get_relative_pan_speed()
	if Input.is_action_pressed("RIGHT"):
		position.x += _get_relative_pan_speed()
