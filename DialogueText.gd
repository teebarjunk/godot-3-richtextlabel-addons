tool
extends RichTextLabelAnimated

const Line = preload("res://addons/dialogue_manager/dialogue_line.gd")

signal actioned(next_id)

export var file:Resource
export var show:String = ""
var line:Line

func _ready():
	show_dialogue(show, file)

# Start some dialogue from a title, then recursively step through further lines
func show_dialogue(title:String, resource:DialogueResource=null) -> void:
	if not resource:
		resource = file
	
	line = yield(DialogueManager.get_next_dialogue_line(title, resource), "completed")
	if line != null:
#		var balloon := DialogueBalloon.instance()
#		balloon.dialogue = dialogue
#		add_child(balloon)
		print(line)
		set_bbcode2(line.dialogue)
		
		# Dialogue might have response options so we have to wait and see
		# what the player chose. "actioned" is emitted and passes the "next_id"
		# once the player has made their choice.
		show_dialogue(yield(self, "actioned"), resource)
	else:
		print("all done")

func _process(delta):
	if not Engine.editor_hint:
		if Input.is_action_just_pressed("ui_accept"):
			advance()

func advance():
	if .advance():
		emit_signal("actioned", line.next_id)
