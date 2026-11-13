# RLS kiểm tra `sub` của token Firebase trên role `anon`

Firebase ID token không có claim `role: authenticated`, nên Supabase xử lý mọi request của người đã đăng nhập dưới role `anon`. Muốn gắn claim đó thì phải có Cloud Function hoặc Identity Platform, mà cả hai đều cần gói Blaze (trả phí) của Firebase. Vì vậy policy RLS của bảng và Storage được viết cho role `anon` và kiểm tra `auth.jwt()->>'sub' = <firebase uid>`. Supabase hosted chỉ chấp nhận token có chữ ký hợp lệ từ đúng project Firebase đã đăng ký, nên không ai giả mạo được `sub`. Request không kèm token sẽ có `sub` rỗng và bị từ chối.

## Considered Options

- Blocking function gắn claim `role` (đúng như tài liệu Supabase hướng dẫn): bị loại vì cần gói Blaze.
- Backend FastAPI gắn claim qua Admin SDK: bị loại vì luồng đăng ký sẽ phụ thuộc vào một server chưa tồn tại.

## Consequences

Nếu sau này nhóm bật gói Blaze và gắn claim `role`, phải đổi mọi policy từ `to anon` sang `to authenticated`.
