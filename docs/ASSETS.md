# Nguồn tài sản

- Bố cục tham khảo: ba ảnh trong `ảnh minh họa.rar` do người dùng cung cấp. MỌT diễn giải lại bố cục, màu sắc và component; không dùng tên/logo Parcel.
- `assets/images/login_art.png`: artwork tạo bằng công cụ imagegen cho MỌT ngày 12/10/2026, mode generate, dùng cho hero đăng nhập/trang chủ. Ảnh được đóng gói local, không gọi AI lúc chạy app.
- Prompt: “A refined friendly 3D clay illustration of stacked books with rounded spines in sage green, ivory, dusty peach, warm ochre, one open book gently floating above, a tiny leafy branch, on a warm cream background. Soft tactile paper, gentle studio daylight, subtle shadows. Landscape 3:2 composition, books concentrated on right half, generous empty cream upper-left area for app logo rendered separately. No text, no lettering, no logos, no people, no watermark. Artwork for upper third of mobile login screen.”
- 20 bìa và metadata sách lấy theo yêu cầu từ https://www.sachhayonline.com. Từng URL nguồn/ảnh gốc lưu trong `BOOK_SOURCES.json`. Bản sách và số lượng là dữ liệu demo, không phản ánh tồn kho website. Nhóm thể loại trong seed là phân loại của MỌT; ISBN/nhà xuất bản/năm để trống khi chưa có dữ liệu xác minh.
- Không sao chép toàn văn sách. Nút nguồn mở trang website ngoài ứng dụng. Bìa thuộc nguồn/chủ thể quyền tương ứng, dùng minh họa học phần; ghi nguồn không đồng nghĩa được cấp phép tái phát hành thương mại.
- Font DejaVu Sans/Serif được đóng gói với giấy phép `assets/fonts/LICENSE.txt`. Logo và splash là widget/vector tự xây dựng.

Prompt triển khai chính: xây dựng Flutter MỌT ba vai trò, giao diện kem/trắng với nút bo góc, splash sách rơi 3–5 giây, form đăng nhập theo ảnh tham khảo, dữ liệu sách từ sachhayonline.com. AI hỗ trợ thiết kế giao diện, sinh mã Flutter/API, thiết kế ràng buộc dữ liệu, viết kiểm thử và tài liệu. Nhóm cần tự đọc hiểu và chạy nghiệm thu trước khi thuyết trình.
