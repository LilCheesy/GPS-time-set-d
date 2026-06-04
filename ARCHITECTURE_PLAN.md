# 🏥 CareBridge — Architecture Plan
> **Emergency Navigation for Expecting Mothers**
> Maternity Emergency Navigation System — Monolithic, Asynchronous, Zero-Friction

---

## 1. SYSTEM OVERVIEW

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CARE BRIDGE SYSTEM                           │
│                   Monolithic Spring Boot + Flutter                  │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────────────┐         HTTP/REST          ┌──────────────────────────┐
│   🌸 FLUTTER APP         │ ──────────────────────────▶│   🚑 SPRING BOOT BE      │
│   (Mother's Phone)       │◀────────────────────────── │   (Java 21 + PostGIS)    │
│                          │         JSON Response       │                          │
│  ┌────────────────────┐  │                              │  ┌────────────────────┐  │
│  │   SOS Button 🔴    │──│                              │  │  SosController     │  │
│  │   (Only 1 button)  │  │                              │  │  POST /api/sos     │  │
│  └────────┬───────────┘  │                              │  └─────────┬──────────┘  │
│           │               │                              │            │             │
│  ┌────────▼───────────┐  │                              │  ┌─────────▼──────────┐  │
│  │   GPS (2D Lat/Lng) │  │                              │  │  SosService        │  │
│  └────────┬───────────┘  │                              │  │  + PostGIS KNN     │  │
│           │               │                              │  │  + Z-Axis Check    │  │
│  ┌────────▼───────────┐  │                              │  └─────────┬──────────┘  │
│  │  TrackAsia Routing │  │                              │            │             │
│  │  API (polyline 🗺) │  │                              │  ┌─────────▼──────────┐  │
│  └────────────────────┘  │                              │  │  PostgreSQL +      │  │
│                          │                              │  │  PostGIS Extension │  │
│  ┌────────────────────┐  │                              │  │  medical_facilities│  │
│  │  flutter_map 🗺️    │  │                              │  │  user_home_profiles│  │
│  │  + polylines 🛣️    │  │                              │  └────────────────────┘  │
│  │  + moving icon 🚑  │  │                              │                          │
│  └────────────────────┘  │                              │                          │
└──────────────────────────┘                              └──────────────────────────┘
         │                                                       │
         │                    ┌──────────────────────────────────┘
         │                    │
         ▼                    ▼
┌─────────────────────────────────────────┐
│       🌐 TRACK ASIA ROUTING API         │
│   (Open Source — OSRM-based Engine)      │
│   GET /v1/route?point=lat,lng&...       │
│   → Returns: polyline geometry           │
└─────────────────────────────────────────┘

```

---

## 2. ASYNC DATA FLOW — SOS SEQUENCE

```
═══════════════════════════════════════════════════════════════════════════
  TIMELINE (target: complete in 1-2 seconds)
═══════════════════════════════════════════════════════════════════════════

  T+0.0s    👩 MẸ BẦU BẤM NÚT SOS
               │
               ├──────────────────────────────────────┐  (Luồng A — HIỆN ẢNH)
               │                                      │
               ▼                                      │
  T+0.0s    📍 LẤY GPS (lat, lng)                    │
               │                                      │
  T+0.1s    📤 Gửi POST /api/sos                     │
            { lat, lng, userId }                     │
               │                                      │
               │◀─────────────────────────────────────┤  (Luồng B — NGẦM)
  T+0.2s    🚑 BE NHẬN REQUEST                          │
               │                                      │
  T+0.3s    🔍 PostGIS KNN: Tìm bệnh viện gần nhất    │
            SELECT ... ORDER BY location <-> point    │
               │                                      │
  T+0.4s    📏 Tính khoảng cách (Haversine)           │
            + ETA estimation                          │
               │                                      │
  T+0.5s    🔎 Z-AXIS CHECK (NGẦM):                  │
            - User home trong bán kính 50m?           │
            - Nếu CÓ → gắn floor/room vào metadata    │
            - Gửi SMS/call cứu hộ (future)            │
               │                                      │
  T+0.6s    ✅ TRẢ VỀ SosResponse                     │
            { destLat, destLng, facility info,        │
              zMetadata }                             │
               │                                      │
  T+0.7s    📱 FE NHẬN RESPONSE                       │
               │                                      │
  T+0.8s    🗺️ Gọi TrackAsia Routing API             │
            GET /v1/route?point=lat,lng|dest_lat,...  │
               │                                      │
  T+1.0s    📐 Nhận polyline (điểm dạng đường)         │
               │                                      │
  T+1.1s    🖌️ VẼ ĐƯỜNG LÊN MAP                      │
            - Đoạn ĐÃ ĐI → màu XÁM                    │
            - Đoạn CHƯA ĐI → màu ĐỎ                  │
            - Icon 🚑 di chuyển mượt dọc polyline     │
               │                                      │
  T+1.5s    ✅ HOÀN TẤT — MẸ BẦU THẤY ĐƯỜNG          │
═══════════════════════════════════════════════════════════════════════════

  LUỒNG A (HIỆN ẢNH):   SOS → GPS → Gửi BE → Nhận đích → Vẽ đường → XONG
  LUỒNG B (NGẦM):       SOS → BE → KNN → Z-Axis → SMS/Call cứu hộ (không chờ)
```

---

## 3. DATABASE SCHEMA (PostGIS)

```
═══════════════════════════════════════════════════════════════════════════

  ┌────────────────────────────────────┐
  │  EXTENSION: postgis                │
  │  CREATE EXTENSION IF NOT EXISTS    │
  │  postgis;                          │
  └────────────────────────────────────┘

  ┌──────────────────────────────────────────────────────────────────┐
  │  TABLE: medical_facilities                                       │
  ├──────────────────────────────────────────────────────────────────┤
  │  id              BIGSERIAL PRIMARY KEY                          │
  │  name            VARCHAR(255) NOT NULL                          │
  │  address         VARCHAR(500) NOT NULL                          │
  │  phone           VARCHAR(20) NOT NULL                           │
  │  facility_type   VARCHAR(50)   (bệnh viện, phòng khám, bác sĩ) │
  │  latitude        DOUBLE PRECISION NOT NULL                      │
  │  longitude       DOUBLE PRECISION NOT NULL                      │
  │  location        GEOMETRY(Point, 4326) NOT NULL  ← PostGIS col │
  │  is_active       BOOLEAN DEFAULT true                           │
  │                                                                  │
  │  INDEX: idx_facility_location USING GIST(location)  ← KNN index │
  └──────────────────────────────────────────────────────────────────┘

  ┌──────────────────────────────────────────────────────────────────┐
  │  TABLE: user_home_profiles                                       │
  ├──────────────────────────────────────────────────────────────────┤
  │  id              BIGSERIAL PRIMARY KEY                          │
  │  user_id         BIGINT NOT NULL UNIQUE                         │
  │  address_label   VARCHAR(255) NOT NULL  (vd: "Nhà riêng")       │
  │  latitude        DOUBLE PRECISION NOT NULL                      │
  │  longitude       DOUBLE PRECISION NOT NULL                      │
  │  home_location   GEOMETRY(Point, 4326) NOT NULL ← PostGIS col   │
  │  floor_number    VARCHAR(20)    (vd: "Tầng 5")                 │
  │  room_number     VARCHAR(20)    (vd: "Phòng 501")              │
  │  is_primary_home BOOLEAN DEFAULT true                           │
  │                                                                  │
  │  INDEX: idx_home_user        (user_id)                          │
  │  INDEX: idx_home_location    USING GIST(home_location)          │
  └──────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════
  PostGIS KNN QUERY (tìm cơ sở y tế gần nhất)
═══════════════════════════════════════════════════════════════════════════

  SELECT f.*
  FROM medical_facilities f
  WHERE f.is_active = true
  AND ST_DWithin(
      f.location::geography,
      ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography,
      5000  ← bán kính tìm kiếm (mét)
  )
  ORDER BY f.location <-> ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)
  LIMIT 1;

  ┌────────────────────────────────────────────────────────────────────┐
  │  <-> = KNN distance operator (sử dụng GIST index)                 │
  │  ST_DWithin = lọc trong bán kính (tránh kết quả xa quá)          │
  │  Sắp xếp theo khoảng cách, lấy 1 kết quả gần nhất                │
  └────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════
  Z-AXIS QUERY (kiểm tra có đang ở nhà không)
═══════════════════════════════════════════════════════════════════════════

  SELECT h.*
  FROM user_home_profiles h
  WHERE h.user_id = :userId
  AND ST_DWithin(
      h.home_location::geography,
      ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography,
      50   ← bán kính 50 mét (độ chính xác GPS ~5-10m)
  )
  LIMIT 1;

  → Nếu có kết quả → trả về { floorNumber, roomNumber, addressLabel }
  → Nếu null     → không có Z-metadata
```

---

## 4. API CONTRACT

```
═══════════════════════════════════════════════════════════════════════════
  POST /api/sos
═══════════════════════════════════════════════════════════════════════════

  REQUEST:
  ┌─────────────────────────────────────────┐
  │ Content-Type: application/json           │
  ├─────────────────────────────────────────┤
  │ {                                       │
  │   "latitude": 10.776889,                 │
  │   "longitude": 106.701116,               │
  │   "userId": 1                            │
  │ }                                       │
  └─────────────────────────────────────────┘

  RESPONSE (200 OK — SUCCESS):
  ┌───────────────────────────────────────────────────────────────────┐
  │ {                                                                 │
  │   "facilityId": 3,                                                │
  │   "facilityName": "Bệnh viện Từ Dũ",                              │
  │   "facilityAddress": "125 Cống Quỳnh, Q.1",                       │
  │   "phone": "02838400752",                                         │
  │   "facilityType": "bệnh viện",                                    │
  │   "destLatitude": 10.7625,                                        │
  │   "destLongitude": 106.6825,                                      │
  │   "distanceMeters": 1200.5,                                       │
  │   "estimatedMinutes": 4,                                          │
  │   "status": "SUCCESS",                                            │
  │   "zMetadata": {                          ← NGẦM, FE không dùng    │
  │     "floorNumber": "Tầng 5",                                      │
  │     "roomNumber": "Phòng 501",                                    │
  │     "addressLabel": "Nhà riêng",                                  │
  │     "locationType": "HOME"                                        │
  │   }                                                               │
  │ }                                                                 │
  └───────────────────────────────────────────────────────────────────┘

  RESPONSE (200 OK — NO FACILITY):
  ┌─────────────────────────────────────────┐
  │ {                                       │
  │   "status": "NO_FACILITY_FOUND"         │
  │ }                                       │
  └─────────────────────────────────────────┘

```

---

## 5. FLUTTER — FILE STRUCTURE (Clean Architecture)

```
frontflutter/lib/
├── main.dart                          ← Entry: runApp → SosScreen
├── .env                               ← ⚠️  KHÔNG COMMIT (TRACKASIA_API_KEY)
│
├── features/sos/                      ← Feature: SOS + Navigation
│   ├── data/
│   │   ├── models/
│   │   │   ├── sos_request.dart        ← SosRequest model
│   │   │   ├── sos_response.dart       ← SosResponse model
│   │   │   └── trackasia_route.dart    ← TrackAsia route response
│   │   ├── datasources/
│   │   │   └── sos_remote_datasource.dart  ← Dio calls: BE + TrackAsia
│   │   └── repositories/
│   │       └── sos_repository_impl.dart
│   │
│   ├── domain/
│   │   ├── repositories/
│   │   │   └── sos_repository.dart     ← Interface
│   │   └── usecases/
│   │       └── send_sos_usecase.dart   ← Use case chính
│   │
│   └── presentation/
│       ├── providers/
│       │   └── sos_provider.dart       ← State management (route, loading)
│       └── screens/
│           └── sos_screen.dart         ← UI: Map + SOS button + Route
│
├── shared/
│   ├── widgets/
│   │   ├── sos_fab.dart               ← Nút SOS tròn đỏ, 80dp
│   │   └── moving_ambulance_icon.dart  ← Icon 🚑 chạy dọc polyline
│   ├── providers/
│   │   └── location_provider.dart     ← GPS stream (Position Stream)
│   └── extensions/
│       └── latlng_extension.dart       ← Extension methods
│
└── core/
    ├── constants/
    │   └── app_constants.dart          ← API URLs, fallback coords
    └── utils/
        └── polyline_decoder.dart       ← Decode polyline → List<LatLng>

```

---

## 6. TRACKASIA ROUTING API CALL

```
═══════════════════════════════════════════════════════════════════════════

  URL:
  https://router.track-asia.com/v1/route/v1/driving/
      {user_lng},{user_lat};{dest_lng},{dest_lat}
      ?overview=full
      &geometries=polyline6
      &steps=true

  HEADERS:
  Authorization: Bearer {TRACKASIA_API_KEY}

  RESPONSE (Polyline6):
  {
    "routes": [{
      "geometry": "a~l~Fjk~uOwBa..."
      "legs": [{
        "steps": [
          { "geometry": "...", "distance": 500, "duration": 60 },
          ...
        ]
      }]
    }],
    "code": "Ok"
  }

═══════════════════════════════════════════════════════════════════════════
  FRONTEND: Giải mã + Vẽ
═══════════════════════════════════════════════════════════════════════════

  decoded_points = polyline6.decode(route.geometry)
  // → List<LatLng> (toàn bộ các điểm trên đường)

  // Vẽ 2 lớp polyline:
  ┌──────────────────────────────────────────────────────────────────┐
  │  1. Lớp NỀN (đoạn đã đi) — màu XÁM                              │
  │     traveled = decoded_points[0..userCurrentIndex]               │
  │     → PolylineLayer(color: Colors.grey, width: 8)                │
  │                                                                  │
  │  2. Lớp TRÊN (đoạn chưa đi) — màu ĐỎ ĐẬM                       │
  │     remaining = decoded_points[userCurrentIndex..end]            │
  │     → PolylineLayer(color: Colors.red, width: 8)                 │
  │                                                                  │
  │  3. Icon 🚒 di chuyển mượt                                       │
  │     - Dùng Marker với widget: Icon(Icons.directions_car)        │
  │     - Cập nhật vị trí bằng animation (lerp giữa 2 điểm)         │
  │     - Xoay theo hướng tuyến đường                                │
  └──────────────────────────────────────────────────────────────────┘

```

---

## 7. SECURITY & CONFIG

```
═══════════════════════════════════════════════════════════════════════════

  ┌─────────────────────────────────────────────────────────┐
  │  frontflutter/.gitignore                                 │
  │  .env                                                    │
  │  .env.local                                              │
  │  .env.*.local                                            │
  │                                                          │
  │  .env.example (COMMIT được — template không có key)     │
  └─────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────┐
  │  frontflutter/.env.example                               │
  │  TRACKASIA_API_KEY=your_key_here                        │
  └─────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────┐
  │  frontflutter/lib/core/constants/app_constants.dart     │
  │  class AppConstants {                                   │
  │    static const String trackAsiaApiKey =               │
  │      String.fromEnvironment('TRACKASIA_API_KEY');       │
  │    static const String backendUrl =                     │
  │      'http://10.0.2.2:8080/api';  // Android emulator  │
  │    static const String trackAsiaRouter =                │
  │      'https://router.track-asia.com/v1/driving';       │
  │  }                                                      │
  └─────────────────────────────────────────────────────────┘

```

---

## 8. DEPLOYMENT / RUN INSTRUCTIONS

```
═══════════════════════════════════════════════════════════════════════════

  BACKEND (IntelliJ IDEA):
  ─────────────────────────
  Môi trường cần thiết:
    ☑ Java 21 JDK
    ☑ PostgreSQL 16+ (có extension PostGIS)
    ☑ Maven 3.9+

  Cài đặt PostGIS:
    CREATE EXTENSION IF NOT EXISTS postgis;

  Chạy database (Docker):
    docker compose -f compose.yaml up -d postgres
    # hoặc chạy PostgreSQL local, connect qua application.properties

  Chạy BE:
    ./mvnw spring-boot:run
    → http://localhost:8080/api/sos

  Test BE (curl):
    curl -X POST http://localhost:8080/api/sos \
      -H "Content-Type: application/json" \
      -d '{"latitude":10.776889,"longitude":106.701116,"userId":1}'

  ─────────────────────────
  FRONTEND (Android Studio):
  ─────────────────────────
  Môi trường cần thiết:
    ☑ Flutter SDK 3.x (Dart 3.x)
    ☑ Android Emulator hoặc thiết bị thật
    ☑ Đã enable GPS trên thiết bị/emulator

  Cài dependencies:
    cd frontflutter
    flutter pub get

  Tạo file .env (KHÔNG COMMIT):
    TRACKASIA_API_KEY=ba6b7d3bc22517804229636ce5ce22e0e2

  Chạy app:
    flutter run

═══════════════════════════════════════════════════════════════════════════
```

---

## 9. WHAT NOT TO DO ❌

```
  ❌ KHÔNG popup, không dialog xác nhận
  ❌ KHÔNG hỏi "Bạn có chắc muốn gọi SOS không?"
  ❌ KHÔNG hiển thị loading spinner chặn màn hình (nhưng có thể có
     indicator nhỏ ở góc)
  ❌ KHÔNG commit file .env lên Git
  ❌ KHÔNG dùng API trả phí (Google Directions, Mapbox)
  ❌ KHÔNG chờ luồng Z-axis (SMS/call) trước khi hiển thị đường
  ❌ KHÔNG tắt màn hình trong khi đang navigation
```

---

## 10. OPEN SOURCE STACK SUMMARY

```
  ┌────────────────────────────────────────────────────────────────┐
  │  COMPONENT          │  TECHNOLOGY          │  LICENSE           │
  ├─────────────────────┼──────────────────────┼────────────────────┤
  │  Routing Engine     │  TrackAsia (OSRM)    │  Apache 2.0        │
  │  Backend Framework  │  Spring Boot 4.0.6   │  Apache 2.0        │
  │  Spatial DB         │  PostgreSQL + PostGIS│  PostgreSQL License│
  │  Mobile Framework   │  Flutter             │  BSD-3             │
  │  Map SDK            │  flutter_map + OSM   │  MIT               │
  │  HTTP Client        │  Dio                 │  MIT               │
  └────────────────────────────────────────────────────────────────┘

  OSRM (Open Source Routing Machine) by TrackAsia:
  📦 https://github.com/track-asia/osrm-backend
  📖 https://github.com/track-asia/osrm-backend/blob/master/docs/http.md
  🌐 Router: https://router.track-asia.com (free public instance)
```

---

*Generated for CareBridge Team — Senior Full-stack Architect*
*Architecture: Monolithic | Async Flow | PostGIS KNN | TrackAsia OSRM*
