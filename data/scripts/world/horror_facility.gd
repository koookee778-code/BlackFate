extends Spatial

onready var ambient_audio : AudioStreamPlayer = $ambient_audio
onready var bunker_light : OmniLight = get_node_or_null("light_bunker_red")
onready var lab_light : OmniLight = get_node_or_null("light_lab_green")
onready var hive_light : OmniLight = get_node_or_null("light_hive_red")

var flicker_timer : float = 0.0
var hive_pulse : float = 0.0
var fire_lights : Array = []
var red_beacons : Array = []

func _ready() -> void:
	# Load and loop ambient horror audio
	if ambient_audio:
		var f = File.new()
		if f.open("res://data/audios/ambient/horror_ambience.ogg", File.READ) == OK:
			var stream = AudioStreamOGGVorbis.new()
			stream.data = f.get_buffer(f.get_len())
			stream.loop = true
			f.close()
			ambient_audio.stream = stream
			ambient_audio.play()

	_spawn_emergency_beacons()
	_spawn_burning_barrels()

func _spawn_emergency_beacons() -> void:
	var beacon_positions = [
		Vector3(0, 4.8, -48),
		Vector3(-8, 4.8, -30),
		Vector3(8, 4.8, -30),
		Vector3(0, 5.2, -10),
		Vector3(-8, 5.5, 12),
		Vector3(8, 5.5, 12),
		Vector3(0, 5.2, 35)
	]
	
	for pos in beacon_positions:
		var b_root = Spatial.new()
		b_root.name = "emergency_beacon"
		b_root.translation = pos
		add_child(b_root)
		
		# Red Omni Light (Subtle Horror Beacon)
		var o_light = OmniLight.new()
		o_light.light_color = Color(1.0, 0.12, 0.12)
		o_light.light_energy = 1.4
		o_light.omni_range = 7.0
		o_light.shadow_enabled = false
		b_root.add_child(o_light)
		red_beacons.append(o_light)
		
		# Emissive red fixture mesh
		var mi = MeshInstance.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.22
		cyl.bottom_radius = 0.22
		cyl.height = 0.35
		var mat = SpatialMaterial.new()
		mat.albedo_color = Color(1.0, 0.1, 0.1)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.1, 0.1)
		mat.emission_energy = 3.5
		cyl.material = mat
		mi.mesh = cyl
		mi.cast_shadow = 0
		b_root.add_child(mi)

func _spawn_burning_barrels() -> void:
	var barrel_positions = [
		Vector3(4.5, 0.0, -50.0),   # Bunker exit corridor
		Vector3(-7.0, 0.0, -18.0),  # Courtyard West entrance
		Vector3(7.5, 0.0, 6.0),     # Grand Hall East entrance
		Vector3(-4.5, 0.0, 36.0)    # Hive Gate Approach
	]
	
	var fire_tex = load("res://data/textures/fire.png")
	var smoke_tex = load("res://data/textures/smoke.png")
	
	for pos in barrel_positions:
		var b = Spatial.new()
		b.name = "burning_fire_barrel"
		b.translation = pos
		add_child(b)
		
		# 1. Dark steel drum mesh
		var drum = MeshInstance.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.45
		cyl.bottom_radius = 0.45
		cyl.height = 1.1
		var drum_mat = SpatialMaterial.new()
		drum_mat.albedo_color = Color(0.18, 0.17, 0.16)
		drum_mat.metallic = 0.6
		drum_mat.roughness = 0.4
		cyl.material = drum_mat
		drum.mesh = cyl
		drum.translation.y = 0.55
		drum.cast_shadow = 0
		b.add_child(drum)
		
		# 2. Fire CPUParticles
		var fire_p = CPUParticles.new()
		fire_p.name = "fire_particles"
		fire_p.translation = Vector3(0, 1.05, 0)
		fire_p.amount = 24
		fire_p.lifetime = 0.65
		fire_p.direction = Vector3(0, 1, 0)
		fire_p.spread = 22.0
		fire_p.initial_velocity = 2.2
		fire_p.initial_velocity_random = 0.4
		fire_p.gravity = Vector3(0, 1.5, 0)
		fire_p.scale_amount = 0.65
		fire_p.scale_amount_random = 0.4
		
		var qm = QuadMesh.new()
		qm.size = Vector2(0.65, 0.65)
		var pmat = SpatialMaterial.new()
		pmat.flags_unshaded = true
		pmat.params_billboard_mode = SpatialMaterial.BILLBOARD_PARTICLES
		pmat.params_blend_mode = SpatialMaterial.BLEND_MODE_ADD
		if fire_tex:
			pmat.albedo_texture = fire_tex
		pmat.albedo_color = Color(1.0, 0.65, 0.2, 0.95)
		qm.material = pmat
		fire_p.mesh = qm
		fire_p.cast_shadow = 0
		b.add_child(fire_p)
		
		# 3. Smoke CPUParticles
		var smoke_p = CPUParticles.new()
		smoke_p.name = "smoke_particles"
		smoke_p.translation = Vector3(0, 1.4, 0)
		smoke_p.amount = 14
		smoke_p.lifetime = 1.2
		smoke_p.direction = Vector3(0, 1, 0)
		smoke_p.spread = 28.0
		smoke_p.initial_velocity = 1.8
		smoke_p.gravity = Vector3(0, 1.2, 0)
		smoke_p.scale_amount = 0.8
		smoke_p.scale_amount_random = 0.5
		
		var sqm = QuadMesh.new()
		sqm.size = Vector2(0.8, 0.8)
		var smat = SpatialMaterial.new()
		smat.flags_unshaded = true
		smat.params_billboard_mode = SpatialMaterial.BILLBOARD_PARTICLES
		if smoke_tex:
			smat.albedo_texture = smoke_tex
		smat.albedo_color = Color(0.12, 0.12, 0.14, 0.45)
		sqm.material = smat
		smoke_p.mesh = sqm
		smoke_p.cast_shadow = 0
		b.add_child(smoke_p)
		
		# 4. Flickering Warm Fire Light (Subtle Horror Fire)
		var f_light = OmniLight.new()
		f_light.translation = Vector3(0, 1.3, 0)
		f_light.light_color = Color(1.0, 0.55, 0.14)
		f_light.light_energy = 1.8
		f_light.omni_range = 9.0
		f_light.shadow_enabled = false
		b.add_child(f_light)
		fire_lights.append(f_light)
		
		# 5. 3D Looping Crackle Audio
		var f_audio = AudioStreamPlayer3D.new()
		f_audio.unit_db = 2.5
		f_audio.max_distance = 18.0
		var af = File.new()
		if af.open("res://data/audios/ambient/fire_crackle.ogg", File.READ) == OK:
			var st = AudioStreamOGGVorbis.new()
			st.data = af.get_buffer(af.get_len())
			st.loop = true
			af.close()
			f_audio.stream = st
			f_audio.play()
		b.add_child(f_audio)

func _process(delta: float) -> void:
	flicker_timer += delta
	hive_pulse += delta
	
	# Bunker red emergency light subtle flicker
	if bunker_light:
		if randf() < 0.03:
			bunker_light.light_energy = rand_range(1.2, 2.8)
		else:
			bunker_light.light_energy = lerp(bunker_light.light_energy, 2.4, 5.0 * delta)
			
	# Lab toxic green light eerie hum
	if lab_light:
		lab_light.light_energy = 2.6 + sin(flicker_timer * 4.0) * 0.5
		
	# Zombie hive red alarm beacon pulse
	if hive_light:
		hive_light.light_energy = 2.5 + sin(hive_pulse * 6.0) * 1.8

	# Emergency red alarm beacons pulse
	for idx in range(red_beacons.size()):
		var beacon = red_beacons[idx]
		if is_instance_valid(beacon):
			var pulse = sin(flicker_timer * 5.0 + float(idx) * 0.8)
			beacon.light_energy = 2.2 + pulse * 1.0

	# Fire flickering simulation
	for fl in fire_lights:
		if is_instance_valid(fl):
			var flicker = rand_range(-0.35, 0.35) + sin(flicker_timer * 12.0) * 0.25
			fl.light_energy = clamp(2.8 + flicker, 1.8, 3.6)
