extends CanvasLayer

const Arabic = preload("res://data/scripts/utils/arabic.gd")

# ============================================================
#  PAUSE MENU — باللغة العربية مع دعم تخصيص أزرار الموبايل
# ============================================================

var is_paused : bool = false
var panel : PanelContainer
var resume_btn : Button
var restart_btn : Button
var customize_hud_btn : Button
var mobile_toggle_btn : Button
var menu_btn : Button
var quit_btn : Button
var stats_lbl : Label

func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS
	_build_ui()
	_set_pause(false)

func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		_set_pause(not is_paused)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.scancode == KEY_ESCAPE:
			_set_pause(not is_paused)
			get_tree().set_input_as_handled()

func _set_pause(paused: bool) -> void:
	is_paused = paused
	get_tree().paused = paused
	
	if panel:
		panel.visible = paused
		
	if paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_update_stats()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _update_stats() -> void:
	if not stats_lbl:
		return
	var spawner = get_tree().get_root().find_node("zombie_spawner", true, false)
	var rem = 50
	var tot = 50
	if spawner:
		rem = spawner.get("zombies_remaining")
		tot = spawner.get("total_zombies")
	stats_lbl.text = "☣ " + Arabic.t("متبقي من حشد الزومبي:") + " " + str(rem) + " / " + str(tot) + " ☣\nZOMBIES REMAINING"

func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.name = "pause_panel"
	panel.visible = false
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.04, 0.06, 0.94)
	style.border_color = Color(0.9, 0.2, 0.2, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	panel.add_stylebox_override("panel", style)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.set("custom_constants/separation", 10)
	panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "⏸️  " + Arabic.t("تم إيقاف اللعبة مؤقتاً") + "  ⏸️\nGAME PAUSED"
	title.align = Label.ALIGN_CENTER
	title.add_color_override("font_color", Color(1.0, 0.25, 0.25))
	vbox.add_child(title)
	
	# Subtitle / Stats
	stats_lbl = Label.new()
	stats_lbl.text = "☣ " + Arabic.t("متبقي من حشد الزومبي: 50 / 50") + " ☣"
	stats_lbl.align = Label.ALIGN_CENTER
	stats_lbl.add_color_override("font_color", Color(0.85, 0.88, 0.95))
	vbox.add_child(stats_lbl)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# Buttons
	resume_btn = _create_btn("▶  " + Arabic.t("استئناف اللعب") + "  (RESUME)")
	resume_btn.connect("pressed", self, "_on_resume_pressed")
	vbox.add_child(resume_btn)
	
	restart_btn = _create_btn("↺  " + Arabic.t("إعادة المعركة") + "  (RESTART)")
	restart_btn.connect("pressed", self, "_on_restart_pressed")
	vbox.add_child(restart_btn)
	
	customize_hud_btn = _create_btn("⚙️  " + Arabic.t("تخصيص مكان أزرار الموبايل") + "  (CUSTOMIZE HUD)")
	customize_hud_btn.connect("pressed", self, "_on_customize_hud_pressed")
	vbox.add_child(customize_hud_btn)

	mobile_toggle_btn = _create_btn("📱  " + Arabic.t("أزرار الموبايل:") + " " + _get_mobile_state_str())
	mobile_toggle_btn.connect("pressed", self, "_on_mobile_toggle_pressed")
	vbox.add_child(mobile_toggle_btn)
	
	menu_btn = _create_btn("⌂  " + Arabic.t("القائمة الرئيسية") + "  (MAIN MENU)")
	menu_btn.connect("pressed", self, "_on_menu_pressed")
	vbox.add_child(menu_btn)
	
	quit_btn = _create_btn("✕  " + Arabic.t("خروج إلى سطح المكتب") + "  (QUIT)")
	quit_btn.connect("pressed", self, "_on_quit_pressed")
	vbox.add_child(quit_btn)

func _get_mobile_state_str() -> String:
	var cur = ProjectSettings.get_setting("custom/mobile_touch_enabled")
	if cur != null and bool(cur):
		return Arabic.t("مفعلة") + " (ON)"
	return Arabic.t("معطلة على الكمبيوتر") + " (OFF)"

func _create_btn(text: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.rect_min_size = Vector2(340, 40)
	
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.09, 0.11, 0.16, 0.95)
	normal.border_color = Color(0.35, 0.40, 0.50, 0.8)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	
	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.75, 0.15, 0.15, 0.95)
	hover.border_color = Color(1.0, 0.3, 0.3, 1.0)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(6)
	
	btn.add_stylebox_override("normal", normal)
	btn.add_stylebox_override("hover", hover)
	btn.add_stylebox_override("pressed", hover)
	btn.add_color_override("font_color", Color(1, 1, 1))
	btn.add_color_override("font_color_hover", Color(1, 1, 1))
	return btn

func _process(_delta: float) -> void:
	if is_paused and panel:
		var vp_sz = panel.get_viewport().size
		var panel_w = min(460.0, vp_sz.x * 0.90)
		var panel_h = 420.0
		panel.rect_size = Vector2(panel_w, panel_h)
		panel.rect_position = (vp_sz - Vector2(panel_w, panel_h)) * 0.5

func _on_resume_pressed() -> void:
	_set_pause(false)

func _on_restart_pressed() -> void:
	_set_pause(false)
	get_tree().reload_current_scene()

func _on_customize_hud_pressed() -> void:
	_set_pause(false)
	var mob = get_tree().get_root().find_node("mobile_controls", true, false)
	if mob and mob.has_method("set_edit_mode"):
		mob.visible = true
		var root_ctrl = mob.get_node_or_null("mobile_root")
		if root_ctrl: root_ctrl.visible = true
		mob.set_edit_mode(true)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_mobile_toggle_pressed() -> void:
	var cur = ProjectSettings.get_setting("custom/mobile_touch_enabled")
	var new_val = not bool(cur) if cur != null else true
	ProjectSettings.set_setting("custom/mobile_touch_enabled", new_val)
	if mobile_toggle_btn:
		mobile_toggle_btn.text = "📱  أزرار الموبايل: " + _get_mobile_state_str()
	var mob = get_tree().get_root().find_node("mobile_controls", true, false)
	if mob:
		mob.is_mobile_active = new_val
		var rc = mob.get_node_or_null("mobile_root")
		if rc: rc.visible = new_val

func _on_menu_pressed() -> void:
	_set_pause(false)
	get_tree().change_scene("res://data/scenes/main_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
