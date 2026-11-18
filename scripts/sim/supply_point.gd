class_name SupplyPoint
extends Node3D
## A shelf, machine or counter where the player takes an item into their hands.
## Stock lives in InventoryManager; this node only asks it to move items.

@export var item_id: StringName = &""
## Interaction volume, centered on the node (x/z) and standing on the floor.
## Ice machine, coffee maker: dead while the generator is critical.
@export var requires_power: bool = false
@export var point_size: Vector3 = Vector3(1.2, 1.6, 0.6)

@onready var interactable: Interactable = $Interactable
@onready var shape: CollisionShape3D = $Interactable/CollisionShape3D


var _generator: GeneratorPoint = null


func _ready() -> void:
	var box: BoxShape3D = BoxShape3D.new()
	box.size = point_size
	shape.shape = box
	shape.position = Vector3(0.0, point_size.y * 0.5, 0.0)
	interactable.interacted.connect(_on_interacted)
	InventoryManager.stock_changed.connect(_on_inventory_changed)
	InventoryManager.carry_changed.connect(_refresh)
	if requires_power:
		_find_generator.call_deferred()
	_refresh()


func _find_generator() -> void:
	_generator = get_tree().get_first_node_in_group(&"generator") as GeneratorPoint
	if _generator != null:
		_generator.power_changed.connect(_refresh)
	_refresh()


func _powered() -> bool:
	return not requires_power or _generator == null or not _generator.is_critical()


func _on_inventory_changed(id: StringName) -> void:
	if id == item_id:
		_refresh()


func _refresh() -> void:
	var item: SupplyItem = InventoryManager.get_item(item_id)
	if item == null:
		interactable.enabled = false
		return
	if not _powered():
		interactable.prompt_text = "%s (no power)" % item.display_name
		return
	var held: String = "carrying %d/%d" % [InventoryManager.get_carried(item_id), item.carry_limit]
	if item.tracked_stock:
		interactable.prompt_text = "Take %s (%d left, %s)" % [
				item.display_name.to_lower(), InventoryManager.get_stock(item_id), held]
	else:
		interactable.prompt_text = "Take %s (%s)" % [item.display_name.to_lower(), held]


func _on_interacted(_by: Node) -> void:
	if not _powered():
		get_tree().call_group("hud", "show_message", "No power. Refuel the generator.")
		return
	var before: int = InventoryManager.get_carried(item_id)
	var err: String = InventoryManager.take(item_id)
	if not err.is_empty():
		get_tree().call_group("hud", "show_message", err)
		return
	var took: int = InventoryManager.get_carried(item_id) - before
	get_tree().call_group("hud", "show_message", "Took %d %s." % [
			took, InventoryManager.display_name(item_id).to_lower()])
