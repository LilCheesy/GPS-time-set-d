# 📘 Chuyển đổi flutter_map → trackasia_gl

> Tài liệu này được viết cho các model AI (Claude, GPT, v.v.) hiểu rõ toàn bộ tiến trình migration từ `flutter_map` sang `trackasia_gl` trong dự án Flutter front-end.

---

## 📌 Mục đích của file này

Cung cấp **toàn bộ context cần thiết** để một model có thể:
1. Hiểu **tại sao** phải thay đổi (không chỉ **làm gì**).
2. Áp dụng migration **chính xác** mà không làm hỏng logic hiện có.
3. Nhận diện đâu là phần code **được phép sửa** và đâu là phần **không được động tới**.

---

## 1. Bối cảnh & Tại sao phải migration

### Vấn đề kỹ thuật

| Thành phần | flutter_map | trackasia_gl |
|---|---|---|
| Loại tile | **Raster tiles** (`.png`) | **Vector tiles** (`.pbf`) |
| Render engine | Flutter widget-based | WebGL (MapLibre Native) |
| Marker support | Widget overlay dễ dàng | Symbol layer / custom widget overlay |
| Polylines | `PolylineLayer` widget | `LineLayer` (addLine API) |
| Camera control | `mapController.move()` | `_mapController.animateCamera()` |
| Fit bounds | `CameraFit.bounds()` | `CameraUpdate.newLatLngBounds()` |

### Lý do bắt buộc chuyển

- TrackAsia **chỉ phục vụ vector tiles** (`*.pbf`) — không hỗ trợ raster tiles (`*.png`).
- `flutter_map` chỉ có thể hiển thị **raster tiles** → không thể hiển thị bản đồ TrackAsia chính hãng.
- `trackasia_gl` là **Flutter SDK chính thức** của TrackAsia, wrapper quanh MapLibre GL Native, hỗ trợ render vector tiles qua WebGL.
- **Style URL chuẩn TrackAsia**:
  ```
  https://tiles.track-asia.com/tiles/v3/style-basic.json?key={API_KEY}
  ```

### Phạm vi thay đổi

```
┌─────────────────────────────────────────────────┐
│ ✅ THAY ĐỔI (render layer)                      │
│   • Dependencies                                │
│   • SOS Screen (map display)                    │
│   • Shared Widgets (ambulance marker overlay)   │
│   • Providers (LatLng import source)            │
│   • Utilities (polyline decoder LatLng ref)     │
├─────────────────────────────────────────────────┤
│ ❌ KHÔNG THAY ĐỔI                              │
│   • Backend Spring Boot                         │
│   • State management (Riverpod) logic           │
│   • SOS routing / backend API                   │
│   • Data models (SosRequest, SosResponse...)    │
│   • UI không liên quan bản đồ                   │
│     - sos_fab.dart                              │
│     - navigation_info_panel.dart                │
│     - facility_list_sheet.dart                  │
└─────────────────────────────────────────────────┘
```

---

## 2. Dependencies — `pubspec.yaml`

### Xoá
```yaml
flutter_map: ^6.1.0
latlong2: ^0.9.1
```

### Thêm
```yaml
trackasia_gl: ^0.1.0
```

### Lưu ý
- `latlong2` **không còn cần thiết** vì `trackasia_gl` cung cấp class `LatLng` riêng (trong package `trackasia_gl`).
- Tất cả các file import `package:latlong2/latlong.dart` phải được cập nhật sang `package:trackasia_gl/trackasia_gl.dart`.
- Class `LatLng` cũ (latlong2) và class `LatLng` mới (trackasia_gl) có cùng interface (lat, lng) nhưng là **hai class khác nhau** → không thể cross-assign.

---

## 3. Mapping tham chiếu API

### 3.1 Widget bản đồ

| flutter_map | trackasia_gl |
|---|---|
| `FlutterMap()` | `TrackasiaMap()` |
| `MapController()` | `TrackasiaMapController()` |

### 3.2 Tile / Style

| flutter_map | trackasia_gl |
|---|---|
| `TileLayer(urlTemplate: '...')` | `styleString: 'https://tiles.track-asia.com/tiles/v3/style-basic.json?key={API_KEY}'` trong `TrackasiaMap()` |
| Tile layer config qua `tileProvider` | Style định nghĩa vector tile source bên trong JSON |

### 3.3 Camera control

| Hành động | flutter_map (cũ) | trackasia_gl (mới) |
|---|---|---|
| Move camera tới vị trí | `_mapController.move(LatLng(lat, lng), zoom)` | `_mapController.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), zoom))` |
| Fit bounds | `_mapController.fitCamera(CameraFit.bounds(...))` | `_mapController.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds.fromLLBounds(...)))` |

### 3.4 Markers

| flutter_map (cũ) | trackasia_gl (mới) |
|---|---|
| `MarkerLayer(markers: [...])` + Flutter widget (Icon, GestureDetector) | Dùng **SymbolLayer** qua `addSymbol()` hoặc đặt **custom widget overlay** (Positioned) trên `Stack` bao quanh `TrackasiaMap()` |

> ⚠️ **Lưu ý quan trọng về markers**: `trackasia_gl` không render Flutter widget trực tiếp trên bản đồ như `flutter_map` làm. Có 2 cách:
> 1. **SymbolLayer (khuyến nghị cho đông markers)**: Dùng `addSymbol()` với icon image — phức tạp, cần pre-load icon.
> 2. **Widget Overlay (đơn giản, phù hợp số ít markers)**: Đặt `TrackasiaMap()` trong `Stack`, rồi đặt các widget ambulance icon lên trên bằng `Positioned` — convert geo-coordinate sang pixel position qua `_mapController.toScreenLocation()`.

### 3.5 Polylines

| flutter_map (cũ) | trackasia_gl (mới) |
|---|---|
| `PolylineLayer(polylines: [...])` | `_mapController.addLine(...)` hoặc dùng `LineLayer` |
| `Polyline(points: [...], color: ..., strokeWidth: ...)` | `LineOptions(line: ..., lineColor: ..., lineWidth: ...)` |

---

## 4. Chi tiết từng file cần thay đổi

### 4.1 `pubspec.yaml`

```yaml
# XOÁ những dòng này:
# flutter_map: ^6.1.0
# latlong2: ^0.9.1

# THÊM:
dependencies:
  trackasia_gl: ^0.1.0
```

---

### 4.2 `lib/screens/sos_screen.dart` — THAY ĐỔI LỚN NHẤT

Đây là nơi chứa widget `FlutterMap()`. Viết lại toàn bộ phần bản đồ.

#### Import cũ → mới
```dart
// XOÁ:
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';

// THÊM:
import 'package:trackasia_gl/trackasia_gl.dart';
```

#### Cấu trúc widget mới

```dart
// WIDGET BẢN ĐỒ MỚI:
TrackasiaMap(
  styleString: 'https://tiles.track-asia.com/tiles/v3/style-basic.json?key=$apiKey',
  initialCameraPosition: const CameraPosition(
    target: LatLng(21.0285, 105.8542), // Hà Nội mặc định
    zoom: 14,
  ),
  onMapCreated: (TrackasiaMapController controller) {
    _mapController = controller;
    // Sau khi map sẵn sàng, có thể move camera hoặc thêm markers
  },
  onStyleLoadedCallback: () {
    // Style đã load xong — có thể thêm symbols / lines ở đây
  },
  myLocationEnabled: true,
  myLocationTrackingMode: MyLocationTrackingMode.Tracking,
  // ... các thuộc tính khác theo nhu cầu
)
```

#### Thay thế camera actions

```dart
// CŨ:
_mapController.move(LatLng(lat, lng), zoom);
_mapController.fitCamera(CameraFit.bounds(
  bounds: LatLngBounds.fromPoints([p1, p2]),
  padding: EdgeInsets.all(50),
));

// MỚI:
_mapController.animateCamera(
  CameraUpdate.newLatLngZoom(LatLng(lat, lng), zoom),
);
_mapController.animateCamera(
  CameraUpdate.newLatLngBounds(
    LatLngBounds.fromLLBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    ),
    padding: 50,
  ),
);
```

#### Markers overlay (nếu dùng widget overlay)

```dart
Stack(
  children: [
    TrackasiaMap(...),  // Bản đồ nền
    // Overlay markers:
    if (_userPosition != null)
      Positioned(
        // Convert geo → pixel:
        left: _mapController.toScreenLocation(_userPosition).x,
        top: _mapController.toScreenLocation(_userPosition).y,
        child: AmbulanceIconWidget(...),  // custom widget từ shared/
      ),
  ],
)
```

> 💡 Khi map move/zoom, cần gọi `setState()` hoặc dùng listener để cập nhật lại vị trí pixel của các overlay markers. Có dùng `_mapController.addListener(() => setState(() {}))`.

---

### 4.3 `lib/shared/moving_ambulance_icon.dart`

#### Xoá
```dart
// import 'package:flutter_map/flutter_map.dart';
// class Marker { ... }  // FlutterMap marker
```

#### Thay bằng overlay widget đơn thuần

```dart
// File này chỉ export một Widget (Stateless/Stateful)
// Được đặt lên bản đồ qua Positioned trong Stack
// Không dùng Marker, không dùng SymbolLayer trong file này

class AmbulanceIconWidget extends StatelessWidget {
  final double size;
  final String? assetPath;
  // ...
  
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath ?? 'assets/images/ambulance.png',
      width: size,
      height: size,
    );
  }
}
```

> Lưu ý: Nếu dùng SymbolLayer thì cần đăng ký icon image với trackasia_gl controller trước — phức tạp hơn overlay widget. **Khuyến nghị dùng overlay widget** vì số lượng markers trong app này không lớn (SOS + facilities).

---

### 4.4 `lib/providers/sos_provider.dart`

```dart
// XOÁ:
// import 'package:latlong2/latlong.dart';

// THÊM:
import 'package:trackasia_gl/trackasia_gl.dart';

// Tất cả LatLng(...) giữ nguyên (cùng constructor signature)
// Nhưng đảm bảo import đúng là từ trackasia_gl
```

#### Kiểm tra các nơi dùng LatLng:
- State `currentPosition: LatLng?` → giữ nguyên type
- State `facilities: List<FacilityInfo>` → các `FacilityInfo` chứa `LatLng` phải dùng đúng class từ `trackasia_gl`
- Method emit map events → chuyển `LatLng` arguments phù hợp

---

### 4.5 `lib/providers/location_provider.dart`

```dart
// XOÁ:
// import 'package:latlong2/latlong.dart';

// THÊM:
import 'package:trackasia_gl/trackasia_gl.dart';

// Các LocationData / Position wrapper không đổi
// Chỉ thay nơi convert vị trí thành LatLng:
// CŨ: LatLng(position.latitude, position.longitude)  // latlong2
// MỚI: LatLng(position.latitude, position.longitude)  // trackasia_gl (cùng API)
```

---

### 4.6 `lib/utils/polyline_decoder.dart`

```dart
// XOÁ:
// import 'package:latlong2/latlong.dart';

// THÊM:
import 'package:trackasia_gl/trackasia_gl.dart';

// DecodedLatLng hoặc class chứa LatLng phải import từ trackasia_gl
// Logic decode polyline string → List<LatLng> giữ nguyên
```

---

## 5. Các file KHÔNG THAY ĐỔI

| File | Lý do |
|---|---|
| `lib/fab/sos_fab.dart` | Chỉ chứa FAB button, không liên quan map |
| `lib/panels/navigation_info_panel.dart` | Hiển thị thông tin navigation, không trực tiếp render map |
| `lib/sheets/facility_list_sheet.dart` | Bottom sheet list facility, không liên quan map |
| `lib/main.dart` | Entry point — chỉ cần thêm Trackasia API key (nếu chưa có) |
| `backjavaspring/**/*` | Backend Spring Boot — hoàn toàn không liên quan |

---

## 6. API Key & Config

### Lấy API key TrackAsia
1. Đăng ký tại [track-asia.com](https://track-asia.com)
2. Tạo account, tạo API key
3. Thêm vào `.env`:
   ```env
   TRACKASIA_API_KEY=your_key_here
   ```
4. Thêm `flutter_dotenv` dependency (nếu chưa có) và load trong `main.dart`

### Style URL format
```
https://tiles.track-asia.com/tiles/v3/style-basic.json?key={API_KEY}
```
- `style-basic.json` — style cơ bản, có thể thay bằng style khác (dark, satellite...) nếu TrackAsia cung cấp.

---

## 7. Web Platform (Edge) — Lưu ý đặc biệt

### Vấn đề WebGL
- `trackasia_gl` render bản đồ qua **WebGL**.
- Trên Web (Edge), cần đảm bảo Edge cho phép WebGL:
  - Vào `edge://settings/content/unsafeWebGpu` — nếu bị tắt thì bản đồ sẽ trắng hoặc lỗi.
  - Kiểm tra `edge://gpu` — xem WebGL status có "Hardware accelerated" không.

### Fallback nếu WebGL lỗi
- Có thể dùng `flutter_map` với **raster fallback** (TileLayer với tile server public) cho Web, và `trackasia_gl` cho mobile.
- Nhưng theo yêu cầu hiện tại → **chuyển hoàn toàn sang trackasia_gl**, bao gồm Web.

### Android emulator / thiết bị thật
- `trackasia_gl` hoạt động tốt hơn trên native platform (Android/iOS) do OpenGL/Vulkan native.
- **Khuyến nghị**: Test trên Android emulator trước, sau đó mới lên Web.

---

## 8. Verification Plan

### Manual Testing Checklist

- [ ] App chạy được, không crash khi load `TrackasiaMap()`
- [ ] Bản đồ hiển thị đúng style TrackAsia (các đường, tòa nhà, icon theo style-basic)
- [ ] Marker "Xe cấp cứu" của user hiển thị đúng vị trí
- [ ] Marker các cơ sở y tế hiện khi quét
- [ ] Polyline route vẽ đúng từ user → facility gần nhất
- [ ] Nút SOS vẫn hoạt động (scan, hiển thị markers, vẽ route)
- [ ] Camera tự động di chuyển về vị trí thật của user khi khởi động
- [ ] Fit bounds hoạt động khi có nhiều facilities
- [ ] Không có error LatLng type mismatch trong console

### Regression Testing (không được phá vỡ)
- [ ] SOS flow: bấm nút → quét facilities → chọn facility → hiển thị route
- [ ] Riverpod state management vẫn ổn (không có error về provider)
- [ ] Backend API calls vẫn hoạt động (SOS request, facility list)
- [ ] Navigation info panel hiển thị thông tin đúng (thời gian, khoảng cách)

---

## 9. Troubleshooting phổ biến

### ❌ "TrackasiaMap renders blank/white"
- Check API key có đúng và còn hạn không
- Check Style URL đúng format
- Check WebGL được bật trên trình duyệt

### ❌ "LatLng type mismatch error"
- Đảm bảo **tất cả** file đã xoá import `latlong2` và thay bằng `trackasia_gl`
- Search toàn project: `grep -r "latlong2" lib/`
- Search toàn project: `grep -r "package:latlong2" lib/`

### ❌ "Markers không hiển thị"
- Nếu dùng SymbolLayer: đảm bảo đã gọi `addImage()` trước khi `addSymbol()`
- Nếu dùng widget overlay: đảm bảo `toScreenLocation()` được gọi **sau khi map ready** (trong `onMapCreated` hoặc `onStyleLoadedCallback`)

### ❌ "Polyline không vẽ"
- Check `addLine()` được gọi **sau** `onStyleLoadedCallback`
- Kiểm tra `LineOptions` có chứa đủ `coordinates`

### ❌ "Camera không di chuyển"
- `animateCamera` chỉ hoạt động khi `_mapController` đã được khởi tạo (trong `onMapCreated`)
- Đảm bảo không gọi camera action trước khi map ready

---

## 10. Roadmap Migration (thứ tự thực hiện)

```
Step 1: Cập nhật pubspec.yaml
        └─ flutter_run pub get

Step 2: Cập nhật imports LatLng trong providers & utils
        └─ sos_provider.dart, location_provider.dart, polyline_decoder.dart

Step 3: Viết lại sos_screen.dart (map widget)
        └─ Thay FlutterMap → TrackasiaMap
        └─ Thay MarkerLayer → widget overlay hoặc SymbolLayer
        └─ Thay PolylineLayer → addLine()

Step 4: Cập nhật moving_ambulance_icon.dart
        └─ Xoá flutter_map Marker dependency
        └─ Chuyển sang StatelessWidget đơn thuần

Step 5: Đảm bảo API key được inject đúng

Step 6: Test trên Android emulator
        └─ Chạy: flutter run -d emulator-5554

Step 7: (Optional) Test trên Web
        └─ Chạy: flutter run -d chrome
        └─ Kiểm tra WebGL hoạt động

Step 8: Full regression test
        └─ SOS flow, routing, state management
```

---

## 11. Ghi chú cho model AI khi đọc code

> Khi bạn (model) đọc code Flutter hiện tại và cần áp dụng migration:
> 1. **Đọc file này trước** — hiểu mapping API ở mục 3.
> 2. **Đừng đoán API của trackasia_gl** — reference chính xác là code mẫu trong mục 4.
> 3. **Giữ nguyên logic Riverpod** — chỉ thay cách render bản đồ, không thay state logic.
> 4. **Kiểm tra import** — đây là lỗi phổ biến nhất. `package:latlong2` → `package:trackasia_gl`.
> 5. **LatLng constructor signature giữ nguyên**: `LatLng(double latitude, double longitude)` — chỉ khác package import.
> 6. **Marker → Overlay là thay đổi lớn nhất** về UX — marker không còn là Flutter widget con của map nữa.

---

*File này được tạo để model AI hiểu đầy đủ tiến trình migration. Mọi thay đổi liên quan đến bản đồ đều nên refer lại đây.*
