# VitaSnap

Ứng dụng mạng xã hội chia sẻ khoảnh khắc ăn uống và tập luyện, kèm AI phân tích calo và cá nhân hóa gợi ý theo bệnh lý nền.

## Danh tính

**Tài khoản (Account)**:
Danh tính dùng để đăng nhập vào VitaSnap, gắn với đúng một địa chỉ email. Mỗi email có tối đa một Tài khoản.
_Avoid_: User, người dùng, login

**Hồ sơ (Profile)**:
Phần Bạn bè nhìn thấy về con người đứng sau một Tài khoản, gồm tên hiển thị, avatar, Chuỗi ngày và các Khoảnh khắc đã chia sẻ. Mỗi Tài khoản có đúng một Hồ sơ.
_Avoid_: UserModel, user info, trang cá nhân

**Thông tin sức khỏe (Health Info)**:
Phần riêng tư của một Tài khoản, gồm giới tính, năm sinh, chiều cao, cân nặng, mục tiêu và các Bệnh lý nền. Chỉ chủ Tài khoản và AI dùng, không bao giờ hiện cho Bạn bè. Có thể để trống.
_Avoid_: health profile, hồ sơ sức khỏe, chỉ số

## Ghi chép

**Nhật ký (Journal)**:
Toàn bộ Bản ghi của một Hồ sơ, chỉ chủ Hồ sơ xem được.
_Avoid_: Log, diary, lịch sử

**Bản ghi (Entry)**:
Một lần ghi vào Nhật ký, là một Bữa ăn hoặc một Hoạt động.
_Avoid_: Log, record, scan

**Bữa ăn (Meal)**:
Bản ghi về một món ăn hoặc đồ uống, bắt đầu từ một tấm ảnh. AI đọc ảnh và ước tính calo, người dùng sửa lại được.
_Avoid_: food log, scan result

**Hoạt động (Activity)**:
Bản ghi về một lần vận động, bắt đầu từ một tấm ảnh. AI nhận ra loại hoạt động từ ảnh. Người dùng khai các số đếm được (hiệp, lần, kg, cái, km, mét, bước). Thời gian có thể ghi thêm nhưng không bắt buộc, trừ những môn không đếm được như yoga. Calo tiêu hao được ước tính từ các số đếm và cân nặng, không lấy từ ảnh.
_Avoid_: workout, bài tập, exercise

## Chia sẻ

**Khoảnh khắc (Moment)**:
Một Bản ghi kèm ảnh mà chủ Hồ sơ chọn chia sẻ cho Bạn bè. Bạn bè xem được Khoảnh khắc của nhau. Bản ghi không chia sẻ thì vẫn chỉ nằm trong Nhật ký.
_Avoid_: Post, bài đăng, story

**Chuỗi ngày (Streak)**:
Số ngày liên tiếp, tính đến hôm nay, mà Tài khoản có ít nhất một Bản ghi. Bản ghi có chia sẻ hay không đều được tính.
_Avoid_: lửa, fire, chuỗi đăng bài

**Bạn bè (Friend)**:
Hai Hồ sơ đã đồng ý kết nối với nhau theo cả hai chiều. Chỉ Bạn bè mới thấy Khoảnh khắc của nhau.
_Avoid_: follower, người theo dõi, cộng đồng

## Sức khỏe

**Bệnh lý nền (Medical Condition)**:
Một tình trạng sức khỏe lâu dài ghi trong Thông tin sức khỏe (ví dụ Huyết áp cao, Đau khớp gối), kèm mức độ (Nhẹ, Đang theo dõi, Hạn chế vận động nặng). Bệnh lý nền là ràng buộc cứng cho mọi gợi ý.
_Avoid_: condition, bệnh
