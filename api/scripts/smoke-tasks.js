// Chạy: node scripts/smoke-tasks.js   (backend phải đang chạy, Node 18+)
const BASE = process.env.BASE || "http://localhost:3000/api";
let pass = 0,
  fail = 0;

const call = async (method, path, token, body) => {
  const res = await fetch(BASE + path, {
    method,
    headers: {
      "Content-Type": "application/json",
      ...(token && { Authorization: `Bearer ${token}` }),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: res.status, json: await res.json().catch(() => ({})) };
};
const check = (name, ok, extra = "") => {
  ok ? pass++ : fail++;
  console.log(`${ok ? "✅" : "❌"} ${name} ${ok ? "" : extra}`);
};

(async () => {
  const stamp = Date.now();
  const reg = async (n) =>
    (
      await call("POST", "/auth/register", null, {
        fullName: `Tester ${n}`,
        email: `t${n}_${stamp}@test.com`,
        password: "Test123456",
      })
    ).json.data;
  const A = await reg("a");
  const B = await reg("b");
  check("Đăng ký 2 tài khoản test", !!A?.token && !!B?.token);

  let r = await call("POST", "/tasks", null, { title: "x" });
  check("Không có token bị chặn (401)", r.status === 401);

  r = await call("POST", "/tasks", A.token, { title: "" });
  check("Tạo task thiếu tên bị từ chối (400)", r.status === 400);

  r = await call("POST", "/tasks", A.token, {
    title: "Hoan thanh bao cao",
    priority: "high",
    startDate: "2026-11-20",
    dueDate: "2026-11-10",
  });
  check("Hạn trước ngày bắt đầu bị từ chối (400)", r.status === 400);

  r = await call("POST", "/tasks", A.token, {
    title: "Hoan thanh bao cao",
    priority: "high",
    dueDate: "2026-12-01",
  });
  check(
    "Tạo task (201)",
    r.status === 201 && r.json.data.task.myRole === "owner",
    JSON.stringify(r.json),
  );
  const id = r.json.data?.task?._id;
  await call("POST", "/tasks", A.token, {
    title: "Mua sach",
    priority: "low",
    dueDate: "2026-11-15",
  });

  r = await call("GET", "/tasks", A.token);
  check(
    "Danh sách có 2 task",
    r.status === 200 && r.json.total === 2,
    JSON.stringify(r.json),
  );

  r = await call("GET", "/tasks?search=bao", A.token);
  check('Tìm theo tên "bao" ra 1 task', r.json.total === 1);

  r = await call("GET", "/tasks?priority=low", A.token);
  check("Lọc ưu tiên thấp ra 1 task", r.json.total === 1);

  r = await call("GET", "/tasks?sortBy=priority&order=desc", A.token);
  check(
    "Sắp xếp ưu tiên giảm dần: high đứng đầu",
    r.json.data.tasks[0]?.priority === "high",
  );

  r = await call("GET", "/tasks?sortBy=dueDate&order=asc", A.token);
  check(
    'Sắp xếp hạn tăng dần: "Mua sach" đứng đầu',
    r.json.data.tasks[0]?.title === "Mua sach",
  );

  r = await call("GET", `/tasks/${id}`, A.token);
  check(
    "Xem chi tiết",
    r.status === 200 && r.json.data.task.title === "Hoan thanh bao cao",
  );

  r = await call("GET", `/tasks/${id}`, B.token);
  check("Người khác không xem được (404)", r.status === 404);

  r = await call("PUT", `/tasks/${id}`, A.token, {
    title: "Bao cao da sua",
    status: "in_progress",
  });
  check(
    "Sửa task",
    r.status === 200 && r.json.data.task.title === "Bao cao da sua",
  );

  r = await call("PATCH", `/tasks/${id}/status`, A.token, { status: "done" });
  check(
    "Đổi trạng thái sang done",
    r.status === 200 && r.json.data.task.status === "done",
  );

  r = await call("PATCH", `/tasks/${id}/status`, A.token, { status: "xyz" });
  check("Trạng thái sai bị từ chối (400)", r.status === 400);

  r = await call("PUT", `/tasks/${id}`, B.token, { title: "hack" });
  check("Người khác không sửa được (404)", r.status === 404);

  r = await call("DELETE", `/tasks/${id}`, B.token);
  check("Người khác không xóa được (404)", r.status === 404);

  r = await call("DELETE", `/tasks/${id}`, A.token);
  check("Chủ task xóa được", r.status === 200);

  r = await call("GET", `/tasks/${id}`, A.token);
  check("Xóa xong không còn (404)", r.status === 404);

  console.log(`\nKết quả: ${pass} đạt, ${fail} lỗi`);
  process.exit(fail ? 1 : 0);
})();
