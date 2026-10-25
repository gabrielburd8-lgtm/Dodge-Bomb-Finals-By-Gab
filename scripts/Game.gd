extends Node2D

# Bomb Dodge 1v1
# Player 1 uses WASD
# Player 2 uses Arrow Keys
# Both players have survival time tracking

const PLAYER_SCENE = preload("res://scenes/Player.tscn")
const BOMB_SCENE = preload("res://scenes/Bomb.tscn")

const ARENA_WIDTH = 1280
const ARENA_HEIGHT = 720

var players: Array = []
var round_active := true
var game_over_label: Label
var bomb_timer: Timer

var p1_time_label: Label
var p2_time_label: Label

var p1_survival_time := 0.0
var p2_survival_time := 0.0

func _ready():
	randomize()
	create_arena()
	spawn_players()
	start_bomb_spawner()
	create_ui_labels()

func create_arena():
	# Dark background
	var bg = ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(ARENA_WIDTH, ARENA_HEIGHT)
	bg.color = Color(0.02, 0.03, 0.08, 1.0)
	add_child(bg)

	# Arena border - visible outline
	var border_thickness = 4
	var border_color = Color(0.4, 0.4, 0.5, 1.0)
	
	# Top border
	var top_border = ColorRect.new()
	top_border.position = Vector2(0, 0)
	top_border.size = Vector2(ARENA_WIDTH, border_thickness)
	top_border.color = border_color
	add_child(top_border)
	
	# Bottom border
	var bottom_border = ColorRect.new()
	bottom_border.position = Vector2(0, ARENA_HEIGHT - border_thickness)
	bottom_border.size = Vector2(ARENA_WIDTH, border_thickness)
	bottom_border.color = border_color
	add_child(bottom_border)
	
	# Left border
	var left_border = ColorRect.new()
	left_border.position = Vector2(0, 0)
	left_border.size = Vector2(border_thickness, ARENA_HEIGHT)
	left_border.color = border_color
	add_child(left_border)
	
	# Right border
	var right_border = ColorRect.new()
	right_border.position = Vector2(ARENA_WIDTH - border_thickness, 0)
	right_border.size = Vector2(border_thickness, ARENA_HEIGHT)
	right_border.color = border_color
	add_child(right_border)

	# Collision walls
	var wall_thickness = 30
	var walls = [
		[Vector2(0, ARENA_HEIGHT / 2), Vector2(wall_thickness, ARENA_HEIGHT)],
		[Vector2(ARENA_WIDTH - wall_thickness, ARENA_HEIGHT / 2), Vector2(wall_thickness, ARENA_HEIGHT)],
		[Vector2(ARENA_WIDTH / 2, 0), Vector2(ARENA_WIDTH, wall_thickness)],
		[Vector2(ARENA_WIDTH / 2, ARENA_HEIGHT - wall_thickness), Vector2(ARENA_WIDTH, wall_thickness)]
	]

	for wall_data in walls:
		var wall = StaticBody2D.new()
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.extents = wall_data[1] / 2
		shape.shape = rect
		wall.add_child(shape)
		wall.position = wall_data[0]
		add_child(wall)

func create_ui_labels():
	# Player 1 Time - Top Left (Cyan)
	p1_time_label = Label.new()
	p1_time_label.text = "P1: 0.0s"
	p1_time_label.position = Vector2(20, 20)
	p1_time_label.scale = Vector2(1.8, 1.8)
	p1_time_label.modulate = Color(0, 1, 1, 1)
	p1_time_label.add_theme_font_size_override("font_size", 28)
	add_child(p1_time_label)

	# Player 2 Time - Top Right (Yellow)
	p2_time_label = Label.new()
	p2_time_label.text = "P2: 0.0s"
	p2_time_label.position = Vector2(1000, 20)
	p2_time_label.scale = Vector2(1.8, 1.8)
	p2_time_label.modulate = Color(1, 1, 0, 1)
	p2_time_label.add_theme_font_size_override("font_size", 28)
	add_child(p2_time_label)

	# Game over label - Center
	game_over_label = Label.new()
	game_over_label.text = ""
	game_over_label.position = Vector2(200, 280)
	game_over_label.scale = Vector2(2.5, 2.5)
	game_over_label.modulate = Color(1, 1, 1, 1)
	game_over_label.add_theme_font_size_override("font_size", 40)
	add_child(game_over_label)

func spawn_players():
	# Player 1 (WASD) - Left side - Cyan
	var player1 = PLAYER_SCENE.instantiate()
	player1.name = "Player1"
	player1.position = Vector2(200, 360)
	player1.set_player_name("Player 1")
	player1.set_player_id(1)
	player1.set_player_color(Color(0, 0.9, 1, 1))
	add_child(player1)
	players.append(player1)

	# Player 2 (Arrow Keys) - Right side - Yellow
	var player2 = PLAYER_SCENE.instantiate()
	player2.name = "Player2"
	player2.position = Vector2(1080, 360)
	player2.set_player_name("Player 2")
	player2.set_player_id(2)
	player2.set_player_color(Color(1, 1, 0, 1))
	add_child(player2)
	players.append(player2)

func start_bomb_spawner():
	bomb_timer = Timer.new()
	bomb_timer.wait_time = 0.8
	bomb_timer.autostart = true
	bomb_timer.one_shot = false
	bomb_timer.timeout.connect(_spawn_bomb)
	add_child(bomb_timer)

func _spawn_bomb():
	if not round_active:
		return

	var bomb = BOMB_SCENE.instantiate()
	bomb.name = "Bomb"
	bomb.position = Vector2(
		randf_range(100, ARENA_WIDTH - 100),
		randf_range(100, ARENA_HEIGHT - 100)
	)
	add_child(bomb)

func _process(delta):
	if round_active:
		check_for_game_over()
		for player in players:
			if player.alive:
				if player.player_id == 1:
					p1_survival_time += delta
				else:
					p2_survival_time += delta

		update_ui()

	if Input.is_key_pressed(KEY_R) and not round_active:
		restart_round()
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

func check_for_game_over():
	var alive_players = []
	for player in get_tree().get_nodes_in_group("players"):
		if player.alive:
			alive_players.append(player)

	if alive_players.size() <= 1:
		round_active = false
		bomb_timer.stop()

		if alive_players.size() == 1:
			var winner = alive_players[0]
			if winner.player_id == 1:
				game_over_label.text = "PLAYER 1 WINS!\nSurvived: %.2fs\n\nPress R to retry" % [p1_survival_time]
				game_over_label.modulate = Color(0, 1, 1, 1)
			else:
				game_over_label.text = "PLAYER 2 WINS!\nSurvived: %.2fs\n\nPress R to retry" % [p2_survival_time]
				game_over_label.modulate = Color(1, 1, 0, 1)
		else:
			game_over_label.text = "DRAW!\nBoth eliminated\n\nPress R to retry"
			game_over_label.modulate = Color(1, 0.5, 0.5, 1)

func update_ui():
	p1_time_label.text = "P1: %.1fs" % p1_survival_time
	p2_time_label.text = "P2: %.1fs" % p2_survival_time

func restart_round():
	for child in get_children():
		if child.name.begins_with("Player") or child.name == "Bomb":
			remove_child(child)
			child.queue_free()

	players.clear()
	game_over_label.text = ""
	round_active = true
	p1_survival_time = 0.0
	p2_survival_time = 0.0
	spawn_players()
	bomb_timer.start()
