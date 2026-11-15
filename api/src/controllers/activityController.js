const Task = require("../models/Task");
const TaskActivity = require("../models/TaskActivity");
const { isValidId, getRoleAsync } = require("../utils/taskAccess");

// GET /api/tasks/:id/activities  (người có quyền xem công việc đều xem được)
const getTaskActivities = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!isValidId(id)) {
      return res.status(400).json({ status: "fail", message: "ID công việc không hợp lệ" });
    }
    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({ status: "fail", message: "Không tìm thấy công việc" });
    }
    const role = await getRoleAsync(task, req.user._id);
    if (!role) {
      return res.status(404).json({ status: "fail", message: "Không tìm thấy công việc" });
    }

    const activities = await TaskActivity.find({ taskId: id })
      .sort({ createdAt: -1, _id: -1 })
      .limit(100)
      .populate("userId", "fullName email avatarUrl")
      .lean();

    res.status(200).json({
      status: "success",
      results: activities.length,
      data: { activities },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { getTaskActivities };
