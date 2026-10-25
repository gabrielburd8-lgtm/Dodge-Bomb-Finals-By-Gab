extends Node2D

const PLAYER_SCENE = preload("res://scenes/Player.tscn")
const BOMB_SCENE = preload("res://scenes/Bomb.tscn")

const ARENA_WIDTH = 1280
const ARENA_HEIGHT = 720
const MAX_ACTIVE_BOMBS = 20
const STARTING_BOMBS = 8
const BOMB_SPAWN_INTERVAL = 0.6
const PICKUP_SPAWN_DELAY = 4.0

const COLOR_OPTIONS = [
	{"name": "Red", "color": Color(1.0, 0.32, 0.32)},
	{"name": "Orange", "color": Color(1.0, 0.62, 0.2)},
	{"name": "Yellow", "color": Color(1.0, 0.88, 0.25)},
	{"name": "Green", "color": Color(0.28, 0.88, 0.42)},
	{"name": "Blue", "color": Color(0.26, 0.62, 1.0)},
	{"name": "Indigo", "color": Color(0.38, 0.42, 0.93)},
	{"name": "Violet", "color": Color(0.76, 0.52, 1.0)},
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
var ability_pickups: Array = []
var bomb_timer: Timer
var pickup_timer: Timer
var timer_label: Label
var info_label: Label
var results_label: Label
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
	ability_pickups.clear()

func clear_ui():
	for child in ui_root.get_children():
		child.queue_free()

func make_menu_button(text_value: String, size: Vector2 = Vector2(260, 56), text_size: int = 22) -> Button:
	var btn = Button.new()
	btn.text = text_value
	btn.custom_minimum_size = size
	btn.add_theme_font_size_override("font_size", text_size)
	
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.15, 0.18, 0.25, 0.95)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.85, 0.9, 1.0, 0.9)
	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal", normal)
	
	var hover = normal.duplicate()
	hover.bg_color = Color(0.23, 0.31, 0.43, 1.0)
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed = normal.duplicate()
	pressed.bg_color = Color(0.3, 0.43, 0.66, 1.0)
	btn.add_theme_stylebox_override("pressed", pressed)
	
	return btn

func show_main_menu():
	match_started = false
	round_active = false
	clear_ui()
	clear_world()
	
	var menu_panel = PanelContainer.new()
	menu_panel.custom_minimum_size = Vector2(900, 500)
	menu_panel.position = Vector2(190, 110)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.15, 0.22, 0.96)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.72, 0.8, 0.96, 1.0)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	menu_panel.add_theme_stylebox_override("panel", style)
	ui_root.add_child(menu_panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "BOMB DODGE"
	title.add_theme_font_size_override("font_size", 54)
	title.modulate = Color(1, 1, 1, 1)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Choose a mode"
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.modulate = Color(0.8, 0.85, 1.0, 1.0)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)
	
	var buttons = VBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.custom_minimum_size = Vector2(280, 0)
	vbox.add_child(buttons)
	
	var solo_button = make_menu_button("Solo", Vector2(260, 58), 24)
	solo_button.pressed.connect(func(): show_color_selection(GameMode.SOLO))
	buttons.add_child(solo_button)
	
	var mp_button = make_menu_button("Local Multiplayer", Vector2(260, 58), 24)
	mp_button.pressed.connect(func(): show_color_selection(GameMode.LOCAL_MULTIPLAYER))
	buttons.add_child(mp_button)
	
	var quit_button = make_menu_button("Quit", Vector2(260, 58), 24)
	quit_button.pressed.connect(func(): get_tree().quit())
	buttons.add_child(quit_button)

func show_color_selection(mode: int):
	game_mode = mode
	clear_ui()
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 500)
	panel.position = Vector2(190, 110)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.15, 0.22, 0.96)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.72, 0.81, 0.96, 1.0)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	ui_root.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "Choose your colors"
	title.add_theme_font_size_override("font_size", 36)
	title.modulate = Color(1, 1, 1, 1)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	if game_mode == GameMode.SOLO:
		var preview = ColorRect.new()
		preview.custom_minimum_size = Vector2(120, 120)
		preview.color = COLOR_OPTIONS[solo_color_index]["color"]
		vbox.add_child(preview)
		
		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(row)
		for i in range(COLOR_OPTIONS.size()):
			var btn = make_menu_button(COLOR_OPTIONS[i]["name"], Vector2(100, 40), 16)
			btn.modulate = COLOR_OPTIONS[i]["color"]
			var pick_index = i
			btn.pressed.connect(func():
				solo_color_index = pick_index
				preview.color = COLOR_OPTIONS[pick_index]["color"]
			)
			row.add_child(btn)
		
		var start_button = make_menu_button("Start Match", Vector2(220, 56), 22)
		start_button.pressed.connect(func(): start_match())
		vbox.add_child(start_button)
	else:
		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(row)
		
		var p1_box = VBoxContainer.new(); p1_box.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_child(p1_box)
		var p1_label = Label.new(); p1_label.text = "PLAYER 1"; p1_label.add_theme_font_size_override("font_size", 22); p1_box.add_child(p1_label)
		var p1_preview = ColorRect.new(); p1_preview.custom_minimum_size = Vector2(110, 110); p1_preview.color = COLOR_OPTIONS[p1_color_index]["color"]; p1_box.add_child(p1_preview)
		var p1_row = HBoxContainer.new(); p1_row.alignment = BoxContainer.ALIGNMENT_CENTER; p1_box.add_child(p1_row)
		for i in range(COLOR_OPTIONS.size()):
			var btn = make_menu_button(COLOR_OPTIONS[i]["name"], Vector2(90, 38), 15)
			btn.modulate = COLOR_OPTIONS[i]["color"]
			btn.set_meta("color_index", i)
			var pick_index = i
			btn.pressed.connect(func():
				p1_color_index = pick_index
				p1_preview.color = COLOR_OPTIONS[p1_color_index]["color"]
				refresh_mp_color_buttons(p1_row, p2_row, p1_preview, p2_preview)
			)
			p1_row.add_child(btn)
		
		var p2_box = VBoxContainer.new(); p2_box.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_child(p2_box)
		var p2_label = Label.new(); p2_label.text = "PLAYER 2"; p2_label.add_theme_font_size_override("font_size", 22); p2_box.add_child(p2_label)
		var p2_preview = ColorRect.new(); p2_preview.custom_minimum_size = Vector2(110, 110); p2_preview.color = COLOR_OPTIONS[p2_color_index]["color"]; p2_box.add_child(p2_preview)
		var p2_row = HBoxContainer.new(); p2_row.alignment = BoxContainer.ALIGNMENT_CENTER; p2_box.add_child(p2_row)
		for i in range(COLOR_OPTIONS.size()):
			var btn = make_menu_button(COLOR_OPTIONS[i]["name"], Vector2(90, 38), 15)
			btn.modulate = COLOR_OPTIONS[i]["color"]
			btn.set_meta("color_index", i)
			var pick_index = i
			btn.pressed.connect(func():
				p2_color_index = pick_index
				p2_preview.color = COLOR_OPTIONS[p2_color_index]["color"]
				refresh_mp_color_buttons(p1_row, p2_row, p1_preview, p2_preview)
			)
			p2_row.add_child(btn)
		
		var start_button = make_menu_button("Start Match", Vector2(220, 56), 22)
		start_button.disabled = p1_color_index == p2_color_index
		start_button.pressed.connect(func():
			if p1_color_index != p2_color_index:
				start_match()
			)
		vbox.add_child(start_button)
		refresh_mp_color_buttons(p1_row, p2_row, p1_preview, p2_preview)
		
	var back_button = make_menu_button("Back to Menu", Vector2(220, 56), 22)
	back_button.pressed.connect(func(): show_main_menu())
	vbox.add_child(back_button)

func refresh_mp_color_buttons(p1_row: HBoxContainer, p2_row: HBoxContainer, p1_preview: ColorRect, p2_preview: ColorRect):
	p1_preview.color = COLOR_OPTIONS[p1_color_index]["color"]
	p2_preview.color = COLOR_OPTIONS[p2_color_index]["color"]
	for child in p1_row.get_children():
		var idx = child.get_meta("color_index")
		child.disabled = idx == p2_color_index
	for child in p2_row.get_children():
		var idx = child.get_meta("color_index")
		child.disabled = idx == p1_color_index

func create_arena():
	var bg = ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(ARENA_WIDTH, ARENA_HEIGHT)
	bg.color = Color(0.02, 0.08, 0.18, 1.0)
	world_root.add_child(bg)
	
	var border_color = Color(0.4, 0.58, 0.8, 1.0)
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

func create_match_ui():
	if timer_label != null:
		timer_label.queue_free()
	if info_label != null:
		info_label.queue_free()
	if results_label != null:
		results_label.queue_free()
	
	timer_label = Label.new()
	timer_label.text = "Time: 0.0s"
	timer_label.position = Vector2(420, 18)
	timer_label.add_theme_font_size_override("font_size", 30)
	timer_label.modulate = Color(1, 1, 1, 1)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.custom_minimum_size = Vector2(440, 40)
	ui_root.add_child(timer_label)
	
	info_label = Label.new()
	info_label.text = ""
	info_label.position = Vector2(380, 655)
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.modulate = Color(0.82, 0.88, 1.0, 1.0)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.custom_minimum_size = Vector2(520, 30)
	ui_root.add_child(info_label)
	
	results_label = Label.new()
	results_label.text = ""
	results_label.position = Vector2(220, 150)
	results_label.custom_minimum_size = Vector2(840, 400)
	results_label.add_theme_font_size_override("font_size", 30)
	results_label.modulate = Color(1, 1, 1, 1)
	results_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	results_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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
	start_pickup_timer()
	
	if game_mode == GameMode.SOLO:
		info_label.text = "WASD to move - survive as long as you can"
	else:
		info_label.text = "Player 1: WASD | Player 2: Arrow Keys"
	
	for i in range(STARTING_BOMBS):
		_spawn_bomb()

func spawn_players():
	players.clear()
	if game_mode == GameMode.SOLO:
		var player = PLAYER_SCENE.instantiate()
		player.name = "Player1"
		player.position = Vector2(200, ARENA_HEIGHT / 2)
		player.set_player_name("Player")
		player.set_player_id(1)
		player.set_player_color(COLOR_OPTIONS[solo_color_index]["color"])
		player.set_arena_bounds(Vector2(ARENA_WIDTH, ARENA_HEIGHT))
		world_root.add_child(player)
		players.append(player)
		return
	
	var player1 = PLAYER_SCENE.instantiate()
	player1.name = "Player1"
	player1.position = Vector2(200, ARENA_HEIGHT / 2)
	player1.set_player_name("Player 1")
	player1.set_player_id(1)
	player1.set_player_color(COLOR_OPTIONS[p1_color_index]["color"])
	player1.set_arena_bounds(Vector2(ARENA_WIDTH, ARENA_HEIGHT))
	world_root.add_child(player1)
	players.append(player1)
	
	var player2 = PLAYER_SCENE.instantiate()
	player2.name = "Player2"
	player2.position = Vector2(1080, ARENA_HEIGHT / 2)
	player2.set_player_name("Player 2")
	player2.set_player_id(2)
	player2.set_player_color(COLOR_OPTIONS[p2_color_index]["color"])
	player2.set_arena_bounds(Vector2(ARENA_WIDTH, ARENA_HEIGHT))
	world_root.add_child(player2)
	players.append(player2)

func start_bomb_spawner():
	if bomb_timer != null:
		bomb_timer.stop()
		bomb_timer.queue_free()
	
	bomb_timer = Timer.new()
	bomb_timer.wait_time = BOMB_SPAWN_INTERVAL
	bomb_timer.autostart = true
	bomb_timer.one_shot = false
	bomb_timer.timeout.connect(_spawn_bomb)
	world_root.add_child(bomb_timer)

func start_pickup_timer():
	if pickup_timer != null:
		pickup_timer.stop()
		pickup_timer.queue_free()
	
	pickup_timer = Timer.new()
	pickup_timer.wait_time = PICKUP_SPAWN_DELAY
	pickup_timer.autostart = true
	pickup_timer.one_shot = false
	pickup_timer.timeout.connect(_try_spawn_pickup)
	world_root.add_child(pickup_timer)

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
		if bombs.has(bomb):
			bombs.erase(bomb)
	)

func _try_spawn_pickup():
	if not round_active:
		return
	if ability_pickups.size() >= 2:
		return
	
	var pickup_type = get_random_compatible_pickup_type()
	if pickup_type == null:
		return
	
	var safe_pos = find_valid_pickup_position()
	if safe_pos == null:
		return
	
	var pickup = Area2D.new()
	pickup.name = "Pickup"
	pickup.position = safe_pos
	pickup.monitoring = true
	pickup.monitorable = true
	var circle = CircleShape2D.new()
	circle.radius = 28
	var shape = CollisionShape2D.new()
	shape.shape = circle
	pickup.add_child(shape)
	
	var bg = ColorRect.new()
	bg.position = Vector2(-28, -28)
	bg.size = Vector2(56, 56)
	bg.color = pickup_type == "dash" ? Color(1.0, 0.32, 0.32) : Color(0.26, 0.62, 1.0)
	pickup.add_child(bg)
	
	var label = Label.new()
	label.text = pickup_type.to_upper()
	label.position = Vector2(-18, -10)
	label.add_theme_font_size_override("font_size", 13)
	label.modulate = Color(1, 1, 1, 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pickup.add_child(label)
	
	pickup.body_entered.connect(func(body):
		if body == null:
			return
		if body.has_method("collect_pickup") and body.can_collect_pickup(pickup_type):
			body.collect_pickup(pickup_type)
			if ability_pickups.has(pickup):
				ability_pickups.erase(pickup)
			pickup.queue_free()
	)
	
	world_root.add_child(pickup)
	ability_pickups.append(pickup)

func get_random_compatible_pickup_type():
	var options: Array = []
	if game_mode == GameMode.SOLO:
		if COLOR_OPTIONS[solo_color_index]["name"] == "Red":
			options.append("dash")
		elif COLOR_OPTIONS[solo_color_index]["name"] == "Blue":
			options.append("shield")
		return options.pick_random() if options.size() > 0 else null
	
	if COLOR_OPTIONS[p1_color_index]["name"] == "Red" or COLOR_OPTIONS[p2_color_index]["name"] == "Red":
		options.append("dash")
	if COLOR_OPTIONS[p1_color_index]["name"] == "Blue" or COLOR_OPTIONS[p2_color_index]["name"] == "Blue":
		options.append("shield")
	return options.pick_random() if options.size() > 0 else null

func find_valid_bomb_position() -> Vector2:
	for i in range(120):
		var x = randf_range(90, ARENA_WIDTH - 90)
		var y = randf_range(90, ARENA_HEIGHT - 90)
		var pos = Vector2(x, y)
		var valid = true
		for player in players:
			if player != null and player.is_inside_tree():
				if player.global_position.distance_to(pos) < 150:
					valid = false
					break
		if valid:
			for bomb in bombs:
				if bomb != null and bomb.is_inside_tree():
					if bomb.global_position.distance_to(pos) < 110:
						valid = false
						break
		if valid:
			for pickup in ability_pickups:
				if pickup != null and pickup.is_inside_tree():
					if pickup.global_position.distance_to(pos) < 80:
						valid = false
						break
		if valid:
			return pos
	return Vector2.ZERO

func find_valid_pickup_position() -> Vector2:
	for i in range(120):
		var x = randf_range(100, ARENA_WIDTH - 100)
		var y = randf_range(100, ARENA_HEIGHT - 100)
		var pos = Vector2(x, y)
		var valid = true
		for player in players:
			if player != null and player.is_inside_tree():
				if player.global_position.distance_to(pos) < 90:
					valid = false
					break
		if valid:
			for bomb in bombs:
				if bomb != null and bomb.is_inside_tree():
					if bomb.global_position.distance_to(pos) < 90:
						valid = false
						break
		if valid:
			for pickup in ability_pickups:
				if pickup != null and pickup.is_inside_tree():
					if pickup.global_position.distance_to(pos) < 90:
						valid = false
						break
		if valid:
			return pos
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
		if pickup_timer != null:
			pickup_timer.stop()
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
	results_label.modulate = Color(1, 1, 1, 1)
