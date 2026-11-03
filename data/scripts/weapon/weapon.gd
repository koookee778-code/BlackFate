class weapon:
	var owner : Node;
	var name : String;
	var firerate : float;
	var bullets : int;
	var ammo : int;
	var max_bullets : int;
	var damage : int;
	var reload_speed : float;
	
	var is_reloading : bool = false
	var reload_timer : float = 0.0
	
	func _init(owner, name, firerate, bullets, ammo, max_bullets, damage, reload_speed) -> void:
		self.owner = owner;
		self.name = name;
		self.firerate = firerate;
		self.bullets = bullets;
		self.ammo = ammo;
		self.max_bullets = max_bullets;
		self.damage = damage;
		self.reload_speed = reload_speed;
	
	# Get animation node
	var anim = owner.get_node("{}/mesh/anim".format([name], "{}"));
	
	# Get current animation
	var animc = anim.current_animation;
	
	# Get mesh node
	var mesh = owner.get_node("{}".format([name], "{}"));
	var is_scoped : bool = false;
	
	func _draw() -> void:
		# Check is visible
		if is_scoped:
			return
		mesh.visible = true;
		var inner_m = mesh.get_node_or_null("mesh")
		if inner_m:
			inner_m.visible = true
		anim.play("Draw");
	
	func _hide() -> void:
		is_reloading = false
		is_scoped = false
		if name == "sniper":
			if owner.character and owner.character.get_node_or_null("head"):
				owner.character.get_node("head").zoom_sens_factor = 1.0
			var hud = owner.character.get_node_or_null("hud")
			if hud and hud.has_method("_set_sniper_scope"):
				hud._set_sniper_scope(false)
		mesh.visible = false;
		var inner_m = mesh.get_node_or_null("mesh")
		if inner_m:
			inner_m.visible = false
		anim.stop();
	
	func _sprint(sprint, _delta) -> void:
		if sprint and owner.character.direction:
			mesh.rotation.x = lerp(mesh.rotation.x, -deg2rad(40), 5 * _delta);
		else:
			mesh.rotation.x = lerp(mesh.rotation.x, 0, 5 * _delta);
	
	func _shoot(_delta) -> void:
		# Block shooting completely while reloading or during reload animation
		if is_reloading or animc == "Reload":
			return
		
		# Get audio node
		var audio = owner.get_node("{}/audio".format([name], "{}"));
		
		# Get effects node
		var effect = owner.get_node("{}/effect".format([name], "{}"));
		
		if bullets > 0:
			# Play shoot animation if not reloading or drawing
			if animc != "Shoot" and animc != "Reload" and animc != "Draw" and animc != "Hide":
				bullets -= 1;
				
				# Recoil
				var recoil_x = rand_range(1.5, 3.0) if name == "sniper" else rand_range(1, 2)
				owner.camera.rotation.x = lerp(owner.camera.rotation.x, recoil_x, _delta);
				owner.camera.rotation.y = lerp(owner.camera.rotation.y, rand_range(-1, 1), _delta);
				
				# Shake the camera
				owner.camera.shake_force = 0.005 if name == "sniper" else 0.002;
				owner.camera.shake_time = 0.25 if name == "sniper" else 0.2;
				
				# Change light energy
				effect.get_node("shoot").light_energy = 3 if name == "sniper" else 2;
				
				# Emit fire particles
				effect.get_node("fire").emitting = true;
				
				# Emit smoke particles
				effect.get_node("smoke").emitting = true;
				
				# Play shoot sound
				audio.get_node("shoot").pitch_scale = rand_range(0.9, 1.1);
				audio.get_node("shoot").play();
				
				# Play shoot animation using firerate speed
				anim.play("Shoot", 0, firerate);
				
				# Get barrel node
				var barrel = owner.get_node("{}/barrel".format([name], "{}"));
				
				# Get main scene
				var main = owner.get_tree().get_root().get_child(0);
				
				# Create an instance of trail scene
				var trail = preload("res://data/scenes/trail.tscn").instance();
				trail.translation = barrel.global_transform.origin;
				trail.rotation = owner.camera.global_transform.basis.get_euler();
				main.add_child(trail);
				
				# Get raycast weapon range
				var ray = owner.get_node("{}/ray".format([name], "{}"));
				
				# Check raycast is colliding
				if ray.is_colliding():
					var collider = ray.get_collider();
					var hit_point = ray.get_collision_point();
					var hit_normal = ray.get_collision_normal();
					var is_enemy = collider.is_in_group("enemy") or (collider.name != null and "bot" in collider.name.to_lower()) or (collider.name != null and "zombie" in collider.name.to_lower());
					var is_headshot = false;
					var local_damage = 0;
					
					if is_enemy:
						# Ultra-Precise Headshot Detection (Targeting 3D animated Head Bone)
						var head_pos = Vector3()
						if collider.has_method("get_head_global_pos"):
							head_pos = collider.get_head_global_pos()
						else:
							var sc = collider.scale.y if ("scale" in collider) else 1.0
							head_pos = collider.global_transform.origin + Vector3(0, 1.78 * sc, 0)
						
						var enemy_scale_y = collider.scale.y if ("scale" in collider) else 1.0
						var head_radius = 0.35 * enemy_scale_y
						var dist_to_head = hit_point.distance_to(head_pos)
						
						# Pinpoint Headshot Hit
						if dist_to_head <= head_radius or (hit_point.y >= (head_pos.y - 0.15) and abs(hit_point.x - head_pos.x) <= head_radius and abs(hit_point.z - head_pos.z) <= head_radius):
							is_headshot = true;
							if name == "sniper":
								local_damage = 999; # 1-shot lethal sniper headshot kill!
							else:
								local_damage = int(damage * 3.5); # 3.5x headshot critical!
							
							# Trigger HUD headshot toast & hitmarker
							if is_instance_valid(owner) and "character" in owner and is_instance_valid(owner.character):
								var hud = owner.character.get_node_or_null("hud");
								if hud and hud.has_method("_show_headshot_toast"):
									hud._show_headshot_toast();
								if hud and hud.has_method("_trigger_hitmarker"):
									hud._trigger_hitmarker(true)
						else:
							if name == "sniper":
								local_damage = 115; # Exactly 2 body shots to kill 160-220 HP regular zombies!
							else:
								local_damage = int(rand_range(damage / 1.4, damage));
								
							if is_instance_valid(owner) and "character" in owner and is_instance_valid(owner.character):
								var hud = owner.character.get_node_or_null("hud");
								if hud and hud.has_method("_trigger_hitmarker"):
									hud._trigger_hitmarker(false)
						
						# Realistic Blood Spray on flesh impact (NO black wall decals on zombies!)
						var blood_scene = preload("res://data/scenes/blood_spray.tscn");
						if blood_scene:
							var blood = blood_scene.instance();
							blood.is_headshot = is_headshot;
							main.add_child(blood);
							blood.global_transform.origin = hit_point;
							if hit_point.distance_squared_to(hit_point + hit_normal) > 0.01:
								blood.look_at(hit_point + hit_normal, Vector3.UP);
					else:
						# Wall or Obstacle: Create bullet hole decal
						var decal = preload("res://data/scenes/decal.tscn").instance();
						collider.add_child(decal);
						decal.global_transform.origin = hit_point;
						decal.look_at(hit_point + hit_normal, Vector3(1, 1, 0));
						
						if collider.is_in_group("prop") and collider.is_in_group("metal"):
							var spark = preload("res://data/scenes/spark.tscn").instance();
							collider.add_child(spark);
							spark.global_transform.origin = hit_point;
							spark.emitting = true;
					
					# Apply physics impulse
					if collider is RigidBody:
						collider.apply_central_impulse(-hit_normal * (local_damage * 0.4));
					
					# Inflict damage
					if collider.has_method("_damage"):
						collider._damage(local_damage);
		else:
			# Play empty out click sound
			if not audio.get_node("out").playing:
				audio.get_node("out").pitch_scale = rand_range(0.9, 1.1);
				audio.get_node("out").play();
			# Auto reload when shooting with empty magazine
			_reload();

	func _reload() -> void:
		if is_reloading:
			return
		if bullets < max_bullets and ammo > 0:
			if animc != "Reload" and animc != "Shoot" and animc != "Draw" and animc != "Hide":
				is_reloading = true
				reload_timer = 1.0 / max(0.2, reload_speed) # Full reload duration
				
				# Cancel scope if aiming
				if name == "sniper":
					mesh.visible = true
					var hud = owner.character.get_node_or_null("hud")
					if hud and hud.has_method("_set_sniper_scope"):
						hud._set_sniper_scope(false)
				
				# Play reload animation
				anim.play("Reload", 0.2, reload_speed);
				
				# Play audio
				var audio = owner.get_node("{}/audio".format([name], "{}"));
				if audio.has_node("reload") and not audio.get_node("reload").playing:
					audio.get_node("reload").play()
	
	func _zoom(input, _delta) -> void:
		var lerp_speed : int = 30;
		var camera = owner.camera;
		
		var is_busy = anim.is_playing() and (animc == "Reload" or animc == "Hide" or animc == "Draw")
		if input and not is_reloading and not is_busy:
			var target_fov = 12.0 if name == "sniper" else 40.0
			camera.fov = lerp(camera.fov, target_fov, lerp_speed * _delta);
			mesh.translation.y = lerp(mesh.translation.y, 0.001, lerp_speed * _delta);
			mesh.translation.x = lerp(mesh.translation.x, -0.088, lerp_speed * _delta);
			if name == "sniper":
				is_scoped = true
				mesh.visible = false
				if owner.character and owner.character.get_node_or_null("head"):
					owner.character.get_node("head").zoom_sens_factor = 0.35
				var hud = owner.character.get_node_or_null("hud")
				if hud and hud.has_method("_set_sniper_scope"):
					hud._set_sniper_scope(true)
		else:
			camera.fov = lerp(camera.fov, 70, lerp_speed * _delta);
			mesh.translation.y = lerp(mesh.translation.y, 0, lerp_speed * _delta);
			mesh.translation.x = lerp(mesh.translation.x, 0, lerp_speed * _delta);
			if name == "sniper":
				is_scoped = false
				mesh.visible = true
				if owner.character and owner.character.get_node_or_null("head"):
					owner.character.get_node("head").zoom_sens_factor = 1.0
				var hud = owner.character.get_node_or_null("hud")
				if hud and hud.has_method("_set_sniper_scope"):
					hud._set_sniper_scope(false)
	
	func _update(_delta) -> void:
		if is_reloading:
			reload_timer -= _delta
			if reload_timer <= 0.0:
				is_reloading = false
				# Bullets are only loaded when reload duration finishes!
				var needed = max_bullets - bullets
				var take = min(needed, ammo)
				bullets += take
				ammo -= take
		
		if animc != "Shoot":
			if owner.arsenal.values()[owner.current] == self:
				owner.camera.rotation.x = lerp(owner.camera.rotation.x, 0, 10 * _delta);
				owner.camera.rotation.y = lerp(owner.camera.rotation.y, 0, 10 * _delta);
		
		# Get current animation
		animc = anim.current_animation if anim.is_playing() else "";
		
		# Get effect node
		var effect = owner.get_node("{}/effect".format([name], "{}"));
		
		# Change light energy
		effect.get_node("shoot").light_energy = lerp(effect.get_node("shoot").light_energy, 0, 5 * _delta);
		
		# Remove recoil
		mesh.rotation.x = lerp(mesh.rotation.x, 0, 5 * _delta);
		
		# Auto reload when magazine is completely empty and player is idle
		if bullets <= 0 and not is_reloading and animc != "Shoot" and animc != "Reload" and animc != "Draw" and animc != "Hide" and ammo > 0:
			_reload();
