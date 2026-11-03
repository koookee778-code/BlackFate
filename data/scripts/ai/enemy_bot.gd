extends KinematicBody

# ============================================================
#  ZOMBIE BOT — High-Performance Realistic Undead AI
#  Smooth 60 FPS on Intel HD Graphics
# ============================================================

enum AIState {
	PATROL,
	SEARCH_LAST_KNOWN,
	COMBAT
}

export var bot_name      : String  = "Zombie"
export var weapon_type   : String  = "runner"
export var is_boss       : bool    = false
export var max_health    : int     = 180
var health               : int     = 180

export var attack_range    : float = 2.4
export var max_vision_dist : float = 55.0
export var move_speed      : float = 3.6
export var fire_interval   : float = 1.1
export var damage_per_shot : int   = 22

export var base_spawn_pos   : Vector3 = Vector3(0, 0.5, -20.0)
export var base_spawn_rot_y : float   = 180.0

# ---- State ----
var current_state         : int     = AIState.PATROL
var last_known_player_pos : Vector3 = Vector3.ZERO
var search_timer          : float   = 0.0
var patrol_target         : Vector3 = Vector3.ZERO
var patrol_wait_timer     : float   = 0.0
var has_direct_los        : bool    = false

var fire_timer            : float   = 0.0
var flash_timer           : float   = 0.0
var hit_flash_timer       : float   = 0.0
var respawn_timer         : float   = 0.0
var is_dead               : bool    = false
var groan_timer           : float   = 3.0
var frame_offset          : int     = 0

# ---- Physics ----
var player_ref       : Spatial  = null
var gravity          : float    = 35.0
var velocity         : Vector3  = Vector3()
var is_melee_zombie  : bool     = true
var frame_counter    : int      = 0
var walk_cycle_time  : float    = 0.0

# ---- Nodes ----
onready var muzzle_pos      : Position3D          = $muzzle
onready var muzzle_light    : OmniLight           = $muzzle/light
onready var shoot_sound     : AudioStreamPlayer3D = $audio_shoot
onready var hit_sound       : AudioStreamPlayer3D = $audio_hit
onready var die_sound       : AudioStreamPlayer3D = $audio_die
onready var los_ray         : RayCast             = $los_ray
onready var health_fill     : Spatial             = $health_bar/bar_fill
onready var collision_shape : CollisionShape      = $collision
onready var soldier_node    : Spatial             = $soldier
onready var weapon_mount    : Spatial             = $weapon_mount

# ---- Zombie Model & Animations ----
var anim_player      : AnimationPlayer = null
var zombie_anim_name : String          = ""
var body_meshes      : Array           = []
var skel             : Skeleton        = null
var head_bone_idx    : int             = -1
var r_arm_bone_idx   : int             = -1
var r_forearm_bone_idx : int           = -1
var r_hand_bone_idx  : int             = -1
var l_arm_bone_idx   : int             = -1
var l_forearm_bone_idx : int           = -1
var l_hand_bone_idx  : int             = -1
var spine_bone_idx   : int             = -1

# ---- Real Zombie Melee Attack Animation ----
var attack_anim_timer    : float = 0.0
var attack_anim_duration : float = 0.52
var attack_anim_variant  : int   = 0
var attack_hit_dealt     : bool  = false
var boss_roar_cooldown   : float = 8.0

# ---- Audio pools ----
var audio_groan  : AudioStreamPlayer3D = null
var audio_roar   : AudioStreamPlayer3D = null
var audio_attack : AudioStreamPlayer3D = null

var groan_streams       = []
var roar_streams        = []
var attack_streams      = []
var die_streams         = []
var boss_roar_stream    = null
var boss_berserk_stream = null

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("prop")
	add_to_group("cullable")

	randomize()
	frame_offset = randi() % 5
	groan_timer = rand_range(2.0, 5.0)

	_setup_zombie_audio()
	_setup_zombie_model()
	_setup_zombie_class()
	_optimize_meshes()

	if base_spawn_pos != Vector3.ZERO:
		global_transform.origin = base_spawn_pos
		rotation_degrees.y = base_spawn_rot_y

	_mount_weapon_model()
	_pick_new_patrol_target()
	health = max_health

# ============================================================
#  ZOMBIE MODEL SETUP (Real 3D Zombie with embedded textures)
# ============================================================
func _setup_zombie_model() -> void:
	if not soldier_node:
		return

	# Find AnimationPlayer and Skeleton by class type
	var search_stack = [soldier_node]
	while search_stack.size() > 0:
		var c = search_stack.pop_back()
		if not anim_player and c is AnimationPlayer:
			anim_player = c
		if not skel and c is Skeleton:
			skel = c
		for ch in c.get_children():
			search_stack.append(ch)

	if anim_player:
		var anims = anim_player.get_animation_list()
		if anims.size() > 0:
			zombie_anim_name = anims[0]
			var a = anim_player.get_animation(zombie_anim_name)
			if a:
				a.loop = true
			anim_player.playback_speed = 1.2
			anim_player.play(zombie_anim_name)

	if skel:
		head_bone_idx = skel.find_bone("mixamorig_Head_06")
		if head_bone_idx < 0:
			head_bone_idx = skel.find_bone("mixamorig:Head_06")

		r_arm_bone_idx = skel.find_bone("mixamorig_RightArm_033")
		r_forearm_bone_idx = skel.find_bone("mixamorig_RightForeArm_034")
		r_hand_bone_idx = skel.find_bone("mixamorig_RightHand_035")

		l_arm_bone_idx = skel.find_bone("mixamorig_LeftArm_09")
		l_forearm_bone_idx = skel.find_bone("mixamorig_LeftForeArm_010")
		l_hand_bone_idx = skel.find_bone("mixamorig_LeftHand_011")

		spine_bone_idx = skel.find_bone("mixamorig_Spine1_03")
		if spine_bone_idx < 0:
			spine_bone_idx = skel.find_bone("mixamorig_Spine_02")

	# Collect all mesh instances
	body_meshes.clear()
	_collect_meshes(soldier_node)

func get_head_global_pos() -> Vector3:
	if skel and head_bone_idx >= 0:
		var bone_pose = skel.get_bone_global_pose(head_bone_idx)
		return skel.global_transform.xform(bone_pose.origin) + Vector3(0, 0.12 * scale.y, 0)
	return global_transform.origin + Vector3(0, 1.78 * scale.y, 0)

func _collect_meshes(node: Node) -> void:
	if node is MeshInstance:
		body_meshes.append(node)
	for child in node.get_children():
		_collect_meshes(child)

# Turn off shadows on zombie geometry for maximum Intel HD 60 FPS
func _optimize_meshes() -> void:
	for mi in body_meshes:
		if is_instance_valid(mi):
			(mi as MeshInstance).cast_shadow = 0

# ============================================================
#  ZOMBIE AUDIO (OGG with binary buffer loader)
# ============================================================
func _setup_zombie_audio() -> void:
	audio_groan = AudioStreamPlayer3D.new()
	audio_groan.name = "audio_groan"
	audio_groan.unit_db = 4.5
	audio_groan.max_distance = 40.0
	add_child(audio_groan)

	for p in [
		"res://data/audios/zombie/zombie_groan_1.ogg",
		"res://data/audios/zombie/zombie_groan_2.ogg",
		"res://data/audios/zombie/zombie_groan_3.ogg",
		"res://data/audios/zombie/zombie_groan.ogg"
	]:
		var s = _load_ogg(p)
		if s: groan_streams.append(s)

	audio_roar = AudioStreamPlayer3D.new()
	audio_roar.name = "audio_roar"
	audio_roar.unit_db = 6.5
	audio_roar.max_distance = 55.0
	add_child(audio_roar)

	for p in [
		"res://data/audios/zombie/zombie_roar_1.ogg",
		"res://data/audios/zombie/zombie_roar_2.ogg",
		"res://data/audios/zombie/zombie_roar.ogg"
	]:
		var s = _load_ogg(p)
		if s: roar_streams.append(s)

	audio_attack = AudioStreamPlayer3D.new()
	audio_attack.name = "audio_attack"
	audio_attack.unit_db = 6.0
	audio_attack.max_distance = 35.0
	add_child(audio_attack)

	for p in [
		"res://data/audios/zombie/zombie_attack_1.ogg",
		"res://data/audios/zombie/zombie_attack_2.ogg",
		"res://data/audios/zombie/zombie_attack.ogg"
	]:
		var s = _load_ogg(p)
		if s: attack_streams.append(s)

	for p in [
		"res://data/audios/zombie/zombie_die_1.ogg",
		"res://data/audios/zombie/zombie_die_2.ogg",
		"res://data/audios/zombie/zombie_die.ogg"
	]:
		var s = _load_ogg(p)
		if s: die_streams.append(s)

	boss_roar_stream    = _load_ogg("res://data/audios/zombie/boss_roar.ogg")
	boss_berserk_stream = _load_ogg("res://data/audios/zombie/boss_berserk.ogg")

func _load_ogg(path: String) -> AudioStreamOGGVorbis:
	var f = File.new()
	if f.open(path, File.READ) == OK:
		var s = AudioStreamOGGVorbis.new()
		s.data = f.get_buffer(f.get_len())
		f.close()
		return s
	return null

# ============================================================
#  ZOMBIE CLASS SETUP
# ============================================================
func _setup_zombie_class() -> void:
	if is_boss:
		bot_name = "GOLIATH TITAN"
		max_health = 2500
		health = 2500
		move_speed = 4.2
		attack_range = 4.2
		damage_per_shot = 60
		fire_interval = 1.0
		is_melee_zombie = true
		scale = Vector3(2.3, 2.3, 2.3) # Massive Boss size
		if anim_player:
			anim_player.playback_speed = 0.9
		_tint_boss()
		return

	match weapon_type:
		"runner":
			bot_name = "Ghoul Runner"
			max_health = 160
			move_speed = 6.2
			attack_range = 2.4
			damage_per_shot = 20
			fire_interval = 0.85
			is_melee_zombie = true
			scale = Vector3(1.15, 1.15, 1.15)
			if anim_player:
				anim_player.playback_speed = 1.7
		"vector":
			bot_name = "Infected Slasher"
			max_health = 190
			move_speed = 5.0
			attack_range = 2.4
			damage_per_shot = 22
			fire_interval = 0.75
			is_melee_zombie = true
			scale = Vector3(1.2, 1.2, 1.2)
			if anim_player:
				anim_player.playback_speed = 1.5
		"stalker":
			bot_name = "Shadow Stalker"
			max_health = 220
			move_speed = 5.2
			attack_range = 2.5
			damage_per_shot = 28
			fire_interval = 0.95
			is_melee_zombie = true
			scale = Vector3(1.3, 1.3, 1.3)
			if anim_player:
				anim_player.playback_speed = 1.4
		"brute":
			bot_name = "Goliath Mutant"
			max_health = 360
			move_speed = 3.4
			attack_range = 3.2
			damage_per_shot = 42
			fire_interval = 1.2
			is_melee_zombie = true
			scale = Vector3(1.6, 1.6, 1.6)
			if anim_player:
				anim_player.playback_speed = 1.05

func _tint_boss() -> void:
	# Demonic red glowing tint for the boss
	for mi in body_meshes:
		if is_instance_valid(mi) and mi.mesh:
			var mat = mi.mesh.surface_get_material(0)
			if mat is SpatialMaterial:
				mat.albedo_color = Color(1.0, 0.45, 0.45)
				mat.emission_enabled = true
				mat.emission = Color(0.8, 0.05, 0.05)
				mat.emission_energy = 2.0
				
	if not has_node("boss_eyes"):
		var eyes = Spatial.new()
		eyes.name = "boss_eyes"
		add_child(eyes)
		eyes.translation = Vector3(0, 1.85, -0.2)
		
		var eye_light = OmniLight.new()
		eye_light.light_color = Color(1.0, 0.05, 0.05)
		eye_light.light_energy = 3.5
		eye_light.omni_range = 6.0
		eye_light.shadow_enabled = false
		eyes.add_child(eye_light)

func _flash_hit_mat() -> void:
	var flash_mat = SpatialMaterial.new()
	flash_mat.albedo_color = Color(1.0, 0.1, 0.05)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0, 0.1, 0.05)
	flash_mat.emission_energy = 2.5
	for mi in body_meshes:
		if is_instance_valid(mi):
			(mi as MeshInstance).material_override = flash_mat

func _clear_hit_mat() -> void:
	# Restore realistic high-resolution embedded textures
	for mi in body_meshes:
		if is_instance_valid(mi):
			(mi as MeshInstance).material_override = null

# ============================================================
#  WEAPON MOUNT (Gunner only)
# ============================================================
func _mount_weapon_model() -> void:
	if not weapon_mount:
		return
	for c in weapon_mount.get_children():
		c.queue_free()

	if is_melee_zombie:
		weapon_mount.visible = false
		return

	weapon_mount.visible = true
	var mat = SpatialMaterial.new()
	mat.albedo_color = Color(0.18, 0.18, 0.18)
	mat.metallic = 0.4
	mat.roughness = 0.6

	var gun = Spatial.new()
	gun.name = "gun_model"
	weapon_mount.add_child(gun)

	var b = MeshInstance.new()
	var c = CubeMesh.new()
	c.size = Vector3(0.09, 0.18, 0.44)
	c.material = mat
	b.mesh = c
	b.translation = Vector3(0, 0, -0.16)
	gun.add_child(b)

func _pick_new_patrol_target() -> void:
	patrol_target = Vector3(
		rand_range(-12.0, 12.0),
		global_transform.origin.y,
		rand_range(-50.0, 30.0)
	)
	patrol_wait_timer = 0.0

# ============================================================
#  MAIN PHYSICS PROCESS (60 FPS)
# ============================================================
func _physics_process(delta: float) -> void:
	if is_dead:
		if not is_boss:
			respawn_timer -= delta
			if respawn_timer <= 0.0:
				var sp = get_tree().get_root().find_node("zombie_spawner", true, false)
				if not sp:
					_respawn()
		return

	frame_counter += 1
	walk_cycle_time += delta

	# ---- Boss HUD update ----
	if is_boss and is_instance_valid(player_ref):
		var hud = player_ref.get_node_or_null("hud")
		if hud and hud.has_method("_update_boss_health"):
			hud._update_boss_health(health, max_health)

	# ---- Procedural Shambling Lean ----
	if soldier_node and soldier_node.visible:
		var h_spd = Vector2(velocity.x, velocity.z).length()
		if h_spd > 0.4:
			soldier_node.rotation_degrees.x = lerp(soldier_node.rotation_degrees.x, 12.0 + sin(walk_cycle_time * 5.0) * 3.5, 5.0 * delta)
			soldier_node.rotation_degrees.z = lerp(soldier_node.rotation_degrees.z, sin(walk_cycle_time * 3.8) * 6.0, 4.0 * delta)
		else:
			soldier_node.rotation_degrees.x = lerp(soldier_node.rotation_degrees.x, 6.0 + sin(walk_cycle_time * 1.5) * 1.5, 3.0 * delta)
			soldier_node.rotation_degrees.z = lerp(soldier_node.rotation_degrees.z, sin(walk_cycle_time * 1.0) * 2.0, 2.0 * delta)

	# ---- Groans ----
	groan_timer -= delta
	if groan_timer <= 0.0:
		groan_timer = rand_range(3.5, 7.5)
		if audio_groan and groan_streams.size() > 0 and randf() < 0.7:
			audio_groan.stream = groan_streams[randi() % groan_streams.size()]
			audio_groan.pitch_scale = rand_range(0.85, 1.15)
			audio_groan.play()

	# ---- Timers ----
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and muzzle_light:
			muzzle_light.light_energy = 0.0

	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0.0:
			_clear_hit_mat()

	if fire_timer > 0.0:
		fire_timer -= delta

	# ---- Procedural Arm Melee Attack Animation ----
	if attack_anim_timer > 0.0:
		attack_anim_timer -= delta
		var prog = clamp(1.0 - (attack_anim_timer / attack_anim_duration), 0.0, 1.0)
		_update_attack_arm_animation(prog)
		if attack_anim_timer <= 0.0:
			_reset_attack_arm_animation()

	# ---- Giant Titan Boss Periodic Roars ----
	if is_boss and not is_dead:
		boss_roar_cooldown -= delta
		if boss_roar_cooldown <= 0.0:
			boss_roar_cooldown = rand_range(8.0, 14.0)
			_play_boss_roar()

	# ---- Find player ----
	if not is_instance_valid(player_ref):
		_find_player()

	# ---- AI line of sight check (staggered every 4 frames) ----
	if (frame_counter + frame_offset) % 4 == 0:
		_check_line_of_sight()

	# ---- AI State Machine ----
	_execute_behavior(delta)

	# ---- Physics Gravity ----
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.5

	velocity = move_and_slide(velocity, Vector3.UP)
	_update_animation()
	_update_health_bar()

# ============================================================
#  FIND PLAYER
# ============================================================
func _find_player() -> void:
	var chars = get_tree().get_nodes_in_group("character")
	for c in chars:
		if c.name == "character" or c.is_in_group("character"):
			player_ref = c
			return
	player_ref = get_node_or_null("../character")

# ============================================================
#  LINE OF SIGHT
# ============================================================
func _check_line_of_sight() -> void:
	if not is_instance_valid(player_ref):
		has_direct_los = false
		return

	if player_ref.get("is_dead") == true or player_ref.get("health") <= 0:
		has_direct_los = false
		current_state = AIState.PATROL
		return

	var my_pos      = global_transform.origin
	var player_pos  = player_ref.global_transform.origin
	var dist        = my_pos.distance_to(player_pos)
	var close_sense = (dist < 12.0)

	if dist > max_vision_dist and not close_sense:
		has_direct_los = false
		return

	if not close_sense:
		var fwd = -global_transform.basis.z.normalized()
		var dir_to_p = (player_pos - my_pos).normalized()
		if rad2deg(fwd.angle_to(dir_to_p)) > 75.0:
			has_direct_los = false
			return

	if los_ray:
		var eye = my_pos + Vector3(0, 1.6 * scale.y, 0)
		los_ray.global_transform.origin = eye
		los_ray.cast_to = los_ray.to_local(player_pos + Vector3(0, 1.2, 0))
		los_ray.force_raycast_update()

		if los_ray.is_colliding():
			var col = los_ray.get_collider()
			if col == player_ref:
				var was_combat = (current_state == AIState.COMBAT)
				has_direct_los = true
				last_known_player_pos = player_pos
				current_state = AIState.COMBAT
				search_timer  = 8.0

				if not was_combat and audio_roar and roar_streams.size() > 0:
					if is_boss and boss_roar_stream:
						audio_roar.stream = boss_roar_stream
						audio_roar.unit_db = 12.0
					else:
						audio_roar.stream = roar_streams[randi() % roar_streams.size()]
						audio_roar.pitch_scale = rand_range(0.9, 1.1)
					audio_roar.play()
			else:
				has_direct_los = false
		else:
			has_direct_los = true
			current_state = AIState.COMBAT

# ============================================================
#  BEHAVIOR FSM
# ============================================================
func _execute_behavior(delta: float) -> void:
	var my_pos = global_transform.origin

	match current_state:
		AIState.COMBAT:
			if not is_instance_valid(player_ref):
				current_state = AIState.PATROL
				return

			var pp   = player_ref.global_transform.origin
			var dist = my_pos.distance_to(pp)

			if has_direct_los:
				var look_t = Vector3(pp.x, my_pos.y, pp.z)
				if my_pos.distance_to(look_t) > 0.1:
					var tf = global_transform.looking_at(look_t, Vector3.UP)
					global_transform.basis = global_transform.basis.orthonormalized().slerp(tf.basis.orthonormalized(), clamp(8.0 * delta, 0.0, 1.0))

				var dir = (pp - my_pos)
				dir.y = 0
				if dir.length_squared() > 0.01:
					dir = dir.normalized()

				velocity.x = dir.x * move_speed
				velocity.z = dir.z * move_speed
				if dist <= attack_range and fire_timer <= 0.0:
					_melee_attack(pp)
			else:
				current_state = AIState.SEARCH_LAST_KNOWN

		AIState.SEARCH_LAST_KNOWN:
			search_timer -= delta
			if search_timer <= 0.0 or last_known_player_pos == Vector3.ZERO:
				current_state = AIState.PATROL
				_pick_new_patrol_target()
				return

			var look_t = Vector3(last_known_player_pos.x, my_pos.y, last_known_player_pos.z)
			if my_pos.distance_to(look_t) > 0.2:
				var tf = global_transform.looking_at(look_t, Vector3.UP)
				global_transform.basis = global_transform.basis.orthonormalized().slerp(tf.basis.orthonormalized(), clamp(5.0 * delta, 0.0, 1.0))

			var mv = (last_known_player_pos - my_pos)
			mv.y = 0
			if mv.length_squared() > 1.5:
				mv = mv.normalized()
				velocity.x = mv.x * move_speed
				velocity.z = mv.z * move_speed
			else:
				velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
				velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
				if search_timer < 2.0:
					current_state = AIState.PATROL
					_pick_new_patrol_target()

		AIState.PATROL:
			if patrol_wait_timer > 0.0:
				patrol_wait_timer -= delta
				velocity.x = lerp(velocity.x, 0.0, 4.0 * delta)
				velocity.z = lerp(velocity.z, 0.0, 4.0 * delta)
				return

			var diff = (patrol_target - my_pos)
			diff.y = 0
			if diff.length() < 2.0:
				patrol_wait_timer = rand_range(1.5, 3.5)
				_pick_new_patrol_target()
			else:
				var mv = diff.normalized()
				velocity.x = mv.x * (move_speed * 0.5)
				velocity.z = mv.z * (move_speed * 0.5)
				var lt = my_pos + mv * 5.0
				var tf = global_transform.looking_at(lt, Vector3.UP)
				global_transform.basis = global_transform.basis.orthonormalized().slerp(tf.basis.orthonormalized(), clamp(4.0 * delta, 0.0, 1.0))

# ============================================================
#  ATTACKS
# ============================================================
func _melee_attack(target_pos: Vector3) -> void:
	fire_timer = fire_interval
	attack_anim_timer = attack_anim_duration
	attack_hit_dealt = false

	if is_boss:
		attack_anim_variant = randi() % 3
	else:
		attack_anim_variant = randi() % 2

	if audio_attack:
		if is_boss and boss_berserk_stream and randf() < 0.6:
			audio_attack.stream = boss_berserk_stream
			audio_attack.unit_db = 11.0
		elif attack_streams.size() > 0:
			audio_attack.stream = attack_streams[randi() % attack_streams.size()]
			audio_attack.pitch_scale = rand_range(0.85, 1.15)
		audio_attack.play()

	var lunge = (target_pos - global_transform.origin).normalized()
	velocity.x += lunge.x * (6.0 if is_boss else 4.5)
	velocity.z += lunge.z * (6.0 if is_boss else 4.5)

func _update_attack_arm_animation(progress: float) -> void:
	if not skel:
		return

	var r_arm_tf = Transform.IDENTITY
	var r_forearm_tf = Transform.IDENTITY
	var l_arm_tf = Transform.IDENTITY
	var l_forearm_tf = Transform.IDENTITY
	var spine_tf = Transform.IDENTITY

	if progress < 0.35:
		# Phase 1: Wind-up (pull arm back and raise claws high)
		var w = progress / 0.35
		var ease_w = sin(w * PI * 0.5)
		if attack_anim_variant == 0:
			r_arm_tf.basis = Basis(Vector3(1, 0, 0), -deg2rad(55.0 * ease_w)) * Basis(Vector3(0, 1, 0), deg2rad(40.0 * ease_w)) * Basis(Vector3(0, 0, 1), -deg2rad(30.0 * ease_w))
			r_forearm_tf.basis = Basis(Vector3(1, 0, 0), -deg2rad(60.0 * ease_w))
			spine_tf.basis = Basis(Vector3(0, 1, 0), -deg2rad(15.0 * ease_w))
		elif attack_anim_variant == 1:
			l_arm_tf.basis = Basis(Vector3(1, 0, 0), -deg2rad(55.0 * ease_w)) * Basis(Vector3(0, 1, 0), -deg2rad(40.0 * ease_w)) * Basis(Vector3(0, 0, 1), deg2rad(30.0 * ease_w))
			l_forearm_tf.basis = Basis(Vector3(1, 0, 0), -deg2rad(60.0 * ease_w))
			spine_tf.basis = Basis(Vector3(0, 1, 0), deg2rad(15.0 * ease_w))
		else:
			var pitch = -deg2rad(70.0 * ease_w)
			r_arm_tf.basis = Basis(Vector3(1, 0, 0), pitch) * Basis(Vector3(0, 0, 1), -deg2rad(25.0 * ease_w))
			r_forearm_tf.basis = Basis(Vector3(1, 0, 0), -deg2rad(50.0 * ease_w))
			l_arm_tf.basis = Basis(Vector3(1, 0, 0), pitch) * Basis(Vector3(0, 0, 1), deg2rad(25.0 * ease_w))
			l_forearm_tf.basis = Basis(Vector3(1, 0, 0), -deg2rad(50.0 * ease_w))
			spine_tf.basis = Basis(Vector3(1, 0, 0), deg2rad(18.0 * ease_w))

	elif progress <= 0.65:
		# Phase 2: Violent forward claw swipe / Titan ground slam
		var s = (progress - 0.35) / 0.30
		var strike_power = sin(s * PI)

		# Strike impact connects at apex of swing
		if s >= 0.35 and not attack_hit_dealt:
			attack_hit_dealt = true
			if is_instance_valid(player_ref) and player_ref.has_method("_damage"):
				var dist = global_transform.origin.distance_to(player_ref.global_transform.origin)
				if dist <= attack_range + 0.9:
					player_ref._damage(damage_per_shot)
					_play_impact_flesh_sound()
					if is_boss and player_ref.has_node("head/neck/camera"):
						var cam = player_ref.get_node("head/neck/camera")
						if "shake_force" in cam:
							cam.shake_force = 0.025
							cam.shake_time = 0.35

		if attack_anim_variant == 0:
			var sweep_pitch = deg2rad(45.0) - deg2rad(90.0 * s)
			var sweep_yaw = deg2rad(30.0) - deg2rad(70.0 * s)
			r_arm_tf.basis = Basis(Vector3(1, 0, 0), sweep_pitch) * Basis(Vector3(0, 1, 0), sweep_yaw) * Basis(Vector3(0, 0, 1), deg2rad(25.0))
			r_forearm_tf.basis = Basis(Vector3(1, 0, 0), -deg2rad(40.0 * strike_power))
			spine_tf.basis = Basis(Vector3(0, 1, 0), deg2rad(20.0 * s)) * Basis(Vector3(1, 0, 0), -deg2rad(15.0 * strike_power))
		elif attack_anim_variant == 1:
			var sweep_pitch = deg2rad(45.0) - deg2rad(90.0 * s)
			var sweep_yaw = -deg2rad(30.0) + deg2rad(70.0 * s)
			l_arm_tf.basis = Basis(Vector3(1, 0, 0), sweep_pitch) * Basis(Vector3(0, 1, 0), sweep_yaw) * Basis(Vector3(0, 0, 1), -deg2rad(25.0))
			l_forearm_tf.basis = Basis(Vector3(1, 0, 0), -deg2rad(40.0 * strike_power))
			spine_tf.basis = Basis(Vector3(0, 1, 0), -deg2rad(20.0 * s)) * Basis(Vector3(1, 0, 0), -deg2rad(15.0 * strike_power))
		else:
			var slam_pitch = -deg2rad(70.0) + deg2rad(140.0 * s)
			r_arm_tf.basis = Basis(Vector3(1, 0, 0), slam_pitch)
			l_arm_tf.basis = Basis(Vector3(1, 0, 0), slam_pitch)
			spine_tf.basis = Basis(Vector3(1, 0, 0), -deg2rad(30.0 * s))

	else:
		# Phase 3: Smooth recovery back to walking pose
		var r = (progress - 0.65) / 0.35
		var blend = 1.0 - r
		if attack_anim_variant == 0:
			r_arm_tf.basis = Basis(Vector3(1, 0, 0), -deg2rad(20.0 * blend))
		elif attack_anim_variant == 1:
			l_arm_tf.basis = Basis(Vector3(1, 0, 0), -deg2rad(20.0 * blend))
		else:
			r_arm_tf.basis = Basis(Vector3(1, 0, 0), deg2rad(15.0 * blend))
			l_arm_tf.basis = Basis(Vector3(1, 0, 0), deg2rad(15.0 * blend))
			spine_tf.basis = Basis(Vector3(1, 0, 0), -deg2rad(10.0 * blend))

	if r_arm_bone_idx >= 0:
		skel.set_bone_custom_pose(r_arm_bone_idx, r_arm_tf)
	if r_forearm_bone_idx >= 0:
		skel.set_bone_custom_pose(r_forearm_bone_idx, r_forearm_tf)
	if l_arm_bone_idx >= 0:
		skel.set_bone_custom_pose(l_arm_bone_idx, l_arm_tf)
	if l_forearm_bone_idx >= 0:
		skel.set_bone_custom_pose(l_forearm_bone_idx, l_forearm_tf)
	if spine_bone_idx >= 0:
		skel.set_bone_custom_pose(spine_bone_idx, spine_tf)

func _reset_attack_arm_animation() -> void:
	if not skel:
		return
	if r_arm_bone_idx >= 0: skel.set_bone_custom_pose(r_arm_bone_idx, Transform.IDENTITY)
	if r_forearm_bone_idx >= 0: skel.set_bone_custom_pose(r_forearm_bone_idx, Transform.IDENTITY)
	if l_arm_bone_idx >= 0: skel.set_bone_custom_pose(l_arm_bone_idx, Transform.IDENTITY)
	if l_forearm_bone_idx >= 0: skel.set_bone_custom_pose(l_forearm_bone_idx, Transform.IDENTITY)
	if spine_bone_idx >= 0: skel.set_bone_custom_pose(spine_bone_idx, Transform.IDENTITY)

func _play_impact_flesh_sound() -> void:
	if audio_attack:
		var s = _load_ogg("res://data/audios/zombie/flesh_impact.ogg")
		if s:
			audio_attack.stream = s
			audio_attack.pitch_scale = rand_range(0.85, 1.15)
			audio_attack.unit_db = 8.5
			audio_attack.play()

func _play_boss_roar() -> void:
	if audio_roar and boss_roar_stream:
		audio_roar.stream = boss_roar_stream
		audio_roar.unit_db = 12.0
		audio_roar.pitch_scale = rand_range(0.88, 1.05)
		audio_roar.play()

func _shoot(target_pos: Vector3, _dist: float) -> void:
	_melee_attack(target_pos)

# ============================================================
#  ANIMATION UPDATE
# ============================================================
func _update_animation() -> void:
	if not anim_player or is_dead or zombie_anim_name == "":
		return
	if soldier_node and not soldier_node.visible:
		return

	var h_spd = Vector2(velocity.x, velocity.z).length()
	if h_spd > 3.0:
		anim_player.playback_speed = 1.9 if weapon_type == "runner" else 1.5
	elif h_spd > 0.4:
		anim_player.playback_speed = 1.1
	else:
		anim_player.playback_speed = 0.4

	if not anim_player.is_playing():
		anim_player.play(zombie_anim_name)

# ============================================================
#  DAMAGE & HEALTH
# ============================================================
func _damage(amount: int) -> void:
	if is_dead:
		return
	health -= amount
	hit_flash_timer = 0.12

	if hit_sound:
		hit_sound.pitch_scale = rand_range(0.88, 1.12)
		hit_sound.play()

	if is_instance_valid(player_ref):
		last_known_player_pos = player_ref.global_transform.origin
		current_state = AIState.COMBAT
		search_timer  = 8.0

	_flash_hit_mat()
	_update_health_bar()
	if health <= 0:
		_die()

func _update_health_bar() -> void:
	if is_boss:
		if health_fill:
			health_fill.get_parent().visible = false
		return
	if not health_fill:
		return

	var ratio = clamp(float(health) / float(max_health), 0.0, 1.0)
	health_fill.scale.x = ratio
	var mat = health_fill.mesh.material as SpatialMaterial
	if mat:
		if ratio > 0.55:
			mat.albedo_color = Color(0.2, 0.95, 0.3)
		elif ratio > 0.25:
			mat.albedo_color = Color(0.95, 0.8, 0.2)
		else:
			mat.albedo_color = Color(0.95, 0.15, 0.15)

# ============================================================
#  DEATH
# ============================================================
func _die() -> void:
	is_dead       = true
	health        = 0
	respawn_timer = 3.5
	velocity      = Vector3()

	if die_sound:
		if is_boss and boss_roar_stream:
			die_sound.stream = boss_roar_stream
			die_sound.pitch_scale = 0.65
			die_sound.unit_db = 12.0
		elif die_streams.size() > 0:
			die_sound.stream = die_streams[randi() % die_streams.size()]
			die_sound.pitch_scale = rand_range(0.85, 1.1)
		die_sound.play()

	if anim_player:
		anim_player.stop()
	if soldier_node:
		soldier_node.rotation_degrees.z = 0.0
	rotation_degrees.x = -82.0
	translation.y = max(0.1, translation.y - 0.65 * scale.y)

	if collision_shape:
		collision_shape.disabled = true
	if weapon_mount:
		weapon_mount.visible = false

	var sp = get_tree().get_root().find_node("zombie_spawner", true, false)
	if sp and sp.has_method("on_zombie_killed"):
		sp.on_zombie_killed(self)

# ============================================================
#  RESPAWN
# ============================================================
func _respawn() -> void:
	if is_boss:
		return
	is_dead = false
	health  = max_health
	rotation_degrees.x = 0.0

	if base_spawn_pos != Vector3.ZERO:
		global_transform.origin = base_spawn_pos
		rotation_degrees.y = base_spawn_rot_y

	if collision_shape:
		collision_shape.disabled = false

	_clear_hit_mat()
	if not is_melee_zombie and weapon_mount:
		weapon_mount.visible = true

	if anim_player and zombie_anim_name != "":
		anim_player.play(zombie_anim_name)

	current_state = AIState.PATROL
	_pick_new_patrol_target()
	_update_health_bar()
