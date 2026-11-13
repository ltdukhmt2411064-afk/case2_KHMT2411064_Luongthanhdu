const Task = require("../models/Task");
const TaskShare = require("../models/TaskShare");
const { isValidId, getRole, getRoleAsync } = require("../utils/taskAccess");

const USER_FIELDS = "fullName email avatarUrl";
const ALL_FIELDS = [
  "title",
  "description",
  "startDate",
  "dueDate",
  "priority",
  "status",
];

const populateTask = (q) =>
  q
    .populate("createdBy", USER_FIELDS)
    .populate("assigneeIds", USER_FIELDS)
    .populate("primaryAssigneeId", USER_FIELDS);

const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

// Tìm task + kiểm tra quyền xem. Trả về { task, role }, hoặc đã gửi lỗi và trả null
const loadTaskWithRole = async (req, res) => {
  const { id } = req.params;
  if (!isValidId(id)) {
    res
      .status(400)
      .json({ status: "fail", message: "ID công việc không hợp lệ" });
    return null;
  }
  const task = await Task.findById(id);
  if (!task) {
    res
      .status(404)
      .json({ status: "fail", message: "Không tìm thấy công việc" });
    return null;
  }
  const role = await getRoleAsync(task, req.user._id);
  if (!role) {
    // Trả 404 thay vì 403 để không lộ việc công việc có tồn tại
    res
      .status(404)
      .json({ status: "fail", message: "Không tìm thấy công việc" });
    return null;
  }
  return { task, role };
};

// GET /api/tasks?role=&status=&priority=&assigneeId=&search=&sortBy=&order=&page=&limit=
const listTasks = async (req, res, next) => {
  try {
    const me = req.user._id;
    const {
      role = "all",
      status,
      priority,
      assigneeId,
      search,
      sortBy = "createdAt",
      order = "desc",
      page = 1,
      limit = 20,
    } = req.query;

    const myShares = await TaskShare.find({ userId: me }).select(
      "taskId permission",
    );
    const shareMap = new Map(
      myShares.map((s) => [String(s.taskId), s.permission]),
    );
    const sharedIds = myShares.map((s) => s.taskId);

    const visibility = {
      created: { createdBy: me },
      assigned: { assigneeIds: me },
      shared: { _id: { $in: sharedIds } },
    };

    const filter = {};
    if (role === "all") {
      filter.$or = [visibility.created, visibility.assigned, visibility.shared];
    } else if (visibility[role]) {
      Object.assign(filter, visibility[role]);
    } else {
      return res
        .status(400)
        .json({
          status: "fail",
          message: "role phải là all, created, assigned hoặc shared",
        });
    }

    if (status) filter.status = status;
    if (priority) filter.priority = priority;
    if (assigneeId) {
      if (!isValidId(assigneeId)) {
        return res
          .status(400)
          .json({ status: "fail", message: "assigneeId không hợp lệ" });
      }
      filter.assigneeIds = assigneeId;
    }
    if (search && search.trim()) {
      filter.title = { $regex: escapeRegex(search.trim()), $options: "i" };
    }

    const sortField =
      { dueDate: "dueDate", priority: "priorityOrder", createdAt: "createdAt" }[
        sortBy
      ] || "createdAt";
    const dir = order === "asc" ? 1 : -1;
    const pageNum = Math.max(parseInt(page, 10) || 1, 1);
    const limitNum = Math.min(Math.max(parseInt(limit, 10) || 20, 1), 100);

    const [tasks, total] = await Promise.all([
      populateTask(Task.find(filter))
        .sort({ [sortField]: dir, _id: -1 })
        .skip((pageNum - 1) * limitNum)
        .limit(limitNum),
      Task.countDocuments(filter),
    ]);

    const data = tasks.map((t) => ({
      ...t.toObject(),
      myRole: getRole(t, me, shareMap.get(String(t._id)) || null),
    }));

    res.status(200).json({
      status: "success",
      results: data.length,
      total,
      page: pageNum,
      data: { tasks: data },
    });
  } catch (error) {
    next(error);
  }
};

// GET /api/tasks/:id
const getTask = async (req, res, next) => {
  try {
    const found = await loadTaskWithRole(req, res);
    if (!found) return;
    const populated = await populateTask(Task.findById(found.task._id));
    res.status(200).json({
      status: "success",
      data: { task: { ...populated.toObject(), myRole: found.role } },
    });
  } catch (error) {
    next(error);
  }
};

// POST /api/tasks
const createTask = async (req, res, next) => {
  try {
    const { title, description, startDate, dueDate, priority, status } =
      req.body;
    const task = await Task.create({
      title,
      description,
      startDate: startDate || null,
      dueDate: dueDate || null,
      priority,
      status,
      createdBy: req.user._id,
    });
    const populated = await populateTask(Task.findById(task._id));
    res.status(201).json({
      status: "success",
      message: "Tạo công việc thành công",
      data: { task: { ...populated.toObject(), myRole: "owner" } },
    });
  } catch (error) {
    next(error);
  }
};

// PUT /api/tasks/:id
// owner/editor: sửa mọi trường | assignee: chỉ đổi status | viewer: không được sửa
const updateTask = async (req, res, next) => {
  try {
    const found = await loadTaskWithRole(req, res);
    if (!found) return;
    const { task, role } = found;

    if (role === "viewer") {
      return res
        .status(403)
        .json({
          status: "fail",
          message: "Bạn chỉ có quyền xem công việc này",
        });
    }

    const editable = ["owner", "editor"].includes(role)
      ? ALL_FIELDS
      : ["status"];
    const forbidden = Object.keys(req.body).filter(
      (k) => ALL_FIELDS.includes(k) && !editable.includes(k),
    );
    if (forbidden.length) {
      return res
        .status(403)
        .json({
          status: "fail",
          message: "Bạn chỉ được cập nhật trạng thái của công việc này",
        });
    }

    editable.forEach((field) => {
      if (req.body[field] !== undefined) {
        task[field] =
          field === "startDate" || field === "dueDate"
            ? req.body[field] || null
            : req.body[field];
      }
    });
    await task.save();

    const populated = await populateTask(Task.findById(task._id));
    res.status(200).json({
      status: "success",
      message: "Cập nhật công việc thành công",
      data: { task: { ...populated.toObject(), myRole: role } },
    });
  } catch (error) {
    next(error);
  }
};

// PATCH /api/tasks/:id/status  (owner, editor, assignee)
const updateStatus = async (req, res, next) => {
  try {
    const found = await loadTaskWithRole(req, res);
    if (!found) return;
    if (found.role === "viewer") {
      return res
        .status(403)
        .json({
          status: "fail",
          message: "Bạn chỉ có quyền xem công việc này",
        });
    }
    found.task.status = req.body.status;
    await found.task.save();
    res.status(200).json({
      status: "success",
      message: "Cập nhật trạng thái thành công",
      data: { task: { _id: found.task._id, status: found.task.status } },
    });
  } catch (error) {
    next(error);
  }
};

// DELETE /api/tasks/:id  (chỉ người tạo)
const deleteTask = async (req, res, next) => {
  try {
    const found = await loadTaskWithRole(req, res);
    if (!found) return;
    if (found.role !== "owner") {
      return res
        .status(403)
        .json({
          status: "fail",
          message: "Chỉ người tạo mới được xóa công việc",
        });
    }
    await TaskShare.deleteMany({ taskId: found.task._id });
    await found.task.deleteOne();
    res.status(200).json({ status: "success", message: "Đã xóa công việc" });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  listTasks,
  getTask,
  createTask,
  updateTask,
  updateStatus,
  deleteTask,
};
