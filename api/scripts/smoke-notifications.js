(async () => {
  const B = "http://localhost:3000/api", ts = Date.now();
  const r = (m, p, b, t) => fetch(B+p, { method: m, headers: { "Content-Type": "application/json", ...(t ? { Authorization: "Bearer "+t } : {}) }, body: b ? JSON.stringify(b) : undefined }).then(x => x.json());
  const u1 = await r("POST", "/auth/register", { fullName: "Nguyen Van A", email: `a${ts}@test.com`, password: "Password123" });
  const u2 = await r("POST", "/auth/register", { fullName: "Tran Thi B", email: `b${ts}@test.com`, password: "Password123" });
  if (!u1.data || !u2.data) { console.log("Lỗi đăng ký:", u1, u2); return; }
  const t1 = u1.data.token, t2 = u2.data.token, id2 = u2.data.user._id || u2.data.user.id;
  const task = await r("POST", "/tasks", { title: "Test Notif" }, t1);
  const tid = task.data.task._id;
  await r("POST", `/tasks/${tid}/assignees`, { userIds: [id2] }, t1);
  const unread = await r("GET", "/notifications/unread-count", null, t2);
  const logs = await r("GET", `/tasks/${tid}/email-logs`, null, t1);
  console.log("✅ Thông báo chưa đọc của B:", unread.data);
  console.log("✅ Email logs của task:", logs.data.emailLogs.length, "bản ghi");
})();
