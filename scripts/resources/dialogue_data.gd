class_name DialogueData
extends Resource
## One conversation: a list of lines, then an optional set of player choices.

@export var id: StringName = &""
@export var lines: Array[DialogueLine] = []
## If non-empty, shown after the last line. dialogue_finished reports the picked index.
@export var choices: PackedStringArray = PackedStringArray()
