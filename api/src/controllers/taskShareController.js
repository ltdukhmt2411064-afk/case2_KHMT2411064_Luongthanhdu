const Task = require("../models/Task");
const TaskShare = require("../models/TaskShare");
const User = require("../models/User");
const { isValidId, getRoleAsync } = require("../utils/taskAccess");

// GET /api/tasks/:id/shares
exports.getShares = async (req, res, next) => {
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
    if (!role) {
      return res
        .status(404)
        .json({ status: "error", message: "Không tìm thấy công việc" });
    }

    const shares = await TaskShare.find({ taskId: id })
      .populate("userId", "fullName email avatarUrl")
      .populate("sharedBy", "fullName email")
      .sort({ createdAt: -1 });

    res.json({
      status: "success",
      data: { shares },
    });
  } catch (err) {
    next(err);
  }
};

// POST /api/tasks/:id/shares
// Body hỗ trợ cả 2 kiểu: { userIds: ["..."], permission: "viewer" } hoặc { shares: [{ userId: "...", permission: "editor" }] }
exports.shareTask = async (req, res, next) => {
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
          message: "Chỉ người tạo mới có quyền chia sẻ công việc",
        });
    }

    let items = [];
    if (Array.isArray(req.body.shares)) {
      items = req.body.shares;
    } else if (Array.isArray(req.body.userIds)) {
      const perm = req.body.permission || "viewer";
      items = req.body.userIds.map((userId) => ({ userId, permission: perm }));
    }

    if (items.length === 0) {
      return res
        .status(400)
        .json({ status: "error", message: "Danh sách chia sẻ không hợp lệ" });
    }

    const results = [];
    for (const item of items) {
      if (!isValidId(item.userId)) continue;
      if (String(item.userId) === String(task.createdBy)) continue; // Không tự chia sẻ cho chủ task
      const permission = ["viewer", "editor"].includes(item.permission)
        ? item.permission
        : "viewer";

      const userExists = await User.exists({ _id: item.userId });
      if (!userExists) continue;

      const shareDoc = await TaskShare.findOneAndUpdate(
        { taskId: id, userId: item.userId },
        {
          taskId: id,
          userId: item.userId,
          permission,
          sharedBy: req.user._id,
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      ).populate("userId", "fullName email avatarUrl");

      results.push(shareDoc);
    }

    res.status(201).json({
      status: "success",
      message: "Chia sẻ công việc thành công",
      data: { shares: results },
    });
  } catch (err) {
    next(err);
  }
};

// PATCH /api/tasks/:id/shares/:shareId
exports.updateSharePermission = async (req, res, next) => {
  try {
    const { id, shareId } = req.params;
    const { permission } = req.body;

    if (!isValidId(id) || !isValidId(shareId)) {
      return res
        .status(400)
        .json({ status: "error", message: "ID không hợp lệ" });
    }

    if (!["viewer", "editor"].includes(permission)) {
      return res
        .status(400)
        .json({ status: "error", message: "Quyền phải là viewer hoặc editor" });
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
          message: "Chỉ người tạo mới có quyền thay đổi phân quyền",
        });
    }

    const share = await TaskShare.findOneAndUpdate(
      { _id: shareId, taskId: id },
      { permission },
      { new: true },
    ).populate("userId", "fullName email avatarUrl");

    if (!share) {
      return res
        .status(404)
        .json({ status: "error", message: "Không tìm thấy bản ghi chia sẻ" });
    }

    res.json({
      status: "success",
      message: "Đã cập nhật quyền chia sẻ",
      data: { share },
    });
  } catch (err) {
    next(err);
  }
};

// DELETE /api/tasks/:id/shares/:shareId
exports.revokeShare = async (req, res, next) => {
  try {
    const { id, shareId } = req.params;
    if (!isValidId(id) || !isValidId(shareId)) {
      return res
        .status(400)
        .json({ status: "error", message: "ID không hợp lệ" });
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
          message: "Chỉ người tạo mới có quyền thu hồi chia sẻ",
        });
    }

    const deleted = await TaskShare.findOneAndDelete({
      _id: shareId,
      taskId: id,
    });
    if (!deleted) {
      return res
        .status(404)
        .json({ status: "error", message: "Không tìm thấy bản ghi chia sẻ" });
    }

    res.json({
      status: "success",
      message: "Đã thu hồi quyền chia sẻ",
    });
  } catch (err) {
    next(err);
  }
};
