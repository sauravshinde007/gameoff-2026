class_name SupplyCatalog
extends Resource
## All items the player can carry, plus supply costs of physical jobs. Placeholder values.

@export var items: Array[SupplyItem] = []
## Units taken from a shelf per interaction.
@export var take_amount: int = 1
## Largest quantity per computer purchase.
@export var max_purchase_quantity: int = 10
## Carried items used up by one room cleaning: item id -> quantity.
@export var clean_cost: Dictionary = {&"cleaning": 1, &"soap": 1, &"towels": 1}
## How long cleaning a room takes (real seconds).
@export var clean_seconds: float = 4.0


func get_item(id: StringName) -> SupplyItem:
	for it: SupplyItem in items:
		if it.id == id:
			return it
	return null
