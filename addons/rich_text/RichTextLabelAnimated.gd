tool
extends RichTextLabel2
class_name RichTextLabelAnimated

func test_button():
	return EvalHelper.new().to_eval('test 10 20 ass:20 okay:"Who-cares?" time:false')

signal command(command)			# [!] tag is reached.
signal character_shown(index)	# character is made visible.

signal started()				# animation starts.
signal paused()					# 'play' is set to false.
signal ended()					# animation ended.
signal faded_in()
signal faded_out()

signal wait_started()			# wait timer started.
signal wait_ended()				# wait timer ended.
signal quote_started()			# "quote" starts.
signal quote_ended()			# "quote" ends.

export(String, ",back,console,fader,focus,prickle,redact,wfc") var animation := "fader" setget set_animation
export(float, 0.0, 1.0) var percent := 0.0 setget set_percent
export var fade_speed := 10.0
var visible_character := -1

export var play := true
export var play_speed := 30.0
export var fade_out := false
export var fade_out_speed := 120.0

var pace := 1.0 # pace of fade in
var wait := 0.0 # wait before animating

export var skip := false setget set_skip

var _installed_effect := false
var _alpha := PoolRealArray()
var _alpha_goal := PoolRealArray()
var _triggers := {}

func is_finished() -> bool:
	return percent >= 1.0

func is_waiting() -> bool:
	return wait > 0.0

func set_skip(s):
	skip = s
	skip()

func skip():
	for i in range(visible_character, get_total_character_count()):
		if i in _triggers:
			for t in _triggers[i]:
				if t[0] in ["h", "hold"]:
					set_percent(i / float(get_total_character_count()))
					return

func set_animation(s):
	animation = s
	redraw()

func advance():
	if not play:
		play = true
	elif not is_finished():
		set_percent(1.0)

func set_percent(p:float):
	var last_percent := percent
	var last_visible_character := visible_character
	
	var next_percent = clamp(p, 0.0, 1.0)
	var next_visible_character = int(floor(get_total_character_count() * next_percent))
	
	if last_percent == next_percent:
		return
	
	# emit signal and pop triggers
	if last_visible_character < next_visible_character:
		for i in range(last_visible_character, next_visible_character):
			
			if i in _triggers:
				for t in _triggers[i]:
					call("_trigger_" + t[0], t[1], t[2])
				
				if is_waiting():
					next_percent = (i+1) / float(get_total_character_count())
					next_visible_character = (i+1)
					break
			
			if is_waiting():
				break
	
	percent = next_percent
	visible_character = next_visible_character
	
	# set alpha
	for i in len(_alpha_goal):
		_alpha_goal[i] = 1.0 if i < visible_character else 0.0
	
	# emit signals
	if last_visible_character < visible_character:
		if visible_character == 0:
			emit_signal("started")
	
		for i in range(last_visible_character, visible_character):
			emit_signal("character_shown", i)
	
		if visible_character == get_total_character_count():
			emit_signal("ended")
	
	if fade_out:
		if percent == 0.0:
			print("FADED OUT")
			emit_signal("faded_out")
	else:
		if percent == 1.0:
			print("FADED IN")
			emit_signal("faded_in")

func redraw():
	_triggers.clear()
	pace = 1.0
	wait = 0.0
	percent = 0.0
	visible_character = -1
	.redraw()
	_alpha.resize(len(text))
	_alpha_goal.resize(len(text))
	for i in len(_alpha):
		_alpha[i] = 0.0
		_alpha_goal[i] = 0.0

func _replace_quotes(q):
	return "[q]%s[]" % ._replace_quotes(q)

func _effect_prepass():
	# add the effect tag.
	if animation and _install_effect(animation):
		_installed_effect = true
		var _err = append_bbcode("[%s]" % animation)
	else:
		_installed_effect = false

func _effect_postpass():
	# remove the effect tag.
	if _installed_effect:
		pop()

func _process(delta):
	
	if fade_out:
		for i in len(_alpha):
			if _alpha[i] > 0.0:
				_alpha[i] = max(0.0, _alpha[i] - delta * fade_speed)
		
		if percent > 0.0:
			self.percent -= delta * fade_out_speed
	
	else:
		for i in len(_alpha):
			if _alpha[i] > _alpha_goal[i]:
				_alpha[i] = max(_alpha_goal[i], _alpha[i] - delta * fade_speed)
			
			elif _alpha[i] < _alpha_goal[i]:
				_alpha[i] = min(_alpha_goal[i], _alpha[i] + delta * fade_speed)
		
		if wait > 0.0:
			wait -= delta
		
		elif play and percent < 1.0:
			var t = (1.0 / float(get_total_character_count())) * play_speed
			self.percent += delta * t * pace

func _make_custom_tooltip(_for_text):
	pass

func _get_character_alpha(index:int) -> float:
	if index < 0 or index >= len(_alpha):
		return 1.0
	return _alpha[index]

func _apply_tag(tag:String, state:Dictionary, open:Array):
	if tag.begins_with("!"):
		_register_trigger("cmd", tag.substr(1))
	
	else:
		._apply_tag(tag, state, open)

func _custom_tag(tag:String, info:Dictionary) -> bool:
	match tag:
		"w", "wait":
			_register_trigger("wait", info, tag)
			return true
		
		"h", "hold":
			_register_trigger("hold", info, tag)
			return true
			
		"p", "pace":
			_register_trigger("pace", info, tag)
			return false
		
		"q", "quote":
			_register_trigger("quote", info, tag)
			return false
	
	return ._custom_tag(tag, info)

func _custom_tag_closed(tag:String):
	match tag:
		"w", "wait": pass
		"h", "hold": pass
		"p", "pace": _register_trigger("pace", {pace=1}, tag)
		"q", "quote": _register_trigger("end_quote")
		_: _custom_tag_closed(tag)

func _register_trigger(id:String, info={}, tag:String=""):
	var index := len(text)-1
	var data := [id, info, tag]
	if not index in _triggers:
		_triggers[index] = [data]
	else:
		_triggers[index].append(data)

func _trigger_cmd(command, _tag):
	emit_signal("command", command)
	print("run command '%s'" % [command])

func _trigger_wait(info, _tag):
	wait = info.get("wait", info.get("w", 1.0))

func _trigger_pace(info, _tag):
	pace = info.get("pace", info.get("p", 1.0))
	prints("Set pace", pace)

func _trigger_hold(_info, _tag):
	play = false

func _trigger_quote(_info, _tag):
	print("quote started")
	emit_signal("quote_started")

func _trigger_end_quote(_info, _tag):
	print("quote ended")
	emit_signal("quote_ended")
