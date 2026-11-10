extends Node
## Plays a DialogueData line by line. UI (DialogueBox) listens to the signals and draws.

signal dialogue_started(id: StringName)
signal line_shown(speaker: String, text: String)
signal choices_shown(options: PackedStringArray)
## choice = picked index, or -1 if the dialogue had no choices.
signal dialogue_finished(id: StringName, choice: int)

var _data: DialogueData = null
var _index: int = -1
var _waiting_for_choice: bool = false


func is_active() -> bool:
	return _data != null


func start(data: DialogueData) -> void:
	if _data != null or data == null:
		return
	_data = data
	_index = -1
	_waiting_for_choice = false
	dialogue_started.emit(data.id)
	advance()


func advance() -> void:
	if _data == null or _waiting_for_choice:
		return
	_index += 1
	if _index < _data.lines.size():
		var line: DialogueLine = _data.lines[_index]
		line_shown.emit(line.speaker, line.text)
	elif not _data.choices.is_empty():
		_waiting_for_choice = true
		choices_shown.emit(_data.choices)
	else:
		_finish(-1)


func choose(index: int) -> void:
	if _data == null or not _waiting_for_choice:
		return
	if index < 0 or index >= _data.choices.size():
		return
	_finish(index)


func reset() -> void:
	_data = null
	_index = -1
	_waiting_for_choice = false


func _finish(choice: int) -> void:
	var id: StringName = _data.id
	reset()
	dialogue_finished.emit(id, choice)
