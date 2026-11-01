# CASE STUDY 2
## ỨNG DỤNG QUẢN LÝ VÀ GIAO CÔNG VIỆC NHÓM
Flutter • Node.js/Express REST API • MongoDB • Email Notification

### 1. Mục tiêu và phạm vi
Ứng dụng cho phép người dùng quản lý công việc cá nhân, giao công việc cho một hoặc nhiều người, chia sẻ công việc để nhiều người cùng xem hoặc chỉnh sửa theo quyền, theo dõi tiến độ và gửi thông báo qua email.
Phạm vi bắt buộc đề xuất: đăng ký/đăng nhập; CRUD công việc; giao việc; chia sẻ và phân quyền; thông báo trong ứng dụng; gửi email khi giao việc hoặc chia sẻ. Các chức năng nâng cao có thể triển khai sau.

### 2. Danh sách chức năng
#### A. Quản lý tài khoản và xác thực
- Đăng ký tài khoản bằng họ tên, email và mật khẩu.
- Đăng nhập bằng email và mật khẩu.
- Đăng xuất khỏi hệ thống.
- Xem và cập nhật thông tin cá nhân.
- Đổi mật khẩu.

#### B. Quản lý công việc
- Xem danh sách công việc được tạo, được giao, được nhận và được chia sẻ.
- Xem chi tiết công việc; tạo, chỉnh sửa và xóa công việc.
- Cập nhật trạng thái: chưa thực hiện, đang thực hiện, đã hoàn thành.
- Thiết lập mức độ ưu tiên: thấp, trung bình, cao.
- Thiết lập ngày bắt đầu và hạn hoàn thành.
- Tìm kiếm theo tên; lọc theo trạng thái, ưu tiên, người phụ trách.
- Sắp xếp theo hạn hoàn thành, mức độ ưu tiên hoặc thời gian tạo.

#### C. Giao việc và chia sẻ
- Giao công việc cho một người hoặc nhiều người thông qua email/tài khoản.
- Chỉ định người phụ trách chính.
- Chia sẻ công việc cho nhiều người để cùng xem.
- Cấp quyền chỉ xem (viewer) hoặc chỉnh sửa (editor).
- Xem danh sách người được giao và người được chia sẻ.
- Thay đổi hoặc thu hồi quyền truy cập.
- Theo dõi tiến độ; phân loại theo vai trò người tạo, người phụ trách và người được chia sẻ.

#### D. Thông báo qua email và trong ứng dụng
- Gửi email khi giao công việc mới.
- Gửi email khi mời người dùng xem hoặc tham gia công việc.
- Gửi email khi hạn hoàn thành hoặc thông tin quan trọng thay đổi.
- Gửi email khi công việc hoàn thành.
- Nhắc việc trước hạn theo lịch cấu hình, ví dụ 24 giờ.
- Lưu lịch sử gửi email và trạng thái thành công/thất bại.
- Hiển thị thông báo trong ứng dụng, đánh dấu đã đọc và mở công việc liên quan.

#### E. Thống kê và tiện ích
- Thống kê tổng số công việc theo trạng thái.
- Thống kê công việc được giao và công việc đang phụ trách.
- Hiển thị công việc sắp đến hạn và đã quá hạn.
- Xem lịch sử hoạt động của công việc.
- Hiển thị trạng thái tải dữ liệu, thông báo lỗi và kết quả thao tác.

### 3. Danh sách màn hình
| Màn hình | Chức năng chính |
| --- | --- |
| 1. Đăng nhập | Nhập email/mật khẩu, kiểm tra thông tin và chuyển đến danh sách công việc; liên kết sang đăng ký. |
| 2. Đăng ký tài khoản | Nhập họ tên, email, mật khẩu và xác nhận mật khẩu; kiểm tra email trùng và tạo tài khoản. |
| 3. Danh sách công việc | Hiển thị công việc liên quan; phân loại công việc của tôi, được giao cho tôi, được chia sẻ; tìm kiếm, lọc, sắp xếp và tạo mới. |
| 4. Chi tiết công việc | Hiển thị mô tả, thời hạn, trạng thái, người tạo, người phụ trách, người được chia sẻ; mở chỉnh sửa, giao việc hoặc quản lý chia sẻ. |
| 5. Thêm công việc | Nhập tên, mô tả, ngày bắt đầu, hạn hoàn thành, mức độ ưu tiên và trạng thái ban đầu. |
| 6. Chỉnh sửa công việc | Cập nhật thông tin công việc và trạng thái theo quyền được cấp. |
| 7. Giao công việc | Tìm người theo tên/email, chọn một hoặc nhiều người phụ trách, chọn người phụ trách chính và xác nhận giao việc. |
| 8. Quản lý chia sẻ và quyền truy cập | Thêm người được xem, cấp viewer/editor, thay đổi quyền và thu hồi quyền chia sẻ. |
| 9. Thông báo | Xem thông báo giao việc, chia sẻ và thay đổi trạng thái; đánh dấu đã đọc và mở công việc liên quan. |
| 10. Cá nhân và thống kê | Xem/cập nhật hồ sơ, đổi mật khẩu, đăng xuất và xem số liệu công việc theo trạng thái, hạn hoàn thành. |

### 4. Cấu trúc dữ liệu MongoDB
- `users`: _id, fullName, email, passwordHash, avatarUrl, createdAt, updatedAt
- `tasks`: _id, title, description, createdBy, assigneeIds, primaryAssigneeId, startDate, dueDate, priority, status, createdAt, updatedAt
- `task_shares`: _id, taskId, userId, permission (viewer/editor), sharedBy, createdAt
- `notifications`: _id, userId, taskId, type, title, message, isRead, createdAt
- `email_logs`: _id, taskId, recipientEmail, eventType, subject, status (pending/sent/failed), attempts, errorMessage, sentAt, createdAt
- `task_activities`: _id, taskId, userId, action, details, createdAt

### 5. Cấu trúc thư mục dự án
#### 5.1. Frontend — Flutter (TaskManager)
#### 5.2. Backend — Node.js, Express và MongoDB (api)

### 6. Danh sách API endpoint
- Xác thực: `/api/auth/*`
- Người dùng: `/api/users/*`
- Công việc: `/api/tasks/*`
- Giao việc: `/api/tasks/:id/assignees/*`
- Chia sẻ: `/api/tasks/:id/shares/*`
- Thông báo: `/api/notifications/*`
- Thống kê: `/api/statistics/*`
- Email: `/api/email-logs/*`
