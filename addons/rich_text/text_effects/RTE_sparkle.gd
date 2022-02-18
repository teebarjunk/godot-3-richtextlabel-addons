tool
extends RichTextEffect

# Syntax: [sparkle freq c1 c2 c3][/sparkle]
var bbcode = "sparkle"

func _process_custom_fx(c:CharFXTransform):
	var s = 1.0 - c.color.s
	c.color.h = wrapf(c.color.h + sin(-c.elapsed_time * 4.0 + c.absolute_index * 2.0) * s * .033, 0.0, 1.0)
	c.color.v = clamp(c.color.v + sin(c.elapsed_time * 4.0 + c.absolute_index) * .25, 0.0, 1.0)
	return true
