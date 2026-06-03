extends Node
@onready var character_body_2d: CharacterBody2D = $"../../CharacterBody2D"
@onready var label: Label = $"../../pausecanvas/Shards/HBoxContainer/Label"
 

@export var hearts : Array[Node]
var points=0
var lives = 5

func decrease_health():
	lives -= 1
	print(lives)
	for h in 5:
		if (h < lives):
			hearts[h].show()
		else:
			hearts[h].hide()
	if lives == 0:
		get_tree().paused == true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		character_body_2d.queue_free()
		$Gameover.visible = true

func add_point():
	points += 1
