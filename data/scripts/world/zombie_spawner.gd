extends Spatial

export var total_zombies : int = 50
var zombies_remaining : int = 50
var is_boss_active : bool = false
var boss_node : Spatial = null

var spawn_points = [
	Vector3(-2.5, 0.5, -42), # Near corridor
	Vector3(3.0, 0.5, -32),  # Lab doorway
	Vector3(-12, 0.5, -25),  # Side chamber
	Vector3(0, 0.5, -15),    # Center archway
	Vector3(8, 0.5, 5),      # Grand Hall Entrance
	Vector3(-8, 0.5, 20),    # Moonlit Hall West
	Vector3(0, 0.5, 35)      # Hive entrance
]

var zombie_classes = ["runner", "runner", "stalker", "vector", "brute"]

func _ready() -> void:
	zombies_remaining = total_zombies
	call_deferred("_init_horde")

func _init_horde() -> void:
	_update_hud()

func _update_hud() -> void:
	var chars = get_tree().get_nodes_in_group("character")
	for c in chars:
		var hud = c.get_node_or_null("hud")
		if hud and hud.has_method("_update_zombies_remaining"):
			hud._update_zombies_remaining(zombies_remaining, total_zombies)

func on_zombie_killed(zombie) -> void:
	if zombie.get("is_boss") == true:
		_on_boss_killed()
		return
		
	if zombies_remaining > 0:
		zombies_remaining -= 1
		_update_hud()
		
		if zombies_remaining <= 0 and not is_boss_active:
			# ALL 50 ZOMBIES ELIMINATED! SPAWN THE GIANT BOSS TITAN!
			call_deferred("_spawn_boss_titan")
		else:
			# Respawn replacement zombie quickly to maintain relentless horde
			var t = Timer.new()
			t.wait_time = rand_range(1.2, 2.5)
			t.one_shot = true
			t.connect("timeout", self, "_respawn_zombie_delayed", [zombie])
			add_child(t)
			t.start()

func _respawn_zombie_delayed(zombie) -> void:
	if not is_instance_valid(zombie) or zombies_remaining <= 0:
		if is_instance_valid(zombie):
			zombie.queue_free()
		return
		
	var sp = spawn_points[randi() % spawn_points.size()]
	zombie.base_spawn_pos = sp
	zombie.weapon_type = zombie_classes[randi() % zombie_classes.size()]
	zombie._setup_zombie_class()
	zombie._respawn()

func _spawn_boss_titan() -> void:
	is_boss_active = true
	
	# Play ground-shaking Boss Roar
	var roar_player = AudioStreamPlayer.new()
	var f = File.new()
	if f.open("res://data/audios/zombie/boss_roar.ogg", File.READ) == OK:
		var stream = AudioStreamOGGVorbis.new()
		stream.data = f.get_buffer(f.get_len())
		f.close()
		roar_player.stream = stream
		roar_player.volume_db = 6.0
	add_child(roar_player)
	roar_player.play()
	
	# Instance Boss from enemy_bot scene
	var enemy_scene = load("res://data/scenes/enemy_bot.tscn")
	if enemy_scene:
		boss_node = enemy_scene.instance()
		boss_node.name = "GOLIATH_TITAN"
		boss_node.set("is_boss", true)
		boss_node.base_spawn_pos = Vector3(0, 0.5, -15) # Spawn right in Grand Hall!
		boss_node.weapon_type = "brute"
		get_parent().add_child(boss_node)
		
		# Setup HUD Boss Bar
		var chars = get_tree().get_nodes_in_group("character")
		for c in chars:
			var hud = c.get_node_or_null("hud")
			if hud and hud.has_method("_set_boss_active"):
				hud._set_boss_active(true, "GOLIATH TITAN - LEVEL 50 APEX MUTANT", 2500.0)

func _on_boss_killed() -> void:
	var chars = get_tree().get_nodes_in_group("character")
	for c in chars:
		var hud = c.get_node_or_null("hud")
		if hud and hud.has_method("_show_victory_screen"):
			hud._show_victory_screen()
