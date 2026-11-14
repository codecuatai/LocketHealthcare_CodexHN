# VitaSnap

Mạng xã hội chia sẻ Khoảnh khắc ăn uống và vận động với bạn bè, kèm AI phân tích calo và cá nhân hóa theo bệnh lý nền. Viết bằng Flutter, dùng Provider.

- **Tài khoản**: Firebase Authentication (email/mật khẩu, Google).
- **Hồ sơ và ảnh**: Supabase (Postgres + Storage, bảo vệ bằng RLS).

Thuật ngữ nằm trong [`GLOSSARY.md`](GLOSSARY.md), các quyết định kiến trúc nằm trong [`docs/adr/`](docs/adr/).

## Chạy

Lần đầu, làm theo [`docs/setup-backend.md`](docs/setup-backend.md) để tạo project Firebase và Supabase. Sau đó:

```sh
flutter pub get
flutter run --dart-define-from-file=env/dev.json
```

Chỉ phần đăng nhập và Hồ sơ là dữ liệu thật. Sau khi đăng nhập, app có ba tab **Bảng tin · Chụp · Nhật ký** và màn **Cá nhân** (mở bằng avatar), tất cả chạy trên dữ liệu demo trong bộ nhớ:

- Mỗi chức năng có một repository dạng interface trong `lib/data/` (AI đọc ảnh, Nhật ký, Khoảnh khắc, Tin nhắn, Bạn bè, Thông tin sức khỏe, AI Coach), kèm bản demo. Nối backend là thay từng bản demo trong `AppServices` (`lib/data/app_services.dart`).
- Camera chưa nối máy ảnh thật: khung ngắm hiện ảnh mẫu trong `assets/images/samples/`, vuốt ngang để đổi; nút thư viện chọn ảnh mẫu. Ảnh bàn làm việc và chai nước dùng để thử ảnh bị từ chối và ảnh vùng xám.
- Thông tin sức khỏe tách khỏi Hồ sơ (xem `GLOSSARY.md`) và hiện chỉ lưu trong bộ nhớ.

## Kiểm tra

```sh
flutter analyze
flutter test
```

Test dùng repository giả (`test/fakes.dart`), nên không cần mạng hay cấu hình backend.
