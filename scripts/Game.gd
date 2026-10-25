extends Node2D

const PLAYER_SCENE = preload("res://scenes/Player.tscn")
const BOMB_SCENE = preload("res://scenes/Bomb.tscn")

const ARENA_WIDTH = 1280
const ARENA_HEIGHT = 720
const MAX_ACTIVE_BOMBS = 6

const COLOR_OPTIONS = [
	{"name": "Red", "color": Color(1.0, 0.28, 0.28)},
	{"name": "Orange", "color": Color(1.0, 0.6, 0.2)},
	{"name": "Yellow", "color": Color(1.0, 0.9, 0.2)},
	{"name": "Green", "color": Color(0.25, 0.9, 0.38)},
	{"name": "Blue", "color": Color(0.2, 0.62, 1.0)},
	{"name": "Indigo", "color": Color(0.35, 0.35, 0.9)},
	{"name": "Violet", "color": Color(0.74, 0.5, 1.0)},
]

enum GameMode {
	SOLO,
	LOCAL_MULTIPLAYER,
}

var world_root: Node2D
var ui_root: CanvasLayer
var game_mode := GameMode.SOLO
var match_started := false
var round_active := false
var elapsed_time := 0.0
var players: Array = []
var bombs: Array = []
var bomb_timer: Timer
var timer_label: Label
var info_label: Label
var results_label: Label
var arena_bg: ColorRect
var solo_color_index := 0
var p1_color_index := 0
var p2_color_index := 1

func _ready():
	randomize()
	world_root = Node2D.new()
	world_root.name = "World"
	add_child(world_root)
	
	ui_root = CanvasLayer.new()
	ui_root.name = "UI"
	add_child(ui_root)
	
	show_main_menu()

func _process(_delta):
	if round_active:
		elapsed_time += _delta
		update_timer_label()
		check_for_game_over()
	
	if not round_active and match_started:
		if Input.is_key_pressed(KEY_R):
			start_match()
		if Input.is_key_pressed(KEY_M):
			show_main_menu()
	
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

func clear_world():
	for child in world_root.get_children():
		child.queue_free()
	players.clear()
	bombs.clear()

func clear_ui():
	for child in ui_root.get_children():
		child.queue_free()

func show_main_menu():
	match_started = false
	round_active = false
	clear_ui()
	clear_world()
	
	var title_label = Label.new()
	title_label.text = "BOMB DODGE"
	title_label.position = Vector2(520, 80)
	title_label.add_theme_font_size_override("font_size", 54)
	title_label.modulate = Color(1, 1, 1, 1)
	ui_root.add_child(title_label)
	
	var subtitle = Label.new()
	subtitle.text = "Choose a mode"
	subtitle.position = Vector2(550, 150)
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.modulate = Color(0.8, 0.85, 1.0, 1.0)
	ui_root.add_child(subtitle)
	
	var button_container = VBoxContainer.new()
	button_container.position = Vector2(500, 220)
	button_container.custom_minimum_size = Vector2(280, 0)
	ui_root.add_child(button_container)
	
	var solo_button = Button.new()
	solo_button.text = "Solo"
	solo_button.custom_minimum_size = Vector2(280, 60)
	solo_button.pressed.connect(func(): show_color_selection(GameMode.SOLO))
	button_container.add_child(solo_button)
	
	var multiplayer_button = Button.new()
	multiplayer_button.text = "Local Multiplayer"
	multiplayer_button.custom_minimum_size = Vector2(280, 60)
	multiplayer_button.pressed.connect(func(): show_color_selection(GameMode.LOCAL_MULTIPLAYER))
	button_container.add_child(multiplayer_button)
	
	var quit_button = Button.new()
	quit_button.text = "Quit"
	quit_button.custom_minimum_size = Vector2(280, 60)
	quit_button.pressed.connect(func(): get_tree().quit())
	button_container.add_child(quit_button)

func show_color_selection(mode: int):
	game_mode = mode
	clear_ui()
	
	var root = VBoxContainer.new()
	root.position = Vector2(200, 60)
	root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ui_root.add_child(root)
	
	var title = Label.new()
	title.text = "Choose your colors"
	title.add_theme_font_size_override("font_size", 34)
	root.add_child(title)
	
	if game_mode == GameMode.SOLO:
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(820, 180)
		root.add_child(panel)
		var solo_box = VBoxContainer.new()
		panel.add_child(solo_box)
		
		var solo_label = Label.new()
		solo_label.text = "Player"
		solo_label.add_theme_font_size_override("font_size", 20)
		solo_box.add_child(solo_label)
		
		var preview = ColorRect.new()
		preview.custom_minimum_size = Vector2(120, 120)
		preview.color = COLOR_OPTIONS[solo_color_index]["color"]
		solo_box.add_child(preview)
		
		var color_grid = HBoxContainer.new()
		color_grid.alignment = BoxContainer.ALIGNMENT_CENTER
		solo_box.add_child(color_grid)
		for i in range(COLOR_OPTIONS.size()):
			var button = Button.new()
			button.text = COLOR_OPTIONS[i]["name"]
			button.custom_minimum_size = Vector2(100, 42)
			button.modulate = COLOR_OPTIONS[i]["color"]
			button.pressed.connect(func():
				solo_color_index = i
				preview.color = COLOR_OPTIONS[i]["color"]
			)
			color_grid.add_child(button)
		
		var start_button = Button.new()
		start_button.text = "Start Match"
		start_button.custom_minimum_size = Vector2(220, 56)
		start_button.pressed.connect(func(): start_match())
		root.add_child(start_button)
	else:
		var top_row = HBoxContainer.new()
		top_row.alignment = BoxContainer.ALIGNMENT_CENTER
		root.add_child(top_row)
		
		var p1_box = VBoxContainer.new()
		p1_box.custom_minimum_size = Vector2(300, 200)
		top_row.add_child(p1_box)
		var p1_label = Label.new(); p1_label.text = "Player 1"; p1_label.add_theme_font_size_override("font_size", 20); p1_box.add_child(p1_label)
		var p1_preview = ColorRect.new(); p1_preview.custom_minimum_size = Vector2(120, 120); p1_preview.color = COLOR_OPTIONS[p1_color_index]["color"]; p1_box.add_child(p1_preview)
		var p1_colors = HBoxContainer.new(); p1_box.add_child(p1_colors)
		var p2_box = VBoxContainer.new(); p2_box.custom_minimum_size = Vector2(300, 200); top_row.add_child(p2_box)
		var p2_label = Label.new(); p2_label.text = "Player 2"; p2_label.add_theme_font_size_override("font_size", 20); p2_box.add_child(p2_label)
		var p2_preview = ColorRect.new(); p2_preview.custom_minimum_size = Vector2(120, 120); p2_preview.color = COLOR_OPTIONS[p2_color_index]["color"]; p2_box.add_child(p2_preview)
		var p2_colors = HBoxContainer.new(); p2_box.add_child(p2_colors)
		
		for i in range(COLOR_OPTIONS.size()):
			var button = Button.new(); button.text = COLOR_OPTIONS[i]["name"]; button.custom_minimum_size = Vector2(90, 36); button.modulate = COLOR_OPTIONS[i]["color"]
			button.pressed.connect(func():
				p1_color_index = i
				p1_preview.color = COLOR_OPTIONS[i]["color"]
				if p1_color_index == p2_color_index:
					p2_color_index = get_next_available_color_index(p1_color_index)
					if p2_color_index != -1:
						p2_preview.color = COLOR_OPTIONS[p2_color_index]["color"]
			)
			p1_colors.add_child(button)
		
		for i in range(COLOR_OPTIONS.size()):
			var button = Button.new(); button.text = COLOR_OPTIONS[i]["name"]; button.custom_minimum_size = Vector2(90, 36); button.modulate = COLOR_OPTIONS[i]["color"]
			button.pressed.connect(func():
				var selected_index = i
				if selected_index == p1_color_index:
					var alt_index = get_next_available_color_index(selected_index)
					if alt_index == -1:
						return
					selected_index = alt_index
				p2_color_index = selected_index
				p2_preview.color = COLOR_OPTIONS[selected_index]["color"]
			)
			p2_colors.add_child(button)
		
		var start_button = Button.new(); start_button.text = "Start Match"; start_button.custom_minimum_size = Vector2(220, 56)
		start_button.pressed.connect(func(): start_match())
		root.add_child(start_button)
	
	var back_button = Button.new(); back_button.text = "Back to Menu"; back_button.custom_minimum_size = Vector2(220, 56)
	back_button.pressed.connect(func(): show_main_menu())
	root.add_child(back_button)

func get_next_available_color_index(excluded_index: int) -> int:
	for i in range(COLOR_OPTIONS.size()):
		if i != excluded_index:
			return i
	return -1

func create_arena():
	arena_bg = ColorRect.new()
	arena_bg.position = Vector2.ZERO
	arena_bg.size = Vector2(ARENA_WIDTH, ARENA_HEIGHT)
	arena_bg.color = Color(0.02, 0.08, 0.18, 1.0)
	world_root.add_child(arena_bg)
	
	var border_color = Color(0.4, 0.55, 0.75, 1.0)
	var border_thickness = 4
	var border_nodes = [
		[Vector2(0, 0), Vector2(ARENA_WIDTH, border_thickness)],
		[Vector2(0, ARENA_HEIGHT - border_thickness), Vector2(ARENA_WIDTH, border_thickness)],
		[Vector2(0, 0), Vector2(border_thickness, ARENA_HEIGHT)],
		[Vector2(ARENA_WIDTH - border_thickness, 0), Vector2(border_thickness, ARENA_HEIGHT)],
	]
	for data in border_nodes:
		var border = ColorRect.new()
		border.position = data[0]
		border.size = data[1]
		border.color = border_color
		world_root.add_child(border)
	
	var wall_thickness = 30
	var wall_data = [
		[Vector2(0, ARENA_HEIGHT / 2), Vector2(wall_thickness, ARENA_HEIGHT)],
		[Vector2(ARENA_WIDTH - wall_thickness, ARENA_HEIGHT / 2), Vector2(wall_thickness, ARENA_HEIGHT)],
		[Vector2(ARENA_WIDTH / 2, 0), Vector2(ARENA_WIDTH, wall_thickness)],
		[Vector2(ARENA_WIDTH / 2, ARENA_HEIGHT - wall_thickness), Vector2(ARENA_WIDTH, wall_thickness)],
	]
	for wall in wall_data:
		var static_wall = StaticBody2D.new()
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.extents = wall[1] / 2
		shape.shape = rect
		static_wall.add_child(shape)
		static_wall.position = wall[0]
		world_root.add_child(static_wall)

func create_match_ui():
	if timer_label != null:
		timer_label.queue_free()
	if info_label != null:
		info_label.queue_free()
	if results_label != null:
		results_label.queue_free()
	
	timer_label = Label.new()
	timer_label.text = "Time: 0.0s"
	timer_label.position = Vector2(470, 18)
	timer_label.add_theme_font_size_override("font_size", 32)
	timer_label.modulate = Color(1, 1, 1, 1)
	ui_root.add_child(timer_label)
	
	info_label = Label.new()
	info_label.text = ""
	info_label.position = Vector2(420, 660)
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.modulate = Color(0.8, 0.85, 1.0, 1.0)
	ui_root.add_child(info_label)
	
	results_label = Label.new()
	results_label.text = ""
	results_label.position = Vector2(340, 150)
	results_label.add_theme_font_size_override("font_size", 32)
	results_label.modulate = Color(1, 1, 1, 1)
	results_label.visible = false
	ui_root.add_child(results_label)
	update_timer_label()

func update_timer_label():
	if timer_label != null:
		timer_label.text = "Time: %.1fs" % elapsed_time

func start_match():
	clear_ui()
	clear_world()
	match_started = true
	round_active = true
	elapsed_time = 0.0
	create_arena()
	create_match_ui()
	spawn_players()
	start_bomb_spawner()
	
	if game_mode == GameMode.SOLO:
		info_label.text = "WASD to move - survive as long as you can"
	else:
		info_label.text = "Player 1: WASD | Player 2: Arrow Keys"

func spawn_players():
	players.clear()
	var player_color_1 = COLOR_OPTIONS[p1_color_index]["color"]
	var player_color_2 = COLOR_OPTIONS[p2_color_index]["color"]
	
	if game_mode == GameMode.SOLO:
		var player = PLAYER_SCENE.instantiate()
		player.name = "Player1"
		player.position = Vector2(200, ARENA_HEIGHT / 2)
		player.set_player_name("Player")
		player.set_player_id(1)
		player.set_player_color(COLOR_OPTIONS[solo_color_index]["color"])
		world_root.add_child(player)
		players.append(player)
		return
	
	var player1 = PLAYER_SCENE.instantiate()
	player1.name = "Player1"
	player1.position = Vector2(200, ARENA_HEIGHT / 2)
	player1.set_player_name("Player 1")
	player1.set_player_id(1)
	player1.set_player_color(player_color_1)
	world_root.add_child(player1)
	players.append(player1)
	
	var player2 = PLAYER_SCENE.instantiate()
	player2.name = "Player2"
	player2.position = Vector2(1080, ARENA_HEIGHT / 2)
	player2.set_player_name("Player 2")
	player2.set_player_id(2)
	player2.set_player_color(player_color_2)
	world_root.add_child(player2)
	players.append(player2)

func start_bomb_spawner():
	if bomb_timer != null:
		bomb_timer.stop()
		bomb_timer.queue_free()
	
	bomb_timer = Timer.new()
	bomb_timer.wait_time = 0.5
	bomb_timer.autostart = true
	bomb_timer.one_shot = false
	bomb_timer.timeout.connect(_spawn_bomb)
	world_root.add_child(bomb_timer)

func _spawn_bomb():
	if not round_active:
		return
	if bombs.size() >= MAX_ACTIVE_BOMBS:
		return
	
	var safe_pos = find_valid_bomb_position()
	if safe_pos == null:
		return
	
	var bomb = BOMB_SCENE.instantiate()
	bomb.name = "Bomb"
	bomb.position = safe_pos
	world_root.add_child(bomb)
	bombs.append(bomb)
	
	bomb.tree_exiting.connect(func():
		bombs.erase(bomb)
	)

func find_valid_bomb_position() -> Vector2:
	var attempts = 0
	while attempts < 60:
		var x = randf_range(80, ARENA_WIDTH - 80)
		var y = randf_range(80, ARENA_HEIGHT - 80)
		var pos = Vector2(x, y)
		var location_ok = true
		for player in players:
			if player != null and player.is_inside_tree():
				if player.global_position.distance_to(pos) < 120:
					location_ok = false
					break
		if location_ok:
			return pos
		attempts += 1
	return Vector2.ZERO

func check_for_game_over():
	var alive_players = []
	for player in get_tree().get_nodes_in_group("players"):
		if player.alive:
			alive_players.append(player)
	
	if alive_players.size() <= 1:
		round_active = false
		if bomb_timer != null:
			bomb_timer.stop()
		show_results(alive_players)

func show_results(alive_players: Array):
	var result_text = ""
	if game_mode == GameMode.SOLO:
		if alive_players.size() == 1:
			result_text = "YOU SURVIVED\n%.1fs\n\nPress R to retry\nM for menu" % elapsed_time
		else:
			result_text = "YOU WERE HIT!\nFinal Time: %.1fs\n\nPress R to retry\nM for menu" % elapsed_time
	else:
		if alive_players.size() == 1:
			var winner = alive_players[0]
			if winner.player_id == 1:
				result_text = "PLAYER 1 WINS!\n%.1fs\n\nPress R to retry\nM for menu" % elapsed_time
			else:
				result_text = "PLAYER 2 WINS!\n%.1fs\n\nPress R to retry\nM for menu" % elapsed_time
		else:
			result_text = "DRAW!\nBoth players were eliminated\n\nPress R to retry\nM for menu"
	
	results_label.text = result_text
	results_label.visible = true
	results_label.position = Vector2(280, 200)
	results_label.modulate = Color(1, 1, 1, 1)

func _on_bomb_removed(bomb):
	if bombs.has(bomb):
		bombs.erase(bomb)
