class_name TransactionData
extends Resource
## One ledger line. `amount` is always a positive magnitude; `type` decides the sign.

enum Type { INCOME, EXPENSE }

@export var id: int = 0
@export var type: Type = Type.INCOME
@export var amount: int = 0
@export var category: StringName = &""
@export var description: String = ""
## Absolute shift minute (see ShiftData) when it was recorded.
@export var minute: int = 0
## Optional references.
@export var room_id: int = 0
@export var ref: String = ""
