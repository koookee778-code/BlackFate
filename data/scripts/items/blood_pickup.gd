extends Area

export var heal_amount : int = 50
export var respawn_time : float = 18.0

var is_available : bool = true
var respawn_timer : float = 0.0
var base_y : float = 0.0
var anim_time : float = 0.0

onready var visual_root : Spatial = $visual
onready var glow_light : OmniLight = $glow_light
onready var audio_pickup : AudioStreamPlayer3D = $audio_pickup
onready var col_shape : CollisionShape = $collision_shape

func _ready() -> void:
	base_y = translation.y
	connect("body_entered", self, "_on_body_entered")
	
	# Load sound if not already assigned
	if audio_pickup and audio_pickup.stream == null:
		var f = File.new()
		if f.open("res://data/audios/pickups/blood_pickup.ogg", File.READ) == OK:
			var stream = AudioStreamOGGVorbis.new()
			stream.data = f.get_buffer(f.get_len())
			f.close()
			audio_pickup.stream = stream

func _process(delta: float) -> void:
	if not is_available:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			_respawn()
		return
	
	anim_time += delta
	# Floating bob and rotate
	if visual_root:
		visual_root.rotate_y(delta * 2.2)
		visual_root.translation.y = sin(anim_time * 3.5) * 0.18
	
	if glow_light:
		glow_light.light_energy = 2.0 + sin(anim_time * 5.0) * 0.6

func _on_body_entered(body: Node) -> void:
	if not is_available:
		return
	
	# Check if player
	if body.is_in_group("character") or body.name == "character":
		var current_hp = body.get("health")
		var max_hp = body.get("max_health")
		if max_hp == null:
			max_hp = 250
		if current_hp != null and current_hp < max_hp:
			# Heal player
			var new_hp = min(max_hp, current_hp + heal_amount)
			body.health = new_hp
			
			# Trigger HUD heal effect
			var hud = body.get_node_or_null("hud")
			if hud and hud.has_method("_heal_flash"):
				hud._heal_flash(heal_amount)
			
			# Play pickup sound
			if audio_pickup:
				audio_pickup.play()
			
			# Deactivate and start respawn timer
			is_available = false
			respawn_timer = respawn_time
			if visual_root:
				visual_root.visible = false
			if glow_light:
				glow_light.light_energy = 0.0

func _respawn() -> void:
	is_available = true
	if visual_root:
		visual_root.visible = true
	if glow_light:
		glow_light.light_energy = 2.2
