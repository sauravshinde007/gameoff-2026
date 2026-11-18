class_name SupplyItem
extends Resource
## One carryable item. Placeholder values, to be reviewed before balancing.

@export var id: StringName = &""
@export var display_name: String = ""
## false = unlimited source with no stock count (ice, coffee). Cannot be bought.
@export var tracked_stock: bool = true
@export var start_stock: int = 0
## Price per unit when bought on the reception computer. 0 = not for sale.
@export var buy_price: int = 0
@export var carry_limit: int = 3
