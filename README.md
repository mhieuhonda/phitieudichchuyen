# 🎯 Phi Tiêu Dịch Chuyển

> **Ném phi tiêu – Dịch chuyển – Nuốt đối thủ!**
> Game 2D top-down kết hợp cơ chế ném phi tiêu và dịch chuyển tức thời, lấy cảm hứng từ game "rắn nuốt nhau".

---

## 📖 Giới thiệu

**Phi Tiêu Dịch Chuyển** là một tựa game kết hợp hai cơ chế chính:

- **Ném phi tiêu**: Người chơi nhắm hướng, chọn lực để phóng một phi tiêu bay theo quỹ đạo vật lý. Phi tiêu có thể cắm vào bề mặt (tường, sàn) hoặc trúng người chơi khác.
- **Dịch chuyển tức thời**: Khi phi tiêu đã cắm **hoặc đang bay**, người chơi có thể kích hoạt để lập tức dịch chuyển nhân vật tới vị trí phi tiêu.

Phong cách chơi lấy cảm hứng từ game "rắn nuốt nhau": nhiều người cùng tham gia một bản đồ, tiêu diệt lẫn nhau để phát triển kích thước/điểm số. Điểm khác biệt cốt lõi: thay vì di chuyển liên tục, người chơi di chuyển giật đoạn qua các cú dịch chuyển, tạo ra chiều sâu chiến thuật và cảm giác "săn mồi" độc đáo.

### ⚡ Cơ chế mới v0.2: Dịch chuyển giữa chừng (Mid-Flight Teleport)

**Bạn có thể dịch chuyển tới phi tiêu KHI NÓ ĐANG BAY!** Đây là cơ chế thay đổi hoàn toàn cách chơi:

- Ném phi tiêu → ngay lập tức nhấn Space → dịch chuyển tới vị trí phi tiêu đang bay giữa không trung
- Tạo ra pha "rush" cực nhanh: ném phi tiêu về phía đối thủ, dịch chuyển theo ngay lập tức để "nuốt" họ
- Phi tiêu có đường dự đoán (predicted line) khi bay, giúp bạn quyết định thời điểm dịch chuyển
- AI cũng có thể sử dụng cơ chế này, tạo ra đối thủ thông minh và nguy hiểm hơn

## 🎮 Cách chơi

### Điều khiển

| Phím | Hành động |
|------|-----------|
| **WASD / Mũi tên** | Di chuyển chậm (đi bộ) |
| **Chuột phải (giữ & kéo)** | Nhắm hướng và lực ném phi tiêu |
| **Chuột phải (thả)** | Ném phi tiêu |
| **Space** | Dịch chuyển tới phi tiêu (cắm hoặc đang bay) |
| **ESC** | Quay lại menu |

### Cơ chế chính

1. **Ném phi tiêu**: Kéo chuột phải để chọn hướng và lực ném. Phi tiêu bay theo đường thẳng trong không gian 2D top-down. Đường dự đoán (predicted line) hiển thị khi phi tiêu đang bay.

2. **Cắm phi tiêu**: Khi phi tiêu va chạm với tường, sàn hoặc chướng ngại vật, nó sẽ cắm lại tại vị trí đó. Phi tiêu tồn tại trong **5 giây** rồi tự biến mất (nhấp nháy cảnh báo trước 1.5s).

3. **Dịch chuyển tới phi tiêu đã cắm**: Nhấn Space để dịch chuyển tức thời tới vị trí phi tiêu đã cắm. Phi tiêu bị tiêu thụ sau khi dịch chuyển.

4. **⚡ Dịch chuyển giữa chừng (MỚI)**: Nhấn Space khi phi tiêu **đang bay** để dịch chuyển tới vị trí hiện tại của phi tiêu giữa không trung. Phi tiêu dừng lại và bị tiêu thụ. Cơ chế này cho phép:
   - **Rush đối thủ**: Ném phi tiêu về phía đối thủ, dịch chuyển ngay để "nuốt" họ
   - **Thoát hiểm**: Ném phi tiêu ra xa, dịch chuyển để thoát khỏi tình thế nguy hiểm
   - **Combo**: Ném nhiều phi tiêu liên tiếp, dịch chuyển qua từng điểm

5. **Nuốt đối thủ**: Nếu dịch chuyển tới vị trí có đối thủ trong bán kính "nuốt", đối thủ bị tiêu diệt. Bạn được tăng kích thước và điểm số.

6. **Phi tiêu trúng người**: Phi tiêu trúng đối thủ gây sát thương (25 HP).

7. **Vòng bo**: Vùng an toàn thu nhỏ dần theo thời gian (nhanh dần), gây sát thương cho người ngoài vùng.

8. **Combo**: Tiêu diệt liên tiếp trong thời gian ngắn được cộng điểm nhân (x1.5, x2.0, x2.5...).

9. **Vật phẩm**: Nhặt vật phẩm hồi máu (xanh) hoặc hồi phi tiêu (vàng) rải trên bản đồ.

10. **Respawn**: Sau khi chết, tự động respawn sau 3 giây tại vị trí ngẫu nhiên trong vùng an toàn.

### Chiến thuật

- **Mid-flight rush**: Ném phi tiêu về phía đối thủ, ngay lập tức Space để dịch chuyển theo và "nuốt" họ — đây là đòn tấn công nguy hiểm nhất
- **Mid-flight escape**: Ném phi tiêu ra xa đối thủ đang săn mình, dịch chuyển để thoát
- **Quản lý phi tiêu**: Giới hạn tối đa 3 phi tiêu cùng lúc — cần quản lý tài nguyên khôn ngoan
- **Kích thước**: Khi to ra, bán kính nuốt lớn hơn nhưng cũng dễ bị trúng phi tiêu hơn
- **Vòng bo**: Cẩn thận với vòng bo thu nhỏ, đứng ngoài vùng sẽ mất máu liên tục
- **Chướng ngại vật**: Dùng chướng ngại vật để cắm phi tiêu vòng ra sau lưng đối thủ

## 🛠️ Công nghệ

| Thành phần | Công nghệ |
|-----------|-----------|
| Game Engine | **Godot 4.2+** |
| Ngôn ngữ | **GDScript 2.0** |
| Nền tảng mục tiêu | **Android 7.0+** (API 24+) |
| Kiến trúc multiplayer | **Client – Authoritative Server** (planned, v0.4+) |
| Góc nhìn | **2D Top-down** |
| Quỹ đạo phi tiêu | **Đường thẳng** |
| CI/CD | **GitHub Actions** (auto-build APK on release) |

## 📁 Cấu trúc project

```
phitieudichchuyen/
├── project.godot              # Cấu hình project Godot
├── export_presets.cfg         # Cấu hình export (Android, Windows, Linux)
├── icon.svg                   # Icon game
├── .github/
│   └── workflows/
│       └── build-release.yml  # GitHub Actions: auto-build APK
├── scenes/
│   ├── main.tscn              # Scene chính (game loop)
│   ├── menu.tscn              # Scene menu chính
│   ├── player.tscn            # Scene nhân vật người chơi
│   ├── dart.tscn              # Scene phi tiêu (bay + cắm + predicted line)
│   ├── ai_player.tscn         # Scene AI đối thủ
│   ├── map.tscn               # Scene bản đồ
│   ├── pickup.tscn            # Scene vật phẩm
│   └── hud.tscn               # Scene giao diện
├── scripts/
│   ├── main.gd                # Controller scene chính + screen shake
│   ├── menu.gd                # Logic menu chính
│   ├── player.gd              # Logic nhân vật (mid-flight teleport)
│   ├── dart.gd                # Logic phi tiêu (bay, cắm, mid-flight, predicted line)
│   ├── ai_player.gd           # Logic AI (mid-flight teleport, dodge, hunt)
│   ├── map.gd                 # Logic bản đồ, vòng bo, pickups
│   ├── pickup.gd              # Logic vật phẩm (hồi máu, hồi phi tiêu)
│   ├── hud.gd                 # Logic giao diện (combo, mid-flight hint)
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

### Tải APK tự động

Mỗi khi tạo bản phát hành (release) mới trên GitHub, **GitHub Actions tự động build APK đã ký** và đính kèm vào release. Tải trực tiếp từ trang [Releases](https://github.com/mhieuhonda/phitieudichchuyen/releases).

## 🗺️ Lộ trình phát triển

> **Lưu ý**: Multiplayer sẽ được thêm ở giai đoạn sau. Hiện tại tập trung hoàn thiện gameplay single-player trước.

### ✅ v0.1 — Prototype Offline

- Scene bản đồ với tường bao và chướng ngại vật
- Nhân vật người chơi (di chuyển chậm WASD)
- Hệ thống ném phi tiêu (aim & release, đường thẳng)
- Phi tiêu cắm vào bề mặt, thời gian tồn tại 5s
- Dịch chuyển tức thời tới phi tiêu (Space)
- Hệ thống "nuốt" đối thủ khi dịch chuyển trúng
- AI đối thủ đơn giản
- HUD cơ bản

### ✅ v0.2 — Hoàn thiện Gameplay (Hiện tại)

- **⚡ Dịch chuyển giữa chừng (Mid-Flight Teleport)**: Nhấn Space khi phi tiêu đang bay để dịch chuyển tới vị trí phi tiêu
- **Đường dự đoán (Predicted Line)**: Hiển thị quỹ đạo dự đoán khi phi tiêu đang bay
- **AI thông minh hơn**: Né tránh phi tiêu, săn mồi, dịch chuyển giữa chừng, lead aim
- **Menu chính**: Màn hình tiêu đề, nút chơi
- **Combo system**: Tiêu diệt liên tiếp được cộng điểm nhân
- **Respawn tự động**: Chết 3s sau tự respawn, không cần restart
- **Vật phẩm**: Hồi máu (xanh) và hồi phi tiêu (vàng) rải trên bản đồ
- **Screen shake**: Rung màn hình khi dịch chuyển/nuốt đối thủ
- **Vòng bo nhanh dần**: Thu nhỏ với tốc độ tăng dần
- **HUD nâng cao**: Combo, kích thước, thời gian, hint mid-flight
- **GitHub Actions**: Auto-build signed APK on release
- **Chướng ngại vật đa dạng**: Hình chữ nhật + hình tròn

### 🔜 v0.3 — Polish & Cân bằng

- [ ] Skin nhân vật & phi tiêu (thay ColorRect bằng sprite đẹp)
- [ ] Hiệu ứng âm thanh (ném, cắm, dịch chuyển, chết, combo)
- [ ] Kỹ năng đặc biệt: phi tiêu nổ, phi tiêu làm chậm, phi tiêu khói
- [ ] Mini-map hiển thị vòng bo và đối thủ
- [ ] Bảng xếp hạng (leaderboard) trong game
- [ ] Chế độ chơi: Survival, Time Attack
- [ ] Cân bằng chi tiết hơn (kích thước vs tốc độ, rủi ro vs phần thưởng)
- [ ] Touch controls cho mobile (joystick ảo + nút)

### 📋 v0.4 — Multiplayer cơ bản

- [ ] Tích hợp mô hình client-server authoritative
- [ ] 2 người chơi kết nối cùng phòng
- [ ] Đồng bộ vị trí nhân vật & trạng thái phi tiêu
- [ ] Server quyết định kết quả dịch chuyển
- [ ] Client-side prediction & server reconciliation
- [ ] Xử lý lag cơ bản

### 🎨 v0.5+ — Hoàn thiện & Mở rộng

- [ ] Hỗ trợ 8–20 người chơi
- [ ] Menu chính nâng cao: tạo phòng, quick join
- [ ] Chế độ chơi: Team battle, Capture the Flag
- [ ] Rung thiết bị (haptic) khi dịch chuyển trên mobile
- [ ] Tối ưu hóa mobile (battery, performance)
- [ ] Anti-cheat cơ bản

## ⚙️ Cấu hình game

Các thông số có thể điều chỉnh trong `scripts/game_manager.gd`:

| Tham số | Mặc định | Mô tả |
|---------|----------|-------|
| `max_darts_per_player` | 3 | Số phi tiêu tối đa cùng lúc |
| `dart_lifetime` | 5.0s | Thời gian phi tiêu tồn tại (cắm) |
| `dart_speed` | 800.0 | Tốc độ phi tiêu |
| `mid_flight_teleport_enabled` | true | Bật/tắt dịch chuyển giữa chừng |
| `walk_speed` | 80.0 | Tốc độ đi bộ |
| `teleport_kill_radius` | 40.0 | Bán kính "nuốt" khi dịch chuyển |
| `dart_hit_damage` | 25.0 | Sát thương phi tiêu trúng |
| `score_per_kill` | 100 | Điểm mỗi lần tiêu diệt |
| `combo_window` | 2.0s | Thời gian giữa các kill để tính combo |
| `max_player_size` | 60.0 | Kích thước tối đa |
| `zone_shrink_interval` | 30.0s | Thời gian giữa các lần thu nhỏ vòng bo |
| `zone_shrink_acceleration` | 1.1 | Vòng bo thu nhỏ nhanh dần |
| `zone_damage_per_second` | 10.0 | Sát thương ngoài vòng bo |
| `num_ai_players` | 5 | Số AI đối thủ |
| `ai_dodge_chance` | 0.4 | Xác suất AI né phi tiêu |
| `ai_mid_flight_teleport_chance` | 0.5 | Xác suất AI dịch chuyển giữa chừng |

## 🎯 Thiết kế

### Quyết định thiết kế

| Câu hỏi | Quyết định | Lý do |
|---------|-----------|-------|
| Góc nhìn | **2D Top-down** | Phù hợp mobile, dễ code, chiến thuật đa hướng |
| Quỹ đạo phi tiêu | **Đường thẳng** | Phù hợp top-down, bắn nhanh, dễ dự đoán |
| Di chuyển thường | **Đi bộ chậm (WASD)** | Giúp né tránh nhẹ, nhưng phi tiêu vẫn là phương thức chính |
| Mid-flight teleport | **Có** | Cơ chế cốt lõi, tạo chiều sâu chiến thuật |
| Engine | **Godot 4** | Miễn phí, hỗ trợ Android tốt, GDScript dễ tiếp cận |
| Multiplayer | **Giai đoạn sau** | Hoàn thiện single-player trước, thêm multiplayer sau |

### Kiến trúc multiplayer (planned - v0.4+)

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
