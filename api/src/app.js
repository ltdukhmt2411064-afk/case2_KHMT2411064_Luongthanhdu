const express = require("express");
const cors = require("cors");
const mongoose = require("mongoose");
const notificationController = require("./controllers/notificationController");
const authMiddleware = require("./middleware/authMiddleware");

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health Check Endpoint
app.get("/api/health", (req, res) => {
  const dbState = mongoose.connection.readyState;
  const states = {
    0: "disconnected",
    1: "connected",
    2: "connecting",
    3: "disconnecting",
  };

  res.status(200).json({
    status: "success",
    message: "Task Manager API is running",
    timestamp: new Date().toISOString(),
    database: {
      status: states[dbState] || "unknown",
      connected: dbState === 1,
    },
  });
});

// API Routes
app.use("/api/auth", require("./routes/authRoutes"));
app.use("/api/users", require("./routes/userRoutes"));
app.use("/api/tasks", require("./routes/taskRoutes"));
app.use("/api/tasks/:id/assignees", require("./routes/assignmentRoutes"));
app.use("/api/tasks/:id/shares", require("./routes/taskShareRoutes"));
app.use("/api/notifications", require("./routes/notificationRoutes"));
app.get(
  "/api/tasks/:id/email-logs",
  authMiddleware,
  notificationController.getTaskEmailLogs,
);
app.post(
  "/api/email-logs/:id/retry",
  authMiddleware,
  notificationController.retryEmailLog,
);

// Welcome Route
app.get("/", (req, res) => {
  res.json({
    name: "Task Manager API",
    version: "1.0.0",
    documentation: "/api/health",
  });
});

// Handle 404 - Not Found
app.use((req, res, next) => {
  res.status(404).json({
    status: "error",
    message: `Không tìm thấy endpoint: ${req.method} ${req.originalUrl}`,
  });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error(" [Unhandled Error]:", err.stack || err.message);
  res.status(err.status || 500).json({
    status: "error",
    message: err.message || "Lỗi máy chủ nội bộ",
  });
});

module.exports = app;
