# Phân tích nghiệp vụ và dữ liệu MỌT

## Vai trò và quyền

| Chức năng | Độc giả | Thủ thư | Quản lý |
|---|---|---|---|
| Hồ sơ, đổi mật khẩu | Của mình | Của mình | Của mình |
| Tra cứu và xem sách | Có | Có | Có |
| Yêu thích, gửi yêu cầu, xin gia hạn | Của mình | Dùng tài khoản độc giả riêng | Dùng tài khoản độc giả riêng |
| Danh sách phiếu mượn/yêu cầu | Của mình | Tất cả | Tất cả |
| Duyệt, giao, trả, ghi hỏng/mất | Không | Có | Có |
| Thêm/sửa đầu sách và bản sách | Không | Có | Có |
| Quản lý hồ sơ/hạn thẻ/khóa độc giả | Không | Có | Có |
| Tạo nhân sự, sửa vai trò | Không | Không | Có |
| Báo cáo vận hành | Không | Có | Có |
| Quy định và nhật ký | Xem quy định | Xem quy định | Sửa quy định, xem nhật ký |

UI hiển thị theo vai trò; API kiểm tra độc lập. Đổi nút hoặc gửi HTTP thủ công không vượt được quyền. Không được tự hạ/khóa tài khoản quản lý đang thao tác; luôn giữ ít nhất một quản lý hoạt động.

## Quy trình mượn

Độc giả gửi yêu cầu cho đầu sách đang lưu hành và còn bản → thủ thư duyệt → hệ thống chọn một bản sẵn sàng và giữ 2 ngày → thủ thư giao thực tế → tạo khoản mượn với hạn trả 14 ngày → nhận trả tốt/hỏng/mất.

- Yêu cầu: pending → approved → fulfilled; pending có thể rejected/cancelled; approved có thể cancelled/expired.
- Bản sách: available → reserved → on_loan → available/damaged/lost. Hủy/hết hạn giữ trả bản về available.
- Phiếu mượn: borrowed → returned hoặc lost. Quá hạn được tính từ hạn trả và trạng thái, không cần ghi đè lịch sử.
- Độc giả không được gửi lặp cùng đầu sách khi đã có yêu cầu hoặc đang mượn đầu sách đó.
- Tổng yêu cầu chờ/chờ nhận và khoản đang mượn không vượt giới hạn. Tài khoản khóa, thẻ hết hạn hoặc có khoản quá hạn không được mượn thêm.
- Gia hạn: độc giả xin → thủ thư duyệt/từ chối. Chỉ duyệt trước hạn, trong số lần cho phép, không có độc giả khác chờ đầu sách đó. Mỗi lần thêm số ngày quy định vào hạn hiện tại.
- Mỗi phiếu gắn một bản. Tất cả việc đổi trạng thái bản, phiếu và tạo thông báo nằm cùng giao dịch SQLite.

## Dữ liệu

| Bảng | Ý nghĩa và trường quan trọng |
|---|---|
| users | id, name, email duy nhất, password hash, recovery hash, role, active, card_expires |
| sessions | token hash, user_id, expires |
| attempts | số lần đăng nhập sai theo email, thời điểm hết hạn chặn |
| books | đầu sách: title, author, category, description, cover, source, isbn, publisher, year, active |
| copies | từng cuốn vật lý: book_id, code duy nhất, shelf, status |
| requests | user_id, book_id, copy_id khi duyệt, status, pickup_until, processed_by, note |
| loans | request_id duy nhất, user_id, copy_id, issued_by, issued_at, due_at, returned_at, received_by, status, condition, renewals |
| renewals | loan_id, status, created_at, processed_by |
| favorites | cặp user_id/book_id duy nhất |
| notifications | user_id, title, body, created_at, is_read |
| settings | quy định mượn dưới dạng JSON |
| audit | người thao tác, hành động, chi tiết, thời điểm |

Một đầu sách có nhiều bản. Một người có nhiều yêu cầu và khoản mượn. Một bản có nhiều khoản mượn theo thời gian, nhưng tối đa một khoản đang mở. Khóa ngoại bảo vệ quan hệ; chỉ mục duy nhất có điều kiện bảo vệ các trạng thái đang hoạt động.

Mật khẩu dùng PBKDF2-SHA256 với salt ngẫu nhiên, 600.000 vòng. Token đăng nhập và mã khôi phục sinh ngẫu nhiên và chỉ lưu hash ở server. Điện thoại lưu token bằng flutter_secure_storage khi người dùng chọn Keep me signed in. Phiên có hạn 30 ngày nếu nhớ đăng nhập, 12 giờ nếu không; kiểm tra quyền/trạng thái tài khoản ở mỗi request. API triển khai công khai phải dùng HTTPS.

## Giao diện

Splash 4 giây; 5 cuốn sách rơi theo nhịp rồi logo hiện. Login dùng phần trên khoảng một phần ba chiều cao, phần dưới là form cuộn được khi bàn phím mở. Home gồm lời chào, tìm kiếm, góc đọc nghệ thuật, thống kê và lối tắt. Thanh điều hướng: Trang chủ, Khám phá, Yêu cầu, Mượn trả, Tài khoản.

Dữ liệu được tải khi mở màn hình hoặc kéo làm mới; không dùng realtime socket. Thông báo hạn trả là mục động tính từ dữ liệu hiện tại, không phải push nền. Vì vậy mục nhắc hạn động có thể vẫn xuất hiện sau khi đánh dấu thông báo đã đọc, cho đến khi trả sách hoặc đổi hạn.
