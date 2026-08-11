extends Node

## LoginRouter (v4.2) — Helper autoload.
## Khi một scene muốn yêu cầu user đăng nhập trước khi tiếp tục,
## nó set `LoginRouter.next_scene` rồi chuyển sang login.tscn.
## Sau khi đăng nhập OK, login scene sẽ chuyển sang `next_scene`
## (nếu rỗng thì về menu.tscn như cũ).
##
## Cũng cho phép "guest" — login scene có nút "Chơi guest" sẽ
## chuyển thẳng sang next_scene mà không cần đăng nhập.

var next_scene: String = ""
