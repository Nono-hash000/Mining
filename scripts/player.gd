class_name Player
extends CharacterBody2D

signal ore_collected(ore_data: OreData, new_count: int)
signal gold_changed(new_amount: int)
signal pickaxe_upgraded(new_strength: int)

const SPEED = 100.0

var is_mining: bool = false
var hitbox_offset: Vector2
var last_direction: Vector2 = Vector2.RIGHT
var detected_rocks: Array = []

var inventory: Dictionary = {}

var gold: int = 0:
	set(value):
		gold = value
		gold_changed.emit(gold)

var current_pickaxe_tier: int = 1
var pickaxe_strength: int = 1:
	get:
		return current_pickaxe_tier

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_box: Area2D = $HitBox
@onready var hit_box_collision_shape_2d: CollisionShape2D = $HitBox/CollisionShape2D
@onready var mining_timer: Timer = $MiningTimer
@onready var pickaxe_hit_sound: AudioStreamPlayer2D = $PickaxeHitSound

func _ready() -> void:
	hitbox_offset = hit_box.position
	hit_box.monitoring = false 

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
		_update_hitbox_position(direction)
	else:
		velocity = Vector2.ZERO

func process_animation() -> void:
	if is_mining:
		return
	
	if velocity != Vector2.ZERO:
		play_animation("run", last_direction)
	else:
		play_animation("idle", last_direction)

func play_animation(anim_name: String, dir: Vector2) -> void:
	var suffix = "right"
	
	if abs(dir.x) > abs(dir.y):
		suffix = "right" 
		animated_sprite_2d.flip_h = (dir.x < 0)
	else:
		suffix = "down" if dir.y > 0 else "up"
		animated_sprite_2d.flip_h = false
		
	animated_sprite_2d.play(anim_name + "_" + suffix)

func _update_hitbox_position(dir: Vector2) -> void:
	var x = abs(hitbox_offset.x)
	var y = hitbox_offset.y
	
	var primary_dir = Vector2.RIGHT
	if abs(dir.x) > abs(dir.y):
		primary_dir = Vector2.RIGHT if dir.x > 0 else Vector2.LEFT
	else:
		primary_dir = Vector2.DOWN if dir.y > 0 else Vector2.UP
		
	match primary_dir:
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
		hit_box.monitoring = false 
		if detected_rocks.size() > 0:
			var rock_to_hit = get_most_overlapping_rock()
			if is_instance_valid(rock_to_hit):
				rock_to_hit.take_damage(pickaxe_strength)
				pickaxe_hit_sound.play()

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body is Rock:
		detected_rocks.append(body)

func get_most_overlapping_rock() -> Rock:
	var best_rock = detected_rocks[0]
	var best_dist = hit_box.global_position.distance_to(best_rock.global_position)
	
	for i in range(1, detected_rocks.size()):
		var r = detected_rocks[i]
		var d = hit_box.global_position.distance_to(r.global_position)
		if d < best_dist:
			best_dist = d
			best_rock = r
	
	return best_rock

func add_ore(data: OreData) -> bool:
	if data == null:
		return false
	
	var current_count: int = inventory.get(data, 0)
	inventory[data] = current_count + 1
	ore_collected.emit(data, inventory[data])
	return true
