extends Spatial

export(NodePath) var character;

export var sensibility : float = 0.2;  # Mouse sensitivity
export var captured : bool = true; # Does not let the mouse leave the screen
var zoom_sens_factor : float = 1.0 # Dynamic multiplier for optical sniper scope

func _ready():
	character = get_node(character);

func _physics_process(_delta) -> void:
	# Calls function to switch between locked and unlocked mouse
	_mouse_toggle();

func _mouse_toggle() -> void:
	if get_tree().paused:
		captured = false
		return
	
	if captured:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);

func _camera_rotation(_event) -> void:
	if get_tree().paused:
		return
	# If the mouse is locked
	if captured:
		var camera : Dictionary = {0: $".", 1: $"."};
		var current_sens = sensibility * zoom_sens_factor
		
		if _event is InputEventMouseMotion:
			# Rotates the camera on the x axis
			camera[0].rotation.x += -deg2rad(_event.relative.y * current_sens);
			
			# Rotates the camera on the y axis
			camera[1].rotation.y += -deg2rad(_event.relative.x * current_sens);
		
		# Creates a limit for the camera on the x axis
		var max_angle: int = 85; # Maximum camera angle
		camera[0].rotation.x = min(camera[0].rotation.x,  deg2rad(max_angle))
		camera[0].rotation.x = max(camera[0].rotation.x, -deg2rad(max_angle))

func rotate_by_relative(rel: Vector2) -> void:
	if get_tree().paused:
		return
	var current_sens = sensibility * zoom_sens_factor
	rotation.x += -deg2rad(rel.y * current_sens)
	rotation.y += -deg2rad(rel.x * current_sens)
	var max_angle: float = deg2rad(85.0)
	rotation.x = clamp(rotation.x, -max_angle, max_angle)

func _input(_event) -> void:
	# Calls the function to rotate the camera
	_camera_rotation(_event);
