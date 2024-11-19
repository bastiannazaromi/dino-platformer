extends Node2D

signal game_over

@export var world_speed = 300
@export var collectible_pitch_reset_interval = 2000

@onready var moving_environment = $"/root/World/Environment/Moving"
@onready var collect_sound = $"/root/World/Sounds/CollectSound"
@onready var score_label = $"/root/World/HUD/UI/Score"
@onready var game_over_label = $"/root/World/HUD/UI/GameOver"
@onready var ammo_label = $"/root/World/HUD/UI/Ammo"
@onready var player = $"/root/World/Player"
@onready var ground = $"/root/World/Environment/Static/Ground"

var platform = preload("res://scene/platform.tscn")
var platform_collectible_single = preload("res://scene/platform_collectible_single.tscn")
var platform_collectible_row = preload("res://scene/platform_collectible_row.tscn")
var platform_collectible_rainbow = preload("res://scene/platform_collectible_rainbow.tscn")
var platform_collectible_ammo = preload("res://scene/platform_collectible_ammo.tscn")
var platform_enemy = preload("res://scene/platform_enemy.tscn")

var rng = RandomNumberGenerator.new()
var last_platform_position = Vector2.ZERO
var next_spawn_time = 0
var score = 0
var collectible_pitch = 1.0
var reset_collectible_pitch_time = 0

func _ready():
	rng.randomize()
	player.player_died.connect(_on_player_died)
	ground.body_entered.connect(_on_ground_body_entered)

func _process(delta):
	if not player.active:
		# restart the game
		if Input.is_action_just_pressed("jump"):
			get_tree().reload_current_scene()
		return
	
	if Time.get_ticks_msec() > reset_collectible_pitch_time:
		collectible_pitch = 1.0
	
	if Time.get_ticks_msec() > next_spawn_time:
		_spawn_next_platform()
	
	score_label.text = "Score : %s" % score
	ammo_label.text = "Ammo : %s" % player.ammo              

func _spawn_next_platform():
	var available_platforms = [
		platform,
		platform_collectible_single,
		platform_collectible_row,
		platform_collectible_rainbow,
		platform_enemy,
		platform_collectible_ammo
	]
	
	var platform_index = rng.randi_range(0, available_platforms.size() -1)
	var new_platform = available_platforms[platform_index].instantiate()
		
	if last_platform_position == Vector2.ZERO:
		new_platform.position = Vector2(400, 0)
	else:
		var x = last_platform_position.x + rng.randi_range(450, 550)
		var y = clamp(last_platform_position.y + rng.randi_range(-150, 150), 200, 6000)
		new_platform.position = Vector2(x, y)
	
	moving_environment.add_child(new_platform)
	
	last_platform_position = new_platform.position
	next_spawn_time += world_speed

func _physics_process(delta):
	if not player.active:
		return
	
	moving_environment.position.x -= world_speed * delta

func add_score(value):
	score += value
	collect_sound.set_pitch_scale(collectible_pitch)
	collect_sound.play()
	collectible_pitch += 0.1
	reset_collectible_pitch_time = Time.get_ticks_msec() + collectible_pitch_reset_interval

func _on_player_died():
	emit_signal("game_over")
	game_over_label.text = game_over_label.text % score
	game_over_label.set_visible(true)

func _on_ground_body_entered(body):
	if body.is_in_group("player"):
		player.die()      
