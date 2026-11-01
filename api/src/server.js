const path = require('path');
const dotenv = require('dotenv');

// Tải biến môi trường từ file api/.env (hỗ trợ chạy từ thư mục gốc hoặc từ thư mục api)
dotenv.config({ path: path.resolve(__dirname, '../.env') });

const app = require('./app');
const connectDB = require('./config/database');

const PORT = process.env.PORT || 3000;

// Kết nối cơ sở dữ liệu MongoDB trước khi khởi động server
const startServer = async () => {
  await connectDB();

  const server = app.listen(PORT, () => {
    console.log(`===============================================`);
    console.log(`🚀 Task Manager API đang chạy tại cổng ${PORT}`);
    console.log(`🌐 Base URL: http://localhost:${PORT}/api`);
    console.log(`🔍 Health Check: http://localhost:${PORT}/api/health`);
    console.log(`===============================================`);
  });

  // Xử lý unhandled promise rejections
  process.on('unhandledRejection', (err) => {
    console.error(' [Unhandled Rejection]:', err.message);
    server.close(() => process.exit(1));
  });
};

startServer();
