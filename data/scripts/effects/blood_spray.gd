extends Spatial

export var is_headshot : bool = false

func _ready() -> void:
	var particles = get_node_or_null("particles")
	if particles:
		particles.emitting = true
		if is_headshot:
			particles.amount = 75
			particles.lifetime = 0.45
			particles.initial_velocity = 15.0
			particles.scale_amount = 0.38
		else:
			particles.amount = 35
			particles.lifetime = 0.32
			particles.initial_velocity = 11.0
			particles.scale_amount = 0.24
	
	var audio = get_node_or_null("audio")
	if audio:
		audio.pitch_scale = rand_range(0.9, 1.1)
		var sound_path = "res://data/audios/zombie/headshot.ogg" if is_headshot else "res://data/audios/zombie/flesh_impact.ogg"
		var s = _load_ogg(sound_path)
		if s:
			audio.stream = s
			audio.unit_db = 7.0 if is_headshot else 4.5
			audio.play()
	
	# Auto remove after 0.5s
	var t = Timer.new()
	t.wait_time = 0.5
	t.one_shot = true
	t.connect("timeout", self, "queue_free")
	add_child(t)
	t.start()

func _load_ogg(path: String) -> AudioStreamOGGVorbis:
	var f = File.new()
	if f.open(path, File.READ) == OK:
		var stream = AudioStreamOGGVorbis.new()
		stream.data = f.get_buffer(f.get_len())
		f.close()
		return stream
	return null
