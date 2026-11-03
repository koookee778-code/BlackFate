extends CanvasLayer

# ============================================================
#  PUBG MOBILE STYLE TOUCH CONTROLS
#  - Auto OS Detection: ONLY active on Mobile/Touch devices!
#  - PUBG High-Tech Vector Icons (Bullet, Scope, Reload, Jump, Slide, Swap)
#  - Interactive Layout Customizer (Drag & Drop buttons + Save)
# ============================================================

const JOYSTICK_RADIUS : float = 65.0
const LOOK_SENSITIVITY : float = 0.30

# Subclass: Joystick Base
class JoyBase extends Control:
	func _draw() -> void:
		var c = Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS)
		draw_circle(c, JOYSTICK_RADIUS, Color(0.06, 0.08, 0.12, 0.55))
		draw_arc(c, JOYSTICK_RADIUS, 0, TAU, 32, Color(0.5, 0.7, 1.0, 0.75), 2.0, true)
		draw_arc(c, JOYSTICK_RADIUS * 0.45, 0, TAU, 24, Color(0.5, 0.7, 1.0, 0.35), 1.0, true)

# Subclass: Joystick Knob
class JoyKnob extends Control:
	func _draw() -> void:
		var c = rect_size * 0.5
		draw_circle(c, 21.0, Color(0.2, 0.55, 0.95, 0.85))
		draw_arc(c, 21.0, 0, TAU, 24, Color(1, 1, 1, 0.9), 1.8, true)
		draw_circle(c, 7.0, Color(1, 1, 1, 0.95))

# Subclass: PUBG Action Button
class PubgBtn extends Control:
	var btn_type : String = "fire"
	var radius : float = 40.0
	var accent : Color = Color(0.95, 0.2, 0.2)
	var is_pressed : bool = false
	var is_edit_mode : bool = false
	var touch_id : int = -1

	func _draw() -> void:
		var r = radius
		var c = Vector2(r, r)

		# 1. Dark Smoked Glass Base
		var bg_col = Color(0.06, 0.08, 0.11, 0.75) if not is_pressed else accent
		draw_circle(c, r, bg_col)

		# 2. Glowing Ring
		var ring_col = Color(1, 1, 1, 0.9) if is_pressed else accent
		draw_arc(c, r, 0, TAU, 32, ring_col, 2.2, true)

		if is_edit_mode:
			draw_arc(c, r + 4.0, 0, TAU, 24, Color(1.0, 0.9, 0.2, 0.9), 1.5, true)

		# 3. Vector Icons
		var icon_col = Color(0.1, 0.1, 0.1) if is_pressed else Color(1, 1, 1, 0.95)

		match btn_type:
			"fire":
				var pts = PoolVector2Array([
					c + Vector2(0, -r * 0.55),
					c + Vector2(r * 0.28, -r * 0.15),
					c + Vector2(r * 0.28, r * 0.40),
					c + Vector2(-r * 0.28, r * 0.40),
					c + Vector2(-r * 0.28, -r * 0.15)
				])
				draw_colored_polygon(pts, icon_col)
				draw_rect(Rect2(c.x - r * 0.32, c.y + r * 0.42, r * 0.64, r * 0.10), icon_col)
				for ang in [-0.8, -0.4, 0.0, 0.4, 0.8]:
					var v = Vector2(sin(ang), -cos(ang))
					draw_line(c + v * (r * 0.62), c + v * (r * 0.85), Color(1.0, 0.8, 0.2), 2.0)

			"aim":
				draw_circle(c, 3.2, icon_col)
				draw_arc(c, r * 0.45, 0, TAU, 24, icon_col, 2.0, true)
				var len_t = r * 0.22
				draw_line(c + Vector2(0, -r * 0.45), c + Vector2(0, -r * 0.45 - len_t), icon_col, 2.2)
				draw_line(c + Vector2(0, r * 0.45), c + Vector2(0, r * 0.45 + len_t), icon_col, 2.2)
				draw_line(c + Vector2(-r * 0.45, 0), c + Vector2(-r * 0.45 - len_t, 0), icon_col, 2.2)
				draw_line(c + Vector2(r * 0.45, 0), c + Vector2(r * 0.45 + len_t, 0), icon_col, 2.2)

			"reload":
				draw_arc(c, r * 0.46, 0.2, PI * 1.6, 24, icon_col, 2.4, true)
				var arr_head = PoolVector2Array([
					c + Vector2(r * 0.46, 0),
					c + Vector2(r * 0.30, -r * 0.20),
					c + Vector2(r * 0.62, -r * 0.20)
				])
				draw_colored_polygon(arr_head, icon_col)
				draw_rect(Rect2(c.x - 3, c.y - 8, 6, 16), icon_col)

			"jump":
				draw_circle(c + Vector2(0, -r * 0.35), 4.5, icon_col)
				draw_line(c + Vector2(0, -r * 0.22), c + Vector2(0, r * 0.15), icon_col, 2.4)
				draw_line(c + Vector2(-r * 0.32, -r * 0.10), c + Vector2(r * 0.32, -r * 0.25), icon_col, 2.2)
				draw_line(c + Vector2(0, r * 0.15), c + Vector2(-r * 0.25, r * 0.45), icon_col, 2.4)
				draw_line(c + Vector2(0, r * 0.15), c + Vector2(r * 0.28, r * 0.35), icon_col, 2.4)
				draw_line(c + Vector2(-r * 0.25, -r * 0.55), c + Vector2(0, -r * 0.72), Color(1.0, 0.85, 0.3), 2.0)
				draw_line(c + Vector2(0, -r * 0.72), c + Vector2(r * 0.25, -r * 0.55), Color(1.0, 0.85, 0.3), 2.0)

			"crouch":
				draw_circle(c + Vector2(-r * 0.10, -r * 0.25), 4.5, icon_col)
				draw_line(c + Vector2(-r * 0.10, -r * 0.12), c + Vector2(0, r * 0.18), icon_col, 2.4)
				draw_line(c + Vector2(0, r * 0.18), c + Vector2(-r * 0.30, r * 0.42), icon_col, 2.4)
				draw_line(c + Vector2(0, r * 0.18), c + Vector2(r * 0.35, r * 0.38), icon_col, 2.4)
				draw_line(c + Vector2(-r * 0.50, r * 0.48), c + Vector2(r * 0.50, r * 0.48), Color(0.7, 0.9, 1.0, 0.8), 2.0)

			"switch":
				draw_rect(Rect2(c.x - r * 0.45, c.y - 4, r * 0.90, 8), icon_col)
				draw_rect(Rect2(c.x + r * 0.10, c.y + 4, 7, 10), icon_col)
				draw_line(c + Vector2(-r * 0.35, -r * 0.32), c + Vector2(r * 0.35, -r * 0.32), Color(0.8, 0.9, 1.0), 1.8)
				draw_line(c + Vector2(r * 0.35, r * 0.32), c + Vector2(-r * 0.35, r * 0.32), Color(0.8, 0.9, 1.0), 1.8)

var is_mobile_active : bool = false
var is_edit_mode : bool = false

var joystick_base : JoyBase
var joystick_knob : JoyKnob
var joystick_touch_id : int = -1
var joystick_center : Vector2 = Vector2.ZERO
var joystick_vector : Vector2 = Vector2.ZERO

var look_touch_id : int = -1
var last_look_pos : Vector2 = Vector2.ZERO

var root_ctrl : Control
var edit_overlay : Control
var btn_fire : PubgBtn
var btn_aim : PubgBtn
var btn_reload : PubgBtn
var btn_jump : PubgBtn
var btn_crouch : PubgBtn
var btn_switch : PubgBtn

var dragging_btn : PubgBtn = null
var drag_offset : Vector2 = Vector2.ZERO
var char_node : Spatial = null
var button_positions : Dictionary = {}

func _ready() -> void:
	_load_saved_layout()
	_check_mobile_active()
	_build_ui()
	call_deferred("_find_character")

func _check_mobile_active() -> void:
	var is_os_mobile = OS.get_name() in ["Android", "iOS"]
	var pref = ProjectSettings.get_setting("custom/mobile_touch_enabled")
	if pref != null:
		is_mobile_active = bool(pref)
	else:
		is_mobile_active = is_os_mobile
	if root_ctrl:
		root_ctrl.visible = is_mobile_active

func _find_character() -> void:
	var chars = get_tree().get_nodes_in_group("character")
	for c in chars:
		char_node = c
		break

func _build_ui() -> void:
	root_ctrl = Control.new()
	root_ctrl.name = "mobile_root"
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.visible = is_mobile_active
	add_child(root_ctrl)

	# 1. Virtual Joystick
	joystick_base = JoyBase.new()
	joystick_base.name = "joystick_base"
	joystick_base.rect_size = Vector2(JOYSTICK_RADIUS * 2, JOYSTICK_RADIUS * 2)
	joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(joystick_base)

	joystick_knob = JoyKnob.new()
	joystick_knob.name = "joystick_knob"
	joystick_knob.rect_size = Vector2(46, 46)
	joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base.add_child(joystick_knob)

	# 2. PUBG Mobile Circular Vector Buttons
	btn_fire   = _make_btn("fire", 40.0, Color(0.95, 0.2, 0.2))
	btn_aim    = _make_btn("aim", 34.0, Color(0.2, 0.6, 1.0))
	btn_reload = _make_btn("reload", 30.0, Color(0.25, 0.85, 0.4))
	btn_jump   = _make_btn("jump", 32.0, Color(1.0, 0.75, 0.15))
	btn_crouch = _make_btn("crouch", 30.0, Color(0.75, 0.35, 0.95))
	btn_switch = _make_btn("switch", 30.0, Color(0.35, 0.5, 0.65))

	root_ctrl.add_child(btn_fire)
	root_ctrl.add_child(btn_aim)
	root_ctrl.add_child(btn_reload)
	root_ctrl.add_child(btn_jump)
	root_ctrl.add_child(btn_crouch)
	root_ctrl.add_child(btn_switch)

	_apply_button_positions()
	_build_edit_overlay()

func _make_btn(btn_type: String, radius: float, accent: Color) -> PubgBtn:
	var b = PubgBtn.new()
	b.name = "btn_" + btn_type
	b.btn_type = btn_type
	b.radius = radius
	b.accent = accent
	b.rect_min_size = Vector2(radius * 2, radius * 2)
	b.rect_size = Vector2(radius * 2, radius * 2)
	return b

func _input(event: InputEvent) -> void:
	if not is_mobile_active:
		return

	var vp_sz = get_viewport().size
	var half_x = vp_sz.x * 0.5

	if is_edit_mode:
		_handle_edit_input(event)
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			var consumed = _check_button_touch_down(event.position, event.index)
			if not consumed:
				if event.position.x < half_x and joystick_touch_id == -1:
					joystick_touch_id = event.index
					joystick_center = event.position
					joystick_base.rect_position = joystick_center - Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS)
					joystick_knob.rect_position = Vector2(JOYSTICK_RADIUS - 23, JOYSTICK_RADIUS - 23)
					joystick_base.visible = true
				elif event.position.x >= half_x and look_touch_id == -1:
					look_touch_id = event.index
					last_look_pos = event.position
		else:
			_check_button_touch_up(event.index)
			if event.index == joystick_touch_id:
				joystick_touch_id = -1
				joystick_vector = Vector2.ZERO
				_reset_joystick_pos()
			elif event.index == look_touch_id:
				look_touch_id = -1

	elif event is InputEventScreenDrag:
		if event.index == joystick_touch_id:
			var diff = event.position - joystick_center
			if diff.length() > JOYSTICK_RADIUS:
				diff = diff.normalized() * JOYSTICK_RADIUS
			joystick_knob.rect_position = Vector2(JOYSTICK_RADIUS - 23, JOYSTICK_RADIUS - 23) + diff
			joystick_vector = diff / JOYSTICK_RADIUS
		elif event.index == look_touch_id:
			var delta_pos = event.position - last_look_pos
			last_look_pos = event.position
			_apply_touch_look(delta_pos)

func _check_button_touch_down(pos: Vector2, t_id: int) -> bool:
	for btn in [btn_fire, btn_aim, btn_reload, btn_jump, btn_crouch, btn_switch]:
		if not is_instance_valid(btn): continue
		var r = btn.radius
		var center = btn.rect_position + Vector2(r, r)
		if pos.distance_to(center) <= r * 1.15:
			btn.is_pressed = true
			btn.touch_id = t_id
			btn.update()
			_on_btn_action_down(btn.btn_type)
			return true
	return false

func _check_button_touch_up(t_id: int) -> void:
	for btn in [btn_fire, btn_aim, btn_reload, btn_jump, btn_crouch, btn_switch]:
		if not is_instance_valid(btn): continue
		if btn.touch_id == t_id:
			btn.is_pressed = false
			btn.touch_id = -1
			btn.update()
			_on_btn_action_up(btn.btn_type)

func _on_btn_action_down(type: String) -> void:
	match type:
		"fire": Input.action_press("fire")
		"aim": Input.action_press("aim")
		"reload":
			Input.action_press("reload")
			yield(get_tree().create_timer(0.1), "timeout")
			Input.action_release("reload")
		"jump": Input.action_press("jump")
		"crouch": Input.action_press("slide")
		"switch": _cycle_weapon()

func _on_btn_action_up(type: String) -> void:
	match type:
		"fire": Input.action_release("fire")
		"aim": Input.action_release("aim")
		"jump": Input.action_release("jump")
		"crouch": Input.action_release("slide")

func _cycle_weapon() -> void:
	if not char_node: return
	var wp = char_node.find_node("weapons", true, false)
	if wp:
		var nxt = (wp.current + 1) % wp.arsenal.size()
		wp.current = nxt
		for w in wp.arsenal.values():
			w._hide()
		wp.arsenal.values()[nxt]._draw()

func _physics_process(_delta: float) -> void:
	if not is_mobile_active:
		return
	if joystick_touch_id != -1 and joystick_vector.length_squared() > 0.04:
		if joystick_vector.y < -0.3: Input.action_press("forward")
		else: Input.action_release("forward")
		if joystick_vector.y > 0.3: Input.action_press("backward")
		else: Input.action_release("backward")
		if joystick_vector.x < -0.3: Input.action_press("left")
		else: Input.action_release("left")
		if joystick_vector.x > 0.3: Input.action_press("right")
		else: Input.action_release("right")
	else:
		if joystick_touch_id == -1:
			Input.action_release("forward")
			Input.action_release("backward")
			Input.action_release("left")
			Input.action_release("right")

func _apply_touch_look(rel: Vector2) -> void:
	if not char_node: return
	var head = char_node.find_node("head", true, false)
	if head and head.has_method("rotate_by_relative"):
		head.rotate_by_relative(rel * LOOK_SENSITIVITY)

func _reset_joystick_pos() -> void:
	var vp_sz = get_viewport().size
	joystick_base.rect_position = Vector2(50, vp_sz.y - JOYSTICK_RADIUS * 2 - 50)
	joystick_knob.rect_position = Vector2(JOYSTICK_RADIUS - 23, JOYSTICK_RADIUS - 23)

func _apply_button_positions() -> void:
	var vp_sz = get_viewport().size
	_reset_joystick_pos()

	var defaults = {
		"fire":   Vector2(vp_sz.x - 130, vp_sz.y - 190),
		"aim":    Vector2(vp_sz.x - 220, vp_sz.y - 120),
		"reload": Vector2(vp_sz.x - 230, vp_sz.y - 210),
		"jump":   Vector2(vp_sz.x - 120, vp_sz.y - 290),
		"crouch": Vector2(vp_sz.x - 300, vp_sz.y - 110),
		"switch": Vector2(vp_sz.x - 130, 40)
	}

	for k in defaults.keys():
		var pos = defaults[k]
		if button_positions.has(k):
			pos = Vector2(button_positions[k][0], button_positions[k][1])
		var node = get_node_or_null("mobile_root/btn_" + k)
		if node:
			node.rect_position = pos

func set_edit_mode(enabled: bool) -> void:
	is_edit_mode = enabled
	if edit_overlay:
		edit_overlay.visible = enabled
	for btn in [btn_fire, btn_aim, btn_reload, btn_jump, btn_crouch, btn_switch]:
		if is_instance_valid(btn):
			btn.is_edit_mode = enabled
			btn.update()

func _build_edit_overlay() -> void:
	edit_overlay = Control.new()
	edit_overlay.name = "edit_overlay"
	edit_overlay.rect_size = Vector2(1920, 1080)
	edit_overlay.visible = false
	add_child(edit_overlay)

	var bar = Panel.new()
	bar.rect_size = Vector2(600, 60)
	bar.rect_position = Vector2((1920 - 600) * 0.5, 20)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.15, 0.92)
	sb.border_color = Color(1.0, 0.8, 0.2, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	bar.add_stylebox_override("panel", sb)
	edit_overlay.add_child(bar)

	var hbox = HBoxContainer.new()
	hbox.rect_size = Vector2(580, 50)
	hbox.rect_position = Vector2(10, 5)
	hbox.alignment = BoxContainer.ALIGN_CENTER
	hbox.set("custom_constants/separation", 16)
	bar.add_child(hbox)

	var title = Label.new()
	title.text = "⚙️ تخصيص أزرار الموبايل (اسحب الأزرار لتغيير مكانها)"
	title.add_color_override("font_color", Color(1.0, 0.85, 0.3))
	hbox.add_child(title)

	var btn_save = Button.new()
	btn_save.text = "💾 حفظ"
	btn_save.connect("pressed", self, "_on_save_layout_pressed")
	hbox.add_child(btn_save)

	var btn_reset = Button.new()
	btn_reset.text = "🔄 ضبط تلقائي"
	btn_reset.connect("pressed", self, "_on_reset_layout_pressed")
	hbox.add_child(btn_reset)

	var btn_close = Button.new()
	btn_close.text = "✕ إغلاق"
	btn_close.connect("pressed", self, "_on_close_layout_pressed")
	hbox.add_child(btn_close)

func _handle_edit_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == BUTTON_LEFT):
		var pos = event.position
		if event.pressed:
			for btn in [btn_fire, btn_aim, btn_reload, btn_jump, btn_crouch, btn_switch]:
				if not is_instance_valid(btn): continue
				var r = btn.radius
				var center = btn.rect_position + Vector2(r, r)
				if pos.distance_to(center) <= r * 1.3:
					dragging_btn = btn
					drag_offset = btn.rect_position - pos
					break
		else:
			dragging_btn = null

	elif event is InputEventScreenDrag or (event is InputEventMouseMotion and dragging_btn != null):
		if dragging_btn:
			var vp = get_viewport().size
			var r = dragging_btn.radius
			var np = event.position + drag_offset
			np.x = clamp(np.x, 10, vp.x - r * 2 - 10)
			np.y = clamp(np.y, 10, vp.y - r * 2 - 10)
			dragging_btn.rect_position = np

func _on_save_layout_pressed() -> void:
	for btn in [btn_fire, btn_aim, btn_reload, btn_jump, btn_crouch, btn_switch]:
		if is_instance_valid(btn):
			button_positions[btn.btn_type] = [btn.rect_position.x, btn.rect_position.y]
	_save_layout_file()
	set_edit_mode(false)

func _on_reset_layout_pressed() -> void:
	button_positions.clear()
	var dir = Directory.new()
	dir.remove("user://mobile_hud_layout.json")
	_apply_button_positions()

func _on_close_layout_pressed() -> void:
	set_edit_mode(false)

func _save_layout_file() -> void:
	var f = File.new()
	if f.open("user://mobile_hud_layout.json", File.WRITE) == OK:
		f.store_string(to_json(button_positions))
		f.close()

func _load_saved_layout() -> void:
	var f = File.new()
	if f.open("user://mobile_hud_layout.json", File.READ) == OK:
		var txt = f.get_as_text()
		f.close()
		var p = parse_json(txt)
		if typeof(p) == TYPE_DICTIONARY:
			button_positions = p
