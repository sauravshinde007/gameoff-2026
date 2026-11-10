class_name ComputerScreen
extends CanvasLayer
## Old-style motel management terminal. Reads RoomManager; assigns rooms to reservations.

signal closed

const GREEN: Color = Color(0.35, 1.0, 0.45)
const GREEN_DIM: Color = Color(0.15, 0.5, 0.2)
const ERROR_RED: Color = Color(1.0, 0.35, 0.3)
const BG: Color = Color(0.02, 0.07, 0.03)

@onready var panel: PanelContainer = %Panel
@onready var rooms_list: ItemList = %RoomsList
@onready var reservations_list: ItemList = %ReservationsList
@onready var info_label: Label = %InfoLabel
@onready var status_label: Label = %StatusLabel
@onready var assign_button: Button = %AssignButton
@onready var close_button: Button = %CloseButton

var _selected_room_id: int = 0
var _selected_reservation_id: String = ""


func _ready() -> void:
	visible = false
	panel.theme = _make_theme()
	rooms_list.item_selected.connect(_on_room_selected)
	reservations_list.item_selected.connect(_on_reservation_selected)
	assign_button.pressed.connect(_on_assign_pressed)
	close_button.pressed.connect(close)
	RoomManager.room_status_changed.connect(_on_room_status_changed)
	RoomManager.reservations_changed.connect(_refresh)


func open() -> void:
	if visible:
		return
	visible = true
	_select_first_pending_if_needed()
	_refresh()
	_set_status("Ready.", false)
	get_tree().call_group("player", "set_controls_enabled", false)


func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().call_group("player", "set_controls_enabled", true)
	closed.emit()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


func _on_room_status_changed(_room_id: int, _status: int) -> void:
	_refresh()


func _on_room_selected(index: int) -> void:
	_selected_room_id = rooms_list.get_item_metadata(index)
	_update_selection_status()


func _on_reservation_selected(index: int) -> void:
	_selected_reservation_id = reservations_list.get_item_metadata(index)
	_refresh_info()
	_update_selection_status()


func _on_assign_pressed() -> void:
	var res: ReservationData = RoomManager.get_reservation(_selected_reservation_id)
	if res == null:
		_set_status("ERROR: Select a reservation first (Reservations tab).", true)
		return
	if res.status != ReservationData.Status.PENDING:
		_set_status("ERROR: Reservation %s is not pending." % res.id, true)
		return
	var room: RoomData = RoomManager.get_room(_selected_room_id)
	if room == null:
		_set_status("ERROR: Select a room first (Rooms tab).", true)
		return
	match room.status:
		RoomData.Status.OCCUPIED:
			_set_status("ERROR: %s is occupied." % room.display_name, true)
			return
		RoomData.Status.OUT_OF_ORDER:
			_set_status("ERROR: %s is out of order." % room.display_name, true)
			return
	if RoomManager.assign_room(room.id, res.id):
		_set_status("OK: %s assigned to %s. Issue key." % [res.guest_name, room.display_name], false)
	else:
		_set_status("ERROR: Assignment refused.", true)


func _update_selection_status() -> void:
	var res_text: String = _selected_reservation_id if not _selected_reservation_id.is_empty() else "none"
	var room: RoomData = RoomManager.get_room(_selected_room_id)
	var room_text: String = room.display_name if room != null else "none"
	_set_status("Selected: reservation %s / %s" % [res_text, room_text], false)


func _select_first_pending_if_needed() -> void:
	var current: ReservationData = RoomManager.get_reservation(_selected_reservation_id)
	if current != null and current.status == ReservationData.Status.PENDING:
		return
	_selected_reservation_id = ""
	for res: ReservationData in RoomManager.get_reservations():
		if res.status == ReservationData.Status.PENDING:
			_selected_reservation_id = res.id
			break


func _refresh() -> void:
	if not is_node_ready():
		return
	rooms_list.clear()
	for room: RoomData in RoomManager.get_rooms():
		var line: String = "%-8s %-13s %s" % [room.display_name, _room_status_text(room.status), room.guest_name]
		var idx: int = rooms_list.add_item(line)
		rooms_list.set_item_metadata(idx, room.id)
		if room.id == _selected_room_id:
			rooms_list.select(idx)
	reservations_list.clear()
	for res: ReservationData in RoomManager.get_reservations():
		var line: String = "%-7s %-14s %s" % [res.id, res.guest_name, _reservation_status_text(res.status)]
		var idx: int = reservations_list.add_item(line)
		reservations_list.set_item_metadata(idx, res.id)
		if res.id == _selected_reservation_id:
			reservations_list.select(idx)
	_refresh_info()


func _refresh_info() -> void:
	var res: ReservationData = RoomManager.get_reservation(_selected_reservation_id)
	if res == null:
		info_label.text = "No reservation selected.\n\nPick one in the Reservations tab."
		return
	var room: RoomData = RoomManager.get_room(res.room_id)
	info_label.text = "Reservation ID: %s\nGuest: %s\nRoom: %s\nStatus: %s" % [
		res.id, res.guest_name,
		room.display_name if room != null else "not assigned",
		_reservation_status_text(res.status)]


func _room_status_text(status: RoomData.Status) -> String:
	match status:
		RoomData.Status.AVAILABLE:
			return "AVAILABLE"
		RoomData.Status.OCCUPIED:
			return "OCCUPIED"
	return "OUT OF ORDER"


func _reservation_status_text(status: ReservationData.Status) -> String:
	match status:
		ReservationData.Status.PENDING:
			return "Check-in Pending"
		ReservationData.Status.CHECKED_IN:
			return "Checked In"
	return "Checked Out"


func _set_status(text: String, is_error: bool) -> void:
	status_label.text = text
	status_label.add_theme_color_override("font_color", ERROR_RED if is_error else GREEN)


func _box(bg: Color, border: Color, border_width: int = 1) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_content_margin_all(8)
	return sb


func _make_theme() -> Theme:
	var t: Theme = Theme.new()
	var font: SystemFont = SystemFont.new()
	font.font_names = PackedStringArray(["Monospace", "DejaVu Sans Mono", "Courier New"])
	t.default_font = font
	t.default_font_size = 18
	t.set_color("font_color", "Label", GREEN)
	t.set_stylebox("panel", "PanelContainer", _box(BG, GREEN, 2))
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var bg: Color = BG if state == "normal" else GREEN_DIM
		t.set_stylebox(state, "Button", _box(bg, GREEN))
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, "Button", GREEN)
	t.set_stylebox("panel", "ItemList", _box(BG, GREEN_DIM))
	t.set_stylebox("selected", "ItemList", _box(GREEN_DIM, GREEN))
	t.set_stylebox("selected_focus", "ItemList", _box(GREEN_DIM, GREEN))
	t.set_color("font_color", "ItemList", GREEN)
	t.set_color("font_selected_color", "ItemList", Color.WHITE)
	t.set_stylebox("panel", "TabContainer", _box(BG, GREEN_DIM))
	t.set_stylebox("tab_selected", "TabContainer", _box(GREEN_DIM, GREEN))
	t.set_stylebox("tab_unselected", "TabContainer", _box(BG, GREEN_DIM))
	t.set_stylebox("tab_hovered", "TabContainer", _box(GREEN_DIM, GREEN_DIM))
	t.set_color("font_selected_color", "TabContainer", Color.WHITE)
	t.set_color("font_unselected_color", "TabContainer", GREEN)
	t.set_color("font_hovered_color", "TabContainer", GREEN)
	return t
