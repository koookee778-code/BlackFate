extends Spatial

# Get character's node path
export(NodePath) var character;

# Get head's node path
export(NodePath) var head;

# Get camera's node path
export(NodePath) var neck;

# Get camera's node path
export(NodePath) var camera;

# Load weapon class for make weapons
var weapon = load("res://data/scripts/weapon/weapon.gd");

# All weapons
var arsenal : Dictionary;

# Current weapon
var current : int = 0;
var prev_current : int = -1;

# Dict of inputs
var input : Dictionary = {};
var force_zoom : bool = false;

func _ready() -> void:
	set_as_toplevel(true);
	
	camera = get_node(camera);
	neck = get_node(neck);
	head = get_node(head);
	character = get_node(character);
	
	# Setup native Sniper weapon node under weapons
	_setup_sniper_weapon()
	
	# Class reference: owner, name, firerate, bullets, ammo, max_bullets, damage, reload_speed
	# [1] Glock 17
	arsenal["glock_17"] = weapon.weapon.new(self, "glock_17", 3.0, 12, 999, 12, 35, 1.2);
	
	# [2] Kriss Vector SMG
	arsenal["kriss"] = weapon.weapon.new(self, "kriss", 6.0, 32, 999, 33, 25, 1.5);
	
	# [3] Mk 23 Pistol
	arsenal["mk_23"] = weapon.weapon.new(self, "mk_23", 2.0, 12, 999, 12, 40, 1.2);
	
	# [4] Tactical Sniper Rifle (High Damage 110, 5 Round Mag, Fast Tactical Reload)
	arsenal["sniper"] = weapon.weapon.new(self, "sniper", 1.25, 5, 999, 5, 110, 1.5);
	
	for w in arsenal:
		arsenal.values()[current]._hide();

func _setup_sniper_weapon() -> void:
	if has_node("sniper"):
		return
	var sniper_root = Spatial.new()
	sniper_root.name = "sniper"
	sniper_root.visible = false
	add_child(sniper_root)
	
	# Raycast
	var ray = RayCast.new()
	ray.name = "ray"
	ray.enabled = true
	ray.cast_to = Vector3(0, 0, -350)
	sniper_root.add_child(ray)
	
	# Barrel
	var barrel = Position3D.new()
	barrel.name = "barrel"
	barrel.translation = Vector3(0.088, -0.05, -1.1)
	sniper_root.add_child(barrel)
	
	# Audio
	var audio = Spatial.new()
	audio.name = "audio"
	sniper_root.add_child(audio)
	
	var aud_shoot = AudioStreamPlayer3D.new()
	aud_shoot.name = "shoot"
	aud_shoot.stream = load("res://data/audios/weapons/sniper/fire.ogg")
	aud_shoot.unit_db = 8.0
	aud_shoot.pitch_scale = 1.0
	audio.add_child(aud_shoot)
	
	var aud_reload = AudioStreamPlayer3D.new()
	aud_reload.name = "reload"
	aud_reload.stream = load("res://data/audios/weapons/sniper/reload.ogg")
	audio.add_child(aud_reload)
	
	var aud_draw = AudioStreamPlayer3D.new()
	aud_draw.name = "draw"
	aud_draw.stream = load("res://data/audios/weapons/sniper/draw.ogg")
	audio.add_child(aud_draw)
	
	var aud_out = AudioStreamPlayer3D.new()
	aud_out.name = "out"
	aud_out.stream = load("res://data/audios/weapons/sniper/out.ogg")
	audio.add_child(aud_out)
	
	# Effects
	var effect = Spatial.new()
	effect.name = "effect"
	sniper_root.add_child(effect)
	
	var light = OmniLight.new()
	light.name = "shoot"
	light.light_energy = 0.0
	light.light_color = Color(1.0, 0.75, 0.3)
	effect.add_child(light)
	
	var glock_effect = get_node_or_null("glock_17/effect")
	if glock_effect:
		var fire_p = glock_effect.get_node("fire").duplicate()
		effect.add_child(fire_p)
		var smoke_p = glock_effect.get_node("smoke").duplicate()
		effect.add_child(smoke_p)
	
	# Mesh Root duplicated directly from kriss/mesh to inherit exact tactical gloved arms and animations
	var kriss_mesh = get_node_or_null("kriss/mesh")
	var mesh = null
	if kriss_mesh:
		mesh = kriss_mesh.duplicate()
		mesh.name = "mesh"
		sniper_root.add_child(mesh)
		
		var skel = mesh.find_node("Skeleton", true, false)
		if skel:
			# Keep First-Person Hands and Tactical Gloves 100% VISIBLE!
			var m_hand = skel.get_node_or_null("Mesh")
			if m_hand: m_hand.visible = true
			var m_glove = skel.get_node_or_null("Mesh 2")
			if m_glove: m_glove.visible = true
			# Hide ONLY the submachine gun parts
			var m_gun = skel.get_node_or_null("Mesh 3")
			if m_gun: m_gun.visible = false
			var m_mag = skel.get_node_or_null("Mesh 4")
			if m_mag: m_mag.visible = false
			
			# Attach 3D Sniper Rifle model securely to the player's weapon bone (main_j_2)
			var bone_att = BoneAttachment.new()
			bone_att.name = "SniperMount"
			bone_att.bone_name = "main_j_2"
			skel.add_child(bone_att)
			
			var sniper_scene = load("res://data/models/weapons/sniper/sniper.tscn")
			if sniper_scene:
				var sniper_model = sniper_scene.instance()
				sniper_model.name = "model"
				sniper_model.scale = Vector3(-9.5, 9.5, -9.5)
				sniper_model.translation = Vector3(2.5, 1.2, 12.0)
				sniper_model.rotation_degrees = Vector3(4, 90, 0)
				bone_att.add_child(sniper_model)

func _physics_process(_delta) -> void:
	_weapon(_delta);
	_change();
	_position(_delta);

func _weapon(_delta) -> void:
	input["shoot"] = int(Input.is_action_pressed("mb_left") or Input.is_action_pressed("fire"));
	input["reload"] = int(Input.is_action_pressed("KEY_R") or Input.is_action_pressed("reload"));
	input["zoom"] = int(Input.is_action_pressed("mb_right") or Input.is_action_pressed("aim") or force_zoom);
	
	var current_weapon = arsenal.values()[current]
	current_weapon._sprint(character.input["sprint"] or character.input["jump"], _delta);
	
	if not character.input["sprint"] or not character.direction:
		# BLOCK SHOOTING IF RELOADING!
		if not current_weapon.is_reloading and current_weapon.animc != "Reload":
			if input["shoot"]:
				current_weapon._shoot(_delta);
		
		current_weapon._zoom(input["zoom"], _delta);
	
	if input["reload"]:
		current_weapon._reload();
	
	# Update arsenal
	for w in range(arsenal.size()):
		arsenal.values()[w]._update(_delta);

func _change() -> void:
	if current == prev_current:
		return
	prev_current = current
	for w in range(arsenal.size()):
		if arsenal.values()[w] != arsenal.values()[current]:
			arsenal.values()[w]._hide();
		else:
			arsenal.values()[w]._draw();

func _position(_delta) -> void:
	var y_lerp = 20;
	var x_lerp = 40;
	
	global_transform.origin = head.global_transform.origin;
	
	if not input["zoom"]:
		rotation.x = lerp_angle(rotation.x, camera.global_transform.basis.get_euler().x, y_lerp * _delta);
		rotation.y = lerp_angle(rotation.y, camera.global_transform.basis.get_euler().y, x_lerp * _delta);
	else:
		rotation = camera.global_transform.basis.get_euler();

func _unhandled_input(event):
	var current_weapon = arsenal.values()[current]
	# BLOCK SWITCHING IF WEAPON IS CURRENTLY RELOADING!
	if current_weapon.is_reloading or current_weapon.animc == "Reload":
		return
	
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_1:
			current = 0;
		elif event.scancode == KEY_2:
			current = 1;
		elif event.scancode == KEY_3:
			current = 2;
		elif event.scancode == KEY_4:
			current = 3;
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_WHEEL_UP:
			current = (current - 1 + arsenal.size()) % arsenal.size();
		elif event.button_index == BUTTON_WHEEL_DOWN:
			current = (current + 1) % arsenal.size();
