extends CanvasLayer

# Screen variables
var fullscreen : bool = false

# All debug inputs
var input : Dictionary = {};

var kill_timer : float = 0.0
var kill_label : Label

func _process(_delta) -> void:
	# Calls the function to switch to fullscren or window with Alt and Enter
	_toggle_fullscreen();
	
	# Calls the function to show the framerate
	_display_framerate();
	
	# Calls the function to reset the game
	_reload_scene();
	
	# Update kill feed
	_update_kill_feed(_delta);

func _toggle_fullscreen() -> void:
	# If you don't have a fullscreen node timer it will create a
	if not has_node("timer_fullscreen"):
		# Creates a timer
		var timer = Timer.new();
		
		# Change timer name to fullscreen
		timer.name = "timer_fullscreen";
		
		# The timer time
		timer.wait_time = 0.2;
		
		# Timer will count once and stop
		timer.one_shot = true;
		
		# Adds the timer to the debug
		add_child(timer);
	
	else: # if you already have the fullscreen node timer
		# Get the fullscreen node timer
		var timer = $"timer_fullscreen";
		
		# If the timer reaches zero I can change the screen mode
		if !timer.time_left:
			input["enter"] = Input.is_action_pressed("KEY_ENTER");
			input['alt']   = Input.is_action_pressed("KEY_ALT");
			
			if input['alt'] and input['enter']:
				fullscreen = !fullscreen;
				
				OS.window_fullscreen = fullscreen;
				
				# Starts the timer again
				timer.start();

const Arabic = preload("res://data/scripts/utils/arabic.gd")

func _display_framerate() -> void:
	if not has_node("info_panel"):
		var panel = PanelContainer.new()
		panel.name = "info_panel"
		panel.rect_position = Vector2(get_viewport().size.x - 420, 15)
		
		var vbox = VBoxContainer.new()
		vbox.name = "vbox"
		panel.add_child(vbox)
		
		var fps_lbl = Label.new()
		fps_lbl.name = "fps_label"
		fps_lbl.add_color_override("font_color", Color(0.2, 1.0, 0.4))
		vbox.add_child(fps_lbl)
		
		var help_lbl = Label.new()
		help_lbl.name = "help_label"
		help_lbl.add_color_override("font_color", Color(0.9, 0.9, 0.95))
		help_lbl.text = "[ZOMBIE HORROR] " + Arabic.t("رعب الزومبي: منشأة الأبحاث السرية | البهو المقمر") + "\n" + Arabic.t("الأسلحة: [1] جلوك | [2] فيكتور | [3] مارك 23 | [4] قناصة | [العجلة] GTA") + "\n" + Arabic.t("التحكم: WASD حركة | Shift جري | C زحلقة | المسافة قفز | R تلقيم")
		vbox.add_child(help_lbl)
		
		kill_label = Label.new()
		kill_label.name = "kill_label"
		kill_label.add_color_override("font_color", Color(1.0, 0.2, 0.2))
		kill_label.text = ""
		vbox.add_child(kill_label)
		
		add_child(panel)
	else:
		var panel = get_node("info_panel")
		if panel:
			panel.rect_position = Vector2(get_viewport().size.x - 420, 15)
		var fps_lbl = get_node("info_panel/vbox/fps_label")
		if fps_lbl:
			fps_lbl.text = "FPS: " + str(Engine.get_frames_per_second()) + " | " + Arabic.t("وضع رعب الزومبي مفعل")

func _notify_kill(bot_name: String) -> void:
	kill_timer = 3.0
	if kill_label:
		kill_label.text = "[KILL] " + Arabic.t("تم القضاء على:") + " " + bot_name + " (" + Arabic.t("إعادة الظهور خلال 4 ثوانٍ") + ")"

func _update_kill_feed(_delta: float) -> void:
	if kill_timer > 0:
		kill_timer -= _delta
		if kill_timer <= 0 and kill_label:
			kill_label.text = ""

func _reload_scene() -> void:
	# Input
	input["reload"] = Input.is_action_just_pressed("KEY_F6")
	
	# If I press the reload button
	if input["reload"]:
		# Reload the scene
		get_tree().reload_current_scene();
