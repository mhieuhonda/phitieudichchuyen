extends Node2D

## Map - Bản đồ game
## Tạo bản đồ với tường bao, chướng ngại vật, và vòng bo

@onready var zone_circle: Line2D = $ZoneCircle
@onready var zone_fill: ColorRect = $ZoneFill

var wall_thickness: float = 20.0

func _ready():
	_create_walls()
	_create_obstacles()
	_update_zone_visual()

func _process(_delta):
	_update_zone_visual()

func _create_walls():
	# Tạo 4 bức tường bao quanh bản đồ
	var map_w = GameManager.map_size.x
	var map_h = GameManager.map_size.y
	var t = wall_thickness
	
	# Tường trên
	_create_wall(Vector2(map_w / 2, -t / 2), Vector2(map_w + t * 2, t))
	# Tường dưới
	_create_wall(Vector2(map_w / 2, map_h + t / 2), Vector2(map_w + t * 2, t))
	# Tường trái
	_create_wall(Vector2(-t / 2, map_h / 2), Vector2(t, map_h + t * 2))
	# Tường phải
	_create_wall(Vector2(map_w + t / 2, map_h / 2), Vector2(t, map_h + t * 2))

func _create_wall(pos: Vector2, size: Vector2):
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
	rect.color = Color(0.3, 0.3, 0.4)
	wall.add_child(rect)
	
	add_child(wall)

func _create_obstacles():
	# Tạo chướng ngại vật ngẫu nhiên
	var rng = RandomNumberGenerator.new()
	rng.seed = 42  # Seed cố định để nhất quán
	
	var num_obstacles = 12
	for i in num_obstacles:
		var ox = rng.randf_range(200, GameManager.map_size.x - 200)
		var oy = rng.randf_range(200, GameManager.map_size.y - 200)
		var osize = rng.randf_range(30, 80)
		
		var obstacle = StaticBody2D.new()
		obstacle.position = Vector2(ox, oy)
		obstacle.add_to_group("obstacles")
		obstacle.add_to_group("walls")
		
		var shape = RectangleShape2D.new()
		shape.size = Vector2(osize, osize)
		
		var collision = CollisionShape2D.new()
		collision.shape = shape
		obstacle.add_child(collision)
		
		# Visual
		var rect = ColorRect.new()
		rect.size = Vector2(osize, osize)
		rect.position = Vector2(-osize / 2, -osize / 2)
		rect.color = Color(0.25, 0.25, 0.35)
		obstacle.add_child(rect)
		
		add_child(obstacle)

func _update_zone_visual():
	# Vẽ vòng bo
	if zone_circle:
		zone_circle.clear_points()
		var segments = 64
		for i in segments + 1:
			var angle = (i / float(segments)) * TAU
			var x = GameManager.zone_center.x + cos(angle) * GameManager.zone_radius
			var y = GameManager.zone_center.y + sin(angle) * GameManager.zone_radius
			zone_circle.add_point(Vector2(x, y))
