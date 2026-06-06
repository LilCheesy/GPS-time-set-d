# CareBridge SOS System

Hệ thống Bản đồ Y tế và Dẫn đường Khẩn cấp (SOS). Hệ thống được thiết kế để xử lý định vị và tìm kiếm cơ sở y tế trong thời gian thực (Real-time) cho người dùng di động.

## Kiến trúc Hệ thống

Hệ thống SOS được thiết kế theo hướng **API-First & Client-Side Processing** nhằm đảm bảo khả năng mở rộng (Scalability) và xử lý dữ liệu thời gian thực mà không bị giới hạn hiệu năng:
- **Phân tán tải trọng (Offloading):** Các tác vụ tính toán phức tạp như rà quét không gian (Spatial Search) và định tuyến đường đi (Routing) được xử lý hoàn toàn trên hệ thống máy chủ Cloud chuyên biệt của **TrackAsia**.
- **Xử lý tại Client:** Ứng dụng Mobile tự đảm nhận việc gửi yêu cầu, lọc dữ liệu thô, loại bỏ trùng lặp và tính toán khoảng cách để mang lại độ trễ thấp nhất cho người dùng.

## Công nghệ & Mã nguồn mở (Open Source Stack)

Ứng dụng tự hào được xây dựng trên vai những dự án xuất sắc trong thế giới mã nguồn mở:
- **MapLibre GL:** Một nhánh mở (fork) từ dự án Mapbox GL mã nguồn mở, cho phép điện thoại render (vẽ) bản đồ vector 2D/3D cực kỳ mượt mà nhờ vào sức mạnh phần cứng (GPU).
- **OSRM (Open Source Routing Machine):** Engine thuật toán mã nguồn mở siêu tốc nằm ẩn đằng sau TrackAsia API. OSRM là tiêu chuẩn vàng trong việc tìm ra đoạn đường đi ngắn nhất dựa trên mạng lưới giao thông thực tế.
- **OpenStreetMap (OSM):** Bách khoa toàn thư mở về bản đồ thế giới, được cộng đồng duy trì, cung cấp hạ tầng đường sá và địa điểm gốc cho nền tảng TrackAsia.

## Luồng dữ liệu & Xử lý chi tiết (Data Flow)

Toàn bộ chu trình từ khi bấm nút SOS chỉ diễn ra trong chưa tới 1 giây nhờ vào luồng xử lý tối ưu:

1. **Luồng Lấy Vị Trí:** Ứng dụng Flutter kết nối trực tiếp với chip GPS trên thiết bị qua thư viện `geolocator` để lấy tọa độ hiện tại (Kinh độ/Vĩ độ) với độ chính xác cao nhất.
2. **Luồng Quét Cơ sở y tế (SOS Scan):** 
   - Ứng dụng bắn **đa luồng** (Concurrency) các request HTTP trực tiếp lên **TrackAsia Places API** với bán kính 10km (tìm cả Bệnh viện, Phòng khám, Trạm y tế).
   - Kết quả thô được tải về dạng JSON. Ứng dụng tiến hành **khử trùng lặp**, dùng công thức Haversine để đo khoảng cách chim bay, và chỉ giữ lại **20 cơ sở gần nhất** đưa lên giao diện.
3. **Luồng Dẫn Đường (Routing):** 
   - Khi chọn đích đến, tọa độ được gửi lên **TrackAsia Routing API** (OSRM). 
   - API trả về một chuỗi tọa độ nén theo chuẩn thuật toán `Polyline`. 
   - Ứng dụng tiến hành "giải nén" chuỗi này thành một mảng tọa độ và yêu cầu MapLibre vẽ một quỹ đạo liền nét màu xanh băng qua các ngả đường.
   - Bản đồ tự động tính toán kích thước (Bounding Box) và thu phóng (Auto-zoom) để bao trọn con đường vào giữa khung hình thiết bị.
