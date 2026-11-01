# Task Manager API (Backend)

REST API phục vụ ứng dụng Quản lý và Giao công việc nhóm (Case Study 2).

## Công nghệ sử dụng
- **Node.js** & **Express**
- **MongoDB** & **Mongoose**
- **dotenv** quản lý biến môi trường
- **bcryptjs** băm mật khẩu
- **jsonwebtoken** xác thực JWT
- **nodemailer** gửi thông báo email

## Hướng dẫn cài đặt & chạy thử
1. Di chuyển vào thư mục `api`:
   ```bash
   cd api
   ```
2. Cài đặt các thư viện:
   ```bash
   npm install
   ```
3. Tạo file cấu hình môi trường `.env`:
   - Copy file mẫu `.env.example` thành `.env`
   - Điền chuỗi kết nối MongoDB vào `MONGO_URI`:
     ```env
     MONGO_URI=mongodb+srv://<username>:<password>@cluster.mongodb.net/task_manager?retryWrites=true&w=majority
     ```
   - Điền các biến `PORT`, `JWT_SECRET`, SMTP nếu cần.
4. Chạy server:
   - Chế độ phát triển (auto-reload):
     ```bash
     npm run dev
     ```
   - Chế độ thông thường:
     ```bash
     npm start
     ```
5. Kiểm tra trạng thái server:
   - Truy cập: `http://localhost:3000/api/health`
