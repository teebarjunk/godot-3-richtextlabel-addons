extends Resource
class_name FontHelper

const DIR := "res://fonts"
const DEFAULT_FONT := ""
const DEFAULT_SIZE := 16
const FALLBACK_FONTS := [
	"res://fonts/unifont/unifont-13.0.01.ttf",
	"res://fonts/unifont/unifont_upper-13.0.01.ttf"
]

const VARIANTS := {
	R = ["-r", "_r", "-regular", "_regular"],
	B = ["-b", "_b", "-bold", "_bold"],
	I = ["-i", "_i", "-italic", "_italic"],
	BI = ["-bi", "_bi", "-bold_italic", "_bold_italic"],
	M = ["-m", "_m", "-mono", "_mono"],
}

var file := File.new()
var font_cache := {}
var fontset_cache := {}

func _get_font(path:String, size:int) -> Font:
	var key = [path, size]
	
	if not key in font_cache:
		if file.file_exists(path):
			var font:DynamicFont = DynamicFont.new()
			font.font_data = load(path)
			font.size = size
			font.use_filter = true
			for fallback in FALLBACK_FONTS:
				if file.file_exists(fallback):
					font.add_fallback(load(fallback))
			font_cache[key] = font
	
	return font_cache.get(key)

func _find_variant(id:String, tails:Array) -> String:
	
	for tail in tails:
		var path := DIR.plus_file(id + tail + ".ttf")
		if file.file_exists(path):
			return path
	
	for tail in tails:
		var path := DIR.plus_file(id).plus_file(id + tail + ".ttf")
		if file.file_exists(path):
			return path
	
	return ""

func _get_font_set(head:String, size:int) -> Dictionary:
	var key = [head, size]
	
	if not key in fontset_cache:
		fontset_cache[key] = {
			r=_get_font(_find_variant(head, VARIANTS.R), size),
			b=_get_font(_find_variant(head, VARIANTS.B), size),
			i=_get_font(_find_variant(head, VARIANTS.I), size),
			bi=_get_font(_find_variant(head, VARIANTS.BI), size),
			m=_get_font(_find_variant(head, VARIANTS.M), size) }
	
	return fontset_cache[key]

func set_fonts(node:Node, font:Dictionary):
	if not is_instance_valid(node) or node.is_queued_for_deletion():
		return
	
	var fname = font.get("font", DEFAULT_FONT)
	var fsize = font.get("size", DEFAULT_SIZE)
	
	if node is RichTextLabel:
		var f = _get_font_set(fname, fsize)
		node.add_font_override("normal_font", f.r)
		node.add_font_override("bold_font", f.get("b", f.r))
		node.add_font_override("italics_font", f.get("i", f.r))
		node.add_font_override("bold_italics_font", f.get("bi", f.r))
		node.add_font_override("mono_font", f.r if not f.m else f.m)
		
#		node.add_color_override("default_color", fcolor)
	else:
		var f = _get_font("%s_regular" % [fname], fsize)
		node.add_font_override("font", f)
		
		if node is OptionButton:
			node.theme = Theme.new()
			node.theme.default_font = f
#			$OptionButton.theme.default_font.font_data = load("res://your_font_file")
