# Kết quả kiểm thử MỌT

Kiểm thử ngày 12/10/2026. Flutter 3.47.7, Dart 3.13.5; Python 3.12; FastAPI 0.143.0. Môi trường Linux, không có Android Emulator hoặc Android SDK để build/cài APK.

## Đã kiểm tra tự động

- `flutter analyze --no-pub`: không có vấn đề. Log: `flutter-analyze.txt`.
- `flutter test --no-pub --update-goldens`: 8 bài đạt. Log: `flutter-tests.txt`.
- `pytest server/tests -q`: 6 bài đạt. Có một cảnh báo deprecation từ TestClient/httpx, không phải lỗi nghiệp vụ. Log: `api-tests.txt`.
- 21 ảnh local được xác minh đọc được; đủ 20 đường dẫn bìa trong catalog.

Kiểm thử Flutter bao gồm splash chuyển sang login sau 4 giây; login/signup ở chiều rộng 320 và 390; cả 5 tab cho 3 vai trò; nút quản trị ẩn với độc giả; lưu/khôi phục token; xóa phiên khi API trả 401; không lưu token khi bỏ nhớ đăng nhập. Golden tại `test/goldens` dùng dữ liệu kiểm thử, không phải ảnh chụp Android thật. Đã xem trực quan login, home, catalog và sửa lỗi phông chữ/ảnh chưa tải trước khi chụp.

Kiểm thử API gồm đăng ký và lưu bền qua khởi tạo lại; chặn tự đăng ký vai trò quản lý; quyền truy cập dữ liệu; khôi phục mật khẩu xoay mã và thu hồi phiên; duyệt/giao/trả; chống giao/trả hai lần; gia hạn; giới hạn mượn; giữ bản hết hạn; quá hạn; tranh chấp bản cuối; quyền sửa vai trò và khóa tài khoản; giới hạn đăng nhập sai.

## Nghiệm thu trên máy bạn

1. Khởi động API, chạy Flutter trên YsPhone, xác nhận splash và không tràn bố cục khi mở bàn phím.
2. Đăng ký email mới, lưu mã khôi phục; đăng xuất/đăng nhập lại. Dừng và khởi động API để xác nhận dữ liệu vẫn còn.
3. Thực hiện chu trình độc giả yêu cầu → thủ thư duyệt/giao → độc giả gia hạn → thủ thư duyệt/nhận trả; xem số bản và thông báo cập nhật.
4. Dùng hai thiết bị/tài khoản nếu có để thử cùng yêu cầu bản cuối; kết quả chỉ một người được giữ bản.
5. Thử nguồn sách mở trình duyệt và Keep me signed in trên Android thật (plugin native không được mô phỏng đầy đủ trong widget test).
6. Chạy khi API tắt để xem lỗi kết nối; bật API rồi tải lại. Các thao tác ghi cần mạng.

Chưa kiểm chứng: build Gradle/APK, cài đặt trên thiết bị Android/iOS, secure storage native và mở trình duyệt native. Không coi các kiểm thử widget/API là thay thế cho nghiệm thu Android. iOS/web trong dự án gốc được giữ lại, chưa nghiệm thu cho phiên bản này.
