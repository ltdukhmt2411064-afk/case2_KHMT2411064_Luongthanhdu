const Task = require("../models/Task");
const TaskShare = require("../models/TaskShare");

const DAY_MS = 24 * 60 * 60 * 1000;

// Công việc liên quan đến người dùng: do mình tạo, được giao hoặc được chia sẻ
const scopeFilter = async (userId) => {
  const shares = await TaskShare.find({ userId }).select("taskId").lean();
  return {
    $or: [
      { createdBy: userId },
      { assigneeIds: userId },
      { _id: { $in: shares.map((s) => s.taskId) } },
    ],
  };
};

const parseDays = (value) => {
  const n = parseInt(value, 10);
  return Math.min(Math.max(Number.isNaN(n) ? 3 : n, 1), 30);
};

// Hạn hoàn thành là đầu ngày; công việc chỉ "quá hạn" khi hết ngày đó
const overdueBefore = () => new Date(Date.now() - DAY_MS);

const dueSoonFilter = (scope, days) => ({
  ...scope,
  status: { $ne: "done" },
  dueDate: { $gte: overdueBefore(), $lte: new Date(Date.now() + days * DAY_MS) },
});

const overdueFilter = (scope) => ({
  ...scope,
  status: { $ne: "done" },
  dueDate: { $lt: overdueBefore(), $ne: null },
});

// GET /api/statistics/overview?days=3
const getOverview = async (req, res, next) => {
  try {
    const me = req.user._id;
    const days = parseDays(req.query.days);
    const scope = await scopeFilter(me);

    const [byStatus, createdByMe, assignedToMe, primaryActive, sharedWithMe, dueSoon, overdue] =
      await Promise.all([
        Task.aggregate([{ $match: scope }, { $group: { _id: "$status", count: { $sum: 1 } } }]),
        Task.countDocuments({ createdBy: me }),
        Task.countDocuments({ assigneeIds: me }),
        Task.countDocuments({ primaryAssigneeId: me, status: { $ne: "done" } }),
        TaskShare.countDocuments({ userId: me }),
        Task.countDocuments(dueSoonFilter(scope, days)),
        Task.countDocuments(overdueFilter(scope)),
      ]);

    const counts = { todo: 0, in_progress: 0, done: 0 };
    byStatus.forEach((row) => {
      if (row._id in counts) counts[row._id] = row.count;
    });

    res.status(200).json({
      status: "success",
      data: {
        total: counts.todo + counts.in_progress + counts.done,
        byStatus: counts,
        createdByMe,
        assignedToMe,
        primaryActive,
        sharedWithMe,
        dueSoon,
        overdue,
        dueSoonDays: days,
      },
    });
  } catch (error) {
    next(error);
  }
};

const listTasks = async (filter, res, next) => {
  try {
    const tasks = await Task.find(filter)
      .sort({ dueDate: 1, _id: -1 })
      .limit(50)
      .populate("createdBy", "fullName email avatarUrl")
      .populate("assigneeIds", "fullName email avatarUrl")
      .lean();
    res.status(200).json({
      status: "success",
      results: tasks.length,
      data: { tasks },
    });
  } catch (error) {
    next(error);
  }
};

// GET /api/statistics/due-soon?days=3
const getDueSoon = async (req, res, next) => {
  try {
    const scope = await scopeFilter(req.user._id);
    await listTasks(dueSoonFilter(scope, parseDays(req.query.days)), res, next);
  } catch (error) {
    next(error);
  }
};

// GET /api/statistics/overdue
const getOverdue = async (req, res, next) => {
  try {
    const scope = await scopeFilter(req.user._id);
    await listTasks(overdueFilter(scope), res, next);
  } catch (error) {
    next(error);
  }
};

module.exports = { getOverview, getDueSoon, getOverdue };
