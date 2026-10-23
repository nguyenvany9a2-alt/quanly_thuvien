# Tài sản hình ảnh và font

Hai ảnh mới được tạo bằng công cụ image_gen tích hợp, sử dụng trong mã nguồn:
- `assets/images/ocean.png`: nền biển.
- `assets/images/cover_atlas.png`: atlas 5 cột × 4 hàng, hiển thị bằng Flutter trong `lib/widgets/editorial_cover.dart`; ánh xạ tên sách ở `cover_data.dart`.

Các bìa mới là minh họa nghệ thuật cho đồ án, không đại diện cho bìa xuất bản chính thức. Tên và tác giả lấy từ danh mục người dùng cung cấp, Flutter dựng chữ riêng để giữ chính xác dấu tiếng Việt.

## Prompt nền biển
Use case: photorealistic-natural. Create one portrait 2:3 premium editorial aerial ocean photograph as a mobile library app background. Deep midnight navy water on left and top, rich slate blue and turquoise under water, intricate natural white sea foam washing diagonally along right edge toward bottom. Soft atmospheric light, quiet luxurious meditative feeling, real organic ocean details, subtle film texture. No text, no lettering, no logo, no frames, no UI. Keep top half relatively calm dark water for overlaid design. Save image for integration in app assets.

## Prompt tranh bìa
Use case: illustration-story. Asset type: artwork texture atlas for 20 literary book covers in a mobile library. Create one image with EXACTLY 5 columns by 4 rows equal rectangular cells, no gutters, no borders. All cells have 2:3 portrait aspect ratio; full atlas landscape 5:6 approximately. Each of the 20 cells is a DIFFERENT premium handpainted vintage Vietnamese literary illustration in atmospheric midnight navy, ivory, faded teal, muted amber; painterly textured paper, evocative editorial art, not photographic. Cell subjects row1: pagoda by moonlit river; pensive woman by shuttered window; old Saigon street; woman with red silk umbrella; solitary boat. Row2: handwritten letter with camellia; white butterfly on dark forest; two women in rice field; misty mountain horizon; father and child walking by river. Row3: rain on village roof; gold ring on linen; antique sailing ship; lone woman at shore; wise scholar beneath pine. Row4: market street at dusk; hound silhouette on foggy moor; old mansion courtyard; village hut and palm trees; lotus on blue pond. Important no text no letters no typography no fake book mockups; flat fullbleed art only in each cell. These images will be displayed inside book jackets by the app with real titles added separately.

## Nội dung và font

- Toàn văn Truyện Kiều: file JSON đã có trong dự án Slider/Lịch của người dùng, ghi nguồn https://vi.wikisource.org/wiki/Truyện_Kiều; Nguyễn Du, tác phẩm thuộc phạm vi công cộng. Không lấy bìa thương mại mới từ nguồn ngoài.
- Dữ liệu 20 đầu sách cũ và các ảnh gốc: giữ từ file dự án đầu vào.
- Font mặc định: các file DejaVu trong dự án đầu vào và giấy phép kèm theo `assets/fonts`.
- Chưa có ba file thương mại Dream Avenue/TAN Buster/Slight; không phân phối hoặc giả lập tên của những file này.
- Tham khảo cách tích hợp font Flutter: https://docs.flutter.dev/cookbook/design/fonts.
