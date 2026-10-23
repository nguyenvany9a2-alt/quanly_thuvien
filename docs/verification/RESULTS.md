# Kết quả kiểm tra Ocean Edition

- Dart analyze lib test: No issues found.
- Flutter test: 10 passed, Flutter 3.47.7, Linux.
- API pytest: 11 passed; FastAPI 0.143.1, Pydantic 2.14.1, Python 3.12.
- Có 1 cảnh báo deprecation trong bộ test Starlette/httpx; không có test thất bại.
- Có kiểm tra migration từ bảng users chưa có avatar/preferences; tài khoản và phiên vẫn giữ nguyên.
- Đã xem ảnh render trang chủ, khám phá, đăng nhập, chi tiết sách, báo cáo và chế độ tối.
- Chưa build APK hoặc chạy trình chọn ảnh trên YsPhone. Cần chạy lại ứng dụng trên Android để nghiệm thu phần native.
- Preview sử dụng dữ liệu giả trong test; bản ứng dụng sử dụng API và dữ liệu DB thực tế.
