# Kịch bản demo MỌT — khoảng 7–10 phút

1. Chạy API trước, mở ứng dụng: chỉ ra hiệu ứng sách xếp chồng 4 giây và màn hình đăng nhập dựa trên bố cục mẫu. “MỌT giúp kết nối độc giả với hoạt động vận hành thư viện, dùng chung dữ liệu nhưng khác quyền.”
2. Sign Up bằng email mới, lưu mã khôi phục, đăng nhập. Tắt/mở lại ứng dụng để cho thấy Keep me signed in. Giới thiệu dữ liệu tài khoản lưu ở SQLite trên máy chủ.
3. Khám phá → tìm một tên sách → mở chi tiết → yêu thích → Gửi yêu cầu. Chỉ ra số bản còn sẵn sàng và nguồn dữ liệu sách.
4. Đăng xuất, đăng nhập librarian@mot.local → Yêu cầu → Duyệt → Giao sách. “Duyệt giữ bản, còn giao sách mới bắt đầu tính hạn trả. Hai bước phản ánh việc nhận sách tại quầy.”
5. Về độc giả → Mượn trả → thấy hạn và khoản mượn → Xin gia hạn. Về thủ thư → Duyệt gia hạn. Sau đó nhận trả và chọn tình trạng. Cho thấy số bản sẵn sàng cập nhật.
6. Thủ thư vào đầu sách → Quản lý bản → thêm mã mới, vị trí kệ. Giới thiệu phân biệt đầu sách và từng bản vật lý. Không xóa dữ liệu lịch sử khi ngừng lưu hành.
7. Quản lý đăng nhập → Tài khoản → Thành viên, Quy định, Báo cáo, Nhật ký. Thay giới hạn mượn; chỉ ra chính sách áp dụng giao dịch mới, lịch sử cũ được giữ nguyên.
8. Tình huống kiểm tra: độc giả không thấy nút quản trị; thử gửi yêu cầu lặp bị chặn. Nếu cần chứng minh sâu, chạy pytest có tình huống hai người tranh bản cuối.
9. Kết thúc bằng kiến trúc: Flutter → HTTP API → SQLite. Trình bày giới hạn đúng phạm vi: một thư viện, chưa thu tiền phạt, chưa đọc toàn văn, chưa push/email; sẵn nền dữ liệu và phân quyền để phát triển tiếp.

Chuẩn bị trước: API đang chạy; máy ảo có mạng; ba tài khoản demo; có ít nhất một đầu sách sẵn sàng; ghi lại email mới và mã khôi phục; thu âm bằng công cụ quay màn hình máy tính có micro nếu quay thuyết trình.
