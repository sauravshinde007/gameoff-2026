class_name ShiftReport
extends RefCounted
## Builds the shift summary from the live manager state, and turns it into text.
## Used by the computer's Report tab (live) and the end screen (final). No grades, no score.

## `tree` is only used to find the phone dispatcher for call counts.
static func build(tree: SceneTree) -> Dictionary:
	var dispatcher: PhoneDispatcher = tree.get_first_node_in_group(&"phone_dispatcher") as PhoneDispatcher
	var guests: Array[Dictionary] = []
	var served: int = 0
	for g: GuestRecord in GuestManager.get_guests():
		if g.room_id <= 0:
			continue
		served += 1
		guests.append({"name": g.display_name, "room": g.room_id, "satisfaction": g.satisfaction})
	var done: int = 0
	var missed: int = 0
	for r: ServiceRequest in GuestManager.get_requests():
		if r.state == ServiceRequest.State.COMPLETED:
			done += 1
		elif r.state == ServiceRequest.State.FAILED:
			missed += 1
	return {
		"start_balance": EconomyManager.get_start_balance(),
		"balance": EconomyManager.get_balance(),
		"income": EconomyManager.get_total_income(),
		"expenses": EconomyManager.get_total_expenses(),
		"net": EconomyManager.get_net(),
		"operating_cost": EconomyManager.config.operating_cost,
		"tasks_done": TaskManager.count_completed(),
		"tasks_failed": TaskManager.count_failed(),
		"tasks_open": TaskManager.count_open(true) + TaskManager.count_open(false),
		"guests_served": served,
		"requests_done": done,
		"requests_missed": missed,
		"calls_answered": dispatcher.get_answered_count() if dispatcher != null else 0,
		"calls_missed": dispatcher.get_missed_count() if dispatcher != null else 0,
		"guests": guests,
	}


static func _money(amount: int) -> String:
	return "%s$%d" % ["-" if amount < 0 else "", absi(amount)]


## live = true: mid-shift view (operating costs not charged yet).
static func to_text(r: Dictionary, live: bool = false) -> String:
	if r.is_empty():
		return ""
	var net: int = r["net"]
	var out: String = ""
	if live:
		out += "SHIFT SO FAR\n"
	out += "Balance: $%d -> $%d  (net %s%s)\n" % [r["start_balance"], r["balance"],
			"+" if net >= 0 else "-", _money(absi(net))]
	out += "Income +$%d   Expenses -$%d\n" % [r["income"], r["expenses"]]
	if live:
		out += "Operating costs of $%d are charged at the end of the shift.\n" % r["operating_cost"]
	out += "Tasks: %d done, %d failed, %d open\n" % [r["tasks_done"], r["tasks_failed"], r["tasks_open"]]
	out += "Guests served: %d   Requests: %d done, %d missed\n" % [
			r["guests_served"], r["requests_done"], r["requests_missed"]]
	out += "Calls: %d answered, %d missed\n" % [r["calls_answered"], r["calls_missed"]]
	var guests: Array = r["guests"]
	if not guests.is_empty():
		out += "\n"
	var shown: int = 0
	for g: Dictionary in guests:
		if shown >= 6:
			out += "...and %d more\n" % (guests.size() - shown)
			break
		out += "%s, Room %02d: %s (%d)\n" % [g["name"], g["room"],
				GuestManager.satisfaction_label(g["satisfaction"]), g["satisfaction"]]
		shown += 1
	return out
