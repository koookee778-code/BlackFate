extends CanvasLayer

export(NodePath) var weapon;
export(NodePath) var weapon_hud;
export(NodePath) var crosshair;

var damage_rect : ColorRect
var heal_rect : ColorRect
var heal_text_label : Label
var heal_text_timer : float = 0.0

# Headshot indicator
var headshot_label : Label
var headshot_timer : float = 0.0

# Death screen elements
var death_overlay : ColorRect
var death_title : Label
var death_countdown_label : Label
var is_showing_death : bool = false

# Victory screen elements
var victory_overlay : ColorRect
var victory_title : Label
var victory_subtitle : Label
var is_showing_victory : bool = false

# Sniper scope overlay
var sniper_scope : Control
var is_sniper_scoped : bool = false

# Custom HUD elements
var pubg_health_bar : Control
var gta_weapon_card : Control
var horde_and_boss_ui : Control
var tactical_crosshair : Control

# Tracking for weapon changes
var last_weapon_index : int = -1
var last_bullets : int = -1
var gta_card_timer : float = 3.0
var gta_card_alpha : float = 1.0

const Arabic = preload("res://data/scripts/utils/arabic.gd")

# High-Visibility Dual-Tone Tactical Crosshair with Hitmarkers
class TacticalCrosshair extends Control:
	var hitmarker_timer : float = 0.0
	var is_headshot_hit : bool = false
	var spread : float = 0.0
	var is_visible : bool = true

	func _draw():
		if not is_visible:
			return
		var center = rect_size / 2.0
		var gap = 6.0 + spread
		var length = 11.0
		var thickness = 2.0
		
		# High-contrast dual-tone: Dark drop-shadow outline with bright neon core
		# Ensures 100% visibility on all backgrounds (dark rooms, bright lights, red blood)
		var shadow_col = Color(0.01, 0.01, 0.02, 0.95)
		var core_col = Color(0.15, 1.0, 0.45, 0.98) # Tactical bright neon green
		
		# 1. Center precision dot
		draw_circle(center, 2.5, shadow_col)
		draw_circle(center, 1.5, core_col)
		
		# 2. Four crosshair bars with shadow
		# Top
		draw_line(center - Vector2(0, gap), center - Vector2(0, gap + length), shadow_col, thickness + 2.0)
		draw_line(center - Vector2(0, gap), center - Vector2(0, gap + length), core_col, thickness)
		# Bottom
		draw_line(center + Vector2(0, gap), center + Vector2(0, gap + length), shadow_col, thickness + 2.0)
		draw_line(center + Vector2(0, gap), center + Vector2(0, gap + length), core_col, thickness)
		# Left
		draw_line(center - Vector2(gap, 0), center - Vector2(gap + length, 0), shadow_col, thickness + 2.0)
		draw_line(center - Vector2(gap, 0), center - Vector2(gap + length, 0), core_col, thickness)
		# Right
		draw_line(center + Vector2(gap, 0), center + Vector2(gap + length, 0), shadow_col, thickness + 2.0)
		draw_line(center + Vector2(gap, 0), center + Vector2(gap + length, 0), core_col, thickness)
		
		# 3. Tactical Corner brackets around reticle
		var b_gap = gap + length + 4.0
		var b_len = 5.0
		var b_col = Color(0.15, 1.0, 0.45, 0.35)
		draw_line(center + Vector2(-b_gap, -b_gap), center + Vector2(-b_gap + b_len, -b_gap), b_col, 1.2)
		draw_line(center + Vector2(-b_gap, -b_gap), center + Vector2(-b_gap, -b_gap + b_len), b_col, 1.2)
		draw_line(center + Vector2(b_gap, -b_gap), center + Vector2(b_gap - b_len, -b_gap), b_col, 1.2)
		draw_line(center + Vector2(b_gap, -b_gap), center + Vector2(b_gap, -b_gap + b_len), b_col, 1.2)
		draw_line(center + Vector2(-b_gap, b_gap), center + Vector2(-b_gap + b_len, b_gap), b_col, 1.2)
		draw_line(center + Vector2(-b_gap, b_gap), center + Vector2(-b_gap, b_gap - b_len), b_col, 1.2)
		draw_line(center + Vector2(b_gap, b_gap), center + Vector2(b_gap - b_len, b_gap), b_col, 1.2)
		draw_line(center + Vector2(b_gap, b_gap), center + Vector2(b_gap, b_gap - b_len), b_col, 1.2)

		# 4. Animated Hitmarker ("X") with fade
		if hitmarker_timer > 0.0:
			var hm_alpha = clamp(hitmarker_timer * 3.5, 0.0, 1.0)
			var hm_col = Color(1.0, 0.15, 0.15, hm_alpha) if is_headshot_hit else Color(1.0, 1.0, 1.0, hm_alpha)
			var hm_size = 14.0 if is_headshot_hit else 9.0
			var hm_g = 5.0
			var hm_thick = 2.8 if is_headshot_hit else 2.0
			
			draw_line(center + Vector2(-hm_g, -hm_g), center + Vector2(-hm_g - hm_size, -hm_g - hm_size), hm_col, hm_thick)
			draw_line(center + Vector2(hm_g, -hm_g), center + Vector2(hm_g + hm_size, -hm_g - hm_size), hm_col, hm_thick)
			draw_line(center + Vector2(-hm_g, hm_g), center + Vector2(-hm_g - hm_size, hm_g + hm_size), hm_col, hm_thick)
			draw_line(center + Vector2(hm_g, hm_g), center + Vector2(hm_g + hm_size, hm_g + hm_size), hm_col, hm_thick)

# Enhanced Military Optical Sniper Scope
class ScopeReticle extends Control:
	const Arabic = preload("res://data/scripts/utils/arabic.gd")

	func _draw():
		var sz = get_viewport_rect().size if get_viewport() else rect_size
		if sz.x <= 1.0 or sz.y <= 1.0:
			sz = Vector2(1280, 720)
		var center = sz / 2.0
		var radius = min(sz.x, sz.y) * 0.42
		
		# 1. 100% Solid Gapless Outer Black Mask (4 outer rects + concentric seal rings)
		var bg_col = Color(0.01, 0.01, 0.02, 1.0)
		draw_rect(Rect2(0, 0, sz.x, max(0.0, center.y - radius)), bg_col, true)
		draw_rect(Rect2(0, center.y + radius, sz.x, max(0.0, sz.y - (center.y + radius))), bg_col, true)
		draw_rect(Rect2(0, 0, max(0.0, center.x - radius), sz.y), bg_col, true)
		draw_rect(Rect2(center.x + radius, 0, max(0.0, sz.x - (center.x + radius)), sz.y), bg_col, true)
		for ring in range(1, 16):
			draw_arc(center, radius + (ring * 12.0), 0, TAU, 64, bg_col, 16.0, false)
		
		# 2. Steel chassis bezel rings
		draw_arc(center, radius + 4.0, 0, TAU, 96, Color(0.08, 0.09, 0.11, 1.0), 8.0, false)
		draw_arc(center, radius, 0, TAU, 96, Color(0.35, 0.38, 0.42, 0.95), 2.5, false)
		draw_arc(center, radius - 3.0, 0, TAU, 96, Color(0.02, 0.03, 0.04, 0.95), 2.0, false)
		
		# 3. Emerald optical anti-reflection lens coating
		draw_circle(center, radius - 4.0, Color(0.02, 0.08, 0.04, 0.07))
		draw_arc(center, radius - 8.0, 0, TAU, 64, Color(0.1, 0.65, 0.3, 0.12), 4.0, false)
		
		# 4. Fine military mil-dot crosshair lines
		var line_col = Color(0.04, 0.05, 0.06, 0.98)
		draw_line(center - Vector2(radius * 0.95, 0), center + Vector2(radius * 0.95, 0), line_col, 2.0)
		draw_line(center - Vector2(0, radius * 0.95), center + Vector2(0, radius * 0.95), line_col, 2.0)
		
		# 5. Mil-dot elevation & windage hash marks
		for i in range(1, 7):
			var d = i * (radius * 0.14)
			var tick_len = 9.0 if i % 2 == 0 else 5.5
			draw_line(center + Vector2(d, -tick_len), center + Vector2(d, tick_len), line_col, 1.5)
			draw_line(center - Vector2(d, -tick_len), center - Vector2(d, tick_len), line_col, 1.5)
			draw_line(center + Vector2(-tick_len, d), center + Vector2(tick_len, d), line_col, 1.5)
			draw_line(center + Vector2(-tick_len, -d), center + Vector2(tick_len, -d), line_col, 1.5)
		
		# 6. Center precision illuminated chevron & lethal red dot
		draw_circle(center, 2.5, Color(1.0, 0.08, 0.08, 0.98))
		draw_arc(center, 8.0, 0, TAU, 24, Color(1.0, 0.15, 0.15, 0.6), 1.5, true)
		
		# 7. Tactical Scope Telemetry Readouts
		var font = get_font("font")
		if font:
			var green_col = Color(0.2, 0.95, 0.35, 0.88)
			draw_string(font, center + Vector2(-radius + 25, -radius + 35), "[ 8.0X OPTICAL MAGNIFICATION ]", green_col)
			draw_string(font, center + Vector2(radius - 195, -radius + 35), "CALIBER: 7.62x51mm AP", green_col)
			draw_string(font, center + Vector2(-radius + 25, radius - 25), "ELEV: +0.0  |  WIND: 0.0 M/S", green_col)
			draw_string(font, center + Vector2(radius - 180, radius - 25), "TARGET: LAB-03 STABILIZED", Color(1.0, 0.25, 0.25, 0.88))

# Top-Center Horde Counter and Giant Boss Health Bar Control
class BossAndHordeUI extends Control:
	const Arabic = preload("res://data/scripts/utils/arabic.gd")
	var zombies_remaining : int = 50
	var total_zombies : int = 50
	var is_boss_active : bool = false
	var boss_hp : float = 2500.0
	var boss_max_hp : float = 2500.0
	var boss_ghost_hp : float = 2500.0
	var boss_name : String = "GOLIATH TITAN - MUTANT APEX"
	var pulse_time : float = 0.0

	func _draw():
		var w = rect_size.x
		var h = rect_size.y
		var font = get_font("font")
		
		if not is_boss_active:
			# === 1. ZOMBIE HORDE COUNTER (50 Zombies in match) ===
			# Outer dark tactical box
			draw_rect(Rect2(0, 0, w, h), Color(0.04, 0.05, 0.07, 0.85))
			draw_rect(Rect2(0, 0, w, h), Color(0.45, 0.15, 0.15, 0.85), false, 1.5)
			
			# Progress bar along bottom
			var killed = total_zombies - zombies_remaining
			var progress_ratio = clamp(float(killed) / float(max(1, total_zombies)), 0.0, 1.0)
			draw_rect(Rect2(0, h - 3, w * progress_ratio, 3), Color(0.9, 0.18, 0.18, 0.95))
			
			if font:
				var status_text = "[ " + Arabic.t("الزومبي المتبقي:") + " " + str(zombies_remaining) + " / " + str(total_zombies) + " ]"
				var sz = font.get_string_size(status_text)
				var pos = Vector2((w - sz.x) * 0.5, (h + sz.y * 0.5) * 0.5 + 1)
				draw_string(font, pos + Vector2(1, 1), status_text, Color(0, 0, 0, 0.9))
				draw_string(font, pos, status_text, Color(1.0, 0.25, 0.25))
		else:
			# === 2. GIANT MUTANT BOSS HEALTH BAR ===
			# Boss Title
			if font:
				var title_str = "[ " + Arabic.t("زعيم الزومبي: جليات تيتان") + " (GOLIATH TITAN) ]"
				var title_sz = font.get_string_size(title_str)
				var title_pos = Vector2((w - title_sz.x) * 0.5, -6)
				draw_string(font, title_pos + Vector2(1, 1), title_str, Color(0, 0, 0, 0.95))
				draw_string(font, title_pos, title_str, Color(1.0, 0.2, 0.15))
			
			# Background bar
			draw_rect(Rect2(-2, -2, w + 4, h + 4), Color(0.02, 0.02, 0.03, 0.9))
			draw_rect(Rect2(0, 0, w, h), Color(0.08, 0.09, 0.10, 0.95))
			
			var hp_ratio = clamp(boss_hp / max(1.0, boss_max_hp), 0.0, 1.0)
			var ghost_ratio = clamp(boss_ghost_hp / max(1.0, boss_max_hp), 0.0, 1.0)
			
			# Ghost trailing bar
			if ghost_ratio > hp_ratio:
				draw_rect(Rect2(0, 0, w * ghost_ratio, h), Color(0.95, 0.35, 0.1, 0.9))
				
			# Main Boss Health fill (Deep pulsating crimson)
			var fill_w = w * hp_ratio
			var flash = (sin(pulse_time * 8.0) + 1.0) * 0.15
			var fill_col = Color(0.85 + flash, 0.05, 0.08, 0.95)
			if fill_w > 0:
				draw_rect(Rect2(0, 0, fill_w, h), fill_col)
				draw_rect(Rect2(0, 0, fill_w, h * 0.35), Color(1, 1, 1, 0.2))
				
			# Segment marks every 10%
			for i in range(1, 10):
				var sx = w * (float(i) * 0.1)
				draw_line(Vector2(sx, 0), Vector2(sx, h), Color(0.04, 0.04, 0.05, 0.8), 1.5)
				
			draw_rect(Rect2(0, 0, w, h), Color(0.8, 0.2, 0.2, 0.9), false, 2.0)
			
			# Numerical Boss HP
			if font:
				var hp_str = str(int(boss_hp)) + " / " + str(int(boss_max_hp)) + " (" + str(int(hp_ratio * 100.0)) + "%)"
				var hp_sz = font.get_string_size(hp_str)
				var hp_pos = Vector2((w - hp_sz.x) * 0.5, (h + hp_sz.y * 0.5) * 0.5)
				draw_string(font, hp_pos + Vector2(1, 1), hp_str, Color(0, 0, 0, 0.95))
				draw_string(font, hp_pos, hp_str, Color(1, 1, 1, 0.98))

# PUBG-Style Health Bar Control
class PubgHealthUI extends Control:
	const Arabic = preload("res://data/scripts/utils/arabic.gd")
	var cur_hp : float = 250.0
	var max_hp : float = 250.0
	var ghost_hp : float = 250.0
	var pulse_time : float = 0.0

	func _draw():
		var w = rect_size.x
		var h = rect_size.y
		
		var hp_ratio = clamp(cur_hp / max(1.0, max_hp), 0.0, 1.0)
		var ghost_ratio = clamp(ghost_hp / max(1.0, max_hp), 0.0, 1.0)
		
		# 1. Outer tactical background container
		draw_rect(Rect2(-2, -2, w + 4, h + 4), Color(0.02, 0.03, 0.04, 0.75))
		draw_rect(Rect2(0, 0, w, h), Color(0.08, 0.09, 0.11, 0.88))
		
		# 2. Ghost trailing bar
		if ghost_ratio > hp_ratio:
			var ghost_w = w * ghost_ratio
			draw_rect(Rect2(0, 0, ghost_w, h), Color(0.85, 0.22, 0.18, 0.85))
		
		# 3. Main health fill
		var fill_w = w * hp_ratio
		var fill_col : Color
		if hp_ratio > 0.65:
			fill_col = Color(0.96, 0.98, 1.0, 0.95)
		elif hp_ratio > 0.25:
			fill_col = Color(1.0, 0.80, 0.18, 0.95)
		else:
			var flash = (sin(pulse_time * 12.0) + 1.0) * 0.5
			fill_col = Color(1.0, 0.12 + 0.3 * flash, 0.12, 0.95)
			
		if fill_w > 0:
			draw_rect(Rect2(0, 0, fill_w, h), fill_col)
			draw_rect(Rect2(0, 0, fill_w, h * 0.38), Color(1, 1, 1, 0.2))
		
		# 4. PUBG Segment dividers (4 quarters)
		var div_col = Color(0.04, 0.05, 0.06, 0.95)
		for i in range(1, 4):
			var div_x = w * (float(i) * 0.25)
			draw_line(Vector2(div_x, 0), Vector2(div_x, h), div_col, 2.0)
			
		draw_rect(Rect2(0, 0, w, h), Color(0.35, 0.38, 0.42, 0.75), false, 1.5)
		
		# 5. Adrenaline / Boost Bar on top
		var boost_h = 4.0
		var boost_y = -7.0
		draw_rect(Rect2(0, boost_y, w, boost_h), Color(0.08, 0.09, 0.11, 0.8))
		draw_rect(Rect2(0, boost_y, w * 0.85, boost_h), Color(1.0, 0.58, 0.12, 0.9))
		for i in range(1, 4):
			var bx = w * (float(i) * 0.25)
			draw_line(Vector2(bx, boost_y), Vector2(bx, boost_y + boost_h), div_col, 1.5)
		draw_rect(Rect2(0, boost_y, w, boost_h), Color(0.35, 0.38, 0.42, 0.6), false, 1.0)
		
		# 6. Left Medical Plus Icon
		var plus_pos = Vector2(-22, h * 0.5)
		draw_circle(plus_pos, 8.5, Color(0.08, 0.09, 0.11, 0.9))
		draw_arc(plus_pos, 8.5, 0.0, TAU, 24, Color(0.4, 0.45, 0.5, 0.8), 1.2, true)
		var p_col = Color(1.0, 0.2, 0.2, 0.95) if hp_ratio < 0.25 else Color(0.2, 0.9, 0.4, 0.95)
		draw_line(plus_pos - Vector2(5, 0), plus_pos + Vector2(5, 0), p_col, 2.0)
		draw_line(plus_pos - Vector2(0, 5), plus_pos + Vector2(0, 5), p_col, 2.0)
		
		# 7. Numerical Health Text
		var hp_str = str(int(cur_hp)) + " / " + str(int(max_hp))
		var default_font = get_font("font")
		if default_font:
			var txt_sz = default_font.get_string_size(hp_str)
			var txt_pos = Vector2(w - txt_sz.x - 6, h - 3)
			draw_string(default_font, txt_pos + Vector2(1, 1), hp_str, Color(0, 0, 0, 0.85))
			draw_string(default_font, txt_pos, hp_str, Color(0.1, 0.12, 0.15) if hp_ratio > 0.65 else Color(1, 1, 1))

# GTA-Style Top-Left Weapon Card Control
class GtaWeaponCardUI extends Control:
	const Arabic = preload("res://data/scripts/utils/arabic.gd")
	var weapon_name : String = "KRISS VECTOR"
	var category_name : String = "SUBMACHINE GUN"
	var ammo_bullets : int = 30
	var ammo_reserve : int = 120
	var weapon_id : int = 0
	var card_alpha : float = 1.0

	func _draw():
		if card_alpha <= 0.01:
			return
			
		var w = rect_size.x
		var h = rect_size.y
		
		var bg_col = Color(0.04, 0.05, 0.07, 0.88 * card_alpha)
		var border_col = Color(0.22, 0.26, 0.32, 0.7 * card_alpha)
		var accent_col = Color(0.18, 0.82, 1.0, 0.95 * card_alpha)
		
		draw_rect(Rect2(0, 0, w, h), bg_col)
		draw_rect(Rect2(0, 0, w, h), border_col, false, 1.5)
		draw_rect(Rect2(0, 0, w, 3.5), accent_col)
		
		var icon_col = Color(0.92, 0.94, 0.98, 0.9 * card_alpha)
		_draw_weapon_silhouette(Vector2(48, 44), icon_col)
		
		draw_line(Vector2(92, 12), Vector2(92, h - 12), Color(0.25, 0.3, 0.35, 0.5 * card_alpha), 1.0)
		
		var font = get_font("font")
		if font:
			var cat_col = Color(0.65, 0.75, 0.85, 0.85 * card_alpha)
			draw_string(font, Vector2(102, 26), category_name.to_upper(), cat_col)
			
			var name_col = Color(1.0, 1.0, 1.0, 0.98 * card_alpha)
			draw_string(font, Vector2(102, 45), weapon_name.to_upper(), name_col)
			
			var ammo_str = str(ammo_bullets) + " / " + str(ammo_reserve)
			var ammo_col = Color(0.2, 0.95, 0.45, 0.95 * card_alpha)
			if ammo_bullets <= 5:
				ammo_col = Color(1.0, 0.2, 0.2, 0.95 * card_alpha)
			elif ammo_bullets <= 12:
				ammo_col = Color(1.0, 0.75, 0.2, 0.95 * card_alpha)
			draw_string(font, Vector2(102, 68), ammo_str, ammo_col)

	func _draw_weapon_silhouette(center: Vector2, col: Color):
		var w_lower = weapon_name.to_lower()
		if "sniper" in w_lower:
			draw_rect(Rect2(center.x - 36, center.y - 2, 72, 4), col)
			draw_rect(Rect2(center.x - 16, center.y - 4, 30, 8), col)
			draw_rect(Rect2(center.x - 10, center.y - 12, 22, 5), col)
			draw_line(center + Vector2(-6, -7), center + Vector2(-6, -4), col, 2.0)
			draw_line(center + Vector2(6, -7), center + Vector2(6, -4), col, 2.0)
			draw_rect(Rect2(center.x - 4, center.y + 4, 6, 12), col)
			draw_polygon(PoolVector2Array([
				center + Vector2(-16, -2), center + Vector2(-34, 4), 
				center + Vector2(-34, 12), center + Vector2(-16, 6)
			]), PoolColorArray([col, col, col, col]))
		elif "vector" in w_lower or "kriss" in w_lower:
			draw_rect(Rect2(center.x - 24, center.y - 6, 44, 12), col)
			draw_rect(Rect2(center.x + 20, center.y - 4, 12, 4), col)
			draw_polygon(PoolVector2Array([
				center + Vector2(6, 4), center + Vector2(12, 4),
				center + Vector2(16, 20), center + Vector2(10, 20)
			]), PoolColorArray([col, col, col, col]))
			draw_polygon(PoolVector2Array([
				center + Vector2(-12, 4), center + Vector2(-6, 4),
				center + Vector2(-8, 18), center + Vector2(-14, 18)
			]), PoolColorArray([col, col, col, col]))
			draw_line(center + Vector2(-24, -2), center + Vector2(-34, -2), col, 3.0)
			draw_line(center + Vector2(-34, -2), center + Vector2(-34, 10), col, 3.0)
		else:
			draw_rect(Rect2(center.x - 18, center.y - 6, 36, 8), col)
			draw_polygon(PoolVector2Array([
				center + Vector2(-12, 2), center + Vector2(-4, 2),
				center + Vector2(-7, 18), center + Vector2(-15, 18)
			]), PoolColorArray([col, col, col, col]))
			draw_line(center + Vector2(-4, 4), center + Vector2(4, 4), col, 1.5)
			draw_line(center + Vector2(4, 4), center + Vector2(2, 10), col, 1.5)

func _ready():
	weapon = get_node_or_null(weapon)
	weapon_hud = get_node_or_null(weapon_hud)
	crosshair = get_node_or_null(crosshair)
	if crosshair:
		crosshair.visible = false
	
	_setup_tactical_crosshair()
	_setup_fullscreen_overlays()
	_setup_pubg_health_bar()
	_setup_gta_weapon_card()
	_setup_horde_and_boss_ui()
	_setup_death_screen()
	_setup_victory_screen()
	_setup_sniper_scope()

func _setup_tactical_crosshair() -> void:
	tactical_crosshair = TacticalCrosshair.new()
	tactical_crosshair.name = "tactical_crosshair"
	tactical_crosshair.rect_size = get_viewport().size
	tactical_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tactical_crosshair)

func _trigger_hitmarker(is_headshot: bool = false) -> void:
	if tactical_crosshair:
		tactical_crosshair.is_headshot_hit = is_headshot
		tactical_crosshair.hitmarker_timer = 0.35
		tactical_crosshair.update()

func _setup_fullscreen_overlays() -> void:
	var ar_f = load("res://data/fonts/arabic_font.tres")
	var ar_lg = load("res://data/fonts/arabic_font_large.tres")
	
	damage_rect = ColorRect.new()
	damage_rect.name = "damage_flash"
	damage_rect.color = Color(1, 0, 0, 0)
	damage_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(damage_rect)
	
	heal_rect = ColorRect.new()
	heal_rect.name = "heal_flash"
	heal_rect.color = Color(0.1, 0.9, 0.3, 0)
	heal_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(heal_rect)
	
	heal_text_label = Label.new()
	heal_text_label.name = "heal_toast"
	heal_text_label.text = "+50 HP " + Arabic.t("تم امتصاص دماء الشفاء")
	heal_text_label.align = Label.ALIGN_CENTER
	if ar_f: heal_text_label.add_font_override("font", ar_f)
	heal_text_label.add_color_override("font_color", Color(0.2, 1.0, 0.4, 0))
	heal_text_label.visible = false
	add_child(heal_text_label)
	
	# Headshot notification label
	headshot_label = Label.new()
	headshot_label.name = "headshot_toast"
	headshot_label.text = ">>> " + Arabic.t("إصابة قاتلة بالرأس! طلقة مميتة") + " +999 <<<"
	headshot_label.align = Label.ALIGN_CENTER
	if ar_lg: headshot_label.add_font_override("font", ar_lg)
	headshot_label.add_color_override("font_color", Color(1.0, 0.1, 0.1, 0))
	headshot_label.visible = false
	add_child(headshot_label)

func _setup_pubg_health_bar() -> void:
	pubg_health_bar = PubgHealthUI.new()
	pubg_health_bar.name = "pubg_health_bar"
	pubg_health_bar.rect_size = Vector2(340, 18)
	pubg_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pubg_health_bar)

func _setup_gta_weapon_card() -> void:
	gta_weapon_card = GtaWeaponCardUI.new()
	gta_weapon_card.name = "gta_weapon_card"
	gta_weapon_card.rect_size = Vector2(240, 84)
	gta_weapon_card.rect_position = Vector2(28, 28)
	gta_weapon_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gta_weapon_card)

func _setup_horde_and_boss_ui() -> void:
	horde_and_boss_ui = BossAndHordeUI.new()
	horde_and_boss_ui.name = "horde_and_boss_ui"
	horde_and_boss_ui.rect_size = Vector2(340, 32)
	horde_and_boss_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(horde_and_boss_ui)

func _setup_death_screen() -> void:
	var ar_f = load("res://data/fonts/arabic_font.tres")
	var ar_lg = load("res://data/fonts/arabic_font_large.tres")
	
	death_overlay = ColorRect.new()
	death_overlay.name = "death_overlay"
	death_overlay.color = Color(0.18, 0.02, 0.02, 0.0)
	death_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	death_overlay.visible = false
	add_child(death_overlay)
	
	death_title = Label.new()
	death_title.name = "death_title"
	death_title.text = "[ " + Arabic.t("تم القضاء عليك بواسطة الزومبي") + " ]"
	death_title.align = Label.ALIGN_CENTER
	if ar_lg: death_title.add_font_override("font", ar_lg)
	death_title.add_color_override("font_color", Color(1.0, 0.2, 0.2))
	death_overlay.add_child(death_title)
	
	death_countdown_label = Label.new()
	death_countdown_label.name = "death_countdown"
	death_countdown_label.text = Arabic.t("إعادة الإنعاش في المخبأ الآمن خلال 3.0 ثوان...")
	death_countdown_label.align = Label.ALIGN_CENTER
	if ar_f: death_countdown_label.add_font_override("font", ar_f)
	death_countdown_label.add_color_override("font_color", Color(1.0, 0.9, 0.9))
	death_overlay.add_child(death_countdown_label)

func _setup_victory_screen() -> void:
	var ar_f = load("res://data/fonts/arabic_font.tres")
	var ar_lg = load("res://data/fonts/arabic_font_large.tres")
	
	victory_overlay = ColorRect.new()
	victory_overlay.name = "victory_overlay"
	victory_overlay.color = Color(0.02, 0.12, 0.04, 0.0)
	victory_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	victory_overlay.visible = false
	add_child(victory_overlay)
	
	victory_title = Label.new()
	victory_title.name = "victory_title"
	victory_title.text = "[ " + Arabic.t("انتصار! تم القضاء على جميع الـ 50 زومبي وهزيمة العملاق جليات") + " ]"
	victory_title.align = Label.ALIGN_CENTER
	if ar_lg: victory_title.add_font_override("font", ar_lg)
	victory_title.add_color_override("font_color", Color(0.25, 1.0, 0.35))
	victory_overlay.add_child(victory_title)
	
	victory_subtitle = Label.new()
	victory_subtitle.name = "victory_subtitle"
	victory_subtitle.text = Arabic.t("تم تطهير المنشأة بالكامل — البقاء تحقق بنجاح!")
	victory_subtitle.align = Label.ALIGN_CENTER
	if ar_f: victory_subtitle.add_font_override("font", ar_f)
	victory_subtitle.add_color_override("font_color", Color(0.9, 1.0, 0.9))
	victory_overlay.add_child(victory_subtitle)

func _setup_sniper_scope() -> void:
	sniper_scope = ScopeReticle.new()
	sniper_scope.name = "sniper_scope"
	sniper_scope.visible = false
	sniper_scope.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sniper_scope.anchor_right = 1.0
	sniper_scope.anchor_bottom = 1.0
	sniper_scope.rect_size = Vector2(1280, 720)
	var f = load("res://data/fonts/modern_font_regular.tres")
	if f:
		sniper_scope.set("custom_fonts/font", f)
	add_child(sniper_scope)

func _set_sniper_scope(enabled: bool) -> void:
	is_sniper_scoped = enabled
	if sniper_scope:
		sniper_scope.visible = enabled
		if enabled:
			sniper_scope.rect_size = get_viewport().size
			sniper_scope.update()
	if crosshair:
		crosshair.visible = false
	if tactical_crosshair:
		tactical_crosshair.is_visible = not enabled
		tactical_crosshair.update()

func _show_headshot_toast() -> void:
	headshot_timer = 1.3
	if headshot_label:
		headshot_label.visible = true

func _update_zombies_remaining(remaining: int, total: int) -> void:
	if horde_and_boss_ui:
		horde_and_boss_ui.zombies_remaining = remaining
		horde_and_boss_ui.total_zombies = total
		horde_and_boss_ui.update()

func _set_boss_active(active: bool, b_name: String, max_hp: float) -> void:
	if horde_and_boss_ui:
		horde_and_boss_ui.is_boss_active = active
		horde_and_boss_ui.boss_name = b_name
		horde_and_boss_ui.boss_max_hp = max_hp
		horde_and_boss_ui.boss_hp = max_hp
		horde_and_boss_ui.boss_ghost_hp = max_hp
		horde_and_boss_ui.update()

func _update_boss_health(cur_hp: float, max_hp: float) -> void:
	if horde_and_boss_ui:
		horde_and_boss_ui.boss_hp = cur_hp
		horde_and_boss_ui.boss_max_hp = max_hp
		horde_and_boss_ui.update()

func _show_victory_screen() -> void:
	is_showing_victory = true
	if victory_overlay:
		victory_overlay.visible = true

func _process(delta: float) -> void:
	_update_pubg_health(delta)
	_update_gta_weapon_card(delta)
	_update_horde_and_boss_ui(delta)
	_update_overlays(delta)
	_update_death_overlay_layout(delta)
	_update_victory_overlay_layout(delta)
	_crosshair()
	
	if tactical_crosshair and tactical_crosshair.hitmarker_timer > 0.0:
		tactical_crosshair.hitmarker_timer -= delta
		tactical_crosshair.update()
	
	if weapon_hud and weapon:
		var off = Vector2(180, 80)
		weapon_hud.position = get_viewport().size - off
		var w_data = weapon.arsenal.values()[weapon.current]
		weapon_hud.get_node("name").text = str(w_data.name)
		weapon_hud.get_node("bullets").text = str(w_data.bullets)
		weapon_hud.get_node("ammo").text = str(w_data.ammo)

func _update_pubg_health(delta: float) -> void:
	var vp_size = get_viewport().size
	if pubg_health_bar:
		var bar_w = 340.0
		var bar_h = 18.0
		pubg_health_bar.rect_size = Vector2(bar_w, bar_h)
		pubg_health_bar.rect_position = Vector2((vp_size.x - bar_w) * 0.5, vp_size.y - 44.0)
		
		var char_node = get_parent()
		if char_node and "health" in char_node:
			pubg_health_bar.cur_hp = float(char_node.health)
			pubg_health_bar.max_hp = float(char_node.get("max_health"))
			if pubg_health_bar.max_hp <= 0:
				pubg_health_bar.max_hp = 250.0
		
		if pubg_health_bar.ghost_hp > pubg_health_bar.cur_hp:
			pubg_health_bar.ghost_hp = lerp(pubg_health_bar.ghost_hp, pubg_health_bar.cur_hp, 3.5 * delta)
		else:
			pubg_health_bar.ghost_hp = pubg_health_bar.cur_hp
			
		pubg_health_bar.pulse_time += delta
		pubg_health_bar.update()

func _update_horde_and_boss_ui(delta: float) -> void:
	if not horde_and_boss_ui:
		return
	var vp_size = get_viewport().size
	horde_and_boss_ui.pulse_time += delta
	
	if horde_and_boss_ui.is_boss_active:
		var bw = min(540.0, vp_size.x * 0.7)
		var bh = 22.0
		horde_and_boss_ui.rect_size = Vector2(bw, bh)
		horde_and_boss_ui.rect_position = Vector2((vp_size.x - bw) * 0.5, 24.0)
		
		# Boss ghost bar
		if horde_and_boss_ui.boss_ghost_hp > horde_and_boss_ui.boss_hp:
			horde_and_boss_ui.boss_ghost_hp = lerp(horde_and_boss_ui.boss_ghost_hp, horde_and_boss_ui.boss_hp, 2.5 * delta)
		else:
			horde_and_boss_ui.boss_ghost_hp = horde_and_boss_ui.boss_hp
	else:
		var cw = 320.0
		var ch = 30.0
		horde_and_boss_ui.rect_size = Vector2(cw, ch)
		horde_and_boss_ui.rect_position = Vector2((vp_size.x - cw) * 0.5, 18.0)
		
	horde_and_boss_ui.update()

func _update_gta_weapon_card(delta: float) -> void:
	if not weapon:
		return
		
	var cur_w_idx = weapon.current
	var w_data = weapon.arsenal.values()[cur_w_idx]
	var cur_bullets = w_data.bullets
	
	if cur_w_idx != last_weapon_index or cur_bullets != last_bullets:
		last_weapon_index = cur_w_idx
		last_bullets = cur_bullets
		gta_card_timer = 3.2
		gta_card_alpha = 1.0
	
	if gta_card_timer > 0.0:
		gta_card_timer -= delta
		gta_card_alpha = lerp(gta_card_alpha, 1.0, 10.0 * delta)
	else:
		gta_card_alpha = lerp(gta_card_alpha, 0.0, 4.0 * delta)
	
	if gta_weapon_card:
		gta_weapon_card.card_alpha = gta_card_alpha
		gta_weapon_card.weapon_id = cur_w_idx
		gta_weapon_card.weapon_name = str(w_data.name)
		gta_weapon_card.ammo_bullets = int(w_data.bullets)
		gta_weapon_card.ammo_reserve = int(w_data.ammo)
		
		var w_name_lower = gta_weapon_card.weapon_name.to_lower()
		if "sniper" in w_name_lower:
			gta_weapon_card.category_name = Arabic.t("قناصة تكتيكية ثقيلة") + " (SNIPER)"
		elif "vector" in w_name_lower or "kriss" in w_name_lower:
			gta_weapon_card.category_name = Arabic.t("رشاش كريس فيكتور") + " (SMG)"
		elif "mk" in w_name_lower:
			gta_weapon_card.category_name = Arabic.t("مسدس قتالي") + " (MK23)"
		else:
			gta_weapon_card.category_name = Arabic.t("مسدس تكتيكي") + " (GLOCK 17)"
			
		gta_weapon_card.update()

func _update_overlays(delta: float) -> void:
	var vp_size = get_viewport().size
	if damage_rect:
		damage_rect.rect_size = vp_size
		damage_rect.color.a = lerp(damage_rect.color.a, 0.0, 5.0 * delta)
		
	if heal_rect:
		heal_rect.rect_size = vp_size
		heal_rect.color.a = lerp(heal_rect.color.a, 0.0, 4.0 * delta)
		
	if heal_text_timer > 0.0:
		heal_text_timer -= delta
		if heal_text_label:
			heal_text_label.visible = true
			heal_text_label.rect_position = Vector2((vp_size.x - 300) * 0.5, vp_size.y - 82)
			heal_text_label.rect_size = Vector2(300, 25)
			var a = clamp(heal_text_timer * 1.5, 0.0, 1.0)
			heal_text_label.add_color_override("font_color", Color(0.2, 1.0, 0.4, a))
	else:
		if heal_text_label:
			heal_text_label.visible = false
			
	if headshot_timer > 0.0:
		headshot_timer -= delta
		if headshot_label:
			headshot_label.visible = true
			headshot_label.rect_position = Vector2((vp_size.x - 300) * 0.5, (vp_size.y * 0.5) - 60)
			headshot_label.rect_size = Vector2(300, 30)
			var a = clamp(headshot_timer * 2.0, 0.0, 1.0)
			headshot_label.add_color_override("font_color", Color(1.0, 0.15, 0.15, a))
	else:
		if headshot_label:
			headshot_label.visible = false

func _update_death_overlay_layout(delta: float) -> void:
	if death_overlay and death_overlay.visible:
		var vp_size = get_viewport().size
		death_overlay.rect_size = vp_size
		if is_showing_death:
			death_overlay.color.a = lerp(death_overlay.color.a, 0.76, 6.0 * delta)
		
		if death_title:
			death_title.rect_position = Vector2(0, (vp_size.y * 0.4) - 20)
			death_title.rect_size = Vector2(vp_size.x, 30)
		if death_countdown_label:
			death_countdown_label.rect_position = Vector2(0, (vp_size.y * 0.4) + 25)
			death_countdown_label.rect_size = Vector2(vp_size.x, 30)

func _update_victory_overlay_layout(delta: float) -> void:
	if victory_overlay and victory_overlay.visible:
		var vp_size = get_viewport().size
		victory_overlay.rect_size = vp_size
		if is_showing_victory:
			victory_overlay.color.a = lerp(victory_overlay.color.a, 0.82, 4.0 * delta)
		if victory_title:
			victory_title.rect_position = Vector2(0, (vp_size.y * 0.4) - 25)
			victory_title.rect_size = Vector2(vp_size.x, 35)
		if victory_subtitle:
			victory_subtitle.rect_position = Vector2(0, (vp_size.y * 0.4) + 20)
			victory_subtitle.rect_size = Vector2(vp_size.x, 30)

func _show_death_screen(countdown: float) -> void:
	is_showing_death = true
	if death_overlay:
		death_overlay.visible = true
		death_overlay.color.a = 0.2
	_update_death_countdown(countdown)

func _update_death_countdown(time_left: float) -> void:
	if death_countdown_label:
		var clamped_time = max(0.0, time_left)
		death_countdown_label.text = "Respawning at Safe Bunker in: " + str(stepify(clamped_time, 0.1)) + "s"

func _hide_death_screen() -> void:
	is_showing_death = false
	if death_overlay:
		death_overlay.visible = false
		death_overlay.color.a = 0.0

func _damage_flash() -> void:
	if damage_rect:
		damage_rect.color.a = 0.48

func _heal_flash(amount: int = 50) -> void:
	if heal_rect:
		heal_rect.color.a = 0.35
	if heal_text_label:
		heal_text_label.text = "+" + str(amount) + " HP BLOOD COLLECTED"
		heal_text_timer = 2.0
		heal_text_label.visible = true

func _crosshair() -> void:
	if crosshair:
		crosshair.visible = false
	if tactical_crosshair:
		tactical_crosshair.rect_size = get_viewport().size
		tactical_crosshair.is_visible = not is_sniper_scoped
		tactical_crosshair.update()
