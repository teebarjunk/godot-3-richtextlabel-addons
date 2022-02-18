# Fades words in one at a time.
tool
extends RichTextEffect

# Syntax: [fade word=false][]
var bbcode = "fader"

func _process_custom_fx(c:CharFXTransform):
	var t:RichTextLabelAnimated = Global._d.get(self)
	c.color.a *= t._get_character_alpha(c.absolute_index)
	return true
