tool
extends RichTextLabel
class_name RichTextLabel2

const COLORN := PoolStringArray(["pink","lightpink","hotpink","deeppink","palevioletred","mediumvioletred","lightsalmon","salmon","darksalmon","lightcoral","indianred","crimson","firebrick","darkred","red","orangered","tomato","coral","darkorange","orange","gold","yellow","lightyellow","lemonchiffon","lightgoldenrodyellow","papayawhip","moccasin","peachpuff","palegoldenrod","khaki","darkkhaki","cornsilk","blanchedalmond","bisque","navajowhite","webgray","wheat","burlywood","tan","rosybrown","sandybrown","goldenrod","darkgoldenrod","peru","chocolate","saddlebrown","sienna","brown","maroon","darkolivegreen","olive","olivedrab","yellowgreen","limegreen","lime","lawngreen","chartreuse","greenyellow","springgreen","mediumspringgreen","lightgreen","palegreen","darkseagreen","mediumseagreen","seagreen","forestgreen","green","darkgreen","mediumaquamarine","aqua","cyan","lightcyan","paleturquoise","aquamarine","turquoise","mediumturquoise","darkturquoise","lightseagreen","cadetblue","darkcyan","teal","lightsteelblue","powderblue","lightblue","skyblue","lightskyblue","deepskyblue","dodgerblue","cornflowerblue","steelblue","royalblue","blue","mediumblue","darkblue","navy","midnightblue","lavender","thistle","plum","violet","orchid","fuchsia","magenta","mediumorchid","mediumpurple","blueviolet","darkviolet","darkorchid","darkmagenta","purple","indigo","darkslateblue","slateblue","mediumslateblue","white","snow","honeydew","mintcream","azure","aliceblue","ghostwhite","whitesmoke","seashell","beige","oldlace","floralwhite","ivory","antiquewhite","linen","lavenderblush","mistyrose","gainsboro","lightgray","silver","darkgray","gray","dimgray","lightslategray","slategray","darkslategray","black"])
const DIR_TEXT_EFFECTS := "res://addons/rich_text/text_effects"
const DIR_TEXT_TRANSITIONS := "res://addons/rich_text/text_transitions"
const DIR_FONTS := "res://fonts"

const CONTEXT_OPENED := "{"
const CONTEXT_CLOSED := "}"

export(int, "None,Left,Center,Right,Fill") var align:int = RichTextLabel.ALIGN_CENTER+1 setget set_align

func set_align(a):
	align = a
	redraw()

export var color:Color = Color.white setget set_color

func set_color(c):
	color = c
	redraw()

# Font
export var font:String = "" setget set_font
export var size:int = 16 setget set_font_size

func set_font(f):
	font = f
	update_font()

func set_font_size(s):
	size = s
	update_font()

func update_font():
	FontHelper.new().set_fonts(self, {font=font, size=size})
	redraw()

# Quotes
export var nicer_quotes_enabled:bool = true setget set_nicer_quotes_enabled
export var nicer_quotes_format:String = "“%s”" setget set_nicer_quotes_format

func set_nicer_quotes_enabled(e):
	nicer_quotes_enabled = e
	redraw()

func set_nicer_quotes_format(e):
	nicer_quotes_format = e
	redraw()

export var markdown_enabled:bool = true setget set_markdown_enabled
export var markdown_i:String = "[i]%s[]" setget set_markdown_i
export var markdown_b:String = "[b]%s[]" setget set_markdown_b
export var markdown_bi:String = "[bi]%s[]" setget set_markdown_bi
export var markdown_s:String = "[s]%s[]" setget set_markdown_s

func set_markdown_enabled(b):
	markdown_enabled = b
	redraw()

func set_markdown_b(b):
	markdown_b = b
	redraw()
func set_markdown_i(b):
	markdown_i = b
	redraw()
func set_markdown_bi(b):
	markdown_bi = b
	redraw()
func set_markdown_s(b):
	markdown_s = b
	redraw()

export var _context:NodePath = "."
onready var context:Node = get_node(_context)
export var context_enabled:bool = true setget set_context_enabled

func set_context_enabled(c):
	context_enabled = c
	redraw()

export(String, MULTILINE) var bbcode2:String = "" setget set_bbcode2

var font_tags:Dictionary = {}
var installed:Array = [] # effects that have been installed

var _flag_cap := false
var _flag_lower := false
var _flag_upper := false

"""
Features:
	- Use any Godot color as a color tag: [red] [tomato] [teal]
	- Use comma seperated values as color: "[%s]This text is red[]" % Color.tomato
	- Clump tags together with ";" : [red;b]My text[]
	- Close last tag with []
	- Close all open tags with [/]
	- Auto installs RichTextEffects when a tag is found: "[my_effect]My effected text.[]"
	- Auto align with "align" field. No need to add "[center]" to everything.
	- Easy font system: Set name and size, and resources are auto generated.
	- Context replacement:
		Anything inside {} will be replaced with context data.
		Can include math or functions. "{score} or {score * 2} or {get_score()}"
	- Tags:
		- [dim] Darkens by 33%.
		- [lit] Lightens by 33%
		- [hide] Make text transparent.
		- [em=icon] Emoji: An image scaled to the font size.
		- [cap] Capitalize all letters.
		- [upper] Uppercase all letters.
		- [lower] Lowercase all letters.
	- Markdown (optional):
		- *italic*
		- **bold**
		- ***bold italic***
		- ~~strikethrough~~
	- Table:
		- Markdown inspired division (newline = row, | = column)
		- Markdown inspired alignment (:left, :center:, right:)
		- Header can be auto styled.
		- Every 2nd row is tinted.
		- Seperate cells with | (Requires closing with [/table]): "[table=2]head1|head2|cell1|cell2|cell3[/table]"
		- Auto table horizontal spacer based on rect_size.
		- Auto commas: 1234567 -> 1,234,567
	- Override _custom_tag(tag, taginfo) to add your own tags.
	- Pad tag with spaces to prevent it from becoming a bbcode: "[ [green]Charisma[] [red]2[] ] Help me out" -> "[Charisma 2] Help me out"
"""

func add_font_tag(tag:String, font:String, size:int):
	var dfont = DynamicFont.new()
	dfont.font_data = load(font)
	dfont.size = size
	font_tags[tag] = dfont

func _get_tool_buttons(): return ["reset"]
func _ready():
	var _e
	_e = connect("meta_hover_started", self, "_hover_started")
	_e = connect("meta_hover_ended", self, "_hover_ended")
	_e = connect("meta_clicked", self, "_clicked")

func redraw():
	set_bbcode2(bbcode2)

func set_bbcode2(bbcode:String):
	bbcode2 = bbcode
	
	custom_effects = []
	text = ""
	bbcode_text = ""
	bbcode_enabled = true
	installed = []
	clear()
	
	bbcode = _preprocess(bbcode)
	
	if align != 0:
		push_align(align-1)
	
	_effect_prepass()
	
	if color != Color.white:
		push_color(color)
	
	_replace_between(bbcode, [])
	
	if color != Color.white:
		pop()
	
	_effect_postpass()
	
	if align != 0:
		pop()

func _effect_prepass(): pass
func _effect_postpass(): pass

func _preprocess(bbcode:String):
	
#	if context_enabled:
#		if not context:
#			context = get_node(_context)
#
#		if context:
#			bbcode = replace_between(bbcode, CONTEXT_OPENED, CONTEXT_CLOSED, funcref(self, "_replace_context"))
#
	if nicer_quotes_enabled:
		bbcode = replace_between(bbcode, '"', '"', funcref(self, "_replace_quotes"))
	
	if markdown_enabled:
		bbcode = replace_between(bbcode, "***", "***", funcref(self, "_replace_md_bi"))
		bbcode = replace_between(bbcode, "___", "___", funcref(self, "_replace_md_bi"))
		bbcode = replace_between(bbcode, "**", "**", funcref(self, "_replace_md_b"))
		bbcode = replace_between(bbcode, "__", "__", funcref(self, "_replace_md_b"))
		bbcode = replace_between(bbcode, "*", "*", funcref(self, "_replace_md_i"))
		bbcode = replace_between(bbcode, "_", "_", funcref(self, "_replace_md_i"))
		
		bbcode = replace_between(bbcode, "~~", "~~", funcref(self, "_replace_md_s"))
	
	return bbcode

func _replace_md_bi(t:String): return markdown_bi % t
func _replace_md_b(t:String): return markdown_b % t
func _replace_md_i(t:String): return markdown_i % t
func _replace_md_s(t:String): return markdown_s % t

const EXPRESSION_FAILED:String = "%EXPRESSION_FAILED%"
func _execute_expression(e:String, default=EXPRESSION_FAILED):
	if context_enabled:
		if not context:
			context = get_node(_context)
		if context:
			var expression := Expression.new()
			if expression.parse(e) == OK:
				var result = expression.execute([], context)
				if not expression.has_execute_failed():
					return result
	return default

#func _replace_context(t:String):
#	var got = _execute_expression(t)
#	return got if got != EXPRESSION_FAILED else "{%s}" % t
#	if got != EXPRESSION_FAILED:
#		return str(got)
#	return "{%s}" % t

func add_text(text:String):
	if _flag_cap:
		text = text.capitalize()
	
	if _flag_upper:
		text = text.to_upper()
	
	if _flag_lower:
		text = text.to_lower()
	
	.add_text(text)

func _hover_started(_meta):
	pass

func _hover_ended(_meta):
	pass

func _clicked(_meta):
	pass

func _replace_between(bbcode:String, open_tags:Array):
	var state:Dictionary = {
		table_rows=0,
		table_cells=0,
		color=color,
		font="",
		text=bbcode
	}
	
	while "[" in state.text:
		var p = state.text.split("[", true, 1)
		
		# add head string
		if p[0]:
			add_text(p[0])
		
		# is [ intentional bracket? ]
		if p[1].begins_with(" "):
			p = p[1].substr(1).split(" ]", true, 1)
			
			# recursively do inner
			add_text("[")
			_replace_between(p[0], open_tags)
			add_text("]")
			
			# right side as leftover
			state.text = "" if len(p) == 1 else p[1]
			
		# get inner
		else:
			p = p[1].split("]", true, 1)
			
			# right side as leftover
			state.text = "" if len(p) == 1 else p[1]
			
			# go through all tags
			var tag = p[0]
			
			if tag == "":
				_pop(open_tags, state)
			
			# close all
			elif tag == "/":
				while open_tags:
					_pop(open_tags, state)
			
			# close old fashioned way
			elif tag.begins_with("/"):
				var _err = append_bbcode(tag)
			
			else:
				var opened = _apply_tags(tag, state)
				if opened:
					open_tags.append(opened)
	
	if state.text:
		add_text(state.text)
	
	
func _replace_quotes(input:String) -> String:
	return nicer_quotes_format % input

func _pop(open_tags:Array, state:Dictionary):
	if not open_tags:
		return
	
	var close = open_tags.pop_back()
	for i in range(len(close)-1, -1, -1):
		match typeof(close[i]):
			TYPE_BOOL: pop()
			TYPE_STRING: _custom_tag_closed(close[i])
			TYPE_COLOR:
				pop()
				state.color = close[i]

func _install_effect(id:String) -> bool:
	if id in installed:
		return true
	
	for dir in [DIR_TEXT_EFFECTS, DIR_TEXT_TRANSITIONS]:
		var path = dir.plus_file("RTE_%s.gd" % id)
		if File.new().file_exists(path):
			var effect:RichTextEffect = load(path).new()
			effect.resource_local_to_scene = true
#			get_tree().set_meta(str(hash(effect)), self)
#			effect.set_meta("rt", get_tree()) # pass a reference to this RichTextLabel
			Global._d[effect] = self
			effect.resource_name = id
			install_effect(effect)
			installed.append(id)
			return true
	
	return false

func _custom_tag_command(command:String):
	pass

# return true if self closing, false if not, and null if not used
func _custom_tag(_tag:String, _info:Dictionary):
#	push_warning("no bbcode tag %s [%s %s]" % [tag, tag, info])
	return null

func _custom_tag_closed(tag:String):
	match tag:
		"cap": _flag_cap = false
		"upper": _flag_upper = false
		"lower": _flag_lower = false

func _find_font(id:String) -> DynamicFont:
	var p = id.substr(1).split(" ", true, 1)
	id = p[0]
	var df = DynamicFont.new()
	df.font_data = load(DIR_FONTS.plus_file(id + ".ttf"))
	df.size = get_font("normal_font").get_height()
	return df

func _find_asset(id:String, extensions:Array, default=null):
	var f := File.new()
	for ext in extensions:
		var p = id + ext
		if f.file_exists(p):
			return load(p)
	return default

# an image adjusted to be the same size as the current font.
func _add_emoj(info:String):
	var image:Texture = _find_asset(info, [".png", ".jpg", ".webp", ".bmp"])
	var isize := image.get_size()
	var font := get_font("normal_font")
	var size
	if "size" in font:
		size = font.size
	else:
		size = font.get_char_size(ord(" ")).y
	var w:int = size * (isize.x / isize.y)
	var h:int = size
	add_image(image, w, h)

func _add_image(info:String):
	var dict:Dictionary = info_to_dict(info)
	var image:Texture = load(dict.img)
	var isize:Vector2 = image.get_size()
	var w:int = int(isize.x)
	var h:int = int(isize.y)
	add_image(image, w, h)

func _apply_tags(tags:String, state:Dictionary) -> Array:
	# special expression tag
	if tags.begins_with("$"):
		tags = tags.substr(1)
		var ev_opened:Array
		if ";" in tags:
			var p := tags.split(";", true, 1)
			tags = p[0]
			ev_opened = _apply_tags(p[1], state)
		add_text(str(_execute_expression(tags)))
		if ev_opened:
			_pop([ev_opened], state)
		return []
	
	var opened:Array = []
	
	for tag in tags.split(";"):
		_apply_tag(tag, state, opened)
	
	return opened

func _apply_tag(tag:String, state:Dictionary, opened:Array):
	var tag_name:String
	var tag_info:String
	
	var a = tag.find("=")
	var b = tag.find(" ")
	if a != -1 and (b == -1 or a < b):
		tag_name = tag.substr(0, a)
		tag_info = tag
		
	elif b != -1 and (a == -1 or b < a):
		tag_name = tag.substr(0, b)
		tag_info = tag.substr(b)
		
	else:
		tag_name = tag
		tag_info = ""
		
	if is_valid_color(tag_name):
		opened.append(state.color)
		state.color = to_color(tag_name)
		push_color(state.color)
		return
	
	match tag_name:
		# built in
		"b":
			opened.append(true)
			push_bold()
			
		"i":
			opened.append(true)
			push_italics()
		
		"bi":
			opened.append(true)
			push_bold_italics()
		
		"u":
			opened.append(true)
			push_underline()
			
		"s":
			opened.append(true)
			push_strikethrough()
			
		"code":
			opened.append(true)
			push_mono()
		
		"left":
			opened.append(true)
			push_align(RichTextLabel.ALIGN_LEFT)
		
		"center":
			opened.append(true)
			push_align(RichTextLabel.ALIGN_CENTER)
			
		"right":
			opened.append(true)
			push_align(RichTextLabel.ALIGN_RIGHT)
			
		"fill":
			opened.append(true)
			push_align(RichTextLabel.ALIGN_FILL)
			
		"indent":
			opened.append(true)
			push_indent(int(tag_info))
			
		"url":
			opened.append(true)
			push_meta(tag_info.split("=", true, 1)[1])
			
		"img":
			_add_image(tag_info)
		
		"cap":
			opened.append("cap")
			_flag_cap = true
		
		"upper":
			opened.append("upper")
			_flag_upper = true
		
		"lower":
			opened.append("lower")
			_flag_lower = true
		
		"font":
			opened.append(true)
			push_font(_find_font(tag_info))
			
		"color":
			opened.append(state.color)
			state.color = to_color(tag_info)
			push_color(state.color)
		
		"hide":
			opened.append(state.color)
			state.color = Color.transparent
			push_color(state.color)
		
		"table":
			opened.append(true)
			state.table_rows = int(tag_info)
			push_table(state.table_rows)
		
		"cell":
			opened.append(true)
			push_cell()
			_on_cell(opened, state)
			
		# Custom Effects
		
		"hue":
			opened.append(state.color)
			var h = _info_to_float(tag_info, 180.0) / 360.0
			state.color.h = wrapf(state.color.h + h, 0.0, 1.0)
			push_color(state.color)
		
		"sat":
			opened.append(state.color)
			var s = _info_to_float(tag_info, 50.0) / 100.0
			state.color.s = clamp(state.color.s + s, 0.0, 1.0)
			push_color(state.color)
		
		"val":
			opened.append(state.color)
			var v = _info_to_float(tag_info, 50.0) / 100.0
			state.color.v = clamp(state.color.v + v, 0.0, 1.0)
			push_color(state.color)
		
		"em":
			_add_emoj(tag.substr(3))
		
		# dim by 33% 50% 66%
		"dim", "dim2", "dim3":
			opened.append(state.color)
			state.color = state.color.darkened({dim=.33,dim2=.5,dim3=.66}[tag_name])#.33)
			push_color(state.color)
		
		# lighten by 33%
		"lit", "lit2", "lit3":
			opened.append(state.color)
			state.color = state.color.lightened({lit=.33,lit2=.5,lit3=.66}[tag_name])#.33)
			push_color(state.color)
		
		# opposite color
#		"opp":
#			var c = state.color
#			opened.append(state.color)
#			state.color = c.from_hsv(wrapf(c.h + .5, 0.0, 1.0), c.s, c.v)
#			push_color(state.color)
#
#		"tri1":
#			var c = state.color
#			opened.append(state.color)
#			state.color = c.from_hsv(wrapf(c.h - .3333, 0.0, 1.0), c.s, c.v)
#			push_color(state.color)
#
#		"tri2":
#			var c = state.color
#			opened.append(state.color)
#			state.color = c.from_hsv(wrapf(c.h + .3333, 0.0, 1.0), c.s, c.v)
#			push_color(state.color)
		
		_:
			# install effect if it exists
			if _install_effect(tag_name):
				var apend = ("[%s]" % tag_name) if not tag_info else ("[%s %s]" % [tag_name, tag_info])
				var _err = append_bbcode(apend)
				opened.append(true)
			
			# pass it on to custom tag
			else:
				var auto_close = _custom_tag(tag_name, info_to_dict(tag_info))
				
				if auto_close == null:
					add_text("[%s]" % [tag_name])
				
				elif auto_close == false:
					opened.append(tag_name)

func _info_to_float(info:String, default:float=0.0):
	if "=" in info:
		var p = info.split("=", true, 1)
		if len(p) == 2:
			return float(p[1])
	return default

func _on_cell(opened:Array, state:Dictionary):
	state.table_cells += 1

static func info_to_dict(info:String) -> Dictionary:
	var out:Dictionary = {}
	if "=" in info:
		for part in info.split(" "):
			var kv = part.split("=", true, 1)
			var v = kv[1]
			if v.begins_with("."):
				v = "0" + v
			out[kv[0]] = str2var(v)
	return out

static func is_valid_color(s:String) -> bool:
	if s in COLORN:
		return true
	if "," in s and s.count(",") in [3, 4]:
		for f in s.split(","):
			if not f.is_valid_float() and not f.is_valid_integer():
				return false
		return true
	return false

# converts from one color type to another
static func to_color(c) -> Color:
	if c is Color:
		return c
	
	elif c is String:
		if c.begins_with("#"):
			push_error("not implemented %s" % c)
			c = Color.white
		
		# "[%s]" % Color.tomato
		elif "," in c:
			c = c.split_floats(",")
			return Color(c[0], c[1], c[2], 1.0 if len(c)==3 else c[3])
		
		elif c == "clear":
			return Color.transparent
		
		elif c == "grey":
			return Color.gray
		
		elif c in COLORN:
			return ColorN(c)
		
		else:
			push_error("no color %s" % c)
			return Color.pink
	
	return c

const INTERNAL:Dictionary = {index = 0}
static func replace_between(s:String, head:String, tail:String, fr) -> String:
	var obj
	INTERNAL.index = 0
	while true:
		INTERNAL.index = s.find(head, INTERNAL.index)
		if INTERNAL.index == -1: break
		var b = s.find(tail, INTERNAL.index+len(head))
		if b == -1: break
		var inner = _part(s, INTERNAL.index+len(head), b)
		if head in inner:
			INTERNAL.index += len(head)
			continue
		var got = fr.call_func(inner)
		if got:
			s = _part(s, 0, INTERNAL.index) + got + _part(s, b+len(tail))
			INTERNAL.index += len(got)
		else:
			s = _part(s, 0, INTERNAL.index) + _part(s, b+len(tail))
	return s

static func _part(a, begin:int=0, end=null):
	if end == null:
		end = len(a)
	
	elif end < 0:
		end = len(a) - end
	
	return (a as String).substr(begin, end-begin)

# 12345678 -> 12,345,678
static func commas(number) -> String:
	var string = str(number)
	var mod = len(string) % 3
	var out := ""
	for i in len(string):
		if i != 0 and i % 3 == mod:
			out += ","
		out += string[i]
	return out

static func eor(test, yes, no):
	return yes if test else no
