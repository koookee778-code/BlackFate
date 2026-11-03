extends Node

# ============================================================
#  ARABIC RESHAPER & BIDI FOR GODOT 3.5 (PURE GDSCRIPT)
#  Handles character shaping (Presentation Forms-B) and
#  full sentence word-order inversion for natural RTL reading.
# ============================================================

const TABLE = {
	"ء": ["\ufe80", "\ufe80", "\ufe80", "\ufe80"],
	"آ": ["\ufe81", "\ufe82", "\ufe82", "\ufe81"],
	"أ": ["\ufe83", "\ufe84", "\ufe84", "\ufe83"],
	"ؤ": ["\ufe85", "\ufe86", "\ufe86", "\ufe85"],
	"إ": ["\ufe87", "\ufe88", "\ufe88", "\ufe87"],
	"ئ": ["\ufe89", "\ufe8a", "\ufe8c", "\ufe8b"],
	"ا": ["\ufe8d", "\ufe8e", "\ufe8e", "\ufe8d"],
	"ب": ["\ufe8f", "\ufe90", "\ufe92", "\ufe91"],
	"ة": ["\ufe93", "\ufe94", "\ufe94", "\ufe93"],
	"ت": ["\ufe95", "\ufe96", "\ufe98", "\ufe97"],
	"ث": ["\ufe99", "\ufe9a", "\ufe9c", "\ufe9b"],
	"ج": ["\ufe9d", "\ufe9e", "\ufea0", "\ufe9f"],
	"ح": ["\ufea1", "\ufea2", "\ufea4", "\ufea3"],
	"خ": ["\ufea5", "\ufea6", "\ufea8", "\ufea7"],
	"د": ["\ufea9", "\ufeaa", "\ufeaa", "\ufea9"],
	"ذ": ["\ufeab", "\ufeac", "\ufeac", "\ufeab"],
	"ر": ["\ufead", "\ufeae", "\ufeae", "\ufead"],
	"ز": ["\ufeaf", "\ufeb0", "\ufeb0", "\ufeaf"],
	"س": ["\ufeb1", "\ufeb2", "\ufeb4", "\ufeb3"],
	"ش": ["\ufeb5", "\ufeb6", "\ufeb8", "\ufeb7"],
	"ص": ["\ufeb9", "\ufeba", "\ufebc", "\ufebb"],
	"ض": ["\ufebd", "\ufebe", "\ufec0", "\ufebf"],
	"ط": ["\ufec1", "\ufec2", "\ufec4", "\ufec3"],
	"ظ": ["\ufec5", "\ufec6", "\ufec8", "\ufec7"],
	"ع": ["\ufec9", "\ufeca", "\ufecc", "\ufecb"],
	"غ": ["\ufecd", "\ufece", "\ufed0", "\ufecf"],
	"ف": ["\ufed1", "\ufed2", "\ufed4", "\ufed3"],
	"ق": ["\ufed5", "\ufed6", "\ufed8", "\ufed7"],
	"ك": ["\ufed9", "\ufeda", "\ufedc", "\ufedb"],
	"ل": ["\ufedd", "\ufede", "\ufee0", "\ufedf"],
	"م": ["\ufee1", "\ufee2", "\ufee4", "\ufee3"],
	"ن": ["\ufee5", "\ufee6", "\ufee8", "\ufee7"],
	"ه": ["\ufee9", "\ufeea", "\ufeec", "\ufeeb"],
	"و": ["\ufeed", "\ufeee", "\ufeee", "\ufeed"],
	"ى": ["\ufeef", "\ufef0", "\ufef0", "\ufeef"],
	"ي": ["\ufef1", "\ufef2", "\ufef4", "\ufef3"],
}

const NON_CONN = ["ء", "آ", "أ", "ؤ", "إ", "ا", "د", "ذ", "ر", "ز", "و", "ى"]

static func has_arabic(text: String) -> bool:
	for i in range(text.length()):
		if TABLE.has(text[i]):
			return true
	return false

static func _reshape_word(word: String) -> String:
	var n = word.length()
	var reshaped = []
	var i = 0
	while i < n:
		var c = word[i]
		if not TABLE.has(c):
			reshaped.append(c)
			i += 1
			continue

		var prev_c = word[i - 1] if i > 0 else ""
		var next_c = word[i + 1] if i < n - 1 else ""

		var prev_conn = (prev_c != "" and TABLE.has(prev_c) and not (prev_c in NON_CONN))
		var next_conn = (next_c != "" and TABLE.has(next_c) and not (c in NON_CONN))

		if c == "ل" and next_c != "":
			var lig = ""
			if next_c == "آ": lig = "\ufef6" if prev_conn else "\ufef5"
			elif next_c == "أ": lig = "\ufef8" if prev_conn else "\ufef7"
			elif next_c == "إ": lig = "\ufefa" if prev_conn else "\ufef9"
			elif next_c == "ا": lig = "\ufefc" if prev_conn else "\ufefb"
			if lig != "":
				reshaped.append(lig)
				i += 2
				continue

		var forms = TABLE[c]
		if prev_conn and next_conn:
			reshaped.append(forms[2])
		elif prev_conn:
			reshaped.append(forms[1])
		elif next_conn:
			reshaped.append(forms[3])
		else:
			reshaped.append(forms[0])
		i += 1

	var s = ""
	for item in reshaped:
		s += item
	return s

static func _reverse_str(s: String) -> String:
	var res = ""
	for i in range(s.length() - 1, -1, -1):
		res += s[i]
	return res

static func _join_tokens(arr: Array, sep: String) -> String:
	var s = ""
	for i in range(arr.size()):
		s += str(arr[i])
		if i < arr.size() - 1:
			s += sep
	return s

static func t(input_text: String) -> String:
	if input_text == "":
		return ""
	
	if "\n" in input_text:
		var lines = input_text.split("\n")
		var out_lines = []
		for line in lines:
			out_lines.append(t(line))
		return _join_tokens(out_lines, "\n")

	var tokens = input_text.split(" ")
	var processed_tokens = []
	for token in tokens:
		if token == "":
			continue
		if has_arabic(token):
			var reshaped = _reshape_word(token)
			processed_tokens.append(_reverse_str(reshaped))
		else:
			processed_tokens.append(token)

	processed_tokens.invert()
	return _join_tokens(processed_tokens, " ")
