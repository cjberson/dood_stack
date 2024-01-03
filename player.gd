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


func _physics_process(delta):	
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
	
	# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# Vertical Velocity
	if not is_on_floor():	 # If in the air, fall towards the floor
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
		

	# Moving the Character
	velocity = target_velocity
	
	if Input.is_action_just_pressed("jump"):
		if base == null:
			# Jumping
			if is_on_floor(): 
				target_velocity.y = jump_impulse
		# Throwing
		else:
			target_velocity.y = jump_impulse
			prev_base = base
			base = null
		
	# Iterate through all collisions that occurred this frame
	for index in range(get_slide_collision_count()):
		# We get one of the collisions with the player
		var collision = get_slide_collision(index)
		var collider = collision.get_collider()
		
		# If the collision is with ground or the base
		if collider == null or collider == base or collider == prev_base:
			continue

		if collider.is_in_group("world"):
			if Vector3.UP.dot(collision.get_normal()) > 0.1:
				prev_base = null
				
				break
			
		# If the collider is with an npc
		if collider.is_in_group("npc"):
			# we check that we are hitting it from above.
			if Vector3.UP.dot(collision.get_normal()) > 0.1:
				position.x = collider.position.x
				position.y = collider.position.y + 1
				position.z = collider.position.z
				base = collider
				
				break
	
	if base == null:
		move_and_slide()
	else:
		base.velocity = velocity
		base.move_and_slide()
		
		position.x = base.position.x
		position.y = base.position.y + 1
		position.z = base.position.z
		
		
