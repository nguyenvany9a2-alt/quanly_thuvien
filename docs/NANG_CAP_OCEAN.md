# MỌT · Ocean Edition

Bản nâng cấp từ quanly_thuvien(3).zip, ngày 15/10/2026.

## Cập nhật dự án đang dùng, giữ tài khoản và phiếu mượn

1. Dừng `flutter run` bằng `q` trong terminal đang chạy Flutter. Dừng máy chủ API bằng Ctrl+C.
2. Giải nén gói mới vào thư mục riêng, ví dụ `D:\MOT_Ocean\quanly_thuvien`. KHÔNG giải nén đè trực tiếp trước khi sao lưu.
3. Trong PowerShell chạy:

```powershell
cd D:\MOT_Ocean\quanly_thuvien
.\UPDATE_MOT.ps1 -Target 'D:\LTDD\quanly_thuvien'
```

Script sao lưu các tệp sẽ cập nhật và `server\data` vào `D:\LTDD\MOT_backup_...`; sau đó chép mã mới. Script không thay DB, không xóa tài khoản, không thay Gradle/JAVA_HOME trên máy bạn. Nếu PowerShell không cho chạy script, có thể sao lưu thủ công rồi chép những mục trong danh sách `$items`; không cần thay đổi chính sách bảo mật hệ thống.

4. Terminal thứ nhất:

```powershell
cd D:\LTDD\quanly_thuvien
.\scripts\start-server.cmd
```

Máy chủ tự thêm bảng/cột còn thiếu. Dữ liệu hiện tại giữ nguyên. Với DB mới, script tạo tài khoản demo; với DB đang có, không tạo lại tài khoản demo.

5. Terminal thứ hai, sau khi máy ảo đã khởi động:

```powershell
cd D:\LTDD\quanly_thuvien
flutter clean
flutter pub get
flutter run -d emulator-5554
```

Bản này có thay mã Android cho chọn ảnh, nên cần khởi chạy lại đầy đủ, không chỉ hot reload. Khi chạy thành công, giữ cả hai terminal hoạt động. Các ảnh chọn trên máy ảo là ảnh có trong bộ nhớ máy ảo; có thể kéo ảnh từ Windows vào máy ảo trước.

## Những gì đã thay đổi

- Nền biển nguyên bản do AI tạo, lớp xanh trắng trong suốt, panel kính mờ, chế độ tối navy; tông màu và khoảng cách dùng xuyên suốt các trang.
- Logo dạng biểu tượng sách + chữ MỌT; nhấn logo trong thanh đầu trang để về Trang chủ. Thông báo và Quy định ở góc phải.
- Avatar, tên, vai trò; lời chào; tìm kiếm; tuyển sách trượt ngang; dashboard cá nhân hoặc thư viện theo quyền.
- 20 bìa minh họa mới, hiển thị từ một atlas; chữ tên sách/tác giả do Flutter vẽ riêng. Đây là bìa minh họa cho đồ án, không phải ảnh bìa ấn bản thương mại.
- Khám phá: carousel, tìm kiếm/lọc, thẻ sách, điểm trung bình và số lượt đánh giá.
- Đánh giá 1–5 sao, nhận xét, sửa đánh giá của chính mình. Mỗi tài khoản có một đánh giá cho mỗi đầu sách; API kiểm tra giới hạn điểm.
- Thông báo: quản lý tạo theo nhóm người nhận, nội dung lưu DB; độc giả và thủ thư không có quyền tạo. Đây là thông báo trong ứng dụng khi mở trang, chưa phải push notification.
- Hồ sơ: đổi/xóa avatar bằng trình chọn ảnh Android, cập nhật tên/điện thoại. Ảnh được thu nhỏ và lưu cùng tài khoản trên máy chủ.
- Trải nghiệm: ba tông nền, ảnh nền riêng, sáng/tối, cỡ chữ 85–130%, giảm chuyển động; lưu theo tài khoản. Bấm Lưu để áp dụng; có xem thử ảnh/cỡ chữ trên trang chỉnh.
- Báo cáo: donut, cột, đường và bảng số liệu thật. Độc giả chỉ xem lịch sử cá nhân; nhân viên xem tổng quan thư viện. Biểu đồ tháng có đủ sáu tháng gần nhất khi đã có dữ liệu.
- Yêu cầu/mượn trả: giữ nghiệp vụ, cập nhật panel, màu/trạng thái, bổ sung bộ lọc từ chối/hủy/hết hạn.

## Nội dung đọc: tình trạng thực tế

Đã có trình đọc nội bộ, mục lục chia phần, tăng/giảm cỡ chữ, chọn phần, lưu vị trí riêng theo tài khoản.

**Đã tích hợp toàn văn Truyện Kiều** từ bản JSON trong dự án Slider/Lịch trước đó, tác giả Nguyễn Du, ghi nguồn Wikisource. Tác phẩm được thêm riêng bằng tên/tác giả; không ghi đè các sách hiện tại. Đây là bản số, không tự tạo tồn kho sách giấy.

**20 đầu sách cũ chưa có toàn văn trong ZIP người dùng gửi.** SachHayOnline trả HTTP 403 khi tải từ môi trường triển khai. Không lấy mô tả hay nội dung AI tự viết giả thành toàn văn. Các sách này hiển thị “Bản số chưa có”; vẫn mượn sách giấy và đánh giá bình thường. Thủ thư/quản lý vào chi tiết sách → Biên tập nội dung đọc → dán văn bản được phép sử dụng và ghi nguồn → lưu. Sau đó nút Đọc sách ngay xuất hiện cho độc giả.

Để hoàn thành toàn văn cho toàn bộ danh mục, cần bổ sung TXT/EPUB/văn bản có quyền sử dụng cho từng đầu sách; không cần thay cấu trúc ứng dụng.

## Ba font yêu cầu

File Dream Avenue, TAN Buster và Slight chưa được gửi. Bản chạy dùng DejaVu Sans/Serif có tiếng Việt, không giả gắn tên font thương mại vào font khác.

Khi có file hợp lệ, đặt trong `assets/fonts`, thêm vào mục `flutter/fonts` của pubspec.yaml:

```yaml
    - family: DreamAvenue
      fonts:
        - asset: assets/fonts/DreamAvenue.ttf
    - family: TanBuster
      fonts:
        - asset: assets/fonts/TanBuster.ttf
    - family: Slight
      fonts:
        - asset: assets/fonts/Slight.ttf
```

Rồi chạy `flutter run -d emulator-5554 --dart-define=MOT_LICENSED_FONTS=true`.
Các biến `bodyFont`, `displayFont`, `accentFont` nằm trong `lib/core/theme.dart`. Cần kiểm tra dấu tiếng Việt trên file font thực tế; font không đủ ký tự sẽ cần fallback phù hợp. Slight dành cho dòng nhấn ngắn, không dùng cho đoạn đọc dài.

## Demo đề xuất

1. Mở splash → đăng nhập độc giả → xem logo, avatar, nền biển.
2. Lướt tuyển sách → khám phá → tìm Truyện Kiều → Đọc sách → tăng chữ/chuyển phần → quay lại để chứng minh vị trí được lưu.
3. Đánh giá một cuốn, sửa điểm và kiểm tra số lượt không tăng trùng.
4. Gửi yêu cầu một sách giấy còn bản → thủ thư duyệt/giao → độc giả xem hạn trả → thủ thư nhận trả.
5. Quản lý tạo thông báo cho nhóm độc giả; mở bằng tài khoản độc giả để kiểm tra.
6. Hồ sơ → chọn avatar; Trải nghiệm → đổi nền/tối/cỡ chữ → lưu.
7. Báo cáo → biểu đồ cột/đường/tròn và bảng. Dữ liệu thay đổi theo thao tác mượn trả thật.

## Kiểm chứng và giới hạn

- `dart analyze lib test`: xem log trong `docs/verification`.
- Kiểm thử API: phân quyền, mượn trả cũ, thông báo theo nhóm, cập nhật đánh giá, vị trí đọc riêng, cấu hình người dùng và khởi tạo lặp không nhân bản dữ liệu.
- Widget test: đăng nhập, ba vai trò, các tab chính, màn hình 320 px/chữ lớn/chế độ tối; chi tiết sách, trình đọc, đánh giá, tùy chỉnh, thông báo, báo cáo.
- Ảnh trong `docs/preview` là render Flutter với dữ liệu kiểm thử; số liệu trên ảnh không phải DB thật của bạn.
- Chưa build APK hay chạy trực tiếp trên YsPhone trong môi trường này. Cần kiểm tra trình chọn ảnh Android trên máy ảo và các bước chạy ở trên.
- Không đính kèm DB của người dùng, thư mục build, .dart_tool, venv hoặc các đường dẫn SDK Windows vào gói mã nguồn.
