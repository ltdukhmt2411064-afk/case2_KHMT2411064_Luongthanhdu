const mongoose = require("mongoose");
const TaskShare = require("../models/TaskShare");

const idOf = (v) => String(v && v._id ? v._id : v);
const isValidId = (id) => mongoose.Types.ObjectId.isValid(id);

// Vai trò của user với 1 công việc: owner | assignee | editor | viewer | null
// sharePermission: quyền chia sẻ của user với task này (nếu có)
const getRole = (task, userId, sharePermission = null) => {
  const uid = String(userId);
  if (idOf(task.createdBy) === uid) return "owner";
  if (task.assigneeIds.some((a) => idOf(a) === uid)) return "assignee";
  if (sharePermission === "editor") return "editor";
  if (sharePermission === "viewer") return "viewer";
  return null;
};

const getRoleAsync = async (task, userId) => {
  const share = await TaskShare.findOne({ taskId: task._id, userId });
  return getRole(task, userId, share ? share.permission : null);
};

module.exports = { idOf, isValidId, getRole, getRoleAsync };
