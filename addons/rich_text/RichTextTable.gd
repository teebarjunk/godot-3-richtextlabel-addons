tool
extends RichTextLabel2
class_name RichTextTable

const UP := "⯅"
const DOWN := "⯆"

export var has_heading:bool = true setget set_has_heading
export var heading_format:String = "b;opp" setget set_heading_format
export var highlight_rows:bool = true setget set_highlight_rows
export(float, 0.0, 1.0) var highlight_row_strength:float = 0.25 setget set_highlight_row_strength

export var sortable:bool = false setget set_sortable

func set_sortable(s):
	sortable = s
	redraw()

# Add commas to large numbers: 1000 -> 1,000
export var auto_comma:bool = true setget set_auto_comma

func set_auto_comma(a):
	auto_comma = a
	redraw()

var sort_on := -1
var reverse := false
var head_data := []
var head_align := []
var cell_data := []

func _ready():
	var _e
	_e = connect("resized", self, "_resized")

func _clicked(meta:String):
	var p := meta.split(":", true, 1)
	match p[0]:
		"row": sort_on(int(p[1]))

func sort_on(row:int):
	if not sortable:
		return
	
	if sort_on == row:
		reverse = not reverse
	else:
		sort_on = row
		reverse = false
	redraw()

func set_has_heading(h):
	has_heading = h
	redraw()

func set_heading_format(h):
	heading_format = h
	redraw()

func set_highlight_rows(h):
	highlight_rows = h
	redraw()

func set_highlight_row_strength(h):
	highlight_row_strength = h
	redraw()

func _update_seperator():
	add_constant_override("table_hseparation", rect_size.x / float(len(head_data) + 2.0))

func _resized():
	_update_seperator()

func _sort(a, b):
	var key = head_data[sort_on]
	if reverse:
		return a[key] < b[key]
	else:
		return a[key] >= b[key]

func _preprocess(b:String):
	head_data.clear()
	cell_data.clear()
	head_align.clear()
	
	var index := 0
	for row in b.strip_edges().split("\n"):
		var c = row.split("|")
		if index == 0:
			for h in c:
				if h.begins_with(":") and h.ends_with(":"):
					head_data.append(h.trim_prefix(":").trim_suffix(":"))
					head_align.append(";center")
				elif h.begins_with(":"):
					head_data.append(h.trim_prefix(":"))
					head_align.append(";left")
				elif h.ends_with(":"):
					head_data.append(h.trim_suffix(":"))
					head_align.append(";right")
				else:
					head_data.append(h)
					head_align.append("")
		
		else:
			var data = {}
			for i in len(head_data):
				data[head_data[i]] = str2var(c[i]) if i < len(c) else null
			
			cell_data.append(data)
		
		index += 1
	
	var out := "[table=%s]" % len(head_data)
	
	# Headings.
	for i in len(head_data):
		var head = head_data[i]
		if sortable and has_heading:
			var icon = DOWN if reverse else UP
			if i == sort_on:
				out += "[cell%s;url=row:%s]%s[dim]%s[][]" % [head_align[i], i, head, icon]
			else:
				out += "[cell%s;url=row:%s]%s[]" % [head_align[i], i, head]
		else:
			out += "[cell%s]%s[]" % [head_align[i], head]
	
	# Cells.
	if sort_on != -1:
		cell_data.sort_custom(self, "_sort")
	
	for i in len(cell_data):
		for j in len(head_data):
			var data = cell_data[i][head_data[j]]
			if auto_comma and data is int:
				data = commas(data)
			out += "[cell%s]%s[]" % [head_align[j], data]
	
	out += "[/table]"
	
	return ._preprocess(out)

func _on_cell(opened:Array, state:Dictionary):
	if state.table_cells < state.table_rows and has_heading and heading_format:
		var h = _apply_tags(heading_format, state)
		opened.append_array(h)
	
	elif highlight_rows and int(state.table_cells / state.table_rows) % 2 == 0:
		opened.append(true)
		push_color(lerp(state.color, Color.black, highlight_row_strength))
	
	._on_cell(opened, state)
