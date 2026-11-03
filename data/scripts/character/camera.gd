extends Camera

# ============================================================
#  CAMERA — Camera Frustum Culling (حذف ما خلف الكاميرا)
#  Optimized for Intel HD Graphics 60 FPS
# ============================================================

export var shake_time : float;
export var shake_force : float;

var cull_timer : float = 0.0

func _ready() -> void:
	# Optimal distance clipping (Fog covers beyond 65m)
	far = 80.0
	near = 0.05

func _process(_delta: float) -> void:
	_shake(_delta)
	_behind_camera_cull(_delta)

func _shake(_delta: float) -> void:
	if shake_time > 0:
		h_offset = rand_range(-shake_force, shake_force)
		v_offset = rand_range(-shake_force, shake_force)
		shake_time -= _delta
	else:
		h_offset = 0
		v_offset = 0

# ============================================================
#  ACTIVE FRUSTUM CULLING (حذف ما خلف الكاميرا بالكامل)
# ============================================================
func _behind_camera_cull(_delta: float) -> void:
	cull_timer += _delta
	if cull_timer >= 0.033: # ~30 checks/sec, ultra low CPU overhead
		cull_timer = 0.0
		var cam_pos = global_transform.origin
		var cam_forward = -global_transform.basis.z.normalized()
		
		var cullables = get_tree().get_nodes_in_group("cullable")
		for node in cullables:
			if is_instance_valid(node) and node is Spatial:
				var to_node = node.global_transform.origin - cam_pos
				# If behind camera and further than 2m behind player back: CULL IT!
				if to_node.dot(cam_forward) < -2.0 and to_node.length_squared() > 9.0:
					node.visible = false
				else:
					node.visible = true
