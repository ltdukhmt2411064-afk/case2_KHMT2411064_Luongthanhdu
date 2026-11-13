const Task = require("../models/Task");
const User = require("../models/User");
const { isValidId, getRoleAsync } = require("../utils/taskAccess");
const { notifyAndEmail } = require("../services/notificationService");

// GET /api/tasks/:id/assignees
exports.getAssignees = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!isValidId(id)) {
      return res
        .status(400)
        .json({ status: "error", message: "ID công việc không hợp lệ" });
    }

    const task = await Task.findById(id)
      .populate("assigneeIds", "fullName email avatarUrl")
      .populate("primaryAssigneeId", "fullName email avatarUrl");

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

    res.json({
      status: "success",
      data: {
        assignees: task.assigneeIds || [],
        primaryAssignee: task.primaryAssigneeId || null,
      },
    });
  } catch (err) {
    next(err);
  }
};

// POST /api/tasks/:id/assignees
exports.assignUsers = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { userIds, primaryAssigneeId } = req.body;

    if (!isValidId(id)) {
      return res
        .status(400)
        .json({ status: "error", message: "ID công việc không hợp lệ" });
    }

    if (!Array.isArray(userIds) || userIds.length === 0) {
      return res
        .status(400)
        .json({ status: "error", message: "Danh sách userIds không hợp lệ" });
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
          message: "Chỉ người tạo mới có quyền giao việc",
        });
    }

    const validUserIds = userIds.filter((uid) => isValidId(uid));
    const users = await User.find({ _id: { $in: validUserIds } }).select("_id");
    if (users.length === 0) {
      return res
        .status(400)
        .json({
          status: "error",
          message: "Không tìm thấy người dùng hợp lệ để giao",
        });
    }

    const currentSet = new Set(
      (task.assigneeIds || []).map((uid) => String(uid)),
    );
    users.forEach((u) => currentSet.add(String(u._id)));
    task.assigneeIds = Array.from(currentSet);

    if (primaryAssigneeId && currentSet.has(String(primaryAssigneeId))) {
      task.primaryAssigneeId = primaryAssigneeId;
    } else if (!task.primaryAssigneeId && task.assigneeIds.length > 0) {
      task.primaryAssigneeId = task.assigneeIds[0];
    }

    await task.save();

    // TỰ ĐỘNG TẠO THÔNG BÁO & GỬI EMAIL CHO NGƯỜI ĐƯỢC GIAO VIỆC
    for (const u of users) {
      if (String(u._id) === String(req.user._id)) continue;
      await notifyAndEmail({
        userId: u._id,
        taskId: task._id,
        type: "task_assigned",
        title: "Bạn được giao công việc mới",
        message: `${req.user.fullName || "Quản lý"} đã giao cho bạn công việc "${task.title}"`,
        emailPayload: { taskTitle: task.title, actorName: req.user.fullName },
      });
    }

    await task.populate("assigneeIds", "fullName email avatarUrl");
    await task.populate("primaryAssigneeId", "fullName email avatarUrl");

    res.json({
      status: "success",
      message: "Giao việc thành công",
      data: {
        assignees: task.assigneeIds,
        primaryAssignee: task.primaryAssigneeId,
      },
    });
  } catch (err) {
    next(err);
  }
};

// PATCH /api/tasks/:id/assignees/:userId
exports.updatePrimaryAssignee = async (req, res, next) => {
  try {
    const { id, userId } = req.params;
    if (!isValidId(id) || !isValidId(userId)) {
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
          message: "Chỉ người tạo mới có quyền đổi người phụ trách chính",
        });
    }

    const isAssigned = (task.assigneeIds || []).some(
      (uid) => String(uid) === String(userId),
    );
    if (!isAssigned) {
      return res
        .status(400)
        .json({
          status: "error",
          message: "Người dùng này chưa được giao công việc",
        });
    }

    task.primaryAssigneeId = userId;
    await task.save();
    await task.populate("primaryAssigneeId", "fullName email avatarUrl");

    res.json({
      status: "success",
      message: "Đã cập nhật người phụ trách chính",
      data: { primaryAssignee: task.primaryAssigneeId },
    });
  } catch (err) {
    next(err);
  }
};

// DELETE /api/tasks/:id/assignees/:userId
exports.removeAssignee = async (req, res, next) => {
  try {
    const { id, userId } = req.params;
    if (!isValidId(id) || !isValidId(userId)) {
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
          message: "Chỉ người tạo mới có quyền hủy giao việc",
        });
    }

    task.assigneeIds = (task.assigneeIds || []).filter(
      (uid) => String(uid) !== String(userId),
    );
    if (
      task.primaryAssigneeId &&
      String(task.primaryAssigneeId) === String(userId)
    ) {
      task.primaryAssigneeId = task.assigneeIds[0] || null;
    }

    await task.save();

    res.json({
      status: "success",
      message: "Đã hủy giao việc cho người dùng",
    });
  } catch (err) {
    next(err);
  }
};
