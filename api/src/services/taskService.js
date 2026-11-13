const mongoose = require('mongoose');

exports.isValidId = (id) => mongoose.Types.ObjectId.isValid(id);

const idOf = (v) => String(v && v._id ? v._id : v);

exports.getAccess = (task, userId) => {
  const uid = String(userId);

  if (idOf(task.createdBy) === uid) {
    return { role: 'creator', canEdit: true, canDelete: true, canUpdateStatus: true };
  }

  if (task.assigneeIds.some((a) => idOf(a) === uid)) {
    return { role: 'assignee', canEdit: false, canDelete: false, canUpdateStatus: true };
  }

  return null;
};