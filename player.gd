extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75
# Vertical impulse applied to the character upon jumping in meters per second.
@export var jump_impulse = 12

var target_velocity = Vector3.ZERO
var base = null
var prev_base = null

const COS_45 = cos(PI / 4)
const SIN_45 = sin(PI / 4)


func _physics_process(delta):	
	set_target_velocity(delta)
	handle_stacking()
	
	if base == null:
		velocity = target_velocity
		move_and_slide()
	else:
		base.velocity = target_velocity
		base.move_and_slide()
		
		# BUG: Setting position of player directly makes it so their collider is ignored
		# Place player directly above the stacked NPC
		position.x = base.position.x
		position.y = base.position.y + 1
		position.z = base.position.z
		
func set_target_velocity(delta: float) -> void:
	var direction = get_direction()
	
	# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# Gravity
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	
	jump_or_throw()	
	target_velocity = cartesian_to_isometric(target_velocity)	
		
func get_direction() -> Vector3:
	# We create a local variable to store the input direction.
	var direction = Vector3.ZERO

	# We check for each move input and update the direction accordingly.
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		# Notice how we are working with the vector's x and z axes.
		# In 3D, the XZ plane is the ground plane.
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
		
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		$Pivot.look_at(position + direction, Vector3.UP)
	
	return direction
		
		
func jump_or_throw() -> void:	
	if Input.is_action_just_pressed("jump"):
		# Jumping
		if base == null:
			# Only jump if the player is on the floor
			if is_on_floor(): 
				target_velocity.y = jump_impulse
		# Throwing
		else:
			# TODO: change to launch impulse rather than jump-esque
			# TODO: once thrown, try allowing them to land back on same npc
			target_velocity.y = jump_impulse
			# After the player is thrown, do not let them land back onto the same NPC
			prev_base = base
			base = null
		
func cartesian_to_isometric(cartesian: Vector3) -> Vector3:
	# Rotation by 45 degrees clockwise: https://en.wikipedia.org/wiki/Rotation_matrix
	var iso_x = cartesian.x * COS_45  - cartesian.z * SIN_45
	var iso_z = cartesian.x * SIN_45 + cartesian.z * COS_45
	
	return Vector3(iso_x, cartesian.y, iso_z)
		
func handle_stacking() -> void:
	# Iterate through all collisions that occurred this frame
	for index in range(get_slide_collision_count()):
		# We get one of the collisions with the player
		var collision = get_slide_collision(index)
		var collider = collision.get_collider()
		
		# If the collision is unknown or the base of the stack
		if collider == null or collider == base or collider == prev_base:
			continue

		# If the collision is with the world, player hit the ground and can now become a stack again
		if collider.is_in_group("world"):
			if Vector3.UP.dot(collision.get_normal()) > 0.1:
				prev_base = null
				
				break
			
		# If the collider is with an npc, stack
		if collider.is_in_group("npc"):
			# we check that we are hitting it from above.
			if Vector3.UP.dot(collision.get_normal()) > 0.1:
				# BUG: Setting position of player directly makes it so their collider is ignored
				position.x = collider.position.x
				position.y = collider.position.y + 1
				position.z = collider.position.z
				base = collider
				
				break	
		
