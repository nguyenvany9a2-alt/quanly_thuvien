# Kiểm thử bản Ocean Refined

Môi trường: Linux, Flutter 3.47.7, Dart đi kèm SDK; backend Python 3.12.

- `dart analyze lib test`: không phát hiện lỗi/cảnh báo.
- Backend: 7 kiểm thử đạt, gồm đăng ký/quyền truy cập, quy trình mượn trả và bảo vệ thông báo của từng tài khoản.
- Flutter: 15 kiểm thử đạt (`flutter test --no-pub`). Các kiểm thử gồm tìm kiếm không dấu ngay tại trang chủ, lọc kết quả, carousel tự chạy/tạm dừng, bố cục yêu cầu/mượn trả, phân biệt thư và nhắc hạn, các màn hình theo vai trò.
- Đã xem ảnh dựng trang chủ, yêu cầu và hộp thư; các ảnh nằm trong `test/goldens`.

Giới hạn: chưa build APK/chạy trên máy ảo Windows của bạn; PowerShell updater chưa được thực thi trong môi trường Windows này. Bộ kiểm thử giao diện dùng API giả; backend dùng database tạm. Không kết nối hay sửa database thật của bạn. Ảnh golden tạo trên Linux có thể khác đôi chút khi kiểm thử trên Windows.

Sau cập nhật cần chạy server và Flutter, rồi kiểm tra một chu trình yêu cầu → duyệt → giao sách → trả sách trên máy của bạn.
