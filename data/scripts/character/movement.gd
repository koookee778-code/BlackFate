extends KinematicBody

# All speed variables
var n_speed : float = 4.0; # Normal
var s_speed : float = 12.0; # Sprint
var w_speed : float = 7.0; # Walking
var c_speed : float = 10.0; # Crouch

# Physics variables
var gravity      : float = 50.0; # Gravity force
var jump_height  : float = 15.0; # Jump height
var friction     : float = 25.0; # friction

# All vectors
var velocity     := Vector3(); # Velocity vector
var direction    := Vector3(); # Direction Vector
var acceleration := Vector3(); # Acceleration Vector

# All character inputs
var input : Dictionary = {};

# Slide variables
var is_sliding : bool = false
var slide_timer : float = 0.0
var slide_max_time : float = 0.85
var slide_speed : float = 18.0
var slide_direction : Vector3 = Vector3()
var default_head_y : float = 3.0
var crouch_head_y : float = 1.7
var slide_head_y : float = 1.3
var prev_c_pressed : bool = false

# Health & Respawn (Lengthened for Zombie Survival)
var max_health : int = 250
var health : int = 250
var is_dead : bool = false
var death_timer : float = 0.0
var spawn_transform : Transform
var flashlight_node : SpotLight = null
var prev_f_pressed : bool = false

func _ready() -> void:
	# Lock solid 60 FPS for ultra-smooth gameplay like GTA
	Engine.target_fps = 60
	
	# Pre-populate all input keys to prevent any dictionary index errors
	input["left"] = 0
	input["right"] = 0
	input["foward"] = 0
	input["back"] = 0
	input["sprint"] = 0
	input["crouch"] = 0
	input["jump"] = 0
	
	add_to_group("character")
	# Safe Bunker coordinates: (0, 1.5, -60) facing North (+Z toward facility and moonlit grand hall)
	spawn_transform.origin = Vector3(0, 1.5, -60)
	spawn_transform.basis = Basis(Vector3.UP, PI)
	global_transform = spawn_transform

	# Tactical Military LED Flashlight
	var cam = get_node_or_null("head/neck/camera")
	if cam and not cam.has_node("flashlight"):
		flashlight_node = SpotLight.new()
		flashlight_node.name = "flashlight"
		flashlight_node.light_color = Color(1.0, 0.95, 0.88)
		flashlight_node.light_energy = 1.8
		flashlight_node.spot_range = 35.0
		flashlight_node.spot_angle = 48.0
		flashlight_node.spot_attenuation = 1.2
		flashlight_node.shadow_enabled = false
		cam.add_child(flashlight_node)

func _physics_process(_delta) -> void:
	if is_dead:
		death_timer -= _delta
		var hud = get_node_or_null("hud")
		if hud and hud.has_method("_update_death_countdown"):
			hud._update_death_countdown(death_timer)
		if death_timer <= 0.0:
			_respawn()
		return

	var f_pressed = Input.is_key_pressed(KEY_F)
	if f_pressed and not prev_f_pressed:
		if is_instance_valid(flashlight_node):
			flashlight_node.visible = not flashlight_node.visible
	prev_f_pressed = f_pressed
	
	_sprint(_delta);
	_movement(_delta);
	_crouch(_delta);
	_jump(_delta);

func _movement(_delta) -> void:
	input["left"]   = int(Input.is_action_pressed("KEY_A"));
	input["right"]  = int(Input.is_action_pressed("KEY_D"));
	input["foward"] = int(Input.is_action_pressed("KEY_W"));
	input["back"]   = int(Input.is_action_pressed("KEY_S"));
	
	if is_on_floor():
		direction = Vector3();
	else:
		direction = direction.linear_interpolate(Vector3(), friction * _delta);
		velocity.y += -gravity * _delta;
	
	var basis = $"head".global_transform.basis;
	direction += (-input["left"]   + input["right"]) * basis.x;
	direction += (-input["foward"] + input["back"])  * basis.z;
	direction.y = 0;
	if direction.length_squared() > 0.001:
		direction = direction.normalized()
	
	if is_sliding:
		slide_timer -= _delta
		slide_speed = lerp(slide_speed, w_speed, 2.5 * _delta)
		var slide_target = slide_direction * slide_speed
		velocity.x = slide_target.x
		velocity.z = slide_target.z
		
		# End sliding if timer runs out or user leaves floor
		if slide_timer <= 0.0 or not is_on_floor():
			is_sliding = false
	else:
		var target = direction * n_speed;
		target.y = 0;
		var temp_velocity = velocity.linear_interpolate(target, n_speed * _delta);
		velocity.x = temp_velocity.x;
		velocity.z = temp_velocity.z;
	
	velocity = move_and_slide(velocity, Vector3(0, 1, 0), false, 4, PI/4, false);

func _crouch(_delta) -> void:
	var c_key = Input.is_key_pressed(KEY_C)
	var ctrl_key = Input.is_action_pressed("KEY_CTRL") or Input.is_key_pressed(KEY_CONTROL)
	var crouch_pressed = ctrl_key or c_key
	var crouch_just_pressed = Input.is_action_just_pressed("KEY_CTRL") or (c_key and not prev_c_pressed)
	prev_c_pressed = c_key
	
	var head = $"head";
	var camera = head.get_node_or_null("neck/camera")
	
	# If sprinting or running fast, pressing C triggers Tactical Slide
	var is_sprinting = (Input.is_action_pressed("KEY_SHIFT") or input.get("sprint", 0) == 1) or (n_speed > (w_speed + 1.0)) or (Vector2(velocity.x, velocity.z).length() > (w_speed + 1.0))
	if crouch_just_pressed and is_on_floor() and not is_sliding:
		if is_sprinting:
			is_sliding = true
			slide_timer = slide_max_time
			slide_speed = 18.0
			slide_direction = direction
			if slide_direction.length_squared() < 0.1:
				slide_direction = -head.global_transform.basis.z
				slide_direction.y = 0
				slide_direction = slide_direction.normalized()
	
	# Slide ends when timer finishes or player leaves floor
	if is_sliding and (slide_timer <= 0.0 or not is_on_floor()):
		is_sliding = false
	
	# If not sliding, crouch is active while holding C or Ctrl
	var is_crouching = crouch_pressed and not is_sliding
	input["crouch"] = int(is_crouching or is_sliding)
	
	if not head.is_colliding():
		var collision = $"collision";
		
		if is_sliding:
			collision.shape.height = lerp(collision.shape.height, 0.5, 12.0 * _delta);
			head.translation.y = lerp(head.translation.y, slide_head_y, 12.0 * _delta);
			if camera:
				camera.rotation.z = lerp(camera.rotation.z, deg2rad(-4.0), 10.0 * _delta);
		elif is_crouching:
			collision.shape.height = lerp(collision.shape.height, 0.7, c_speed * _delta);
			head.translation.y = lerp(head.translation.y, crouch_head_y, c_speed * _delta);
			if camera:
				camera.rotation.z = lerp(camera.rotation.z, 0.0, 10.0 * _delta);
		else:
			collision.shape.height = lerp(collision.shape.height, 2.0, c_speed * _delta);
			head.translation.y = lerp(head.translation.y, default_head_y, c_speed * _delta);
			if camera:
				camera.rotation.z = lerp(camera.rotation.z, 0.0, 10.0 * _delta);

func _jump(_delta) -> void:
	input["jump"] = int(Input.is_action_pressed("KEY_SPACE"));
	
	if input["jump"]:
		if is_on_floor():
			if is_sliding:
				# Slide-Jump boost!
				velocity.y = jump_height * 1.05;
				velocity += slide_direction * 4.0;
				is_sliding = false;
			else:
				velocity.y = jump_height;

func _sprint(_delta) -> void:
	input["sprint"] = int(Input.is_action_pressed("KEY_SHIFT"));
	
	if not input["crouch"] and not is_sliding:
		var toggle_speed : float = w_speed + ((s_speed - w_speed) * input["sprint"])
		n_speed = lerp(n_speed, toggle_speed, 3 * _delta);
	else:
		n_speed = lerp(n_speed, w_speed * 0.5, 5 * _delta);

func _damage(amount: int) -> void:
	if is_dead:
		return
	
	health -= amount
	var hud = get_node_or_null("hud")
	if hud and hud.has_method("_damage_flash"):
		hud._damage_flash()
	
	if health <= 0:
		_die()

func _die() -> void:
	is_dead = true
	health = 0
	death_timer = 3.0 # Exactly 3 seconds death timer
	velocity = Vector3()
	is_sliding = false
	
	var weapons = find_node("weapons", true, false)
	if weapons:
		weapons.visible = false
	
	var hud = get_node_or_null("hud")
	if hud and hud.has_method("_show_death_screen"):
		hud._show_death_screen(death_timer)

func _respawn() -> void:
	is_dead = false
	health = max_health
	# Teleport player into Team 1 Base (facing +Z forward)
	global_transform = spawn_transform
	velocity = Vector3()
	is_sliding = false
	
	var weapons = find_node("weapons", true, false)
	if weapons:
		weapons.visible = true
	
	var hud = get_node_or_null("hud")
	if hud and hud.has_method("_hide_death_screen"):
		hud._hide_death_screen()
