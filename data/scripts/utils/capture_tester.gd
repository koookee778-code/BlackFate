extends Node

var step = 0
var frame_count = 0
var current_test_node : Node = null

func _ready():
	print("CAPTURE TESTER: Starting screenshot sequence...")

func _process(_delta):
	frame_count += 1
	
	if step == 0 and frame_count == 5:
		print("CAPTURE TESTER: Testing startup loading screen...")
		var sc = load("res://data/scenes/startup_loading.tscn")
		current_test_node = sc.instance()
		add_child(current_test_node)
		
	elif step == 0 and frame_count == 25:
		var img = get_viewport().get_texture().get_data()
		img.flip_y()
		img.save_png("res://screenshot_startup_loading.png")
		print("CAPTURE TESTER: Saved screenshot_startup_loading.png")
		current_test_node.queue_free()
		current_test_node = null
		step = 1
		frame_count = 0
		
	elif step == 1 and frame_count == 5:
		print("CAPTURE TESTER: Testing main menu...")
		var sc = load("res://data/scenes/main_menu.tscn")
		current_test_node = sc.instance()
		add_child(current_test_node)
		
	elif step == 1 and frame_count == 25:
		var img = get_viewport().get_texture().get_data()
		img.flip_y()
		img.save_png("res://screenshot_menu_arabic.png")
		print("CAPTURE TESTER: Saved screenshot_menu_arabic.png")
		current_test_node.queue_free()
		current_test_node = null
		step = 2
		frame_count = 0
		
	elif step == 2 and frame_count == 5:
		print("CAPTURE TESTER: Testing match loading...")
		var sc = load("res://data/scenes/match_loading.tscn")
		current_test_node = sc.instance()
		add_child(current_test_node)
		
	elif step == 2 and frame_count == 25:
		var img = get_viewport().get_texture().get_data()
		img.flip_y()
		img.save_png("res://screenshot_match_loading.png")
		print("CAPTURE TESTER: Saved screenshot_match_loading.png")
		current_test_node.queue_free()
		current_test_node = null
		step = 3
		frame_count = 0
		
	elif step == 3 and frame_count == 5:
		print("CAPTURE TESTER: Testing gameplay and crosshair...")
		var sc = load("res://data/scenes/main.tscn")
		current_test_node = sc.instance()
		add_child(current_test_node)
		
	elif step == 3 and frame_count == 40:
		var img = get_viewport().get_texture().get_data()
		img.flip_y()
		img.save_png("res://screenshot_gameplay_crosshair.png")
		print("CAPTURE TESTER: Saved screenshot_gameplay_crosshair.png")
		current_test_node.queue_free()
		current_test_node = null
		step = 4
		frame_count = 0
		print("CAPTURE TESTER: All screenshots captured successfully!")
		get_tree().quit(0)
