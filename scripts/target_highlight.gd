extends Node2D

## TargetHighlight - Vẽ vòng tròn đỏ quanh đối thủ khi aim trúng (v2.1)
## Script được attach vào Node2D, dùng _draw để vẽ vòng tròn pulsing

var target: Node2D = null
var pulse_time: float = 0.0

func _process(delta):
        pulse_time += delta
        if target and is_instance_valid(target):
                # Di chuyển highlight theo target
                global_position = target.global_position
                queue_redraw()
        else:
                visible = false

func set_target(t: Node2D):
        target = t
        visible = true

func _draw():
        if not target or not is_instance_valid(target):
                return
        # Tính radius dựa trên target size
        var radius = 35.0
        if "current_size" in target:
                radius = target.current_size + 15.0
        elif "size" in target:
                radius = float(target.size) + 15.0
        # Pulse effect
        var pulse = 1.0 + 0.1 * sin(pulse_time * 8.0)
        radius *= pulse
        # Vòng tròn ngoài (đỏ, alpha cao)
        draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(1.0, 0.15, 0.15, 0.95), 3.5)
        # Vòng tròn trong (đỏ, alpha thấp - glow effect)
        draw_arc(Vector2.ZERO, radius + 4, 0, TAU, 48, Color(1.0, 0.3, 0.3, 0.4), 2.0)
        # 4 chấm chỉ hướng (trên/dưới/trái/phải)
        var dot_color = Color(1.0, 0.2, 0.2, 0.95)
        var dot_size = 4.0
        draw_circle(Vector2(radius, 0), dot_size, dot_color)
        draw_circle(Vector2(-radius, 0), dot_size, dot_color)
        draw_circle(Vector2(0, radius), dot_size, dot_color)
        draw_circle(Vector2(0, -radius), dot_size, dot_color)
