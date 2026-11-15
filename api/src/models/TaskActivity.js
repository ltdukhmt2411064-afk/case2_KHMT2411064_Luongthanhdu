const mongoose = require("mongoose");

// Lịch sử hoạt động của công việc: ai làm gì, lúc nào
const taskActivitySchema = new mongoose.Schema(
  {
    taskId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Task",
      required: true,
      index: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    // task_created, task_updated, status_changed, task_deleted,
    // assignees_added, primary_assignee_changed, assignee_removed,
    // task_shared, share_permission_changed, share_revoked
    action: { type: String, required: true },
    details: { type: String, default: "" },
  },
  {
    collection: "task_activities",
    timestamps: { createdAt: true, updatedAt: false },
  },
);

taskActivitySchema.index({ taskId: 1, createdAt: -1 });

module.exports = mongoose.model("TaskActivity", taskActivitySchema);
