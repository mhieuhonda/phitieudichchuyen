extends Node2D

## Map - Bản đồ game (v1.0)
## - Grid pattern background với texture đẹp
## - Vòng bo gradient glow
## - Obstacles đa dạng: đá, cây, thùng, bụi cỏ
## - Decorative elements: hoa, lốp, pallet
## - Pickups rải đều

@onready var zone_circle: Line2D = $ZoneCircle
@onready var zone_fill: Polygon2D = $ZoneFill
@onready var background: ColorRect = $Background
@onready var grid_layer: Node2D = $GridLayer
@onready var decor_layer: Node2D = $DecorLayer

var wall_thickness: float = 24.0
var pickup_scene: PackedScene = preload("res://scenes/pickup.tscn")
var pickups: Array = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready():
    rng.seed = 42
    _setup_background()
    _create_grid()
    _create_walls()
    _create_obstacles()
    _create_decorations()
    _create_pickups()
    _update_zone_visual()

func _process(_delta):
    _update_zone_visual()
    _cleanup_pickups()

func _setup_background():
    # Gradient nền: tối ở rìa, sáng ở giữa
    if background:
        background.color = Color(0.10, 0.12, 0.18, 1.0)
        background.size = GameManager.map_size

func _create_grid():
    # Vẽ grid lines nhẹ
    if not grid_layer:
        return
    var grid_color = Color(1, 1, 1, 0.04)
    var step = 100.0
    var map_w = GameManager.map_size.x
    var map_h = GameManager.map_size.y
    # Vertical lines
    for x in range(0, int(map_w) + 1, int(step)):
        var line = Line2D.new()
        line.add_point(Vector2(x, 0))
        line.add_point(Vector2(x, map_h))
        line.width = 1.0
        line.default_color = grid_color
        grid_layer.add_child(line)
    # Horizontal lines
    for y in range(0, int(map_h) + 1, int(step)):
        var line = Line2D.new()
        line.add_point(Vector2(0, y))
        line.add_point(Vector2(map_w, y))
        line.width = 1.0
        line.default_color = grid_color
        grid_layer.add_child(line)
    # Major grid (mỗi 500px) - đậm hơn
    var major_color = Color(1, 1, 1, 0.08)
    for x in range(0, int(map_w) + 1, 500):
        var line = Line2D.new()
        line.add_point(Vector2(x, 0))
        line.add_point(Vector2(x, map_h))
        line.width = 2.0
        line.default_color = major_color
        grid_layer.add_child(line)
    for y in range(0, int(map_h) + 1, 500):
        var line = Line2D.new()
        line.add_point(Vector2(0, y))
        line.add_point(Vector2(map_w, y))
        line.width = 2.0
        line.default_color = major_color
        grid_layer.add_child(line)

func _create_walls():
    var map_w = GameManager.map_size.x
    var map_h = GameManager.map_size.y
    var t = wall_thickness

    # 4 tường với màu nâu đá
    _create_wall(Vector2(map_w / 2, -t / 2), Vector2(map_w + t * 2, t))
    _create_wall(Vector2(map_w / 2, map_h + t / 2), Vector2(map_w + t * 2, t))
    _create_wall(Vector2(-t / 2, map_h / 2), Vector2(t, map_h + t * 2))
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

    # Visual: dark stone wall với viền sáng
    var rect = ColorRect.new()
    rect.size = size
    rect.position = -size / 2
    rect.color = Color(0.22, 0.20, 0.28, 1.0)
    wall.add_child(rect)

    # Border highlight
    var border = Line2D.new()
    border.add_point(Vector2(-size.x/2, -size.y/2))
    border.add_point(Vector2(size.x/2, -size.y/2))
    border.add_point(Vector2(size.x/2, size.y/2))
    border.add_point(Vector2(-size.x/2, size.y/2))
    border.add_point(Vector2(-size.x/2, -size.y/2))
    border.width = 2.0
    border.default_color = Color(0.45, 0.42, 0.55, 1.0)
    wall.add_child(border)

    add_child(wall)

func _create_obstacles():
    # Các cụm chướng ngại vật đa dạng
    # Seed cố định để map nhất quán
    var positions = [
        Vector2(400, 400), Vector2(1600, 400), Vector2(400, 1600), Vector2(1600, 1600),  # 4 góc
        Vector2(1000, 700), Vector2(700, 1300), Vector2(1300, 1300),  # giữa
        Vector2(1000, 1000),  # center
        Vector2(300, 1000), Vector2(1700, 1000), Vector2(1000, 300), Vector2(1000, 1700),  # giữa các cạnh
        Vector2(600, 600), Vector2(1400, 600), Vector2(600, 1400), Vector2(1400, 1400),
        Vector2(1200, 800), Vector2(800, 1200), Vector2(1200, 1200), Vector2(800, 800),
    ]
    var types = ["rock", "tree", "crate", "rock", "tree", "crate"]
    for i in range(positions.size()):
        var pos = positions[i]
        var tp = types[i % types.size()]
        _create_obstacle(pos, tp, i)

func _create_obstacle(pos: Vector2, type: String, idx: int):
    var obstacle = StaticBody2D.new()
    obstacle.position = pos
    obstacle.add_to_group("obstacles")
    obstacle.add_to_group("walls")

    match type:
        "rock":
            var radius = rng.randf_range(28, 42)
            var shape = CircleShape2D.new()
            shape.radius = radius
            var collision = CollisionShape2D.new()
            collision.shape = shape
            obstacle.add_child(collision)
            # Visual: đá xám với viền tối
            var poly = Polygon2D.new()
            var segments = 16
            var pts = PackedVector2Array()
            for j in segments:
                var angle = (j / float(segments)) * TAU
                var r = radius * (0.85 + 0.25 * sin(angle * 3 + idx))
                pts.append(Vector2(cos(angle), sin(angle)) * r)
            poly.polygon = pts
            poly.color = Color(0.32, 0.30, 0.36, 1.0)
            obstacle.add_child(poly)
            # Highlight trên
            var hl = Polygon2D.new()
            var hl_pts = PackedVector2Array()
            for j in segments:
                var angle = (j / float(segments)) * TAU
                if sin(angle) < 0:  # nửa trên
                    var r = radius * 0.6
                    hl_pts.append(Vector2(cos(angle), sin(angle)) * r)
            if hl_pts.size() > 2:
                hl.polygon = hl_pts
                hl.color = Color(0.5, 0.48, 0.55, 0.5)
                obstacle.add_child(hl)
            # Viền
            var border = Line2D.new()
            for j in segments:
                var angle = (j / float(segments)) * TAU
                var r = radius * (0.85 + 0.25 * sin(angle * 3 + idx))
                border.add_point(Vector2(cos(angle), sin(angle)) * r)
            border.add_point(border.get_point_position(0))
            border.width = 2.0
            border.default_color = Color(0.18, 0.16, 0.22, 1.0)
            obstacle.add_child(border)
        "tree":
            var radius = rng.randf_range(25, 35)
            var shape = CircleShape2D.new()
            shape.radius = radius
            var collision = CollisionShape2D.new()
            collision.shape = shape
            obstacle.add_child(collision)
            # Thân cây (nâu)
            var trunk = ColorRect.new()
            trunk.size = Vector2(8, 18)
            trunk.position = Vector2(-4, radius - 5)
            trunk.color = Color(0.30, 0.20, 0.12, 1.0)
            obstacle.add_child(trunk)
            # Tán cây (xanh đậm) - nhiều lớp
            for layer in range(3):
                var r = radius * (1.0 - layer * 0.15)
                var poly = Polygon2D.new()
                var segments = 14
                var pts = PackedVector2Array()
                for j in segments:
                    var angle = (j / float(segments)) * TAU
                    var rr = r * (0.9 + 0.15 * sin(angle * 4 + idx + layer))
                    pts.append(Vector2(cos(angle), sin(angle)) * rr - Vector2(0, 5 + layer * 3))
                poly.polygon = pts
                var green_intensity = 0.25 + layer * 0.05
                poly.color = Color(0.15 + layer * 0.05, green_intensity + layer * 0.05, 0.18, 1.0)
                obstacle.add_child(poly)
        "crate":
            var osize = rng.randf_range(40, 60)
            var shape = RectangleShape2D.new()
            shape.size = Vector2(osize, osize)
            var collision = CollisionShape2D.new()
            collision.shape = shape
            obstacle.add_child(collision)
            # Thùng gỗ với viền
            var rect = ColorRect.new()
            rect.size = Vector2(osize, osize)
            rect.position = Vector2(-osize / 2, -osize / 2)
            rect.color = Color(0.45, 0.30, 0.18, 1.0)
            obstacle.add_child(rect)
            # Viền đậm
            var border = Line2D.new()
            border.add_point(Vector2(-osize/2, -osize/2))
            border.add_point(Vector2(osize/2, -osize/2))
            border.add_point(Vector2(osize/2, osize/2))
            border.add_point(Vector2(-osize/2, osize/2))
            border.add_point(Vector2(-osize/2, -osize/2))
            border.width = 3.0
            border.default_color = Color(0.25, 0.15, 0.08, 1.0)
            obstacle.add_child(border)
            # X chữ trên thùng
            var x_line1 = Line2D.new()
            x_line1.add_point(Vector2(-osize/2 + 4, -osize/2 + 4))
            x_line1.add_point(Vector2(osize/2 - 4, osize/2 - 4))
            x_line1.width = 2.0
            x_line1.default_color = Color(0.30, 0.18, 0.10, 1.0)
            obstacle.add_child(x_line1)
            var x_line2 = Line2D.new()
            x_line2.add_point(Vector2(-osize/2 + 4, osize/2 - 4))
            x_line2.add_point(Vector2(osize/2 - 4, -osize/2 + 4))
            x_line2.width = 2.0
            x_line2.default_color = Color(0.30, 0.18, 0.10, 1.0)
            obstacle.add_child(x_line2)
    add_child(obstacle)

func _create_decorations():
    # Thêm decoration không collision: hoa, bụi cỏ, vết nứt
    if not decor_layer:
        return
    var local_rng = RandomNumberGenerator.new()
    local_rng.seed = 999
    for i in range(40):
        var pos = Vector2(local_rng.randf_range(80, GameManager.map_size.x - 80),
                          local_rng.randf_range(80, GameManager.map_size.y - 80))
        var type = local_rng.randi() % 3
        match type:
            0:  # Bụi cỏ
                var grass = Polygon2D.new()
                var pts = PackedVector2Array()
                pts.append(Vector2(-3, 0))
                pts.append(Vector2(-1, -8))
                pts.append(Vector2(0, -12))
                pts.append(Vector2(1, -8))
                pts.append(Vector2(3, 0))
                grass.polygon = pts
                grass.color = Color(0.20, 0.35, 0.20, 0.5)
                grass.position = pos
                decor_layer.add_child(grass)
            1:  # Hoa nhỏ
                var flower = Node2D.new()
                flower.position = pos
                # Cánh hoa
                for k in range(5):
                    var petal = Polygon2D.new()
                    var pts = PackedVector2Array()
                    var angle = k * TAU / 5.0
                    pts.append(Vector2(cos(angle) * 2, sin(angle) * 2))
                    pts.append(Vector2(cos(angle) * 5, sin(angle) * 5))
                    pts.append(Vector2(cos(angle + 0.5) * 2, sin(angle + 0.5) * 2))
                    petal.polygon = pts
                    petal.color = Color(0.9, 0.5, 0.7, 0.6)
                    flower.add_child(petal)
                decor_layer.add_child(flower)
            2:  # Vết nứt sàn
                var crack = Line2D.new()
                var start = pos
                var cur = start
                crack.add_point(cur)
                for k in range(4):
                    cur += Vector2(local_rng.randf_range(-15, 15), local_rng.randf_range(-15, 15))
                    crack.add_point(cur)
                crack.width = 1.0
                crack.default_color = Color(0.05, 0.05, 0.10, 0.4)
                decor_layer.add_child(crack)

func _create_pickups():
    var local_rng = RandomNumberGenerator.new()
    local_rng.seed = 123
    var num_pickups = 12
    for i in num_pickups:
        var px = local_rng.randf_range(150, GameManager.map_size.x - 150)
        var py = local_rng.randf_range(150, GameManager.map_size.y - 150)
        var pickup = pickup_scene.instantiate()
        pickup.global_position = Vector2(px, py)
        pickup.pickup_type = [Pickup.PickupType.HEALTH, Pickup.PickupType.DART_REFILL][i % 2]
        add_child(pickup)
        pickups.append(pickup)

func _cleanup_pickups():
    for i in pickups.size():
        if not is_instance_valid(pickups[i]):
            var local_rng = RandomNumberGenerator.new()
            local_rng.seed = i * 31 + Time.get_ticks_msec()
            var px = local_rng.randf_range(150, GameManager.map_size.x - 150)
            var py = local_rng.randf_range(150, GameManager.map_size.y - 150)
            var pickup = pickup_scene.instantiate()
            pickup.global_position = Vector2(px, py)
            pickup.pickup_type = [Pickup.PickupType.HEALTH, Pickup.PickupType.DART_REFILL][i % 2]
            add_child(pickup)
            pickups[i] = pickup

func _update_zone_visual():
    if zone_circle:
        zone_circle.clear_points()
        var segments = 96
        for i in segments + 1:
            var angle = (i / float(segments)) * TAU
            var x = GameManager.zone_center.x + cos(angle) * GameManager.zone_radius
            var y = GameManager.zone_center.y + sin(angle) * GameManager.zone_radius
            zone_circle.add_point(Vector2(x, y))
        # Màu đỏ/cam sống động
        zone_circle.default_color = Color(0.3, 0.8, 0.5, 0.7)
        zone_circle.width = 3.0
    # Zone fill - subtle inner glow
    if zone_fill:
        var segments = 64
        var pts = PackedVector2Array()
        for i in segments:
            var angle = (i / float(segments)) * TAU
            var x = GameManager.zone_center.x + cos(angle) * GameManager.zone_radius
            var y = GameManager.zone_center.y + sin(angle) * GameManager.zone_radius
            pts.append(Vector2(x, y))
        zone_fill.polygon = pts
        zone_fill.color = Color(1.0, 0.35, 0.35, 0.04)
