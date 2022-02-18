tool
extends Node

var _d:Dictionary = {}

func clear():
	_d.clear()

func test(a=true, b=false, kwargs={}):
	prints("'test' got:", a, b, kwargs)

func _set(property:String, value):
	if "." in property:
		var parts = property.split(".")
		var d = _d
		for i in len(parts)-1:
			if not parts[i] in d:
				d[parts[i]] = {}
			d = d[parts[i]]
		d[parts[-1]] = value
		return true
	
	else:
		_d[property] = value
		return true

func _get(property:String):
	if "." in property:
		var parts = property.split(".")
		var d = _d
		for i in len(parts):
			if not parts[i] in d:
				return null
			d = d[parts[i]]
		return d
	
	else:
		return _d.get(property)

func display():
	print(JSON.print(_d, "\t"))
