# Cài đặt backend: Firebase + Supabase

Firebase lo **Tài khoản** (đăng nhập bằng email/mật khẩu và Google). Supabase lo **Hồ sơ** và **kho ảnh**. Lý do chia đôi nằm ở `docs/adr/0001` và `docs/adr/0002`.

Mọi bước đều làm trên trang web của Firebase và Supabase, không cần Firebase CLI hay FlutterFire CLI. Mỗi bước chỉ làm một lần cho mỗi project. Hiện tại app chỉ hỗ trợ Android, package name là **`com.vitasnap.vitasnap`**.

## 0. Chuẩn bị máy (Windows)

- Bật **Developer Mode** (`start ms-settings:developers`). Flutter cần quyền tạo symlink để build plugin.
- Android SDK cần có **NDK 28.2.13676358**. Lần build đầu Gradle sẽ báo nếu thiếu. Cài bằng Android Studio (SDK Manager → SDK Tools → NDK (Side by side)) hoặc bằng lệnh:
  ```sh
  "%LOCALAPPDATA%\Android\sdk\cmdline-tools\latest\bin\android.exe" sdk install ndk/28.2.13676358
  ```

## 1. Firebase (console.firebase.google.com)

1. **Add project**, đặt tên (ví dụ `vitasnap-hn`). Google Analytics không bắt buộc.
2. **Build → Authentication → Get started → Sign-in method**:
   - Bật **Email/Password**. Không bật "Email link".
   - Bật **Google** và chọn email hỗ trợ. Mở lại mục Google, phần **Web SDK configuration** có **Web client ID**. Chép giá trị này để dùng ở bước 3.
3. **Authentication → Settings → User actions**: giữ **Email enumeration protection** ở trạng thái bật (mặc định).
4. Lấy vân tay SHA của keystore debug trên máy mình. Đây là bước duy nhất phải dùng terminal, vì trang web không đọc được keystore:
   ```sh
   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```
   Chép 2 dòng **SHA1** và **SHA256**.
5. Ở **Project Overview**, bấm biểu tượng **Android** để đăng ký app:
   - Android package name: `com.vitasnap.vitasnap`
   - Debug signing certificate SHA-1: dán SHA1 ở bước 4
   - Bấm **Register app** → **Download google-services.json**, rồi đặt file vào **`android/app/google-services.json`**.
   - Các bước "Add Firebase SDK" của wizard thì bỏ qua, vì repo đã cấu hình sẵn plugin Google Services trong Gradle.
6. **Project settings → Your apps → Android app → Add fingerprint**: thêm SHA-256.

Mỗi máy dev có keystore debug riêng, nên mỗi thành viên phải thêm SHA-1/SHA-256 của máy mình ở bước 6. Sau mỗi lần thêm vân tay, tải lại `google-services.json`.

App không dùng `firebase_options.dart`: trên Android, `Firebase.initializeApp()` tự đọc cấu hình mà plugin Google Services sinh ra từ `google-services.json`.

## 2. Supabase (supabase.com/dashboard)

1. **New project**, chọn region gần nhất (Singapore).
2. Mở **SQL Editor → New query**, dán toàn bộ file `supabase/migrations/20261113000000_profiles_and_storage.sql` rồi bấm **Run**. Script này tạo bảng `profiles`, 2 bucket `avatars` và `moment-photos`, cùng toàn bộ policy. Chạy lại nhiều lần cũng không sao.
3. **Authentication → Sign In / Providers → Third-Party Auth → Add provider → Firebase**, nhập **Firebase project ID** (`project_info.project_id` trong `google-services.json`). Thiếu bước này thì Supabase từ chối token của app và mọi request đọc/ghi Hồ sơ sẽ bị chặn.
4. **Authentication → Sign In / Providers → Email**: tắt **Allow new users to sign up**. App không dùng Supabase Auth, và tắt đi thì không ai tạo được tài khoản Supabase riêng.
5. Chép 2 giá trị khác nhau: **Project URL** ở **Project Settings → Data API**, và **Publishable key** ở **Project Settings → API Keys** (key cũ tên là `anon`). Key này được phép nằm trong app. **Không bao giờ** đưa `service_role`/secret key vào app hoặc repo.

## 3. Cắm cấu hình vào app

Copy `env/dev.example.json` thành `env/dev.json` (file này đã nằm trong `.gitignore`) rồi điền:

| Khoá | Lấy ở đâu |
| --- | --- |
| `SUPABASE_URL` | Supabase → Project Settings → Data API → **Project URL** (dạng `https://<ref>.supabase.co`) |
| `SUPABASE_PUBLISHABLE_KEY` | Supabase → Project Settings → API Keys → **Publishable key** (dạng `sb_publishable_...`) |
| `GOOGLE_SERVER_CLIENT_ID` | Firebase → Authentication → Google → Web client ID |

Chạy app:

```sh
flutter run --dart-define-from-file=env/dev.json
```

Nếu thiếu cấu hình, app hiện màn **"Chưa cấu hình backend"** kèm tên khoá còn thiếu, thay vì crash.

## 4. Kiểm tra

1. Đăng nhập bằng Google. Vào Supabase **Table Editor → profiles**: phải có một dòng mới, với `id` là UID Firebase, tên và ảnh lấy từ Google.
2. Đăng xuất rồi đăng nhập lại: không có dòng trùng.
3. Đăng nhập sai mật khẩu: app báo "Email hoặc mật khẩu không đúng…".
4. Chạy thử trong SQL Editor (role mặc định của editor bỏ qua RLS, nên thử bằng role `anon`):
   ```sql
   set role anon;
   select count(*) from public.profiles; -- phải ra 0: không có token Firebase thì không thấy Hồ sơ nào
   reset role;
   ```

## Lỗi thường gặp

| Hiện tượng | Nguyên nhân |
| --- | --- |
| Build báo `File google-services.json is missing` | Chưa đặt file vào `android/app/` (bước 1.5). |
| Build báo thiếu NDK | Chưa cài NDK 28.2.13676358 (bước 0). |
| Đăng nhập Firebase được nhưng hiện "Chưa tải được hồ sơ" | Chưa thêm Firebase vào Third-Party Auth của Supabase (bước 2.3), hoặc chưa chạy SQL (bước 2.2). |
| Bấm Google báo "chưa hỗ trợ" hoặc không có gì xảy ra | Thiếu SHA-1 (bước 1.5/1.6) hoặc thiếu `GOOGLE_SERVER_CLIENT_ID`. |
| `Building with plugins requires symlink support` | Chưa bật Developer Mode (bước 0). |
