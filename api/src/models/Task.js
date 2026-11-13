const mongoose = require("mongoose");

const PRIORITY_ORDER = { low: 1, medium: 2, high: 3 };

const taskSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, "Tên công việc là bắt buộc"],
      trim: true,
      maxlength: [200, "Tên công việc tối đa 200 ký tự"],
    },
    description: { type: String, default: "", trim: true, maxlength: 5000 },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    // Nhóm C sẽ dùng 2 trường này để giao việc
    assigneeIds: [
      { type: mongoose.Schema.Types.ObjectId, ref: "User", index: true },
    ],
    primaryAssigneeId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },
    startDate: { type: Date, default: null },
    dueDate: { type: Date, default: null },
    priority: {
      type: String,
      enum: ["low", "medium", "high"],
      default: "medium",
    },
    priorityOrder: { type: Number, default: 2 }, // để sắp xếp theo ưu tiên
    status: {
      type: String,
      enum: ["todo", "in_progress", "done"],
      default: "todo",
    },
  },
  { timestamps: true },
);

// Luôn đồng bộ priorityOrder với priority (chạy cả khi create và save)
taskSchema.pre("validate", function (next) {
  this.priorityOrder = PRIORITY_ORDER[this.priority] || 2;
  next();
});

module.exports = mongoose.model("Task", taskSchema);
