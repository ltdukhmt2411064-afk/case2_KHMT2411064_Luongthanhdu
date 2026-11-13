const Notification = require("../models/Notification");
const EmailLog = require("../models/EmailLog");
const Task = require("../models/Task");
const { isValidId, getRoleAsync } = require("../utils/taskAccess");
const { sendTaskEmail } = require("../services/emailService");

// GET /api/notifications
exports.getNotifications = async (req, res, next) => {
  try {
    const notifications = await Notification.find({ userId: req.user._id })
      .populate("taskId", "title status dueDate")
      .sort({ createdAt: -1 })
      .limit(50);

    res.json({ status: "success", data: { notifications } });
  } catch (err) {
    next(err);
  }
};

// GET /api/notifications/unread-count
exports.getUnreadCount = async (req, res, next) => {
  try {
    const count = await Notification.countDocuments({
      userId: req.user._id,
      isRead: false,
    });
    res.json({ status: "success", data: { unreadCount: count } });
  } catch (err) {
    next(err);
  }
};

// PATCH /api/notifications/:id/read
exports.markAsRead = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!isValidId(id)) {
      return res
        .status(400)
        .json({ status: "error", message: "ID thông báo không hợp lệ" });
    }

    const notification = await Notification.findOneAndUpdate(
      { _id: id, userId: req.user._id },
      { isRead: true },
      { new: true },
    );

    if (!notification) {
      return res
        .status(404)
        .json({ status: "error", message: "Không tìm thấy thông báo" });
    }

    res.json({ status: "success", data: { notification } });
  } catch (err) {
    next(err);
  }
};

// PATCH /api/notifications/read-all
exports.markAllAsRead = async (req, res, next) => {
  try {
    await Notification.updateMany(
      { userId: req.user._id, isRead: false },
      { isRead: true },
    );
    res.json({
      status: "success",
      message: "Đã đánh dấu tất cả thông báo là đã đọc",
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/tasks/:id/email-logs
exports.getTaskEmailLogs = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!isValidId(id)) {
      return res
        .status(400)
        .json({ status: "error", message: "ID công việc không hợp lệ" });
    }

    const task = await Task.findById(id);
    if (!task) {
      return res
        .status(404)
        .json({ status: "error", message: "Không tìm thấy công việc" });
    }

    const role = await getRoleAsync(task, req.user._id);
    if (role !== "owner") {
      return res
        .status(403)
        .json({
          status: "error",
          message: "Chỉ người tạo mới được xem lịch sử email",
        });
    }

    const logs = await EmailLog.find({ taskId: id }).sort({ createdAt: -1 });
    res.json({ status: "success", data: { emailLogs: logs } });
  } catch (err) {
    next(err);
  }
};

// POST /api/email-logs/:id/retry
exports.retryEmailLog = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!isValidId(id)) {
      return res
        .status(400)
        .json({ status: "error", message: "ID lịch sử email không hợp lệ" });
    }

    const log = await EmailLog.findById(id);
    if (!log) {
      return res
        .status(404)
        .json({ status: "error", message: "Không tìm thấy bản ghi email" });
    }

    if (log.status === "sent") {
      return res
        .status(400)
        .json({
          status: "error",
          message: "Email này đã được gửi thành công trước đó",
        });
    }

    if (log.attempts >= 5) {
      return res
        .status(429)
        .json({
          status: "error",
          message: "Đã vượt quá số lần thử gửi lại cho phép",
        });
    }

    const task = log.taskId ? await Task.findById(log.taskId) : null;
    if (task) {
      const role = await getRoleAsync(task, req.user._id);
      if (role !== "owner") {
        return res
          .status(403)
          .json({
            status: "error",
            message: "Không có quyền thử gửi lại email này",
          });
      }
    }

    const updated = await sendTaskEmail({
      taskId: log.taskId,
      recipientEmail: log.recipientEmail,
      eventType: log.eventType,
      payload: { taskTitle: task?.title },
    });

    res.json({ status: "success", data: { emailLog: updated } });
  } catch (err) {
    next(err);
  }
};
