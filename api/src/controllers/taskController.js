const Task = require('../models/Task');
const taskService = require('../services/taskService');
const PRIORITY_RANK = { low: 1, medium: 2, high: 3 };
const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

exports.createTask = async (req, res, next) => {
  try {
    const { title, description, priority, startDate, dueDate } = req.body;

    const task = await Task.create({
      title,
      description,
      priority,
      startDate: startDate || null,
      dueDate: dueDate || null,
      createdBy: req.user._id,
    });

    res.status(201).json({ message: 'Tạo công việc thành công', task });
  } catch (err) {
    next(err);
  }
};

exports.listTasks = async (req, res, next) => {
  try {
    const {
      scope = 'all',
      q,
      status,
      priority,
      sortBy = 'createdAt',
      order = 'desc',
    } = req.query;
    const me = req.user._id;

    if (status && !['todo', 'in_progress', 'completed'].includes(status)) {
      return res.status(400).json({ message: 'Trạng thái không hợp lệ' });
    }
    if (priority && !['low', 'medium', 'high'].includes(priority)) {
      return res.status(400).json({ message: 'Mức độ ưu tiên không hợp lệ' });
    }
    if (!['createdAt', 'dueDate', 'priority'].includes(sortBy)) {
      return res.status(400).json({ message: 'Tiêu chí sắp xếp không hợp lệ' });
    }
    if (!['asc', 'desc'].includes(order)) {
      return res.status(400).json({ message: 'Thứ tự sắp xếp không hợp lệ' });
    }

    let base;
    if (scope === 'created') {
      base = { createdBy: me };
    } else if (scope === 'assigned') {
      base = { assigneeIds: me };
    } else if (scope === 'shared') {
      // Nhóm C sẽ bổ sung: tìm theo bảng task_shares
      return res.json({ tasks: [] });
    } else if (scope === 'all') {
      base = { $or: [{ createdBy: me }, { assigneeIds: me }] };
    } else {
      return res.status(400).json({ message: 'Phạm vi danh sách không hợp lệ' });
    }

    const conditions = [base];
    if (q && q.trim()) {
      conditions.push({ title: { $regex: escapeRegex(q.trim()), $options: 'i' } });
    }
    if (status) conditions.push({ status });
    if (priority) conditions.push({ priority });

    const tasks = await Task.find({ $and: conditions });

    const dir = order === 'asc' ? 1 : -1;
    tasks.sort((a, b) => {
      if (sortBy === 'dueDate') {
        // Công việc chưa có hạn luôn xếp cuối
        if (!a.dueDate && !b.dueDate) return 0;
        if (!a.dueDate) return 1;
        if (!b.dueDate) return -1;
        return (a.dueDate - b.dueDate) * dir;
      }
      if (sortBy === 'priority') {
        return (PRIORITY_RANK[a.priority] - PRIORITY_RANK[b.priority]) * dir;
      }
      return (a.createdAt - b.createdAt) * dir;
    });

    res.json({ tasks });
  } catch (err) {
    next(err);
  }
};

exports.getTask = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!taskService.isValidId(id)) {
      return res.status(400).json({ message: 'Mã công việc không hợp lệ' });
    }

    const task = await Task.findById(id)
      .populate('createdBy', 'fullName email')
      .populate('assigneeIds', 'fullName email')
      .populate('primaryAssigneeId', 'fullName email');

    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }

    const access = taskService.getAccess(task, req.user._id);
    if (!access) {
      return res.status(403).json({ message: 'Bạn không có quyền truy cập công việc này' });
    }

    res.json({ task, access });
  } catch (err) {
    next(err);
  }
};

exports.updateTask = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!taskService.isValidId(id)) {
      return res.status(400).json({ message: 'Mã công việc không hợp lệ' });
    }

    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }

    const access = taskService.getAccess(task, req.user._id);
    if (!access) {
      return res.status(403).json({ message: 'Bạn không có quyền truy cập công việc này' });
    }
    if (!access.canEdit) {
      return res.status(403).json({ message: 'Bạn không có quyền chỉnh sửa công việc này' });
    }

    const { title, description, priority, startDate, dueDate } = req.body;
    if (title !== undefined) task.title = title;
    if (description !== undefined) task.description = description;
    if (priority !== undefined) task.priority = priority;
    if (startDate !== undefined) task.startDate = startDate || null;
    if (dueDate !== undefined) task.dueDate = dueDate || null;

    if (task.startDate && task.dueDate && task.dueDate < task.startDate) {
      return res.status(400).json({ message: 'Hạn hoàn thành phải sau ngày bắt đầu' });
    }

    await task.save();
    res.json({ message: 'Cập nhật công việc thành công', task });
  } catch (err) {
    next(err);
  }
};

exports.deleteTask = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!taskService.isValidId(id)) {
      return res.status(400).json({ message: 'Mã công việc không hợp lệ' });
    }

    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }

    const access = taskService.getAccess(task, req.user._id);
    if (!access) {
      return res.status(403).json({ message: 'Bạn không có quyền truy cập công việc này' });
    }
    if (!access.canDelete) {
      return res.status(403).json({ message: 'Bạn không có quyền xóa công việc này' });
    }

    await task.deleteOne();
    res.json({ message: 'Xóa công việc thành công' });
  } catch (err) {
    next(err);
  }
};

exports.updateStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!taskService.isValidId(id)) {
      return res.status(400).json({ message: 'Mã công việc không hợp lệ' });
    }

    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }

    const access = taskService.getAccess(task, req.user._id);
    if (!access) {
      return res.status(403).json({ message: 'Bạn không có quyền truy cập công việc này' });
    }
    if (!access.canUpdateStatus) {
      return res.status(403).json({ message: 'Bạn không có quyền cập nhật trạng thái' });
    }

    task.status = req.body.status;
    await task.save();
    res.json({ message: 'Cập nhật trạng thái thành công', task });
  } catch (err) {
    next(err);
  }
};