extends Node2D

## Map - Bản đồ game
## Tạo bản đồ với tường bao, chướng ngại vật, vật phẩm, và vòng bo

@onready var zone_circle: Line2D = $ZoneCircle

var wall_thickness: float = 20.0
var pickup_scene: PackedScene = preload("res://scenes/pickup.tscn")
var pickups: Array = []

func _ready():
	_create_walls()
	_create_obstacles()
	_create_pickups()
	_update_zone_visual()

func _process(_delta):
	_update_zone_visual()
	# Cập nhật pickups
	_cleanup_pickups()

func _create_walls():
	var map_w = GameManager.map_size.x
	var map_h = GameManager.map_size.y
	var t = wall_thickness
	
	# Tường trên
	_create_wall(Vector2(map_w / 2, -t / 2), Vector2(map_w + t * 2, t), Color(0.35, 0.3, 0.4))
	# Tường dưới
	_create_wall(Vector2(map_w / 2, map_h + t / 2), Vector2(map_w + t * 2, t), Color(0.35, 0.3, 0.4))
	# Tường trái
	_create_wall(Vector2(-t / 2, map_h / 2), Vector2(t, map_h + t * 2), Color(0.35, 0.3, 0.4))
	# Tường phải
	_create_wall(Vector2(map_w + t / 2, map_h / 2), Vector2(t, map_h + t * 2), Color(0.35, 0.3, 0.4))

func _create_wall(pos: Vector2, size: Vector2, color: Color = Color(0.3, 0.3, 0.4)):
	var wall = StaticBody2D.new()
	wall.position = pos
	wall.add_to_group("walls")
	
	var shape = RectangleShape2D.new()
	shape.size = size
	
	var collision = CollisionShape2D.new()
	collision.shape = shape
	wall.add_child(collision)
	
	# Visual
	var rect = ColorRect.new()
	rect.size = size
	rect.position = -size / 2
	rect.color = color
	wall.add_child(rect)
	
	add_child(wall)

func _create_obstacles():
	var rng = RandomNumberGenerator.new()
	rng.seed = 42
	
	# Chướng ngại vật đa dạng: hình chữ nhật, hình tròn
	var num_obstacles = 16
	for i in num_obstacles:
		var ox = rng.randf_range(200, GameManager.map_size.x - 200)
		var oy = rng.randf_range(200, GameManager.map_size.y - 200)
		var is_round = rng.randf() < 0.3
		
		var obstacle = StaticBody2D.new()
		obstacle.position = Vector2(ox, oy)
		obstacle.add_to_group("obstacles")
		obstacle.add_to_group("walls")
		
		if is_round:
			var radius = rng.randf_range(20, 40)
			var shape = CircleShape2D.new()
			shape.radius = radius
			var collision = CollisionShape2D.new()
			collision.shape = shape
			obstacle.add_child(collision)
			
			var circle = Node2D.new()
			var rect = ColorRect.new()
			rect.size = Vector2(radius * 2, radius * 2)
			rect.position = Vector2(-radius, -radius)
			rect.color = Color(0.3, 0.28, 0.38)
			obstacle.add_child(rect)
		else:
			var osize_x = rng.randf_range(30, 90)
			var osize_y = rng.randf_range(30, 90)
			var shape = RectangleShape2D.new()
			shape.size = Vector2(osize_x, osize_y)
			var collision = CollisionShape2D.new()
			collision.shape = shape
			obstacle.add_child(collision)
			
			var rect = ColorRect.new()
			rect.size = Vector2(osize_x, osize_y)
			rect.position = Vector2(-osize_x / 2, -osize_y / 2)
			# Màu sắc đa dạng cho chướng ngại vật
			var colors = [Color(0.25, 0.25, 0.35), Color(0.3, 0.25, 0.3), Color(0.25, 0.3, 0.3)]
			rect.color = colors[i % colors.size()]
			obstacle.add_child(rect)
		
		add_child(obstacle)

func _create_pickups():
	# Tạo vật phẩm rải trên bản đồ
	var rng = RandomNumberGenerator.new()
	rng.seed = 123
	
	var num_pickups = 8
	for i in num_pickups:
		var px = rng.randf_range(150, GameManager.map_size.x - 150)
		var py = rng.randf_range(150, GameManager.map_size.y - 150)
		var pickup = pickup_scene.instantiate()
		pickup.global_position = Vector2(px, py)
		pickup.pickup_type = [Pickup.PickupType.HEALTH, Pickup.PickupType.DART_REFILL][i % 2]
		add_child(pickup)
		pickups.append(pickup)

func _cleanup_pickups():
	# Respawn pickups đã bị nhặt
	for i in pickups.size():
		if not is_instance_valid(pickups[i]):
			# Tạo pickup mới
			var rng = RandomNumberGenerator.new()
			rng.seed = i * 31 + Time.get_ticks_msec()
			var px = rng.randf_range(150, GameManager.map_size.x - 150)
			var py = rng.randf_range(150, GameManager.map_size.y - 150)
			var pickup = pickup_scene.instantiate()
			pickup.global_position = Vector2(px, py)
			pickup.pickup_type = [Pickup.PickupType.HEALTH, Pickup.PickupType.DART_REFILL][i % 2]
			add_child(pickup)
			pickups[i] = pickup

func _update_zone_visual():
	if zone_circle:
		zone_circle.clear_points()
		var segments = 64
		for i in segments + 1:
			var angle = (i / float(segments)) * TAU
			var x = GameManager.zone_center.x + cos(angle) * GameManager.zone_radius
			var y = GameManager.zone_center.y + sin(angle) * GameManager.zone_radius
			zone_circle.add_point(Vector2(x, y))
