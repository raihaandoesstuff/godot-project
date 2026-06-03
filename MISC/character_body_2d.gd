extends CharacterBody2D

# Speed variables

var walk_speed := 100
var run_speed := 230
var gravity := 900
var jump_force := -500
var jump_cut_off_speed := -200  # Speed when jump transition to falling starts
var max_fall_speed := 400  # Max speed for falling

# State variables
var is_running := false
var jump_phase := "idle"  # Initial jump phase
var is_attacking := false  # To prevent animation conflict during an attack

# Animation player or animated sprite node
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var actionable_finder: Area2D = $Marker2D/actionable_finder
@onready var landingsound = $landingsound


func attack():
	if is_attacking:  # Prevent starting a new attack if already attacking
		return
	
	is_attacking = true
	sprite_2d.animation = "attack"  # Replace with the name of your attack animation
	$attack_sound.play()  # Optional: Play attack sound if applicable

	# Correctly connect the "animation_finished" signal to the handler
	sprite_2d.connect("animation_finished", Callable(self, "_on_attack_finished"))
func _on_attack_finished():
	if sprite_2d.animation == "attack":  # Ensure it's the attack animation
		is_attacking = false  # Reset attacking state
		# Disconnect the signal using the callable reference
		sprite_2d.disconnect("animation_finished", Callable(self, "_on_attack_finished"))

func jump():
	velocity.y = jump_force



func _physics_process(delta):
	
	# Apply gravity
	if !is_on_floor():
		self.velocity.y += gravity * delta
	else:
		self.velocity.y = 0

	# Get input for movement and actions
	var direction := Input.get_action_strength("right") - Input.get_action_strength("left")
	is_running = Input.is_action_pressed("run")
	var jump_pressed := Input.is_action_just_pressed("jump")
	
	# Horizontal movement
	if direction != 0:
		if is_running:
			self.velocity.x = direction * run_speed
			if jump_phase == "idle":  # Play running animation only if on ground
				sprite_2d.animation = "running"
		else:
			self.velocity.x = direction * walk_speed
			if jump_phase == "idle":
				sprite_2d.animation = "walking"
	else:
		self.velocity.x = 0
		if jump_phase == "idle":
			sprite_2d.animation = "idle"

	# Jump handling (broken down into phases)
	if jump_phase == "idle":
		if jump_pressed and is_on_floor():
			$initialjumping.play()
			
			# Begin the jump with a "push" phase
			self.velocity.y = jump_force
			jump_phase = "push"
			sprite_2d.animation = "jump_push"

	elif jump_phase == "push":
		# Push phase transitions to "up" as the character rises
		if self.velocity.y < 0:
			jump_phase = "up"
			sprite_2d.animation = "jump_up"

	elif jump_phase == "up":
		# Transition to falling if moving downward
		if self.velocity.y > jump_cut_off_speed:
			jump_phase = "falling"
			sprite_2d.animation = "fall"

	elif jump_phase == "falling":
		# Apply gravity and clamp fall speed
		self.velocity.y = min(self.velocity.y + gravity * delta, max_fall_speed)

	if jump_phase == "idle" and !is_on_floor() and self.velocity.y > 0:
		jump_phase = "falling"
		sprite_2d.animation = "fall"

	# Movement with collision handling
	move_and_slide()

	# Check if character has landed
	if is_on_floor():
		if jump_phase == "falling":
			jump_phase = "land"
			sprite_2d.animation = "land"
			landingsound.play()
		elif jump_phase == "land" or self.velocity.x == 0:
			jump_phase = "idle"
			sprite_2d.animation = "idle"
		else:
			if $Timer.time_left <= 0:
				$walkingsound.pitch_scale = randf_range(0.8,1.2)
				$walkingsound.play()
				$Timer.start(0.2)
				
				
				
	
	var isLeft = velocity.x < 0
	sprite_2d.flip_h = isLeft
	
func _process(_delta):
	# Check for interaction input
	if Input.is_action_just_pressed("interact"):
		var actionables = actionable_finder.get_overlapping_areas()
		if actionables.size() > 0:
			actionables[0].action()
			return
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
