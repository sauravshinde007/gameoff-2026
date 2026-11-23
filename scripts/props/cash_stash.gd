class_name CashStash
extends Node3D
## Cash left on the reception desk by guests paying for a room. The money only reaches the
## motel balance when the player picks it up (one ledger transaction per payment).
## Guests find it through the "cash_stash" group; with no stash in the scene they pay directly.

signal collected(total: int)

## One money stack per payment, laid out in this grid on the desk (metres, local space).
@export var stack_spacing: Vector2 = Vector2(0.32, 0.12)
## Size multiplier for each stack. The imported model is only ~16 x 2 x 4 cm at 1.0.
@export var stack_scale: float = 1.8
@export var stacks_per_row: int = 2
## Stacks shown at most; further payments still add to the pile's value.
@export var max_visible_stacks: int = 8

const MONEY_SCENE: PackedScene = preload("res://assets/models/props/money_stack.glb")

@onready var interactable: Interactable = $Interactable
@onready var stacks_root: Node3D = $Stacks

## Sound names looked up in the AudioManager bank (silently skipped if the bank has none).
@export var drop_sfx: StringName = &"cash_drop"
@export var collect_sfx: StringName = &"cash_collect"

## Each entry: {amount, category, description, ref, room_id}.
var _pending: Array[Dictionary] = []


func _ready() -> void:
	add_to_group(&"cash_stash")
	interactable.interacted.connect(_on_interacted)
	_refresh()


func add_payment(amount: int, category: StringName, description: String,
		ref: String = "", room_id: int = 0) -> void:
	if amount <= 0:
		return
	_pending.append({"amount": amount, "category": category, "description": description,
			"ref": ref, "room_id": room_id})
	AudioManager.play_sfx(drop_sfx, global_position)
	_refresh()


func get_pending_total() -> int:
	var total: int = 0
	for p: Dictionary in _pending:
		total += p["amount"] as int
	return total


func has_cash() -> bool:
	return not _pending.is_empty()


## Records every pending payment as income. `silent` skips the sound/message (end of shift).
func collect_all(silent: bool = false) -> int:
	var total: int = 0
	for p: Dictionary in _pending:
		if EconomyManager.record_income(p["amount"], p["category"], p["description"],
				p["ref"], p["room_id"]):
			total += p["amount"] as int
	_pending.clear()
	_refresh()
	if total > 0:
		collected.emit(total)
		if not silent:
			AudioManager.play_sfx(collect_sfx, global_position)
			get_tree().call_group("hud", "show_message", "Collected $%d." % total)
	return total


func _on_interacted(_by: Node) -> void:
	collect_all()


func _refresh() -> void:
	var want: int = mini(_pending.size(), max_visible_stacks)
	while stacks_root.get_child_count() < want:
		var i: int = stacks_root.get_child_count()
		var stack: Node3D = MONEY_SCENE.instantiate() as Node3D
		stack.set_script(RetroModel)
		var col: int = i % stacks_per_row
		var row: int = floori(float(i) / stacks_per_row) % 2
		var layer: int = floori(float(i) / (stacks_per_row * 2))
		stack.position = Vector3((col - (stacks_per_row - 1) * 0.5) * stack_spacing.x,
				layer * 0.02, row * stack_spacing.y)
		stack.rotation.y = deg_to_rad(randf_range(-12.0, 12.0))
		stack.scale = Vector3.ONE * stack_scale
		stacks_root.add_child(stack)
	while stacks_root.get_child_count() > want:
		var last: Node = stacks_root.get_child(stacks_root.get_child_count() - 1)
		stacks_root.remove_child(last)
		last.queue_free()
	interactable.enabled = has_cash()
	interactable.prompt_text = "Collect cash ($%d)" % get_pending_total()
