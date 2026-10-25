extends Area2D

# Bomb behavior:
# - FAST countdown (2 seconds)
# - high pressure gameplay
# - eliminates players in explosion radius

var countdown := 2.0  # VERY FAST
var explosion_radius := 110.0
var exploded := false

@onready var label: Label = $Label

func _ready():
	label.text = str(int(ceil(countdown)))
	label.modulate = Color(1, 1, 1, 1)
	label.add_theme_font_size_override("font_size", 32)

func _process(delta):
	if exploded:
		return

	countdown -= delta
	label.text = str(max(0, ceil(countdown)))

	if countdown <= 0:
		explode()

func _draw():
	if exploded:
		draw_circle(Vector2.ZERO, explosion_radius, Color(1.0, 0.5, 0.2, 0.4))
		return

	draw_circle(Vector2.ZERO, 14.0, Color(1.0, 0.6, 0.1, 1.0))

func explode():
	exploded = true
	label.visible = false
	monitoring = false

	# Eliminate any player standing in the blast radius
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player.alive and player.global_position.distance_to(global_position) <= explosion_radius:
			player.die()

	queue_redraw()

	await get_tree().create_timer(0.15).timeout
	queue_free()
