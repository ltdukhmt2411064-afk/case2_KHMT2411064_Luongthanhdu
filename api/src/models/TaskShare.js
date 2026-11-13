// Dùng đầy đủ ở nhóm C (chia sẻ). Tạo sẵn để danh sách "được chia sẻ" ở nhóm B hoạt động.
const mongoose = require("mongoose");

const taskShareSchema = new mongoose.Schema(
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
      index: true,
    },
    permission: { type: String, enum: ["viewer", "editor"], default: "viewer" },
    sharedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  },
  { timestamps: { createdAt: true, updatedAt: false } },
);

taskShareSchema.index({ taskId: 1, userId: 1 }, { unique: true });

module.exports = mongoose.model("TaskShare", taskShareSchema);
