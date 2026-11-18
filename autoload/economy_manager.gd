extends Node
## Single source of truth for the motel balance. Every change is a ledger transaction.
## Amounts are positive integers; income adds, expense subtracts. Never goes negative.

signal balance_changed(balance: int)
signal transaction_recorded(tx: TransactionData)

@export var config: EconomyConfig = preload("res://data/sim/economy_config.tres")

var _balance: int = 0
var _start_balance: int = 0
var _ledger: Array[TransactionData] = []
var _refs: Dictionary[String, bool] = {}
var _next_id: int = 1


func _ready() -> void:
	reset()


func reset() -> void:
	_ledger.clear()
	_refs.clear()
	_next_id = 1
	_balance = config.starting_balance
	_start_balance = _balance
	balance_changed.emit(_balance)


func get_balance() -> int:
	return _balance


func get_start_balance() -> int:
	return _start_balance


func get_ledger() -> Array[TransactionData]:
	return _ledger


func get_total_income() -> int:
	return _sum(TransactionData.Type.INCOME)


func get_total_expenses() -> int:
	return _sum(TransactionData.Type.EXPENSE)


func get_net() -> int:
	return get_total_income() - get_total_expenses()


func can_afford(amount: int) -> bool:
	return amount >= 0 and amount <= _balance


## Returns false (balance untouched) for amount <= 0 or a `ref` already recorded.
func record_income(amount: int, category: StringName, description: String,
		ref: String = "", room_id: int = 0) -> bool:
	return _record(TransactionData.Type.INCOME, amount, category, description, ref, room_id)


## Returns false (balance untouched) for amount <= 0, a duplicate `ref`, or insufficient funds.
func record_expense(amount: int, category: StringName, description: String,
		ref: String = "", room_id: int = 0) -> bool:
	return _record(TransactionData.Type.EXPENSE, amount, category, description, ref, room_id)


func _record(type: TransactionData.Type, amount: int, category: StringName,
		description: String, ref: String, room_id: int) -> bool:
	if amount <= 0:
		return false
	if not ref.is_empty() and _refs.has(ref):
		return false
	if type == TransactionData.Type.EXPENSE and amount > _balance:
		return false
	var tx: TransactionData = TransactionData.new()
	tx.id = _next_id
	tx.type = type
	tx.amount = amount
	tx.category = category
	tx.description = description
	tx.minute = ShiftManager.get_minute()
	tx.room_id = room_id
	tx.ref = ref
	_next_id += 1
	_ledger.append(tx)
	if not ref.is_empty():
		_refs[ref] = true
	_balance += amount if type == TransactionData.Type.INCOME else -amount
	balance_changed.emit(_balance)
	transaction_recorded.emit(tx)
	return true


func _sum(type: TransactionData.Type) -> int:
	var total: int = 0
	for tx: TransactionData in _ledger:
		if tx.type == type:
			total += tx.amount
	return total
