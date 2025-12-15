extends CharacterBody3D

@onready var head: Node3D = $head
@onready var eyes: Node3D = $head/eyes
@onready var camera_3d: Camera3D = $head/eyes/Camera3D
@onready var standing_collision_shape: CollisionShape3D = $standingCollisionShape
@onready var crouching_collision_shape: CollisionShape3D = $crouchingCollisionShape
@onready var standup_check: RayCast3D = $standupCheck
@onready var interaction_controller: Node = %InteractionController

#Movement variables
const walking_speed: float = 3.0
const sprinting_speed: float = 5.0
const crouching_speed: float = 1.0
var current_speed: float = 0.0
var moving: bool = false
var input_dir: Vector2 = Vector2.ZERO
var direction: Vector3 = Vector3.ZERO
const crouching_depth: float = -0.9
const jump_velocity: float = 4.0

var lerp_speed: float = 10.0

#player settings
var base_fov: float = 90.0
var mouse_sensitivity: float = 0.2

#state machine
enum PlayerState {
	IDLE_STAND,
	IDLE_CROUCH,
	CROUCHING,
	WALKING,
	SPRINTING,
	AIR
	}
var player_state: PlayerState = PlayerState.IDLE_STAND

#headbobbing variables
const head_bobbing_sprinting_speed: float = 22.0
const head_bobbing_walking_speed: float = 14.0
const head_bobbing_crouching_speed: float = 10.0
const head_bobbing_sprinting_intensity: float = 0.2
const head_bobbing_walking_intensity: float = 0.1
const head_bobbing_crouching_intensity: float = 0.05
var head_bobbing_current_intensity: float = 0.0
var head_bobbing_vector: Vector2 = Vector2.ZERO
var head_bobbing_index: float = 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
	if event is InputEventMouseMotion:
		if not interaction_controller.isCameraLocked():
			rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
			head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))

func _physics_process(delta: float) -> void:
	
	updatePlayerState()
	updateCamera(delta)
	
	#falling
	if not is_on_floor():
		if velocity.y >= 0: #jumping upwards
			velocity += get_gravity() * delta
		else: #falling down
			velocity += get_gravity() * delta * 2.0
	else: #jumping
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
	
	input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*lerp_speed)
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	move_and_slide()

func updatePlayerState() -> void:
	moving = (input_dir != Vector2.ZERO)
	if not is_on_floor():
		player_state = PlayerState.AIR
	else:
		if Input.is_action_pressed("crouch"):
			if not moving:
				player_state = PlayerState.IDLE_CROUCH
			else:
				player_state = PlayerState.CROUCHING
		elif !standup_check.is_colliding():
			if not moving:
				player_state = PlayerState.IDLE_STAND
			elif Input.is_action_pressed("sprint"):
				player_state = PlayerState.SPRINTING
			else:
				player_state = PlayerState.WALKING
	
	updatePlayerColShape(player_state)
	updatePlayerSpeed(player_state)

func updatePlayerColShape(_player_state: PlayerState) -> void:
	if _player_state == PlayerState.CROUCHING or _player_state == PlayerState.IDLE_CROUCH:
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
	else:
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true

func updatePlayerSpeed(_player_state: PlayerState) -> void:
	if _player_state == PlayerState.CROUCHING or _player_state == PlayerState.IDLE_CROUCH:
		current_speed = crouching_speed
	elif _player_state == PlayerState.WALKING:
		current_speed = walking_speed
	elif _player_state == PlayerState.SPRINTING:
		current_speed = sprinting_speed

func updateCamera(delta: float) -> void:
	if player_state == PlayerState.AIR:
		pass
	
	if player_state == PlayerState.CROUCHING or player_state == PlayerState.IDLE_CROUCH:
		head.position.y = lerp(head.position.y, 1.8 + crouching_depth, delta*lerp_speed)
		camera_3d.fov = lerp(camera_3d.fov, base_fov*0.95, delta*lerp_speed)
		head_bobbing_current_intensity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_crouching_speed * delta
	elif player_state == PlayerState.IDLE_STAND:
		head.position.y = lerp(head.position.y, 1.8, delta*lerp_speed)
		camera_3d.fov = lerp(camera_3d.fov, base_fov, delta*lerp_speed)
		head_bobbing_current_intensity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed * delta
	elif player_state == PlayerState.WALKING:
		head.position.y = lerp(head.position.y, 1.8, delta*lerp_speed)
		camera_3d.fov = lerp(camera_3d.fov, base_fov, delta*lerp_speed)
		head_bobbing_current_intensity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed * delta
	elif player_state == PlayerState.SPRINTING:
		head.position.y = lerp(head.position.y, 1.8, delta*lerp_speed)
		camera_3d.fov = lerp(camera_3d.fov, base_fov*1.05, delta*lerp_speed)
		head_bobbing_current_intensity = head_bobbing_sprinting_intensity
		head_bobbing_index += head_bobbing_sprinting_speed * delta
	
	head_bobbing_vector.y = sin(head_bobbing_index)
	head_bobbing_vector.x = (sin(head_bobbing_index/2.0)+0.5)
	if moving:
		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y*(head_bobbing_current_intensity/2.0), delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x*(head_bobbing_current_intensity), delta*lerp_speed)
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta*lerp_speed)
