class_name DayNightCycle
extends Node
## Timed day/night cycle. Blends the LightingPresets set at keyframe hours (through DayNight)
## and moves the sun (group "sun") along an arc. Time comes from the shift clock
## (ShiftManager) in the main game, or from its own looping clock (Free Roam).

## Hours of day (0-24, ascending). Between two keyframes the presets blend; it wraps past midnight.
@export var keyframe_hours: PackedFloat32Array = PackedFloat32Array([4.5, 6.0, 7.5, 18.0, 19.5, 21.0])
## One preset per keyframe hour.
@export var keyframe_presets: Array[LightingPreset] = []
@export_group("Clock")
## true = follow ShiftManager's clock. false = run an own looping clock (Free Roam).
@export var use_shift_clock: bool = true
## Own clock only.
@export var start_hour: float = 8.0
## Own clock only: real seconds per in-game hour.
@export var seconds_per_hour: float = 30.0
## Seconds between lighting refreshes (the blend is applied to many lights and materials).
@export var update_interval: float = 0.5
@export_group("Sun")
@export var animate_sun: bool = true
## Sunrise and sunset hours: the sun is on the horizon here; between them it arcs overhead,
## and the moon (the same light, dimmed by the night preset) arcs through the night.
@export var sunrise_hour: float = 6.0
@export var sunset_hour: float = 20.0
@export_range(0.0, 90.0) var sun_max_elevation_degrees: float = 60.0
@export_range(0.0, 90.0) var moon_max_elevation_degrees: float = 45.0
## Lowest elevation, so shadows never become endless streaks.
@export_range(0.0, 45.0) var min_elevation_degrees: float = 8.0
## Compass yaw (radians) where the sun rises; it sets half a turn later.
@export var sunrise_yaw: float = 2.2

var hour: float = 0.0
## Own clock only: multiplies the clock speed (Free Roam holds F for a timelapse).
var time_scale: float = 1.0

var _day_night: DayNight
var _since_update: float = 0.0
## Hour last applied. The look is only recomputed when the hour has moved (a paused clock costs nothing).
var _applied_hour: float = -1.0


func _ready() -> void:
	add_to_group(&"day_night_cycle")
	hour = start_hour
	_day_night = get_tree().get_first_node_in_group(&"day_night") as DayNight
	if _day_night == null:
		_day_night = get_parent().get_node_or_null("DayNight") as DayNight
	refresh.call_deferred()


func _process(delta: float) -> void:
	if not use_shift_clock:
		hour = fposmod(hour + delta * time_scale / maxf(seconds_per_hour, 0.01), 24.0)
	_since_update += delta
	if _since_update >= update_interval:
		_since_update = 0.0
		var current_hour: float = fposmod(ShiftManager.get_exact_minute() / 60.0, 24.0) if use_shift_clock else hour
		if not is_equal_approx(current_hour, _applied_hour):
			refresh()


## Apply the look for the current time now.
func refresh() -> void:
	_since_update = 0.0
	if use_shift_clock:
		hour = fposmod(ShiftManager.get_exact_minute() / 60.0, 24.0)
	_applied_hour = hour
	_apply_presets()
	if animate_sun:
		_apply_sun()


## Own clock only: jump ahead (e.g. Free Roam's skip key).
func skip_hours(hours: float) -> void:
	hour = fposmod(hour + hours, 24.0)
	refresh()


func get_time_text() -> String:
	return ShiftManager.format_minute(int(hour * 60.0))


func _apply_presets() -> void:
	var n: int = mini(keyframe_hours.size(), keyframe_presets.size())
	if _day_night == null or n == 0:
		return
	if n == 1:
		_day_night.apply(keyframe_presets[0])
		return
	# Segment [i, i+1] containing the hour; the last one wraps to the first (+24 h).
	var i: int = n - 1
	for k: int in n:
		if hour < keyframe_hours[k]:
			i = k - 1
			break
	if i < 0:
		i = n - 1
	var j: int = (i + 1) % n
	var h0: float = keyframe_hours[i]
	var h1: float = keyframe_hours[j]
	var h: float = hour
	if h1 <= h0:
		h1 += 24.0
	if h < h0:
		h += 24.0
	var t: float = smoothstep(0.0, 1.0, (h - h0) / maxf(h1 - h0, 0.001))
	_day_night.blend(keyframe_presets[i], keyframe_presets[j], t)


## One continuous turn per day: the sun crosses the sky between sunrise and sunset, then the
## moon (same light) continues the turn through the night, so the light never jumps.
func _apply_sun() -> void:
	var day_len: float = fposmod(sunset_hour - sunrise_hour, 24.0)
	var since_rise: float = fposmod(hour - sunrise_hour, 24.0)
	var frac: float
	var max_elev: float
	var yaw: float
	if since_rise <= day_len:
		frac = since_rise / day_len
		max_elev = sun_max_elevation_degrees
		yaw = sunrise_yaw - PI * frac
	else:
		frac = (since_rise - day_len) / (24.0 - day_len)
		max_elev = moon_max_elevation_degrees
		yaw = sunrise_yaw - PI - PI * frac
	var elev: float = lerpf(min_elevation_degrees, max_elev, sin(PI * frac))
	for sun: Node in get_tree().get_nodes_in_group(&"sun"):
		(sun as Node3D).rotation = Vector3(-deg_to_rad(elev), yaw, 0.0)
