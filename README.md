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

Các màn Camera, Feed và Dashboard vẫn dùng dữ liệu mẫu. Chỉ phần đăng nhập và Hồ sơ là dữ liệu thật.

## Kiểm tra

```sh
flutter analyze
flutter test
```

Test dùng repository giả (`test/fakes.dart`), nên không cần mạng hay cấu hình backend.
