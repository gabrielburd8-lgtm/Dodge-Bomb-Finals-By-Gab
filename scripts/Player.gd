extends CharacterBody2D

# Player script for 1v1 multiplayer
# Player 1: WASD movement
# Player 2: Arrow keys movement
# Both track individual survival and dodge count

const SPEED = 380.0

var alive = true
var player_name := "Player"
var player_id := 1
var player_color := Color(0, 0.8, 1, 1)

func _ready():
	add_to_group("players")
	# Set the ColorRect color
	if has_node("ColorRect"):
		$ColorRect.color = player_color

func _physics_process(_delta):
	if not alive:
		return

	var move = Vector2.ZERO

	if player_id == 1:
		# Player 1: WASD
		if Input.is_key_pressed(KEY_W):
			move.y -= 1
		if Input.is_key_pressed(KEY_S):
			move.y += 1
		if Input.is_key_pressed(KEY_A):
			move.x -= 1
		if Input.is_key_pressed(KEY_D):
			move.x += 1
	else:
		# Player 2: Arrow Keys
		if Input.is_key_pressed(KEY_UP):
			move.y -= 1
		if Input.is_key_pressed(KEY_DOWN):
			move.y += 1
		if Input.is_key_pressed(KEY_LEFT):
			move.x -= 1
		if Input.is_key_pressed(KEY_RIGHT):
			move.x += 1

	if move.length() > 0:
		move = move.normalized()

	velocity = move * SPEED
	move_and_slide()

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

func die():
	alive = false
	visible = false
	set_physics_process(false)
