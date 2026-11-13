function buildEmailTemplate(
  eventType,
  { taskTitle, actorName, permission, dueDate },
) {
  const safeTitle = taskTitle || "Công việc";
  const safeActor = actorName || "Một thành viên";

  switch (eventType) {
    case "task_assigned":
      return {
        subject: `[Task Manager] Bạn được giao công việc mới: ${safeTitle}`,
        html: `<p>Xin chào,</p><p><b>${safeActor}</b> vừa giao cho bạn công việc: <b>${safeTitle}</b>.</p>`,
      };
    case "task_shared":
      return {
        subject: `[Task Manager] Công việc "${safeTitle}" đã được chia sẻ với bạn`,
        html: `<p>Xin chào,</p><p><b>${safeActor}</b> đã chia sẻ công việc <b>${safeTitle}</b> với quyền <b>${permission || "viewer"}</b>.</p>`,
      };
    case "due_date_changed":
      return {
        subject: `[Task Manager] Thay đổi hạn hoàn thành: ${safeTitle}`,
        html: `<p>Xin chào,</p><p><b>${safeActor}</b> đã cập nhật hạn hoàn thành của công việc <b>${safeTitle}</b> thành <b>${dueDate || "chưa xác định"}</b>.</p>`,
      };
    case "task_completed":
      return {
        subject: `[Task Manager] Công việc đã hoàn thành: ${safeTitle}`,
        html: `<p>Xin chào,</p><p>Công việc <b>${safeTitle}</b> đã được <b>${safeActor}</b> đánh dấu hoàn thành.</p>`,
      };
    default:
      return {
        subject: `[Task Manager] Cập nhật công việc: ${safeTitle}`,
        html: `<p>Xin chào,</p><p>Có cập nhật mới từ <b>${safeActor}</b> trên công việc <b>${safeTitle}</b>.</p>`,
      };
  }
}

module.exports = { buildEmailTemplate };
