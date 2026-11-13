const mongoose = require("mongoose");
const TaskShare = require("../models/TaskShare");

function isValidId(id) {
  return mongoose.Types.ObjectId.isValid(id);
}

/**
 * Xác định vai trò/quyền đồng bộ khi đã có sẵn bản ghi share
 * Trả về: 'owner' | 'assignee' | 'editor' | 'viewer' | null
 */
function getRole(task, userId, share = null) {
  if (!task || !userId) return null;
  const uid = String(userId);

  if (task.createdBy && String(task.createdBy._id || task.createdBy) === uid) {
    return "owner";
  }

  if (
    Array.isArray(task.assigneeIds) &&
    task.assigneeIds.some((id) => String(id._id || id) === uid)
  ) {
    return "assignee";
  }

  if (share && share.permission) {
    return share.permission; // 'editor' hoặc 'viewer'
  }

  return null;
}

/**
 * Xác định vai trò/quyền bất đồng bộ (tự truy vấn collection task_shares)
 */
async function getRoleAsync(task, userId) {
  if (!task || !userId) return null;
  const uid = String(userId);

  const directRole = getRole(task, uid, null);
  if (directRole) return directRole;

  const share = await TaskShare.findOne({
    taskId: task._id,
    userId: uid,
  }).lean();

  return share ? share.permission : null;
}

module.exports = {
  isValidId,
  getRole,
  getRoleAsync,
};
