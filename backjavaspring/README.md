# CareBridge SOS - Backend (Spring Boot)

Máy chủ API (Backend) phục vụ cho hệ thống CareBridge SOS, được xây dựng bằng Java Spring Boot.
Chức năng chính là cung cấp API và quản lý cơ sở dữ liệu không gian (Spatial Data) cho các địa điểm y tế thông qua PostgreSQL kết hợp PostGIS.

## Yêu cầu môi trường
- Java JDK 17 (Hoặc JDK 21).
- Docker và Docker Compose (Để chạy Database).
- Maven.

## Cài đặt & Sử dụng

### 1. Khởi động Cơ sở dữ liệu (PostGIS)
Dự án sử dụng Docker để giả lập nhanh Database PostgreSQL có tích hợp sẵn module PostGIS (chuyên xử lý tọa độ bản đồ).
Mở Terminal tại thư mục `backjavaspring` và chạy:
```bash
docker compose up -d
```
*Lệnh này sẽ tải image `postgis/postgis` và chạy Database ở cổng `5432`.*

### 2. Thiết lập Cấu hình
Mở file `src/main/resources/application.properties`, đảm bảo các thông số kết nối Database đang trỏ đúng về localhost:
```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/carebridge
spring.datasource.username=postgres
spring.datasource.password=123456
```

### 3. Chạy Server
Sử dụng công cụ Maven Wrapper có sẵn để tải thư viện và khởi động máy chủ:
```bash
# Trên Windows
.\mvnw.cmd spring-boot:run

# Trên Linux/Mac
./mvnw spring-boot:run
```
*(Hoặc anh/chị có thể mở dự án bằng IntelliJ IDEA và bấm nút Run).*

Server sẽ khởi động và lắng nghe tại cổng mặc định: `http://localhost:8080`.
