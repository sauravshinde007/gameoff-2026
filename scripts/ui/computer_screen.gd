class_name ComputerScreen
extends CanvasLayer
## Old-style motel management terminal. Reads RoomManager; assigns rooms to reservations.

signal closed

const GREEN: Color = Color(0.93, 0.96, 1.0)  # text / lines (white-blue)
const GREEN_DIM: Color = Color(0.0, 0.2, 0.62)  # selected rows, pressed buttons
const ERROR_RED: Color = Color(1.0, 0.86, 0.3)  # errors (yellow reads better on blue)
const BG: Color = Color(0.0, 0.3, 0.82)  # screen blue
const BEZEL: Color = Color(0.86, 0.83, 0.72)  # cream monitor frame
const SCREEN_FONT: Font = preload("res://assets/fonts/screen_font.tres")

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
	AudioManager.play_sfx(&"computer_beep")
	_select_first_pending_if_needed()
	_refresh()
	_set_status("Ready.", false)


func close() -> void:
	if not visible:
		return
	visible = false
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
	_mark_viewed(_selected_reservation_id)
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
	_mark_viewed(res.id)
	if res.room_id > 0 and RoomManager.get_room(res.room_id) == null:
		_set_status("ERROR: Room %d does not exist." % res.room_id, true)
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


## Reports "this reservation was looked at" as a story flag, e.g. viewed_res_0013.
func _mark_viewed(reservation_id: String) -> void:
	EventManager.set_flag(StringName("viewed_res_" + reservation_id.trim_prefix("#")))


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
		var row: String = "%s   |   %s" % [room.display_name, _room_status_text(room.status)]
		if not room.guest_name.is_empty():
			row += "   |   " + room.guest_name
		var idx: int = rooms_list.add_item(row)
		rooms_list.set_item_metadata(idx, room.id)
		if room.id == _selected_room_id:
			rooms_list.select(idx)
	reservations_list.clear()
	for res: ReservationData in RoomManager.get_reservations():
		var row: String = "%s   |   %s   |   %s" % [res.id, res.guest_name, _reservation_status_text(res.status)]
		var idx: int = reservations_list.add_item(row)
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
		_room_text(res, room),
		_reservation_status_text(res.status)]


func _room_text(res: ReservationData, room: RoomData) -> String:
	if room != null:
		return room.display_name
	if res.room_id > 0:
		return str(res.room_id)
	return "not assigned"


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
	if is_error:
		AudioManager.play_sfx(&"computer_beep")
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
	t.default_font = SCREEN_FONT
	t.default_font_size = 24
	t.set_font_size("font_size", "Label", 24)
	var line: StyleBoxLine = StyleBoxLine.new()
	line.color = GREEN
	line.thickness = 3
	t.set_stylebox("separator", "HSeparator", line)
	t.set_color("font_color", "Label", GREEN)
	t.set_stylebox("panel", "PanelContainer", _box(BG, BEZEL, 14))
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
