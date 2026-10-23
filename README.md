# MỌT — Ocean Refined

Gói cập nhật cho dự án Flutter hiện có tại `D:\LTDD\quanly_thuvien`. Đây là gói cập nhật mã nguồn, không phải APK hay dự án Android độc lập.

## Những thay đổi

- Logo vector riêng: trang sách tạo chữ M, điểm sáng phía trên và nét màu champagne trên nền navy.
- Các Panel dùng kính mờ bán trong suốt; ảnh nền Ocean rõ hơn. Kệ sách giữ lớp navy đậm để ảnh bìa nổi bật.
- Trang chủ tìm ngay theo tên sách, tác giả, ISBN; nhập không dấu vẫn tìm được. Có lọc còn sách, bản số và thể loại; kết quả mở đúng chi tiết sách.
- Kệ sách tự dịch chuyển mỗi 4 giây; có tạm dừng/tiếp tục. Ngừng tự trượt khi app ở nền, mở trang khác, chạm/kéo kệ sách hoặc bật giảm chuyển động của hệ thống.
- Hộp thư có số chưa đọc, bộ lọc và đánh dấu từng thông báo. Nhắc hạn trả tách riêng, tự biến mất khi không còn thỏa điều kiện nhắc hạn; không bị coi là thư có thể đánh dấu đã đọc.
- Yêu cầu và mượn trả dùng ảnh bìa bên trái, thông tin/nút bên phải; vẫn giữ thao tác và quyền của từng vai trò.
- `docs/noi_dung_sach`: 20 bài đọc đồng hành biên soạn mới + trích đoạn Truyện Kiều từ dữ liệu đã có trong dự án. Bài đồng hành không phải nguyên văn hoặc tóm tắt cốt truyện. Không tự thay nội dung sách trong database.

## Cập nhật trên Windows

1. Trong terminal Flutter đang chạy, bấm `q`. Dừng server bằng Ctrl+C trong terminal server. Đóng Android Studio nếu đang mở dự án.
2. Giải nén ZIP vào `D:\MOT_Refined`. Kiểm tra có `D:\MOT_Refined\quanly_thuvien\UPDATE_MOT.ps1`.
3. Trong CMD hoặc PowerShell chạy:

```text
powershell -NoProfile -Command "Unblock-File -LiteralPath 'D:\MOT_Refined\quanly_thuvien\UPDATE_MOT.ps1'"
powershell -NoProfile -File "D:\MOT_Refined\quanly_thuvien\UPDATE_MOT.ps1" -Target "D:\LTDD\quanly_thuvien"
```

Script sao lưu các mục sẽ sửa cùng `server/data` vào thư mục `MOT_backup_<thời gian>` nằm cạnh dự án. Database đang dùng và cấu hình Gradle Android không bị ghi đè. Không giải nén đè trực tiếp lên thư mục đang chạy.

4. Mở terminal 1 tại `D:\LTDD\quanly_thuvien`:

```text
scripts\start-server.cmd
```

Nếu dùng PowerShell:

```powershell
.\scripts\start-server.cmd
```

5. Terminal 2:

```text
cd D:\LTDD\quanly_thuvien
flutter pub get
flutter devices
flutter run -d emulator-5554
```

Thay `emulator-5554` nếu `flutter devices` cho mã khác. Cần khởi động lại server để dùng chức năng đánh dấu riêng từng thông báo; hot reload không cập nhật Python server.

## Thêm nội dung đọc

Đăng nhập thủ thư/quản lý → Khám phá → chọn sách → Biên tập bản số. Mở file tương ứng trong `docs/noi_dung_sach`, dán nội dung, ghi nguồn, xác nhận quyền sử dụng và lưu. Giữ nhãn “Bài đọc đồng hành” để người đọc không nhầm với tác phẩm gốc. Với Truyện Kiều dùng nguồn ghi trong file trích đoạn; không cần thay bản đầy đủ nếu sách đã có nội dung.

## Kiểm tra sau cập nhật

- Gõ `ho bieu chanh` trên trang chủ: kết quả hiển thị ngay, không chuyển tab.
- Chờ 4 giây trên kệ sách có đủ nhiều sách; thử tạm dừng/tiếp tục.
- Thử duyệt/từ chối một yêu cầu bằng thủ thư; thử đọc từng thông báo bằng người nhận.
- Thử mượn/trả/gia hạn với dữ liệu demo trước khi trình diễn.
- Xem `docs/KIEM_THU.md` để biết phạm vi kiểm thử đã thực hiện.

Không cần đổi JAVA_HOME, Gradle hoặc nâng phiên bản dependency để dùng bản cập nhật này. Các font thương mại chưa được bổ sung vì gói hiện tại không có file font được cấp phép.
