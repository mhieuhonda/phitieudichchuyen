extends Label

## DamageNumber - Floating damage number popup (v2.8)
## Hiện số damage nổi lên khi trúng AI, rồi fade out

var _lifetime: float = 1.0
var _velocity: Vector2 = Vector2.ZERO

func _ready():
        add_theme_font_size_override("font_size", 18)
        horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        var angle = randf_range(-0.6, 0.6) - PI / 2.0
        _velocity = Vector2(cos(angle), sin(angle)) * randf_range(40, 80)

func _process(delta: float):
        position += _velocity * delta
        _velocity.y += 30.0 * delta
        _lifetime -= delta
        modulate.a = clamp(_lifetime / 0.4, 0.0, 1.0)
        if _lifetime <= 0:
                queue_free()

func setup(value: float, is_crit: bool = false):
        text = "%d" % int(value)
        if is_crit:
                text = "CRIT! %d" % int(value)
                add_theme_font_size_override("font_size", 24)
                add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
        else:
                add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
