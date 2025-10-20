class_name Player
extends CharacterBody2D


const SPEED = 100.0
const JUMP_VELOCITY = -300.0
const ATTACK_DURATION := 0.2
const DROP_DISABLE_TIME := 0.25
const PLATFORM_LAYER_BIT := 2
const SWORD_OFFSET := 10.0
const SWORD_BASE_Y := -15.0
const SWORD_SWING_RAISE := -21.0
const SWORD_SWING_DROP := -8.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_attacking := false
var is_dropping := false
var attack_tween: Tween
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_area: Area2D = $SwordArea
@onready var sword_collision: CollisionShape2D = $SwordArea/CollisionShape2D
@onready var attack_timer: Timer = $AttackTimer
@onready var drop_timer: Timer = $DropTimer


func _ready() -> void:
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	drop_timer.timeout.connect(_on_drop_timer_timeout)
	sword_area.area_entered.connect(_on_sword_area_area_entered)
	_set_sword_active(false)
	_set_platform_collision_enabled(true)


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("attack"):
		attack()
	# Handle jump.
	elif Input.is_action_pressed("move_down") and Input.is_action_just_pressed("jump") and is_on_floor():
		_start_drop_through()
	elif (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump")) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		_update_facing(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if velocity.x != 0.0:
			_update_facing(sign(velocity.x))

	move_and_slide()


func attack() -> void:
	if is_attacking:
		return

	is_attacking = true
	_update_sword_transform()
	_set_sword_active(true)
	_start_attack_animation()
	attack_timer.start(ATTACK_DURATION)


func _update_facing(direction: float) -> void:
	animated_sprite.flip_h = direction < 0.0
	_update_sword_transform()


func _update_sword_transform() -> void:
	var facing_left := animated_sprite.flip_h
	if facing_left:
		sword_area.position.x = -SWORD_OFFSET
		sword_area.rotation_degrees = 180.0
	else:
		sword_area.position.x = SWORD_OFFSET
		sword_area.rotation_degrees = 0.0
	sword_area.position.y = SWORD_BASE_Y


func _set_sword_active(active: bool) -> void:
	sword_area.visible = active
	sword_area.monitoring = active
	sword_area.monitorable = active
	sword_collision.disabled = not active
	if not active and attack_tween and attack_tween.is_running():
		attack_tween.kill()
		attack_tween = null
	if not active:
		sword_area.scale = Vector2.ONE
		sword_area.position.y = SWORD_BASE_Y


func _on_attack_timer_timeout() -> void:
	is_attacking = false
	if animated_sprite.flip_h:
		sword_area.rotation_degrees = 180.0
	else:
		sword_area.rotation_degrees = 0.0
	_set_sword_active(false)


func _start_attack_animation() -> void:
	var base_angle := 0.0
	var start_angle := -110.0
	if animated_sprite.flip_h:
		base_angle = 180.0
		start_angle = 290.0
	sword_area.rotation_degrees = start_angle
	sword_area.position.y = SWORD_SWING_RAISE
	sword_area.scale = Vector2.ONE
	if attack_tween and attack_tween.is_running():
		attack_tween.kill()
		attack_tween = null
	attack_tween = create_tween()
	attack_tween.parallel().tween_property(sword_area, "rotation_degrees", base_angle, ATTACK_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	attack_tween.parallel().tween_property(sword_area, "position:y", SWORD_SWING_DROP, ATTACK_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var scale_track := attack_tween.parallel()
	scale_track.tween_property(sword_area, "scale", Vector2(1.18, 0.10), ATTACK_DURATION * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	scale_track.chain().tween_property(sword_area, "scale", Vector2.ONE, ATTACK_DURATION * 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _start_drop_through() -> void:
	if is_dropping:
		return

	is_dropping = true
	_set_platform_collision_enabled(false)
	drop_timer.start(DROP_DISABLE_TIME)
	velocity.y = 50.0


func _set_platform_collision_enabled(enabled: bool) -> void:
	set_collision_mask_value(PLATFORM_LAYER_BIT, enabled)


func _on_drop_timer_timeout() -> void:
	is_dropping = false
	_set_platform_collision_enabled(true)


func _on_sword_area_area_entered(area: Area2D) -> void:
	var candidate := area.get_parent()
	if candidate != null and candidate.is_in_group("enemy"):
		candidate.queue_free()
