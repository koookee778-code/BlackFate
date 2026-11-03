extends CanvasLayer

# ============================================================
#  BLACK FATE (LAB-03) — AAA INTERACTIVE MAIN MENU
#  تطوير وبرمجة المطور: محمد عماد (Mohamed Emad)
# ============================================================

const Arabic = preload("res://data/scripts/utils/arabic.gd")

var bg_rect : TextureRect
var overlay_shader : ColorRect
var logo_rect : TextureRect
var slogan_rect : TextureRect
var root_ctrl : Control
var buttons_col : VBoxContainer

var settings_modal : PanelContainer
var credits_modal : PanelContainer
var dossier_modal : PanelContainer

var font_title : DynamicFont
var font_lg : DynamicFont
var font_med : DynamicFont
var font_reg : DynamicFont
var font_sm : DynamicFont

var tex_btn_normal : Texture
var tex_btn_hover : Texture
var tex_btn_pressed : Texture

var bg_base_pos : Vector2 = Vector2(-90, -90)
var target_bg_pos : Vector2 = Vector2(-90, -90)
var pulse_time : float = 0.0

# Vector Icon Drawer matching Mockup
class MenuIconDrawer extends Control:
	var icon_type: String = "play"
	var icon_color: Color = Color(0.96, 0.97, 1.0)

	func _init(t: String):
		icon_type = t
		rect_min_size = Vector2(28, 28)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_color(c: Color) -> void:
		icon_color = c
		update()

	func _draw() -> void:
		var c = rect_size * 0.5
		var col = icon_color
		match icon_type:
			"play":
				# Solid sharp play triangle
				var pts = PoolVector2Array([
					c + Vector2(-5, -8),
					c + Vector2(8, 0),
					c + Vector2(-5, 8)
				])
				draw_colored_polygon(pts, col)
			"gamepad":
				# Sleek console gamepad controller
				draw_circle(c + Vector2(-6, 2), 6.2, col)
				draw_circle(c + Vector2(6, 2), 6.2, col)
				draw_rect(Rect2(c.x - 7, c.y - 4, 14, 8), col)
				# Inner D-pad
				draw_line(c + Vector2(-8, 2), c + Vector2(-4, 2), Color(0.08, 0.08, 0.1), 1.8)
				draw_line(c + Vector2(-6, 0), c + Vector2(-6, 4), Color(0.08, 0.08, 0.1), 1.8)
				# Action button dots
				draw_circle(c + Vector2(6, 0), 1.1, Color(0.08, 0.08, 0.1))
				draw_circle(c + Vector2(6, 4), 1.1, Color(0.08, 0.08, 0.1))
				draw_circle(c + Vector2(4, 2), 1.1, Color(0.08, 0.08, 0.1))
				draw_circle(c + Vector2(8, 2), 1.1, Color(0.08, 0.08, 0.1))
			"mobile":
				# Mobile device & touch ring
				draw_rect(Rect2(c.x - 6, c.y - 11, 12, 22), col, false, 1.8)
				draw_line(c + Vector2(-3, -8), c + Vector2(3, -8), col, 1.2)
				draw_circle(c + Vector2(0, 7), 1.4, col)
				draw_arc(c + Vector2(9, 0), 6.0, -PI*0.4, PI*0.4, 10, Color(col.r, col.g, col.b, 0.5), 1.2, true)
			"gear":
				# Mechanical cogwheel with hollow hub and radiating teeth
				draw_arc(c, 5.0, 0, TAU, 16, col, 2.2, true)
				for i in range(8):
					var ang = i * (TAU / 8.0)
					var dir = Vector2(cos(ang), sin(ang))
					draw_line(c + dir * 5.0, c + dir * 9.5, col, 2.2)
			"monitor":
				# Display monitor with stand
				draw_rect(Rect2(c.x - 9, c.y - 7, 18, 13), col, false, 1.8)
				draw_line(c + Vector2(-6, 2), c + Vector2(6, 2), col, 1.0)
				draw_line(c + Vector2(0, 6), c + Vector2(0, 9), col, 2.0)
				draw_line(c + Vector2(-5, 9), c + Vector2(5, 9), col, 2.0)
			"quit":
				# Exit door frame with outward arrow
				draw_polyline(PoolVector2Array([
					c + Vector2(3, -9),
					c + Vector2(-6, -9),
					c + Vector2(-6, 9),
					c + Vector2(3, 9)
				]), col, 1.8)
				# Arrow pointing right
				draw_line(c + Vector2(-2, 0), c + Vector2(8, 0), col, 2.0)
				draw_line(c + Vector2(5, -4), c + Vector2(8, 0), col, 2.0)
				draw_line(c + Vector2(5, 4), c + Vector2(8, 0), col, 2.0)

# Skewed Texture Button Class with Vector Icons
class SkewMenuButton extends TextureButton:
	var label_en : Label
	var label_ar : Label
	var icon_drawer : MenuIconDrawer
	var tween : Tween

	func _init(p_tex_n: Texture, p_tex_h: Texture, p_tex_p: Texture, p_icon_type: String, p_en: String, p_ar: String, f_med: DynamicFont, f_sm: DynamicFont):
		texture_normal = p_tex_n
		texture_hover = p_tex_h
		texture_focused = p_tex_h
		texture_pressed = p_tex_p
		expand = true
		rect_min_size = Vector2(460, 56)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		tween = Tween.new()
		add_child(tween)

		var h = HBoxContainer.new()
		h.anchor_right = 1.0
		h.anchor_bottom = 1.0
		h.margin_left = 28
		h.margin_right = -20
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(h)

		# Vector Icon Drawer
		icon_drawer = MenuIconDrawer.new(p_icon_type)
		h.add_child(icon_drawer)

		var sp1 = Control.new()
		sp1.rect_min_size = Vector2(8, 0)
		sp1.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(sp1)

		# English Title
		label_en = Label.new()
		label_en.text = p_en
		label_en.add_color_override("font_color", Color(0.96, 0.97, 1.0))
		if f_med: label_en.add_font_override("font", f_med)
		label_en.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(label_en)

		var sp2 = Control.new()
		sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sp2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(sp2)

		# Arabic Subtitle
		label_ar = Label.new()
		label_ar.text = Arabic.t(p_ar)
		label_ar.add_color_override("font_color", Color(0.80, 0.85, 0.92))
		if f_sm: label_ar.add_font_override("font", f_sm)
		label_ar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(label_ar)

		connect("mouse_entered", self, "_on_hover")
		connect("mouse_exited", self, "_on_unhover")
		connect("focus_entered", self, "_on_hover")
		connect("focus_exited", self, "_on_unhover")

	func _on_hover() -> void:
		rect_pivot_offset = Vector2(0, rect_size.y * 0.5)
		if icon_drawer:
			icon_drawer.set_color(Color(1.0, 0.35, 0.35))
		if tween:
			tween.stop_all()
			tween.interpolate_property(self, "rect_scale", rect_scale, Vector2(1.04, 1.04), 0.14, Tween.TRANS_SINE, Tween.EASE_OUT)
			tween.interpolate_property(label_en, "custom_colors/font_color", label_en.get("custom_colors/font_color"), Color(1.0, 0.35, 0.35), 0.14)
			tween.start()

	func _on_unhover() -> void:
		if icon_drawer:
			icon_drawer.set_color(Color(0.96, 0.97, 1.0))
		if tween:
			tween.stop_all()
			tween.interpolate_property(self, "rect_scale", rect_scale, Vector2(1.0, 1.0), 0.14, Tween.TRANS_SINE, Tween.EASE_OUT)
			tween.interpolate_property(label_en, "custom_colors/font_color", label_en.get("custom_colors/font_color"), Color(0.96, 0.97, 1.0), 0.14)
			tween.start()

func _load_texture_safe(path: String) -> Texture:
	var f = File.new()
	if f.file_exists(path):
		var img = Image.new()
		if img.load(path) == OK:
			var itex = ImageTexture.new()
			itex.create_from_image(img, 7)
			return itex
	var res = load(path)
	if res is Texture:
		return res
	return null

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	font_title = load("res://data/fonts/modern_font_title.tres")
	font_lg = load("res://data/fonts/modern_font_large.tres")
	font_med = load("res://data/fonts/modern_font_medium.tres")
	font_reg = load("res://data/fonts/modern_font_regular.tres")
	font_sm = load("res://data/fonts/modern_font_small.tres")

	tex_btn_normal = _load_texture_safe("res://data/ui/btn_skew_normal.png")
	tex_btn_hover = _load_texture_safe("res://data/ui/btn_skew_hover.png")
	tex_btn_pressed = _load_texture_safe("res://data/ui/btn_skew_pressed.png")

	_build_menu()
	_update_bg_layout()
	get_viewport().connect("size_changed", self, "_update_bg_layout")

func _update_bg_layout() -> void:
	var vp = get_viewport()
	if vp and bg_rect:
		var sz = vp.size
		var margin = 90.0
		bg_base_pos = -Vector2(margin, margin)
		bg_rect.rect_position = bg_base_pos
		bg_rect.rect_size = sz + Vector2(margin * 2.0, margin * 2.0)

func _build_menu() -> void:
	# 1. Background Container with Margins for Parallax Shift
	var bg_container = Control.new()
	bg_container.anchor_right = 1.0
	bg_container.anchor_bottom = 1.0
	add_child(bg_container)

	bg_rect = TextureRect.new()
	bg_rect.name = "bg_rect"
	bg_rect.expand = true
	bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bg_t = _load_texture_safe("res://data/ui/bg_main_menu_clean.png")
	if bg_t:
		bg_rect.texture = bg_t
	bg_container.add_child(bg_rect)

	# 2. Cinematic LAB-03 Atmosphere Shader Overlay
	overlay_shader = ColorRect.new()
	overlay_shader.name = "overlay_shader"
	overlay_shader.anchor_right = 1.0
	overlay_shader.anchor_bottom = 1.0
	overlay_shader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s_res = load("res://data/shaders/lab03_atmosphere.gdshader")
	if s_res is Shader:
		var mat = ShaderMaterial.new()
		mat.shader = s_res
		mat.set_shader_param("vignette_intensity", 0.65)
		mat.set_shader_param("red_pulse_strength", 0.07)
		mat.set_shader_param("scanline_alpha", 0.035)
		mat.set_shader_param("time_scale", 1.4)
		overlay_shader.material = mat
	add_child(overlay_shader)

	# 3. Root UI Control
	root_ctrl = Control.new()
	root_ctrl.anchor_right = 1.0
	root_ctrl.anchor_bottom = 1.0
	add_child(root_ctrl)

	# ============================================================
	# TOP HEADER BAR (Classification Tag & Developer Prestige Badge)
	# ============================================================
	var top_bar = HBoxContainer.new()
	top_bar.anchor_right = 1.0
	top_bar.margin_left = 40
	top_bar.margin_right = -40
	top_bar.margin_top = 18
	top_bar.margin_bottom = 54
	root_ctrl.add_child(top_bar)

	# Left: Classification Tag
	var class_lbl = Label.new()
	class_lbl.text = "[ BIOHAZARD ]  CLASSIFIED // OUTBREAK CONTAINMENT PROTOCOL ACTIVE"
	class_lbl.add_color_override("font_color", Color(1.0, 0.28, 0.28))
	if font_sm: class_lbl.add_font_override("font", font_sm)
	top_bar.add_child(class_lbl)

	var top_sp = Control.new()
	top_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(top_sp)

	# Developer Prestige Badge (Mohamed Emad)
	var dev_badge = PanelContainer.new()
	var d_style = StyleBoxFlat.new()
	d_style.bg_color = Color(0.06, 0.08, 0.12, 0.90)
	d_style.border_color = Color(0.95, 0.75, 0.2, 0.9)
	d_style.set_border_width_all(1)
	d_style.set_corner_radius_all(6)
	d_style.content_margin_left = 14
	d_style.content_margin_right = 14
	d_style.content_margin_top = 4
	d_style.content_margin_bottom = 4
	dev_badge.add_stylebox_override("panel", d_style)
	top_bar.add_child(dev_badge)

	var dev_lbl = Label.new()
	dev_lbl.text = "[ LEAD DEVELOPER ]  " + Arabic.t("تطوير وبرمجة المطور: محمد عماد") + "  //  MOHAMED EMAD"
	dev_lbl.add_color_override("font_color", Color(1.0, 0.85, 0.25))
	if font_sm: dev_lbl.add_font_override("font", font_sm)
	dev_badge.add_child(dev_lbl)

	# ============================================================
	# TOP RIGHT SLOGAN ("YOUR FATE... IS BLACK") — Matching Mockup
	# ============================================================
	slogan_rect = TextureRect.new()
	slogan_rect.name = "slogan_rect"
	var slogan_t = _load_texture_safe("res://data/ui/slogan_your_fate_is_black.png")
	if slogan_t:
		slogan_rect.texture = slogan_t
		slogan_rect.rect_position = Vector2(980, 52)
		slogan_rect.rect_size = Vector2(260, 150)
		slogan_rect.expand = true
		slogan_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root_ctrl.add_child(slogan_rect)

	# ============================================================
	# LEFT COLUMN: LOGO & INTERACTIVE SKEWED BUTTONS
	# ============================================================
	var left_col = VBoxContainer.new()
	left_col.rect_position = Vector2(40, 50)
	left_col.rect_size = Vector2(480, 610)
	left_col.set("custom_constants/separation", 8)
	root_ctrl.add_child(left_col)

	# Official Black Fate Logo
	logo_rect = TextureRect.new()
	logo_rect.name = "logo_rect"
	var logo_t = _load_texture_safe("res://data/ui/logo_black_fate.png")
	if logo_t:
		logo_rect.texture = logo_t
		logo_rect.rect_min_size = Vector2(440, 145)
		logo_rect.expand = true
		logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	left_col.add_child(logo_rect)

	# Subtitle Tag
	var sub_lbl = Label.new()
	sub_lbl.text = "FIGHT  •  SURVIVE  •  ESCAPE  —  " + Arabic.t("رعب البقاء: المنشأة 07")
	sub_lbl.add_color_override("font_color", Color(0.85, 0.90, 0.98))
	if font_sm: sub_lbl.add_font_override("font", font_sm)
	left_col.add_child(sub_lbl)

	var sep = HSeparator.new()
	sep.rect_min_size = Vector2(0, 4)
	left_col.add_child(sep)

	# SKEWED MENU BUTTONS (Exact Match to ref_main_menu_mockup.png)
	buttons_col = VBoxContainer.new()
	buttons_col.set("custom_constants/separation", 6)
	left_col.add_child(buttons_col)

	var btn_continue = _add_skew_btn("play", "CONTINUE", "استمرار معركة النجاة", "_on_continue")
	var btn_new = _add_skew_btn("gamepad", "NEW GAME", "معركة جديدة (50 زومبي)", "_on_new_game")
	var btn_mobile = _add_skew_btn("mobile", "TOUCH CONTROLS", _get_mobile_str_ar(), "_on_mobile_toggle")
	var btn_settings = _add_skew_btn("gear", "SETTINGS", "الإعدادات التكتيكية", "_on_settings_open")
	var btn_credits = _add_skew_btn("monitor", "CREDITS", "فريق العمل والمطور", "_on_credits_open")
	var btn_quit = _add_skew_btn("quit", "QUIT", "خروج من اللعبة", "_on_quit")

	btn_continue.grab_focus()

	# ============================================================
	# BOTTOM COMMAND STRIP (Keybind Pills & Version Status)
	# ============================================================
	var bottom_bar = HBoxContainer.new()
	bottom_bar.anchor_right = 1.0
	bottom_bar.anchor_top = 1.0
	bottom_bar.margin_left = 40
	bottom_bar.margin_right = -40
	bottom_bar.margin_top = -42
	bottom_bar.margin_bottom = -16
	bottom_bar.set("custom_constants/separation", 10)
	root_ctrl.add_child(bottom_bar)

	_add_keybind_pill(bottom_bar, "WASD", "حركة")
	_add_keybind_pill(bottom_bar, "MOUSE", "تصويب وإطلاق")
	_add_keybind_pill(bottom_bar, "R", "تلقيم سريع")
	_add_keybind_pill(bottom_bar, "C", "زحلقة قتالية")
	_add_keybind_pill(bottom_bar, "1-4", "تبديل الأسلحة")
	_add_keybind_pill(bottom_bar, "ESC", "قائمة الإيقاف")

	# Quick Intel Dossier Button
	var intel_btn = Button.new()
	intel_btn.text = "[ INTEL ]  " + Arabic.t("ملف الاستخبارات")
	intel_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	intel_btn.connect("pressed", self, "_on_dossier_open")
	bottom_bar.add_child(intel_btn)

	var bot_sp = Control.new()
	bot_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_bar.add_child(bot_sp)

	var ver_lbl = Label.new()
	ver_lbl.text = "BLACK FATE (LAB-03) v1.0.0 (BETA)  //  GODOT GLES2 60 FPS"
	ver_lbl.add_color_override("font_color", Color(0.45, 0.55, 0.65))
	if font_sm: ver_lbl.add_font_override("font", font_sm)
	bottom_bar.add_child(ver_lbl)

	# ============================================================
	# POPUP MODALS: SETTINGS, CREDITS & INTEL DOSSIER
	# ============================================================
	_build_modals()

func _add_skew_btn(icon_type: String, en_text: String, ar_text: String, callback_name: String) -> SkewMenuButton:
	var b = SkewMenuButton.new(tex_btn_normal, tex_btn_hover, tex_btn_pressed, icon_type, en_text, ar_text, font_med, font_sm)
	b.connect("pressed", self, callback_name)
	buttons_col.add_child(b)
	return b

func _add_keybind_pill(parent: Control, key: String, desc_ar: String) -> void:
	var pill = PanelContainer.new()
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.10, 0.14, 0.85)
	s.border_color = Color(0.25, 0.32, 0.42, 0.7)
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 2
	s.content_margin_bottom = 2
	pill.add_stylebox_override("panel", s)
	parent.add_child(pill)

	var lbl = Label.new()
	lbl.text = "[" + key + "] " + Arabic.t(desc_ar)
	lbl.add_color_override("font_color", Color(0.8, 0.85, 0.92))
	if font_sm: lbl.add_font_override("font", font_sm)
	pill.add_child(lbl)

func _build_modals() -> void:
	# 1. Settings Modal
	settings_modal = PanelContainer.new()
	settings_modal.name = "settings_modal"
	settings_modal.anchor_left = 0.5
	settings_modal.anchor_top = 0.5
	settings_modal.anchor_right = 0.5
	settings_modal.anchor_bottom = 0.5
	settings_modal.margin_left = -260
	settings_modal.margin_right = 260
	settings_modal.margin_top = -180
	settings_modal.margin_bottom = 180
	var s_box = StyleBoxFlat.new()
	s_box.bg_color = Color(0.06, 0.07, 0.10, 0.96)
	s_box.border_color = Color(0.9, 0.2, 0.2, 0.9)
	s_box.set_border_width_all(2)
	s_box.set_corner_radius_all(10)
	s_box.content_margin_left = 24
	s_box.content_margin_right = 24
	s_box.content_margin_top = 20
	s_box.content_margin_bottom = 20
	settings_modal.add_stylebox_override("panel", s_box)
	settings_modal.visible = false
	root_ctrl.add_child(settings_modal)

	var s_v = VBoxContainer.new()
	s_v.set("custom_constants/separation", 14)
	settings_modal.add_child(s_v)

	var s_title = Label.new()
	s_title.text = "[*]  " + Arabic.t("الإعدادات التكتيكية") + "  //  SETTINGS"
	s_title.align = Label.ALIGN_CENTER
	s_title.add_color_override("font_color", Color(1.0, 0.85, 0.25))
	if font_lg: s_title.add_font_override("font", font_lg)
	s_v.add_child(s_title)

	var s_mob_btn = Button.new()
	s_mob_btn.text = Arabic.t("أزرار شاشة اللمس:") + " " + _get_mobile_str_ar()
	s_mob_btn.connect("pressed", self, "_on_mobile_toggle")
	s_v.add_child(s_mob_btn)

	var s_hud_btn = Button.new()
	s_hud_btn.text = Arabic.t("تخصيص مكان أزرار اللمس (HUD Editor)")
	s_hud_btn.connect("pressed", self, "_on_customize_hud")
	s_v.add_child(s_hud_btn)

	var s_close = Button.new()
	s_close.text = Arabic.t("إغلاق الإعدادات") + " [X]"
	s_close.connect("pressed", self, "_on_modal_close")
	s_v.add_child(s_close)

	# 2. Credits Modal
	credits_modal = PanelContainer.new()
	credits_modal.name = "credits_modal"
	credits_modal.anchor_left = 0.5
	credits_modal.anchor_top = 0.5
	credits_modal.anchor_right = 0.5
	credits_modal.anchor_bottom = 0.5
	credits_modal.margin_left = -260
	credits_modal.margin_right = 260
	credits_modal.margin_top = -180
	credits_modal.margin_bottom = 180
	var c_box = StyleBoxFlat.new()
	c_box.bg_color = Color(0.06, 0.07, 0.10, 0.96)
	c_box.border_color = Color(1.0, 0.85, 0.25, 0.9)
	c_box.set_border_width_all(2)
	c_box.set_corner_radius_all(10)
	c_box.content_margin_left = 24
	c_box.content_margin_right = 24
	c_box.content_margin_top = 20
	c_box.content_margin_bottom = 20
	credits_modal.add_stylebox_override("panel", c_box)
	credits_modal.visible = false
	root_ctrl.add_child(credits_modal)

	var c_v = VBoxContainer.new()
	c_v.set("custom_constants/separation", 14)
	credits_modal.add_child(c_v)

	var c_title = Label.new()
	c_title.text = "[ ARCHITECT & LEAD DEVELOPER ]"
	c_title.align = Label.ALIGN_CENTER
	c_title.add_color_override("font_color", Color(1.0, 0.85, 0.25))
	if font_lg: c_title.add_font_override("font", font_lg)
	c_v.add_child(c_title)

	var c_name = Label.new()
	c_name.text = Arabic.t("تطوير وبرمجة اللعبة بالكامل:") + "\n" + "MOHAMED EMAD (محمد عماد)"
	c_name.align = Label.ALIGN_CENTER
	c_name.add_color_override("font_color", Color(1.0, 0.3, 0.3))
	if font_med: c_name.add_font_override("font", font_med)
	c_v.add_child(c_name)

	var c_desc = Label.new()
	c_desc.text = "BLACK FATE (LAB-03)\nAAA Zombie Survival Horror Experience\nBuilt with Godot Engine GLES2"
	c_desc.align = Label.ALIGN_CENTER
	c_desc.add_color_override("font_color", Color(0.8, 0.85, 0.92))
	if font_sm: c_desc.add_font_override("font", font_sm)
	c_v.add_child(c_desc)

	var c_close = Button.new()
	c_close.text = Arabic.t("إغلاق النافذة") + " [X]"
	c_close.connect("pressed", self, "_on_modal_close")
	c_v.add_child(c_close)

	# 3. Holographic Dossier Modal (Pop-up Intel)
	dossier_modal = PanelContainer.new()
	dossier_modal.name = "dossier_modal"
	dossier_modal.anchor_left = 0.5
	dossier_modal.anchor_top = 0.5
	dossier_modal.anchor_right = 0.5
	dossier_modal.anchor_bottom = 0.5
	dossier_modal.margin_left = -280
	dossier_modal.margin_right = 280
	dossier_modal.margin_top = -240
	dossier_modal.margin_bottom = 240
	var d_box = StyleBoxFlat.new()
	d_box.bg_color = Color(0.04, 0.055, 0.085, 0.96)
	d_box.border_color = Color(0.85, 0.22, 0.22, 0.95)
	d_box.set_border_width_all(2)
	d_box.set_corner_radius_all(10)
	d_box.content_margin_left = 22
	d_box.content_margin_right = 22
	d_box.content_margin_top = 18
	d_box.content_margin_bottom = 18
	dossier_modal.add_stylebox_override("panel", d_box)
	dossier_modal.visible = false
	root_ctrl.add_child(dossier_modal)

	var d_vbox = VBoxContainer.new()
	d_vbox.set("custom_constants/separation", 10)
	dossier_modal.add_child(d_vbox)

	var d_head = HBoxContainer.new()
	d_vbox.add_child(d_head)

	var d_t = Label.new()
	d_t.text = "[ INTEL ]  " + Arabic.t("ملف استخبارات مختبر LAB-03")
	d_t.add_color_override("font_color", Color(1.0, 0.85, 0.25))
	if font_lg: d_t.add_font_override("font", font_lg)
	d_head.add_child(d_t)

	var d_sp = Control.new()
	d_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	d_head.add_child(d_sp)

	var d_tag = Label.new()
	d_tag.text = "[ LEVEL 4 BREACH ]"
	d_tag.add_color_override("font_color", Color(1.0, 0.25, 0.25))
	if font_sm: d_tag.add_font_override("font", font_sm)
	d_head.add_child(d_tag)

	var d_sep = HSeparator.new()
	d_vbox.add_child(d_sep)

	_add_dossier_entry(d_vbox, "[THREAT]", "مستوى التهديد البيولوجي", "حرج للغاية ومميت (CRITICAL APEX MUTATION)", Color(1.0, 0.25, 0.25))
	_add_dossier_entry(d_vbox, "[HORDE]", "حشد الأعداء", "50 زومبي مصاب + الوحش العملاق جليات تيتان", Color(0.95, 0.45, 0.2))
	_add_dossier_entry(d_vbox, "[WEAPONS]", "ترسانة الأسلحة المتاحة", "Glock 17, Kriss Vector, Mk23, Sniper 7.62", Color(0.25, 0.85, 1.0))
	_add_dossier_entry(d_vbox, "[COMBAT]", "بروتوكول القتال الفوري", "إصابة الرأس القاتلة بطلقة واحدة (1-Shot Headshot Kill)", Color(0.25, 1.0, 0.45))
	_add_dossier_entry(d_vbox, "[HEALTH]", "نظام البقاء واستعادة الصحة", "امتصاص كبسولات دماء الزومبي لتجديد الصحة +50 HP", Color(1.0, 0.3, 0.35))
	_add_dossier_entry(d_vbox, "[MISSION]", "الهدف العملياتي النهائي", "تطهير المنشأة بالكامل والبقاء على قيد الحياة!", Color(1.0, 0.9, 0.3))

	var d_close = Button.new()
	d_close.text = Arabic.t("إغلاق الملف") + " [X]"
	d_close.connect("pressed", self, "_on_modal_close")
	d_vbox.add_child(d_close)

func _add_dossier_entry(parent: Control, icon: String, title_ar: String, detail_ar: String, col: Color) -> void:
	var c = HBoxContainer.new()
	c.set("custom_constants/separation", 10)
	parent.add_child(c)

	var icn_lbl = Label.new()
	icn_lbl.text = icon
	icn_lbl.rect_min_size = Vector2(90, 0)
	icn_lbl.add_color_override("font_color", col)
	if font_reg: icn_lbl.add_font_override("font", font_reg)
	c.add_child(icn_lbl)

	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.set("custom_constants/separation", 2)
	c.add_child(v)

	var t_lbl = Label.new()
	t_lbl.text = Arabic.t(title_ar)
	t_lbl.add_color_override("font_color", Color(0.7, 0.76, 0.85))
	if font_sm: t_lbl.add_font_override("font", font_sm)
	v.add_child(t_lbl)

	var d_lbl = Label.new()
	d_lbl.text = Arabic.t(detail_ar)
	d_lbl.add_color_override("font_color", col)
	if font_reg: d_lbl.add_font_override("font", font_reg)
	v.add_child(d_lbl)

func _process(delta: float) -> void:
	pulse_time += delta

	# Mouse-Driven 3D Parallax Movement with safe margins
	var vp = get_viewport()
	if vp:
		var vp_sz = vp.size
		if vp_sz.x > 0 and vp_sz.y > 0:
			var m_norm = (vp.get_mouse_position() / vp_sz) - Vector2(0.5, 0.5)
			target_bg_pos = bg_base_pos - (m_norm * Vector2(36.0, 22.0))
			if bg_rect:
				bg_rect.rect_position = bg_rect.rect_position.linear_interpolate(target_bg_pos, delta * 5.0)

	# Floating animation for logo and slogan
	if logo_rect:
		logo_rect.rect_position.y = sin(pulse_time * 1.6) * 3.0
	if slogan_rect:
		slogan_rect.rect_position.y = 52.0 + sin(pulse_time * 1.4) * 4.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.scancode == KEY_F11:
		OS.window_fullscreen = !OS.window_fullscreen

func _get_mobile_str_ar() -> String:
	var cur = ProjectSettings.get_setting("custom/mobile_touch_enabled")
	if cur != null and bool(cur):
		return "مفعل دائماً (ON)"
	return "تلقائي (فقط على الهواتف)"

func _on_continue() -> void:
	get_tree().change_scene("res://data/scenes/match_loading.tscn")

func _on_new_game() -> void:
	get_tree().change_scene("res://data/scenes/match_loading.tscn")

func _on_mobile_toggle() -> void:
	var cur = ProjectSettings.get_setting("custom/mobile_touch_enabled")
	var new_val = true if (cur == null or not bool(cur)) else false
	ProjectSettings.set_setting("custom/mobile_touch_enabled", new_val)
	if buttons_col and buttons_col.get_child_count() > 2:
		var btn = buttons_col.get_child(2) as SkewMenuButton
		if btn and btn.label_ar:
			btn.label_ar.text = Arabic.t(_get_mobile_str_ar())

func _on_customize_hud() -> void:
	get_tree().change_scene("res://data/scenes/main.tscn")

func _on_settings_open() -> void:
	credits_modal.visible = false
	dossier_modal.visible = false
	settings_modal.visible = true

func _on_credits_open() -> void:
	settings_modal.visible = false
	dossier_modal.visible = false
	credits_modal.visible = true

func _on_dossier_open() -> void:
	settings_modal.visible = false
	credits_modal.visible = false
	dossier_modal.visible = true

func _on_modal_close() -> void:
	settings_modal.visible = false
	credits_modal.visible = false
	dossier_modal.visible = false

func _on_quit() -> void:
	get_tree().quit(0)
