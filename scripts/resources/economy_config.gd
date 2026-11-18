class_name EconomyConfig
extends Resource
## Economy tuning. Placeholder defaults, to be reviewed before balancing.

@export var starting_balance: int = 300
## Room payment per stay, recorded when the key is handed over.
@export var room_price: int = 45
@export var ice_price: int = 2
@export var coffee_price: int = 3
## Charged once at the end of the shift (Task 7).
@export var operating_cost: int = 120
## Transactions shown in the computer's Finance tab.
@export var recent_count: int = 8
