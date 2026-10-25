extends CharacterBody2D

const SPEED = 360.0
const DASH_SPEED = 670.0
const DASH_TIME = 0.18
const DASH_COOLDOWN = 1.5
const SHIELD_DURATION = 10.0
const SHIELD_COOLDOWN = 12.0
const DEFAULT_ARENA_SIZE = Vector2(1280.0, 720.0)

var alive = true
var player_name := "Player"
var player_id := 1
var player_color := Color(0, 0.8, 1, 1)
var last_movement_direction := Vector2.RIGHT
var dash_timer := 0.0
var dash_cooldown := 0.0
var shield_timer := 0.0
var shield_cooldown := 0.0
var shield_active := false
var arena_size := DEFAULT_ARENA_SIZE

func _ready():
	add_to_group("players")
	if has_node("ColorRect"):
		$ColorRect.color = player_color
	queue_redraw()

func _physics_process(delta):
	if not alive:
		return

	if dash_timer > 0.0:
		dash_timer = max(0.0, dash_timer - delta)
	if dash_cooldown > 0.0:
		dash_cooldown = max(0.0, dash_cooldown - delta)

	if shield_active:
		shield_timer = max(0.0, shield_timer - delta)
		if shield_timer <= 0.0:
			shield_active = false
			shield_timer = 0.0
			shield_cooldown = SHIELD_COOLDOWN
	elif shield_cooldown > 0.0:
		shield_cooldown = max(0.0, shield_cooldown - delta)

	var move = Vector2.ZERO
	if player_id == 1:
		if Input.is_key_pressed(KEY_W):
			move.y -= 1.0
		if Input.is_key_pressed(KEY_S):
			move.y += 1.0
		if Input.is_key_pressed(KEY_A):
			move.x -= 1.0
		if Input.is_key_pressed(KEY_D):
			move.x += 1.0
		if Input.is_key_pressed(KEY_SHIFT):
			activate_ability()
	else:
		if Input.is_key_pressed(KEY_UP):
			move.y -= 1.0
		if Input.is_key_pressed(KEY_DOWN):
			move.y += 1.0
		if Input.is_key_pressed(KEY_LEFT):
			move.x -= 1.0
		if Input.is_key_pressed(KEY_RIGHT):
			move.x += 1.0
		if Input.is_key_pressed(KEY_CTRL):
			activate_ability()

	if move.length() > 0.0:
		move = move.normalized()
		last_movement_direction = move

	var current_speed = SPEED
	var direction = move
	if dash_timer > 0.0:
		current_speed = DASH_SPEED
		if direction.length() <= 0.0:
			direction = last_movement_direction
	else:
		direction = move

	velocity = direction * current_speed
	move_and_slide()
	keep_in_arena()
	queue_redraw()

func _draw():
	if not alive:
		return

	if shield_active:
		draw_circle(Vector2.ZERO, 35.0, Color(0.26, 0.62, 1.0, 0.08))
		draw_arc(Vector2.ZERO, 35.0, 0.0, TAU, 40, Color(0.26, 0.62, 1.0, 0.9), 3.0)

	if dash_timer > 0.0:
		draw_arc(Vector2.ZERO, 32.0, 0.0, TAU, 22, Color(1.0, 0.32, 0.32, 0.75), 3.0)

func set_player_name(name_text: String):
	player_name = name_text

func get_player_name() -> String:
	return player_name

func set_player_id(id: int):
	player_id = id

func set_player_color(color: Color):
	player_color = color
	if has_node("ColorRect"):
		$ColorRect.color = player_color
	queue_redraw()

func set_arena_bounds(size: Vector2):
	arena_size = size

func get_ability_type() -> String:
	if is_color_close(player_color, Color(1.0, 0.32, 0.32)):
		return "dash"
	if is_color_close(player_color, Color(0.26, 0.62, 1.0)):
		return "shield"
	return "none"

func is_color_close(color_a: Color, color_b: Color) -> bool:
	var delta = Vector3(
		color_a.r - color_b.r,
		color_a.g - color_b.g,
		color_a.b - color_b.b
	)
	return delta.length() < 0.15

func activate_ability():
	var ability = get_ability_type()
	if ability == "dash":
		if dash_cooldown > 0.0 or dash_timer > 0.0:
			return
		dash_timer = DASH_TIME
		dash_cooldown = DASH_COOLDOWN
		if last_movement_direction.length() == 0.0:
			last_movement_direction = Vector2.RIGHT
		return

	if ability == "shield":
		if shield_active or shield_cooldown > 0.0:
			return
		shield_active = true
		shield_timer = SHIELD_DURATION
		shield_cooldown = SHIELD_COOLDOWN
		return

func is_dash_ready() -> bool:
	return get_ability_type() == "dash" and dash_cooldown <= 0.0 and dash_timer <= 0.0

func is_shield_active() -> bool:
	return get_ability_type() == "shield" and shield_active

func is_shield_ready() -> bool:
	return get_ability_type() == "shield" and not shield_active and shield_cooldown <= 0.0

func get_dash_cooldown() -> float:
	return dash_cooldown

func get_shield_time_remaining() -> float:
	return shield_timer

func get_shield_cooldown() -> float:
	return shield_cooldown

func is_protected_from_explosions() -> bool:
	return is_shield_active()

func keep_in_arena():
	var min_bounds = Vector2(26.0, 26.0)
	var max_bounds = arena_size - Vector2(26.0, 26.0)
	global_position = global_position.clamp(min_bounds, max_bounds)

func die():
	alive = false
	visible = false
	shield_active = false
	shield_timer = 0.0
	set_physics_process(false)
	queue_redraw()
