extends RigidBody3D

@export var friction: float = 1.0
@export var bounce: float = 0.0

func _ready():
	# Ensure the bucket responds to physics
	self.mass = mass
	self.friction = friction
	self.bounce = bounce
	self.contact_monitor = true
	self.max_contacts_reported = 10

	# Optional: connect to collisions for sound or effects
	self.connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.name.begins_with("Brick"):
		print("Bucket got hit by brick!")

		# Get contact point from collision if available
		var contact_point: Vector3 = body.global_transform.origin

		# Calculate impulse based on brick velocity and mass
		var impulse_strength: float = body.mass * body.linear_velocity.length() * .15

		var impulse_vector = body.linear_velocity.normalized() * impulse_strength

		# Apply at contact point offset from bucket center
		self.apply_impulse(contact_point - self.global_transform.origin, impulse_vector)
		
