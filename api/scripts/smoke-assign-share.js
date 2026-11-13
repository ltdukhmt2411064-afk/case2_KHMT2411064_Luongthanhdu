const BASE = "http://localhost:3000/api";

async function req(method, path, body, token) {
  const res = await fetch(BASE + path, {
    method,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: res.status, json: await res.json().catch(() => ({})) };
}

(async () => {
  const ts = Date.now();
  const u1 = await req("POST", "/auth/register", {
    fullName: "Owner",
    email: `own_${ts}@test.com`,
    password: "Password123",
  });
  const u2 = await req("POST", "/auth/register", {
    fullName: "Member",
    email: `mem_${ts}@test.com`,
    password: "Password123",
  });
  const u3 = await req("POST", "/auth/register", {
    fullName: "Viewer",
    email: `view_${ts}@test.com`,
    password: "Password123",
  });

  const t1 = u1.json.data.token;
  const t2 = u2.json.data.token;
  const t3 = u3.json.data.token;
  const id2 = u2.json.data.user._id || u2.json.data.user.id;
  const id3 = u3.json.data.user._id || u3.json.data.user.id;

  // 1. Tạo task
  const taskRes = await req(
    "POST",
    "/tasks",
    { title: "Task Test Muc C", priority: "high" },
    t1,
  );
  const taskId = taskRes.json.data.task._id;
  console.log(
    "1. Tạo task:",
    taskRes.status === 201 ? "✅" : "❌",
    taskRes.json,
  );

  // 2. Giao việc cho u2
  const assignRes = await req(
    "POST",
    `/tasks/${taskId}/assignees`,
    { userIds: [id2], primaryAssigneeId: id2 },
    t1,
  );
  console.log(
    "2. Giao việc:",
    assignRes.status === 200 ? "✅" : "❌",
    assignRes.json.message,
  );

  // 3. Chia sẻ quyền viewer cho u3
  const shareRes = await req(
    "POST",
    `/tasks/${taskId}/shares`,
    { userIds: [id3], permission: "viewer" },
    t1,
  );
  const shareId = shareRes.json.data?.shares?.[0]?._id;
  console.log(
    "3. Chia sẻ viewer:",
    shareRes.status === 201 ? "✅" : "❌",
    shareRes.json.message,
  );

  // 4. u3 (viewer) thử sửa task -> phải bị chặn (403)
  const editByViewer = await req(
    "PUT",
    `/tasks/${taskId}`,
    { title: "Hack" },
    t3,
  );
  console.log(
    "4. Viewer bị chặn sửa:",
    editByViewer.status === 403 ? "✅" : "❌",
    editByViewer.status,
  );

  // 5. Đổi quyền u3 sang editor -> sửa thành công
  const patchShare = await req(
    "PATCH",
    `/tasks/${taskId}/shares/${shareId}`,
    { permission: "editor" },
    t1,
  );
  const editByEditor = await req(
    "PUT",
    `/tasks/${taskId}`,
    { title: "Updated by Editor" },
    t3,
  );
  console.log(
    "5. Editor sửa thành công:",
    editByEditor.status === 200 ? "✅" : "❌",
    editByEditor.status,
  );

  // 6. Thu hồi quyền u3 & hủy giao việc u2
  const delShare = await req(
    "DELETE",
    `/tasks/${taskId}/shares/${shareId}`,
    null,
    t1,
  );
  const delAssign = await req(
    "DELETE",
    `/tasks/${taskId}/assignees/${id2}`,
    null,
    t1,
  );
  console.log(
    "6. Thu hồi & hủy giao:",
    delShare.status === 200 && delAssign.status === 200 ? "✅" : "❌",
  );
})();
