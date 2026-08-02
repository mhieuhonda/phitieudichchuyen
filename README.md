# 🎯 Phi Tiêu Dịch Chuyển

> **Ném phi tiêu – Dịch chuyển – Nuốt đối thủ!**
> Game 2D top-down kết hợp cơ chế ném phi tiêu và dịch chuyển tức thời, lấy cảm hứng từ game "rắn nuốt nhau".

---

## 📖 Giới thiệu

**Phi Tiêu Dịch Chuyển** là một tựa game kết hợp hai cơ chế chính:

- **Ném phi tiêu**: Người chơi nhắm hướng, chọn lực để phóng một phi tiêu bay theo quỹ đạo vật lý. Phi tiêu có thể cắm vào bề mặt (tường, sàn) hoặc trúng người chơi khác.
- **Dịch chuyển tức thời**: Khi phi tiêu đã cắm **hoặc đang bay**, người chơi có thể kích hoạt để lập tức dịch chuyển nhân vật tới vị trí phi tiêu.

### ⚡ Cơ chế Mid-Flight Teleport (v0.2)

**Nhấn Space khi phi tiêu ĐANG BAY** để dịch chuyển tới vị trí phi tiêu giữa không trung! Tạo ra pha "rush" cực nhanh và cảm giác chiến thuật độc đáo.

### 🎨 Sprite & Đồ họa (v0.3)

Nhân vật, phi tiêu, vật phẩm đều có sprite đẹp mắt thay vì hình chữ nhật đơn sắc. Hỗ trợ cài đặt đồ họa từ Cực Thấp đến Cao.

### 📱 Mobile Controls (v0.3)

Joystick ảo + nút bấm Teleport/Throw cho người chơi mobile. Tự động hiển thị trên Android.

### 🔧 CI/CD Fixed (v0.4)

GitHub Actions tự động build APK (Android), EXE (Windows), và binary (Linux) mỗi khi tạo release. Tất cả artefact được upload lên GitHub Release.

## 🎮 Cách chơi

### Điều khiển PC

| Phím | Hành động |
|------|-----------|
| **WASD / Mũi tên** | Di chuyển chậm (đi bộ) |
| **Chuột phải (giữ & kéo)** | Nhắm hướng và lực ném phi tiêu |
| **Chuột phải (thả)** | Ném phi tiêu |
| **Space** | Dịch chuyển tới phi tiêu (cắm hoặc đang bay) |
| **ESC** | Quay lại menu |

### Điều khiển Mobile

| Nút | Hành động |
|-----|-----------|
| **Joystick (trái)** | Di chuyển |
| **Nút ⚡ (phải)** | Dịch chuyển tới phi tiêu |
| **Nút 🎯 (phải)** | Ném phi tiêu |

### Cơ chế chính

1. **Ném phi tiêu**: Kéo chuột phải / nhấn nút Throw để chọn hướng và lực ném. Phi tiêu bay theo đường thẳng.
2. **Cắm phi tiêu**: Va chạm tường/sàn/chướng ngại vật → cắm lại, tồn tại 5s.
3. **Dịch chuyển tới phi tiêu đã cắm**: Space → teleport tới vị trí phi tiêu.
4. **⚡ Dịch chuyển giữa chừng**: Space khi phi tiêu đang bay → teleport tới vị trí phi tiêu giữa không trung.
5. **Nuốt đối thủ**: Dịch chuyển trúng đối thủ → tiêu diệt, +kích thước, +điểm.
6. **Phi tiêu trúng người**: Gây sát thương (25 HP).
7. **Vòng bo**: Vùng an toàn thu nhỏ nhanh dần, gây sát thương ngoài vùng.
8. **Combo**: Tiêu diệt liên tiếp → cộng điểm nhân.
9. **Vật phẩm**: Hồi máu (xanh) và hồi phi tiêu (vàng).
10. **Respawn**: Tự động respawn sau 3s.

## 🛠️ Công nghệ

| Thành phần | Công nghệ |
|-----------|-----------|
| Game Engine | **Godot 4.2+** |
| Ngôn ngữ | **GDScript 2.0** |
| Nền tảng | **Android 7.0+**, Windows, Linux |
| Đồ họa | **Sprite PNG** (tự tạo bằng Python/Pillow) |
| Mobile Controls | **Joystick ảo + Touch buttons** |
| CI/CD | **GitHub Actions** (auto-build APK + EXE + Linux) |

## 📁 Cấu trúc project

```
phitieudichchuyen/
├── project.godot
├── export_presets.cfg
├── .github/workflows/build-release.yml
├── assets/sprites/              # Sprite PNG (tự tạo)
│   ├── player_blue.png          # Nhân vật người chơi
│   ├── ai_*.png                 # 10 sprite AI khác màu
│   ├── dart.png                 # Phi tiêu
│   ├── pickup_health.png        # Vật phẩm hồi máu
│   ├── pickup_dart.png          # Vật phẩm hồi phi tiêu
│   ├── joystick_base.png        # Joystick (vòng ngoài)
│   ├── joystick_stick.png       # Joystick (cần)
│   ├── btn_teleport.png         # Nút dịch chuyển
│   └── btn_throw.png            # Nút ném phi tiêu
├── scenes/
│   ├── main.tscn, menu.tscn, settings.tscn
│   ├── player.tscn, dart.tscn, ai_player.tscn
│   ├── map.tscn, pickup.tscn, hud.tscn
│   ├── virtual_joystick.tscn, mobile_controls.tscn
├── scripts/
│   ├── game_manager.gd, settings_manager.gd
│   ├── player.gd, dart.gd, ai_player.gd
│   ├── map.gd, pickup.gd, hud.gd
│   ├── main.gd, menu.gd, settings_menu.gd
│   ├── virtual_joystick.gd, mobile_controls.gd
```

## 🚀 Cài đặt & Chạy

### Yêu cầu
- **Godot 4.2+** ([tải](https://godotengine.org/download))
- Android: Android SDK, JDK 17+, Android Build Template

### Chạy
```bash
git clone https://github.com/mhieuhonda/phitieudichchuyen.git
# Mở Godot Editor → Import → F5
```

### Tải
Mỗi release trên GitHub có **APK đã ký** (Android), **EXE** (Windows), **Linux binary** tự động build bởi GitHub Actions. Tải từ [Releases](https://github.com/mhieuhonda/phitieudichchuyen/releases).

## 🗺️ Lộ trình phát triển

> **Multiplayer sẽ được thêm ở giai đoạn sau.** Hiện tại tập trung hoàn thiện single-player.

### ✅ v0.1 — Prototype Offline
- Hệ thống ném phi tiêu, cắm, dịch chuyển cơ bản
- AI đơn giản, HUD cơ bản

### ✅ v0.2 — Hoàn thiện Gameplay
- **Mid-Flight Teleport**: Dịch chuyển tới phi tiêu đang bay
- Combo system, respawn, vật phẩm, screen shake
- AI thông minh (né tránh, săn mồi, lead aim)
- Menu chính, GitHub Actions

### ✅ v0.3 — Polish & Mobile
- **Sprite đẹp**: Nhân vật có mắt, miệng, bóng; phi tiêu có cánh; vật phẩm có icon
- **Cài đặt đồ họa**: Cực Thấp / Thấp / Trung Bình / Cao
- **Joystick ảo**: Di chuyển bằng joystick cho mobile
- **Mobile controls**: Nút Teleport + Throw cho mobile
- **Auto-detect mobile**: Tự động hiển thị joystick trên Android
- **FPS counter**: Hiển thị FPS (bật/tắt trong Settings)
- **Screen shake toggle**: Bật/tắt rung màn hình
- **Âm thanh**: Volume slider (chuẩn bị cho v0.4)

### ✅ v0.4 — CI/CD Fix
- **Sửa toàn bộ GitHub Actions**: Build APK + EXE + Linux trơn tru
- **Loại bỏ `--install-android-build-template`** (không cần cho Godot 4.2+ Gradle build)
- **Sửa lỗi import headless** — dùng `timeout` thay vì `sleep`
- **Sửa lỗi keystore** — dùng Python patching thay vì sed
- **Embed PCK** cho Windows & Linux (phân phối 1 file duy nhất)
- **Build Linux/X11** và upload ZIP lên release
- **ZIP packaging** cho Windows build
- **Verify step** sau mỗi lần export
- **Gộp 2 job thành 1** — tối ưu, tránh lặp setup

### 🔜 v0.5 — Âm thanh & Kỹ năng
- [ ] Hiệu ứng âm thanh (ném, cắm, dịch chuyển, chết, combo)
- [ ] Nhạc nền
- [ ] Kỹ năng đặc biệt: phi tiêu nổ, phi tiêu làm chậm, phi tiêu khói
- [ ] Mini-map
- [ ] Bảng xếp hạng trong game
- [ ] Chế độ chơi: Survival, Time Attack
- [ ] Touch controls nâng cao (aim bằng kéo thả trên mobile)

### 📋 v0.6 — Multiplayer
- [ ] Client-server authoritative
- [ ] 2+ người chơi online
- [ ] Đồng bộ & lag handling

## ⚙️ Cài đặt đồ họa

| Mức | Particle | Glow | Trail | Predicted Line |
|------|----------|------|-------|---------------|
| Cực Thấp | Tắt | Tắt | Tắt | Tắt |
| Thấp | 30% | Tắt | Bật | Bật |
| Trung Bình | 70% | Bật | Bật | Bật |
| Cao | 100% | Bật | Bật | Bật |

## 📜 Giấy phép

MIT License. Xem file `LICENSE`.

---

<div align="center">

**Phi Tiêu Dịch Chuyển** — Ném. Dịch. Nuốt. 🎯

</div>
