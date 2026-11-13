# Firebase lo xác thực, Supabase lo lưu trữ

Tài khoản được quản lý bằng Firebase Authentication, còn Hồ sơ và ảnh được lưu trong Supabase (Postgres + Storage). Supabase tin Firebase ID token thông qua tính năng Third-Party Auth, nên app không dùng Supabase Auth. Khóa của mọi dữ liệu là Firebase UID, kiểu `text` chứ không phải `uuid`.

Nhóm quyết định chia đôi như vậy dù Supabase Auth đã làm được cả hai việc. Đây là lựa chọn của nhóm khi lên kế hoạch hackathon, nên đừng "gộp về Supabase Auth" nếu chưa bàn lại.
