const mongoose = require("mongoose");
const Task = require("../models/Task");
const TaskShare = require("../models/TaskShare");
const User = require("../models/User");
const TaskActivity = require("../models/TaskActivity");

// Tự động ghi lịch sử hoạt động cho các thao tác thành công trên /api/tasks/*
// mà KHÔNG cần sửa từng controller. Mọi lỗi ghi log đều bị bỏ qua để không
// ảnh hưởng đến thao tác chính của người dùng.

const STATUS = {
  todo: "Chưa thực hiện",
  in_progress: "Đang thực hiện",
  done: "Đã hoàn thành",
};
const PRIORITY = { low: "Thấp", medium: "Trung bình", high: "Cao" };
const PERMISSION = { viewer: "Chỉ xem", editor: "Được sửa" };

const ID = "([a-fA-F0-9]{24})";
const RE = {
  create: /^\/api\/tasks$/,
  task: new RegExp(`^/api/tasks/${ID}$`),
  status: new RegExp(`^/api/tasks/${ID}/status$`),
  assignees: new RegExp(`^/api/tasks/${ID}/assignees$`),
  assignee: new RegExp(`^/api/tasks/${ID}/assignees/${ID}$`),
  shares: new RegExp(`^/api/tasks/${ID}/shares$`),
  share: new RegExp(`^/api/tasks/${ID}/shares/${ID}$`),
};

const fmtDate = (d) =>
  d
    ? new Date(d).toLocaleDateString("vi-VN", { timeZone: "Asia/Ho_Chi_Minh" })
    : "chưa đặt";

const timeOf = (d) => (d ? new Date(d).getTime() : null);

const statusText = (s) => STATUS[s] || s;

const userNames = async (ids) => {
  const valid = (ids || []).filter((i) => mongoose.Types.ObjectId.isValid(i));
  if (!valid.length) return "";
  const users = await User.find({ _id: { $in: valid } })
    .select("fullName")
    .lean();
  return users.map((u) => u.fullName).join(", ");
};

const bodyUserIds = (body) => {
  if (Array.isArray(body.userIds)) return body.userIds;
  if (body.userId) return [body.userId];
  return [];
};

function diffTask(before, after) {
  const changes = [];
  if (before.title !== after.title) {
    changes.push(`Tên: "${before.title}" → "${after.title}"`);
  }
  if ((before.description || "") !== (after.description || "")) {
    changes.push("Đã sửa mô tả");
  }
  if (timeOf(before.startDate) !== timeOf(after.startDate)) {
    changes.push(
      `Ngày bắt đầu: ${fmtDate(before.startDate)} → ${fmtDate(after.startDate)}`,
    );
  }
  if (timeOf(before.dueDate) !== timeOf(after.dueDate)) {
    changes.push(
      `Hạn hoàn thành: ${fmtDate(before.dueDate)} → ${fmtDate(after.dueDate)}`,
    );
  }
  if (before.priority !== after.priority) {
    changes.push(
      `Ưu tiên: ${PRIORITY[before.priority] || before.priority} → ${PRIORITY[after.priority] || after.priority}`,
    );
  }
  const statusChange =
    before.status !== after.status
      ? `Trạng thái: ${statusText(before.status)} → ${statusText(after.status)}`
      : null;
  return { changes, statusChange };
}

// Trả về { record(body) } nếu request này cần ghi lịch sử, ngược lại trả null
async function prepare(req, url) {
  const log = (taskId, action, details) =>
    TaskActivity.create({ taskId, userId: req.user._id, action, details });
  let m;

  if (req.method === "POST" && RE.create.test(url)) {
    return {
      record: async (body) => {
        const t = body && body.data && body.data.task;
        if (t) await log(t._id, "task_created", `Tạo công việc "${t.title}"`);
      },
    };
  }

  if ((m = url.match(RE.task))) {
    const taskId = m[1];
    if (req.method === "PUT") {
      const before = await Task.findById(taskId).lean();
      return {
        record: async (body) => {
          const after = body && body.data && body.data.task;
          if (!before || !after) return;
          const { changes, statusChange } = diffTask(before, after);
          if (changes.length) await log(taskId, "task_updated", changes.join("; "));
          if (statusChange) await log(taskId, "status_changed", statusChange);
        },
      };
    }
    if (req.method === "DELETE") {
      const before = await Task.findById(taskId).select("title").lean();
      return {
        record: async () => {
          if (before) await log(taskId, "task_deleted", `Xóa công việc "${before.title}"`);
        },
      };
    }
    return null;
  }

  if (req.method === "PATCH" && (m = url.match(RE.status))) {
    const taskId = m[1];
    const before = await Task.findById(taskId).select("status").lean();
    return {
      record: async (body) => {
        const after = body && body.data && body.data.task;
        if (!before || !after || before.status === after.status) return;
        await log(
          taskId,
          "status_changed",
          `Trạng thái: ${statusText(before.status)} → ${statusText(after.status)}`,
        );
      },
    };
  }

  if (req.method === "POST" && (m = url.match(RE.assignees))) {
    const taskId = m[1];
    const ids = bodyUserIds(req.body || {});
    return {
      record: async () => {
        const names = await userNames(ids);
        await log(taskId, "assignees_added", `Giao việc cho: ${names || ids.length + " người"}`);
      },
    };
  }

  if ((m = url.match(RE.assignee))) {
    const [, taskId, userId] = m;
    if (req.method === "PATCH") {
      return {
        record: async () => {
          const name = await userNames([userId]);
          await log(taskId, "primary_assignee_changed", `Đặt ${name || "một người"} làm người phụ trách chính`);
        },
      };
    }
    if (req.method === "DELETE") {
      return {
        record: async () => {
          const name = await userNames([userId]);
          await log(taskId, "assignee_removed", `Hủy giao việc của ${name || "một người"}`);
        },
      };
    }
    return null;
  }

  if (req.method === "POST" && (m = url.match(RE.shares))) {
    const taskId = m[1];
    const ids = bodyUserIds(req.body || {});
    const permission = (req.body && req.body.permission) || "viewer";
    return {
      record: async () => {
        const names = await userNames(ids);
        await log(
          taskId,
          "task_shared",
          `Chia sẻ cho: ${names || ids.length + " người"} (${PERMISSION[permission] || permission})`,
        );
      },
    };
  }

  if ((m = url.match(RE.share))) {
    const [, taskId, shareId] = m;
    if (req.method === "PATCH") {
      const permission = req.body && req.body.permission;
      return {
        record: async () => {
          const share = await TaskShare.findById(shareId).populate("userId", "fullName").lean();
          const name = share && share.userId ? share.userId.fullName : "một người";
          await log(
            taskId,
            "share_permission_changed",
            `Đổi quyền của ${name} thành: ${PERMISSION[permission] || permission}`,
          );
        },
      };
    }
    if (req.method === "DELETE") {
      const share = await TaskShare.findById(shareId).populate("userId", "fullName").lean();
      return {
        record: async () => {
          const name = share && share.userId ? share.userId.fullName : "một người";
          await log(taskId, "share_revoked", `Thu hồi chia sẻ của ${name}`);
        },
      };
    }
  }

  return null;
}

module.exports = async function activityTracker(req, res, next) {
  try {
    if (!["POST", "PUT", "PATCH", "DELETE"].includes(req.method)) return next();
    if (!req.headers.authorization) return next();

    const url = req.originalUrl.split("?")[0].replace(/\/+$/, "");
    const ctx = await prepare(req, url).catch(() => null);
    if (!ctx) return next();

    let payload;
    const originalJson = res.json.bind(res);
    res.json = (body) => {
      payload = body;
      return originalJson(body);
    };

    res.on("finish", () => {
      if (res.statusCode < 200 || res.statusCode >= 300) return;
      if (!req.user || !req.user._id) return;
      Promise.resolve(ctx.record(payload)).catch(() => {});
    });
  } catch (e) {
    // không để lỗi ghi lịch sử chặn request
  }
  next();
};
