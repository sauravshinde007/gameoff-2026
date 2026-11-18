extends Node
## Shared motel stock and the player's small carry inventory. No grid, no weight.
## Quantities never go negative. Purchases go through EconomyManager (money and stock change together).

signal stock_changed(item_id: StringName)
signal carry_changed()

@export var catalog: SupplyCatalog = preload("res://data/sim/supply_catalog.tres")

var _stock: Dictionary[StringName, int] = {}
var _carry: Dictionary[StringName, int] = {}


func _ready() -> void:
	reset()


func reset() -> void:
	_stock.clear()
	_carry.clear()
	for it: SupplyItem in catalog.items:
		if it.tracked_stock:
			_stock[it.id] = maxi(it.start_stock, 0)
	for it: SupplyItem in catalog.items:
		stock_changed.emit(it.id)
	carry_changed.emit()


func get_items() -> Array[SupplyItem]:
	return catalog.items


func get_item(id: StringName) -> SupplyItem:
	return catalog.get_item(id)


func display_name(id: StringName) -> String:
	var it: SupplyItem = catalog.get_item(id)
	return it.display_name if it != null else String(id)


## Stock count. Untracked items (ice, coffee) report -1.
func get_stock(id: StringName) -> int:
	return _stock.get(id, -1)


func get_carried(id: StringName) -> int:
	return _carry.get(id, 0)


func has_carried(id: StringName, qty: int = 1) -> bool:
	return qty > 0 and get_carried(id) >= qty


## true if every item of `cost` (id -> qty) is carried.
func has_carried_all(cost: Dictionary) -> bool:
	for id: StringName in cost:
		if not has_carried(id, cost[id]):
			return false
	return true


## Names of the items in `cost` that are not carried in sufficient quantity.
func missing_names(cost: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for id: StringName in cost:
		if not has_carried(id, cost[id]):
			out.append(display_name(id).to_lower())
	return out


## Move up to `qty` from the shelf into the player's hands. Returns "" on success, else the reason.
func take(id: StringName, qty: int = -1) -> String:
	var it: SupplyItem = catalog.get_item(id)
	if it == null:
		return "Unknown item."
	if qty < 0:
		qty = catalog.take_amount
	if qty <= 0:
		return "Nothing to take."
	var room_in_hands: int = it.carry_limit - get_carried(id)
	if room_in_hands <= 0:
		return "Hands full: already carrying %d %s." % [get_carried(id), it.display_name.to_lower()]
	var moved: int = mini(qty, room_in_hands)
	if it.tracked_stock:
		var left: int = _stock.get(id, 0)
		if left <= 0:
			return "Out of %s." % it.display_name.to_lower()
		moved = mini(moved, left)
		_stock[id] = left - moved
		stock_changed.emit(id)
	_carry[id] = get_carried(id) + moved
	carry_changed.emit()
	return ""


## Use up carried items. All-or-nothing; returns false (nothing changes) if not enough.
func consume_carried(cost: Dictionary) -> bool:
	if not has_carried_all(cost):
		return false
	for id: StringName in cost:
		_carry[id] = get_carried(id) - int(cost[id])
		if _carry[id] <= 0:
			_carry.erase(id)
	carry_changed.emit()
	return true


## Buy `qty` units for the motel stock. Returns "" on success, else why not. Money and stock
## change together or not at all.
func purchase(id: StringName, qty: int) -> String:
	var it: SupplyItem = catalog.get_item(id)
	if it == null or not it.tracked_stock or it.buy_price <= 0:
		return "That item cannot be bought."
	if qty <= 0 or qty > catalog.max_purchase_quantity:
		return "Quantity must be 1 to %d." % catalog.max_purchase_quantity
	var cost: int = it.buy_price * qty
	if not EconomyManager.can_afford(cost):
		return "Not enough funds: need $%d, have $%d." % [cost, EconomyManager.get_balance()]
	if not EconomyManager.record_expense(cost, &"supplies", "%d x %s" % [qty, it.display_name]):
		return "Payment was refused."
	_stock[id] = _stock.get(id, 0) + qty
	stock_changed.emit(id)
	return ""


## "Towels x2, Ice x1" or "" when empty.
func carry_text() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for it: SupplyItem in catalog.items:
		var n: int = get_carried(it.id)
		if n > 0:
			parts.append("%s x%d" % [it.display_name, n])
	return ", ".join(parts)
