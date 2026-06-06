# CareBridge SOS - App (Flutter)

Ứng dụng di động hỗ trợ tìm kiếm cơ sở y tế khẩn cấp (SOS) và dẫn đường theo thời gian thực.
Được xây dựng bằng Flutter, kết hợp engine vẽ bản đồ `maplibre_gl` và hệ thống dữ liệu API của TrackAsia.

## Tính năng chính
- Tìm kiếm cơ sở y tế gần nhất trong bán kính 10km (hỗ trợ Bệnh viện, Trạm y tế, Phòng khám).
- Tự động lấy tọa độ GPS người dùng.
- Hiển thị bản đồ vector 2D/3D mượt mà.
- Dẫn đường (Turn-by-turn routing) ngay trên bản đồ với tính năng Auto-zoom thông minh.

## Cài đặt & Sử dụng

### 1. Yêu cầu môi trường
- Flutter SDK (phiên bản hỗ trợ Null Safety).
- Máy ảo (Emulator) hoặc thiết bị thật (Android/iOS).

### 2. Thiết lập API Key
Dự án yêu cầu TrackAsia API Key để tải bản đồ và tìm đường.
1. Tạo một file tên là `.env` ở thư mục gốc của `frontflutter`.
2. Thêm dòng sau vào file `.env`:
   ```env
   TRACKASIA_API_KEY=your_api_key_here
   ```

### 3. Chạy ứng dụng
Mở Terminal tại thư mục `frontflutter` và chạy:
```bash
# Tải các thư viện phụ thuộc
flutter pub get

# Chạy ứng dụng trên thiết bị
flutter run
```

## Công nghệ sử dụng
- **MapLibre GL:** Render bản đồ vector.
- **TrackAsia API:** Cung cấp Tiles bản đồ, Tìm kiếm địa điểm (Places), và Dẫn đường (Routing).
- **Riverpod:** Quản lý State.
- **Geolocator:** Bắt tọa độ GPS.
