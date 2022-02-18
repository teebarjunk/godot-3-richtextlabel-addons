# Makes words shake around.
tool
extends RichTextEffect

# Syntax: [jit scale=1.0 freq=8.0][/jit]
var bbcode = "jit"

const SPLITTERS = [ord(" "), ord("."), ord("!"), ord("?"), ord(","), ord("-")]

var _word = 0.0
var _last = 0

func _process_custom_fx(c:CharFXTransform):
	if c.relative_index == 0:
		_word = 0
		
	var scale:float = c.env.get("scale", 1.0)
	var freq:float = c.env.get("freq", 16.0)
	
	if c.character in SPLITTERS or _last in SPLITTERS:
		_word += PI * .33
	
	var t = c.elapsed_time
	var s = fmod((_word + t) * PI * 1.25, TAU)
	var p = sin(t * freq) * .5
	c.offset.x += sin(s) * p * scale
	c.offset.y += cos(s) * p * scale
	
	_last = c.character
	return true
