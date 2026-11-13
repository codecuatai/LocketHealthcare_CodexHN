# VitaSnap

Ứng dụng mạng xã hội chia sẻ khoảnh khắc ăn uống và tập luyện, kèm AI phân tích calo và cá nhân hóa gợi ý theo bệnh lý nền.

## Danh tính

**Tài khoản (Account)**:
Danh tính dùng để đăng nhập vào VitaSnap, gắn với đúng một địa chỉ email. Mỗi email có tối đa một Tài khoản.
_Avoid_: User, người dùng, login

**Hồ sơ (Profile)**:
Thông tin về con người đứng sau một Tài khoản, gồm tên hiển thị và các chỉ số sức khỏe. Mỗi Tài khoản có đúng một Hồ sơ.
_Avoid_: UserModel, user info, health profile (khi muốn nói toàn bộ Hồ sơ)

## Chia sẻ

**Khoảnh khắc (Moment)**:
Một bức ảnh về bữa ăn, đồ uống hoặc lúc vận động trong đời sống hằng ngày, được chia sẻ cho bạn bè.
_Avoid_: Post, bài đăng, story

## Sức khỏe

**Bệnh lý nền (Medical Condition)**:
Một tình trạng sức khỏe lâu dài ghi trong Hồ sơ (ví dụ Huyết áp cao, Đau khớp gối), dùng làm ràng buộc cứng cho mọi gợi ý.
_Avoid_: condition, bệnh
