extends StaticBody2D

var health: int

@export var data: RockData

@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	health = data.max_health
	sprite_2d.texture = data.texture
