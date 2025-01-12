class_name RTSCamera2D extends Camera2D

@export_group("Zoom", "ZOOM_")
# These control the maximum zoom in and out levels. This means a maximum zoom in of 2x and a zoom out of 100x (0.01)
@export_range(0, 5, 0.01, "suffix:times", "hide_slider") var ZOOM_MAX: float = 2.0
@export_range(0, 5, 0.01, "suffix:times", "hide_slider") var ZOOM_MIN: float = 0.01
# Control how quickly we zoom in and out by a factor of
@export_range(1, 10, 0.5) var ZOOM_SPEED: float = 2
@export_range(0, 2, 0.1, "suffix:seconds") var ZOOM_TWEEN_DURATION : float = 0.3

# Zoom X and Y should be uniform so we only take the X.
# This controls our active zoom level for tweening
var zoom_level = zoom.x
var zoom_tween: Tween = null

@export_group("Pan", "PAN_")
# This controls how quickly we pan when using the keyboard (this scales based on zoom level).
@export_range(2.5, 20, 5) var PAN_KEYBOARD_MOVEMENT_SPEED: float = 10.0
# This controls how quickly we lerp to the new location based on where the mouse is on zoom in
@export var PAN_MOUSE_ZOOM_SPEED: float = 30.0
# What ratio of the mouse movement is translated into PAN movement? Increasing this increases the
# sensitivity of the mouse movement (a smaller mouse movement results in a larger camera movement).
@export_range(1, 5, 0.5, "suffix:ratio") var PAN_MOUSE_MOVEMENT_RATIO: float = 2.0

# Manage our mouse panning variables
var PAN_MOUSE_ACTIVE: bool = false
var PAN_MOUSE_POSITION: Vector2 = Vector2.ZERO

# Capture mouse click events
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
	if Input.is_action_just_pressed("ZOOM_OUT") or Input.is_action_just_pressed("ZOOM_IN"):
		if Input.is_action_just_pressed("ZOOM_OUT"):
			zoom_level = lerp(zoom_level, zoom_level / ZOOM_SPEED, delta * 20)
		elif Input.is_action_just_pressed("ZOOM_IN"):
			zoom_level = lerp(zoom_level, zoom_level * ZOOM_SPEED, delta * 20)
		
		# We limit the value between `min_zoom` and `max_zoom`
		zoom_level = clamp(zoom_level, ZOOM_MIN, ZOOM_MAX)
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

		# When we zoom in and out, we want to zoom centered on where the mouse pointer is. This
		# means shifting the view window towards the mouse position
		position = position.lerp(get_global_mouse_position(), delta * PAN_MOUSE_ZOOM_SPEED)

	# We also want to support window movement using the keyboard shortcuts
	var relative_pan: float = (PAN_KEYBOARD_MOVEMENT_SPEED * 100 / zoom_level) * delta
	if Input.is_action_pressed("UP"):
		position.y -= relative_pan
	if Input.is_action_pressed("DOWN"):
		position.y += relative_pan
	if Input.is_action_pressed("LEFT"):
		position.x -= relative_pan
	if Input.is_action_pressed("RIGHT"):
		position.x += relative_pan
