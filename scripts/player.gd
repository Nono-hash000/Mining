class_name Player
extends CharacterBody2D

const SPEED = 100.0

var is_mining: bool = false
var hitbox_offset: Vector2
var last_direction: Vector2 = Vector2.RIGHT
var detected_rocks: Array = []
var pickaxe_strength: int = 1

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_box: Area2D = $HitBox
@onready var hit_box_collision_shape_2d: CollisionShape2D = $HitBox/CollisionShape2D
@onready var mining_timer: Timer = $MiningTimer
@onready var pickaxe_hit_sound: AudioStreamPlayer2D = $PickaxeHitSound

func _ready() -> void:
	hitbox_offset = hit_box.position

func reset(pos: Vector2) -> void:
	position = pos

func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("use_pickaxe") and mining_timer.is_stopped():
		use_pickaxe()
	
	if is_mining:
		velocity = Vector2.ZERO
		return
	
	process_movement()
	process_animation()
	move_and_slide()

func process_movement() -> void:
	var direction := Input.get_vector("left", "right", "up", "down")
	
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		last_direction = direction
		update_hitbox_position()
	else:
		velocity = Vector2.ZERO

func process_animation() -> void:
	hit_box.monitoring = false
	
	if velocity != Vector2.ZERO:
		play_animation("run", last_direction)
	else:
		play_animation("idle", last_direction)

func play_animation(prefix: String, dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "_up")
	elif dir.y > 0:
		animated_sprite_2d.play(prefix + "_down")

func update_hitbox_position() -> void:
	var x := hitbox_offset.x
	var y := hitbox_offset.y
	
	match last_direction:
		Vector2.LEFT:
			hit_box.position = Vector2(-x, y)
			hit_box_collision_shape_2d.rotation_degrees = 0
		Vector2.RIGHT:
			hit_box.position = Vector2(x, y)
			hit_box_collision_shape_2d.rotation_degrees = 0
		Vector2.UP:
			hit_box.position = Vector2(y, -x)
			hit_box_collision_shape_2d.rotation_degrees = 90
		Vector2.DOWN:
			hit_box.position = Vector2(-y, x)
			hit_box_collision_shape_2d.rotation_degrees = 90


func use_pickaxe() -> void:
	detected_rocks.clear()
	hit_box.monitoring = true
	is_mining = true
	mining_timer.start()
	play_animation("swing_pickaxe", last_direction)

func _on_animated_sprite_2d_animation_finished() -> void:
	if is_mining:
		is_mining = false
		if detected_rocks.size() > 0:
			var rock_to_hit = get_most_overlapping_rock()
			rock_to_hit.take_damage(pickaxe_strength)
			pickaxe_hit_sound.play()

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body is Rock:
		detected_rocks.append(body)

func get_most_overlapping_rock() -> Rock:
	var best_rock = detected_rocks[0]
	var best_dist = hit_box.global_position.distance_to(best_rock.global_position)
	
	for rock in detected_rocks:
		var dist = hit_box.global_position.distance_to(rock.global_position)
		if dist < best_dist:
			best_dist = dist
			best_rock = rock
	
	return best_rock

func add_ore(data: OreData) -> bool:
	print(data)
	return true
