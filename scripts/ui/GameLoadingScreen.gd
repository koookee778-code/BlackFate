extends Control

# ============================================================
#  BLACK FATE (LAB-03) — IN-GAME ASYNC LOADING SCREEN
#  تطوير وبرمجة المطور: محمد عماد (Mohamed Emad)
# ============================================================

const Arabic = preload("res://data/scripts/utils/arabic.gd")

var bg_rect : TextureRect
var overlay_shader : ColorRect
var logo_rect : TextureRect
var header_lbl : Label
var dev_lbl : Label
var bar_progress : TextureProgress
var percent_lbl : Label
var tip_lbl : Label

var font_title : DynamicFont
var font_lg : DynamicFont
var font_med : DynamicFont
var font_reg : DynamicFont
var font_sm : DynamicFont

var progress : float = 0.0
var target_progress : float = 0.0
var is_finished : bool = false
var ready_for_input : bool = false
var pulse_time : float = 0.0

var tip_timer : float = 0.0
var current_tip_idx : int = 0

var tips = [
	"Tip: Stay alert... The nightmare is not over yet.",
	"نصيحة تكتيكية: طلقات الرأس بالقناصة تسقط الزومبي فورياً بطلقة واحدة قاتلة!",
	"Tip: Aim for the head or bio-cores to stagger LAB-03 mutants.",
	"نصيحة تكتيكية: اقترب من كبسولات الدماء الحمراء المتوهجة لاستعادة صحتك +50 HP!",
	"Tip: Conserve your ammunition—containment breaches attract more hostiles.",
	"نصيحة تكتيكية: استخدم الزحلقة القتالية بحرف C للمراوغة السريعة عند محاصرة الزومبي لك!"
]

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

	_build_ui()
	_update_fullscreen_layout()
	get_viewport().connect("size_changed", self, "_update_fullscreen_layout")

func _build_ui() -> void:
	# 1. Full-screen Covered Background (Goliath Titan in Cylinder)
	bg_rect = TextureRect.new()
	bg_rect.name = "bg_rect"
	bg_rect.expand = true
	bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bg_t = _load_texture_safe("res://data/ui/bg_game_loading_clean.png")
	if bg_t:
		bg_rect.texture = bg_t
	add_child(bg_rect)

	# 2. Cinematic LAB-03 Atmosphere Shader
	overlay_shader = ColorRect.new()
	overlay_shader.name = "overlay_shader"
	overlay_shader.anchor_right = 1.0
	overlay_shader.anchor_bottom = 1.0
	overlay_shader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s_res = load("res://data/shaders/lab03_atmosphere.gdshader")
	if s_res is Shader:
		var mat = ShaderMaterial.new()
		mat.shader = s_res
		mat.set_shader_param("vignette_intensity", 0.68)
		mat.set_shader_param("red_pulse_strength", 0.08)
		mat.set_shader_param("scanline_alpha", 0.035)
		mat.set_shader_param("time_scale", 1.5)
		overlay_shader.material = mat
	add_child(overlay_shader)

	# 3. Top Classification Strip
	var top_bar = HBoxContainer.new()
	top_bar.anchor_right = 1.0
	top_bar.margin_left = 36
	top_bar.margin_right = -36
	top_bar.margin_top = 18
	top_bar.margin_bottom = 44
	add_child(top_bar)

	var class_lbl = Label.new()
	class_lbl.text = "[ BIOHAZARD ]  DEPLOYMENT TELEMETRY // ENTERING LAB-03 QUARANTINE"
	class_lbl.add_color_override("font_color", Color(1.0, 0.28, 0.28))
	if font_sm: class_lbl.add_font_override("font", font_sm)
	top_bar.add_child(class_lbl)

	var top_sp = Control.new()
	top_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(top_sp)

	# Developer Prestige Badge
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

	var dev_top_lbl = Label.new()
	dev_top_lbl.text = "[ ARCHITECT ]  " + Arabic.t("تطوير وبرمجة اللعبة: محمد عماد") + "  //  DEVELOPED BY MOHAMED EMAD"
	dev_top_lbl.add_color_override("font_color", Color(1.0, 0.85, 0.25))
	if font_sm: dev_top_lbl.add_font_override("font", font_sm)
	dev_badge.add_child(dev_top_lbl)

	# 4. Right Side HUD Container (Matching ref_loading_mockup.png)
	var right_hud = VBoxContainer.new()
	right_hud.name = "right_hud"
	right_hud.rect_position = Vector2(580, 160)
	right_hud.rect_size = Vector2(660, 480)
	right_hud.set("custom_constants/separation", 14)
	add_child(right_hud)

	var logo_center = CenterContainer.new()
	logo_center.rect_min_size = Vector2(0, 150)
	right_hud.add_child(logo_center)

	logo_rect = TextureRect.new()
	logo_rect.name = "logo_rect"
	var logo_t = _load_texture_safe("res://data/ui/logo_black_fate.png")
	if logo_t:
		logo_rect.texture = logo_t
		logo_rect.rect_min_size = Vector2(460, 180)
		logo_rect.expand = true
		logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_center.add_child(logo_rect)

	header_lbl = Label.new()
	header_lbl.text = "— Loading... —"
	header_lbl.align = Label.ALIGN_CENTER
	header_lbl.add_color_override("font_color", Color(0.85, 0.90, 0.98))
	if font_lg: header_lbl.add_font_override("font", font_lg)
	right_hud.add_child(header_lbl)

	dev_lbl = Label.new()
	dev_lbl.text = ">>>  Mohamed Emad  <<<"
	dev_lbl.align = Label.ALIGN_CENTER
	dev_lbl.add_color_override("font_color", Color(1.0, 0.22, 0.22))
	if font_lg: dev_lbl.add_font_override("font", font_lg)
	right_hud.add_child(dev_lbl)

	var bar_row = HBoxContainer.new()
	bar_row.rect_min_size = Vector2(0, 42)
	bar_row.set("custom_constants/separation", 14)
	right_hud.add_child(bar_row)

	bar_progress = TextureProgress.new()
	bar_progress.name = "bar_progress"
	bar_progress.min_value = 0.0
	bar_progress.max_value = 100.0
	bar_progress.value = 0.0
	bar_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_progress.rect_min_size = Vector2(560, 36)
	bar_progress.nine_patch_stretch = true
	var under_t = _load_texture_safe("res://data/ui/loading_bar_under.png")
	var fill_t = _load_texture_safe("res://data/ui/loading_bar_fill.png")
	if under_t: bar_progress.texture_under = under_t
	if fill_t: bar_progress.texture_progress = fill_t
	bar_row.add_child(bar_progress)

	percent_lbl = Label.new()
	percent_lbl.text = "0%"
	percent_lbl.rect_min_size = Vector2(60, 0)
	percent_lbl.add_color_override("font_color", Color(1.0, 0.85, 0.25))
	if font_med: percent_lbl.add_font_override("font", font_med)
	bar_row.add_child(percent_lbl)

	tip_lbl = Label.new()
	tip_lbl.text = _format_tip(0)
	tip_lbl.align = Label.ALIGN_CENTER
	tip_lbl.add_color_override("font_color", Color(0.85, 0.88, 0.95))
	if font_sm: tip_lbl.add_font_override("font", font_sm)
	right_hud.add_child(tip_lbl)

func _update_fullscreen_layout() -> void:
	var vp = get_viewport()
	if vp and bg_rect:
		var sz = vp.size
		var margin = 60.0
		bg_rect.rect_position = -Vector2(margin, margin)
		bg_rect.rect_size = sz + Vector2(margin * 2.0, margin * 2.0)

func _format_tip(idx: int) -> String:
	var t = tips[idx]
	if t.begins_with("نصيحة"):
		return "[!]  " + Arabic.t(t)
	return "[!]  " + t

func _process(delta: float) -> void:
	pulse_time += delta

	# Ken Burns Effect on Background
	if bg_rect:
		var s = 1.0 + sin(pulse_time * 0.7) * 0.015
		bg_rect.rect_scale = Vector2(s, s)
		bg_rect.rect_pivot_offset = bg_rect.rect_size * 0.5

	# Tip cycle
	tip_timer += delta
	if tip_timer >= 3.6:
		tip_timer = 0.0
		current_tip_idx = (current_tip_idx + 1) % tips.size()
		if tip_lbl:
			tip_lbl.text = _format_tip(current_tip_idx)

	if not is_finished:
		progress = lerp(progress, 1.0, 0.55 * delta)

		var pct_val = int(clamp(progress, 0.0, 1.0) * 100.0)
		if bar_progress:
			bar_progress.value = pct_val
		if percent_lbl:
			percent_lbl.text = str(pct_val) + "%"

		if progress >= 0.985:
			progress = 1.0
			is_finished = true
			ready_for_input = true
			if header_lbl:
				header_lbl.text = "—  PRESS ANY KEY TO ENTER LAB-03  —"
				header_lbl.set("custom_colors/font_color", Color(1.0, 0.85, 0.25))

	if ready_for_input and header_lbl:
		var a = 0.45 + 0.55 * sin(pulse_time * 5.0)
		header_lbl.modulate = Color(1.0, 1.0, 1.0, a)

func _unhandled_input(event: InputEvent) -> void:
	if not ready_for_input:
		return
	if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		ready_for_input = false
		_enter_game()

func _enter_game() -> void:
	var tw = Tween.new()
	add_child(tw)
	tw.interpolate_property(self, "modulate", Color(1, 1, 1, 1), Color(0, 0, 0, 1), 0.35, Tween.TRANS_SINE, Tween.EASE_OUT)
	tw.start()
	yield(tw, "tween_completed")
	get_tree().change_scene("res://data/scenes/main.tscn")
