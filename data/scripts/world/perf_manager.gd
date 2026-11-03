extends Node

# ============================================================
#  PERFORMANCE MANAGER — Ultra-Smooth 60 FPS for Intel HD
#  - Eliminates GLES2 Multi-Pass Light bottlenecks
#  - Frustum & Distance Culling for 3D Zombie Models
#  - Optimizes Environment & Camera Clipping
# ============================================================

var player_cam : Camera = null
var enemies : Array = []
var cull_timer : float = 0.0

func _ready() -> void:
	Engine.target_fps = 60
	Engine.iterations_per_second = 60
	OS.vsync_enabled = false
	call_deferred("_apply_intel_hd_optimizations")

func _apply_intel_hd_optimizations() -> void:
	var root = get_tree().get_root()
	
	# 1. Turn off redundant OmniLights to eliminate GLES2 multi-pass bottleneck
	# Emissive materials and ambient light already provide glowing visuals
	var all_nodes = []
	_collect_all_nodes(root, all_nodes)
	for n in all_nodes:
		if n is OmniLight:
			var light = n as OmniLight
			if light.name == "glow_light" or light.name == "light":
				light.visible = false
				light.light_energy = 0.0
			elif "moon" in light.name.to_lower():
				# Hall moonlights: subtle ambient, no shadow
				light.shadow_enabled = false
				light.omni_range = min(light.omni_range, 25.0)

	# 2. WorldEnvironment Optimization: Disable expensive GLES2 depth fog
	var env_node = root.find_node("environment", true, false)
	if env_node and env_node is WorldEnvironment and env_node.environment:
		var env = env_node.environment
		env.fog_enabled = false # Disabling depth fog saves massive pixel fill-rate on Intel HD
		env.ambient_light_energy = 1.05

	# 3. Camera Clipping Optimization
	var cam = root.find_node("camera", true, false)
	if cam and cam is Camera:
		player_cam = cam
		cam.far = 48.0 # Don't render geometry beyond the horror facility bounds (saves draw calls)

	_refresh_enemies()

func _collect_all_nodes(node: Node, acc: Array) -> void:
	acc.append(node)
	for c in node.get_children():
		_collect_all_nodes(c, acc)

func _refresh_enemies() -> void:
	var en_parent = get_tree().get_root().find_node("enemies", true, false)
	if en_parent:
		enemies = en_parent.get_children()

func _process(delta: float) -> void:
	cull_timer += delta
	if cull_timer < 0.08: # Update culling ~12 times per second to keep CPU overhead near zero
		return
	cull_timer = 0.0

	if not is_instance_valid(player_cam):
		var root = get_tree().get_root()
		player_cam = root.find_node("camera", true, false)
		if not player_cam:
			return

	if enemies.empty():
		_refresh_enemies()

	var cam_pos = player_cam.global_transform.origin
	var cam_fwd = -player_cam.global_transform.basis.z.normalized()

	for e in enemies:
		if not is_instance_valid(e) or not (e is Spatial):
			continue
		var soldier = e.get_node_or_null("soldier")
		if not soldier:
			continue

		var e_pos = (e as Spatial).global_transform.origin
		var to_e = e_pos - cam_pos
		var dist_sq = to_e.length_squared()

		# Distance culling: beyond 42m, don't draw high-poly zombie meshes
		if dist_sq > 1764.0: # 42 * 42
			soldier.visible = false
		else:
			# Frustum culling: check if zombie is behind player's field of view
			if dist_sq > 16.0: # If further than 4m away
				var dot = to_e.normalized().dot(cam_fwd)
				if dot < -0.15: # Behind the camera!
					soldier.visible = false
				else:
					soldier.visible = true
			else:
				# Very close zombies always visible
				soldier.visible = true
