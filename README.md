# 🎯 Phi Tiêu Dịch Chuyển

> **Ném phi tiêu – Dịch chuyển – Nuốt đối thủ!**
> Game multiplayer 2D top-down kết hợp cơ chế ném phi tiêu và dịch chuyển tức thời, lấy cảm hứng từ game "rắn nuốt nhau".

---

## 📖 Giới thiệu

**Phi Tiêu Dịch Chuyển** là một tựa game online nhiều người chơi (multiplayer) kết hợp hai cơ chế chính:

- **Ném phi tiêu**: Người chơi nhắm hướng, chọn lực để phóng một phi tiêu bay theo quỹ đạo vật lý. Phi tiêu có thể cắm vào bề mặt (tường, sàn) hoặc trúng người chơi khác.
- **Dịch chuyển tức thời**: Khi phi tiêu đã cắm, người chơi có thể kích hoạt để lập tức dịch chuyển nhân vật tới vị trí phi tiêu.

Phong cách chơi lấy cảm hứng từ game "rắn nuốt nhau": nhiều người cùng tham gia một bản đồ, tiêu diệt lẫn nhau để phát triển kích thước/điểm số. Điểm khác biệt cốt lõi: thay vì di chuyển liên tục, người chơi di chuyển giật đoạn qua các cú dịch chuyển, tạo ra chiều sâu chiến thuật và cảm giác "săn mồi" độc đáo.

## 🎮 Cách chơi

### Điều khiển

| Phím | Hành động |
|------|-----------|
| **WASD** | Di chuyển chậm (đi bộ) |
| **Chuột phải (giữ & kéo)** | Nhắm hướng và lực ném phi tiêu |
| **Chuột phải (thả)** | Ném phi tiêu |
| **Space** | Dịch chuyển tới phi tiêu gần nhất |
| **R** | Chơi lại (khi chết) |

### Cơ chế chính

1. **Ném phi tiêu**: Kéo chuột phải để chọn hướng và lực ném. Phi tiêu bay theo đường thẳng trong không gian 2D top-down.
2. **Cắm phi tiêu**: Khi phi tiêu va chạm với tường, sàn hoặc chướng ngại vật, nó sẽ cắm lại tại vị trí đó. Phi tiêu tồn tại trong **5 giây** rồi tự biến mất.
3. **Dịch chuyển**: Nhấn Space để dịch chuyển tức thời tới vị trí phi tiêu đã cắm. Phi tiêu bị tiêu thụ sau khi dịch chuyển.
4. **Nuốt đối thủ**: Nếu dịch chuyển tới vị trí có đối thủ trong bán kính "nuốt", đối thủ bị tiêu diệt. Bạn được tăng kích thước và điểm số.
5. **Phi tiêu trúng người**: Phi tiêu trúng đối thủ gây sát thương (25 HP).
6. **Vòng bo**: Vùng an toàn thu nhỏ dần theo thời gian, gây sát thương cho người ngoài vùng.

### Chiến thuật

- Mỗi cú ném vừa là **di chuyển**, vừa là **đòn tấn công**, vừa là **cách thoát thân**.
- Giới hạn tối đa **3 phi tiêu** cùng lúc trên bản đồ — cần quản lý tài nguyên khôn ngoan.
- Khi to ra, tầm ảnh hưởng lớn hơn nhưng cũng dễ bị trúng phi tiêu hơn.
- Sử dụng chướng ngại vật để cắm phi tiêu vòng ra sau lưng đối thủ.

## 🛠️ Công nghệ

| Thành phần | Công nghệ |
|-----------|-----------|
| Game Engine | **Godot 4.2+** |
| Ngôn ngữ | **GDScript 2.0** |
| Nền tảng mục tiêu | **Android 7.0+** (API 24+) |
| Kiến trúc multiplayer | **Client – Authoritative Server** (planned) |
| Góc nhìn | **2D Top-down** |
| Quỹ đạo phi tiêu | **Đường thẳng** |

## 📁 Cấu trúc project

```
phitieudichchuyen/
├── project.godot              # Cấu hình project Godot
├── export_presets.cfg         # Cấu hình export (Android, Windows, Linux)
├── icon.svg                   # Icon game
├── scenes/
│   ├── main.tscn              # Scene chính (game loop)
│   ├── player.tscn            # Scene nhân vật người chơi
│   ├── dart.tscn              # Scene phi tiêu
│   ├── ai_player.tscn         # Scene AI đối thủ
│   ├── map.tscn               # Scene bản đồ
│   └── hud.tscn               # Scene giao diện
├── scripts/
│   ├── main.gd                # Controller scene chính
│   ├── player.gd              # Logic nhân vật người chơi
│   ├── dart.gd                # Logic phi tiêu (bay, cắm, hết hạn)
│   ├── ai_player.gd           # Logic AI đối thủ
│   ├── map.gd                 # Logic bản đồ & vòng bo
│   ├── hud.gd                 # Logic giao diện
│   └── game_manager.gd        # Singleton quản lý trạng thái toàn cục
├── assets/
│   ├── sprites/               # Hình ảnh sprite
│   └── audio/                 # Âm thanh
└── README.md
```

## 🚀 Cài đặt & Chạy

### Yêu cầu

- **Godot 4.2** trở lên ([tải tại đây](https://godotengine.org/download))
- Để export Android: Android SDK, Java JDK 17+, Android Build Template

### Chạy trên máy tính

1. Clone repository:
   ```bash
   git clone https://github.com/mhieuhonda/phitieudichchuyen.git
   ```
2. Mở Godot Editor → **Import** → Chọn thư mục `phitieudichchuyen`
3. Nhấn **Play** (F5) để chạy

### Export Android

1. Cài đặt Android Build Template: **Project → Install Android Build Template**
2. Cấu hình debug keystore: **Editor → Editor Settings → Export → Android**
3. Chọn **Export** → **Android** → Export APK
4. Cài đặt APK lên thiết bị Android 7.0+

## 🗺️ Lộ trình phát triển

### ✅ v0.1 — Prototype Offline (Giai đoạn 1 & 2)

- [x] Scene bản đồ với tường bao và chướng ngại vật
- [x] Nhân vật người chơi (di chuyển chậm WASD)
- [x] Hệ thống ném phi tiêu (aim & release, đường thẳng)
- [x] Phi tiêu cắm vào bề mặt, thời gian tồn tại 5s
- [x] Dịch chuyển tức thời tới phi tiêu (Space)
- [x] Hệ thống "nuốt" đối thủ khi dịch chuyển trúng
- [x] AI đối thủ đơn giản (wander, aim, throw, teleport)
- [x] HUD (điểm, máu, số phi tiêu, vòng bo)
- [x] Vòng bo thu nhỏ dần
- [x] Hiệu ứng biến mất/xuất hiện khi dịch chuyển
- [x] Kill feed thông báo

### 🔜 v0.2 — Multiplayer cơ bản (Giai đoạn 3)

- [ ] Tích hợp mô hình client-server authoritative
- [ ] 2 người chơi kết nối cùng phòng
- [ ] Đồng bộ vị trí nhân vật & trạng thái phi tiêu
- [ ] Server quyết định kết quả dịch chuyển
- [ ] Client-side prediction & server reconciliation
- [ ] Xử lý lag cơ bản

### 📋 v0.3 — Hoàn thiện gameplay (Giai đoạn 4)

- [ ] Hỗ trợ 8–20 người chơi
- [ ] Cơ chế phát triển kích thước chi tiết hơn
- [ ] Vòng bo nâng cao (nhiều phase, hiệu ứng)
- [ ] Bảng xếp hạng realtime
- [ ] Menu chính, tạo phòng, quick join
- [ ] Respawn sau khi chết

### 🎨 v1.0 — Polish & mở rộng (Giai đoạn 5)

- [ ] Skin nhân vật & phi tiêu
- [ ] Kỹ năng đặc biệt (phi tiêu nổ, phi tiêu làm chậm, khói)
- [ ] Chế độ chơi: Team battle, Capture the Flag
- [ ] Hiệu ứng âm thanh & hình ảnh
- [ ] Rung màn hình khi dịch chuyển
- [ ] Tối ưu hóa mobile

## ⚙️ Cấu hình game

Các thông số có thể điều chỉnh trong `scripts/game_manager.gd`:

| Tham số | Mặc định | Mô tả |
|---------|----------|-------|
| `max_darts_per_player` | 3 | Số phi tiêu tối đa cùng lúc |
| `dart_lifetime` | 5.0s | Thời gian phi tiêu tồn tại |
| `dart_speed` | 800.0 | Tốc độ phi tiêu |
| `walk_speed` | 80.0 | Tốc độ đi bộ |
| `teleport_kill_radius` | 40.0 | Bán kính "nuốt" khi dịch chuyển |
| `dart_hit_damage` | 25.0 | Sát thương phi tiêu trúng |
| `score_per_kill` | 100 | Điểm mỗi lần tiêu diệt |
| `size_per_kill` | 5.0 | Tăng kích thước mỗi lần tiêu diệt |
| `zone_shrink_interval` | 30.0s | Thời gian giữa các lần thu nhỏ vòng bo |
| `zone_damage_per_second` | 10.0 | Sát thương ngoài vòng bo |
| `num_ai_players` | 5 | Số AI đối thủ |

## 🎯 Thiết kế

### Quyết định thiết kế

| Câu hỏi | Quyết định | Lý do |
|---------|-----------|-------|
| Góc nhìn | **2D Top-down** | Phù hợp mobile, dễ code, chiến thuật đa hướng |
| Quỹ đạo phi tiêu | **Đường thẳng** | Phù hợp top-down, bắn nhanh, dễ dự đoán |
| Di chuyển thường | **Đi bộ chậm (WASD)** | Giúp né tránh nhẹ, nhưng phi tiêu vẫn là phương thức chính |
| Engine | **Godot 4** | Miễn phí, hỗ trợ Android tốt, GDScript dễ tiếp cận |

### Kiến trúc multiplayer (planned)

```
┌──────────┐     Input      ┌──────────────┐    State     ┌──────────┐
│  Client  │ ──────────────► │  Authoritative│ ──────────► │  Client  │
│  (Player)│                 │    Server     │              │  (Other) │
│          │ ◄────────────── │              │ ◄─────────── │          │
│          │  Prediction +   │              │  Interpolated│          │
│          │  Reconciliation │              │  State       │          │
└──────────┘                 └──────────────┘              └──────────┘
```

## 📜 Giấy phép

Dự án này được phát hành dưới giấy phép **MIT License**. Xem chi tiết tại file `LICENSE`.

## 👥 Đóng góp

Mọi đóng góp đều được hoan nghênh! Vui lòng:

1. Fork repository
2. Tạo feature branch (`git checkout -b feature/amazing-feature`)
3. Commit thay đổi (`git commit -m 'Add amazing feature'`)
4. Push lên branch (`git push origin feature/amazing-feature`)
5. Tạo Pull Request

---

<div align="center">

**Phi Tiêu Dịch Chuyển** — Ném. Dịch. Nuốt. 🎯

</div>
