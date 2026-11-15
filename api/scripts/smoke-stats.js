// Chạy: node scripts/smoke-stats.js   (backend phải đang chạy, Node 18+)
const BASE = process.env.BASE || 'http://127.0.0.1:3000/api';
let pass = 0, fail = 0;

const call = async (method, path, token, body) => {
  const res = await fetch(BASE + path, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token && { Authorization: `Bearer ${token}` }) },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: res.status, json: await res.json().catch(() => ({})) };
};
const check = (name, ok, extra = '') => {
  ok ? pass++ : fail++;
  console.log(`${ok ? '✅' : '❌'} ${name} ${ok ? '' : extra}`);
};
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
const day = (n) => new Date(Date.now() + n * 86400000).toISOString();

(async () => {
  const stamp = Date.now();
  const reg = async (n) =>
    (await call('POST', '/auth/register', null, { fullName: `Stat ${n}`, email: `s${n}_${stamp}@test.com`, password: 'Test123456' })).json.data;
  const A = await reg('a'), B = await reg('b'), C = await reg('c');
  check('Đăng ký 3 tài khoản test', !!A?.token && !!B?.token && !!C?.token);

  let r = await call('GET', '/statistics/overview');
  check('Thống kê không có token bị chặn (401)', r.status === 401);

  r = await call('POST', '/tasks', A.token, { title: 'Qua han', dueDate: day(-3), priority: 'high' });
  const overdueId = r.json.data?.task?._id;
  r = await call('POST', '/tasks', A.token, { title: 'Sap den han', dueDate: day(1) });
  const soonId = r.json.data?.task?._id;
  r = await call('POST', '/tasks', A.token, { title: 'Da xong', status: 'done' });

  r = await call('GET', '/statistics/overview', A.token);
  const d = r.json.data || {};
  check('Tổng số công việc = 3', d.total === 3, JSON.stringify(d));
  check('Theo trạng thái: 2 chưa làm, 1 hoàn thành', d.byStatus?.todo === 2 && d.byStatus?.done === 1, JSON.stringify(d.byStatus));
  check('Có 1 công việc quá hạn', d.overdue === 1, JSON.stringify(d));
  check('Có 1 công việc sắp đến hạn', d.dueSoon === 1, JSON.stringify(d));
  check('Tôi tạo = 3', d.createdByMe === 3);

  r = await call('GET', '/statistics/overdue', A.token);
  check('Danh sách quá hạn có "Qua han"', r.json.data?.tasks?.length === 1 && r.json.data.tasks[0].title === 'Qua han');
  r = await call('GET', '/statistics/due-soon', A.token);
  check('Danh sách sắp đến hạn có "Sap den han"', r.json.data?.tasks?.length === 1 && r.json.data.tasks[0].title === 'Sap den han');

  // Lịch sử hoạt động
  await call('PUT', `/tasks/${soonId}`, A.token, { title: 'Sap den han (da sua)', dueDate: day(2) });
  await call('PATCH', `/tasks/${soonId}/status`, A.token, { status: 'in_progress' });
  await call('POST', `/tasks/${soonId}/assignees`, A.token, { userIds: [B.user._id] });
  await call('POST', `/tasks/${soonId}/shares`, A.token, { userIds: [C.user._id], permission: 'viewer' });
  await wait(600);

  r = await call('GET', `/tasks/${soonId}/activities`, A.token);
  const acts = (r.json.data?.activities || []).map((a) => a.action);
  check('Lịch sử có "task_created"', acts.includes('task_created'), acts.join(','));
  check('Lịch sử có "task_updated"', acts.includes('task_updated'), acts.join(','));
  check('Lịch sử có "status_changed"', acts.includes('status_changed'), acts.join(','));
  check('Lịch sử có "assignees_added"', acts.includes('assignees_added'), acts.join(','));
  check('Lịch sử có "task_shared"', acts.includes('task_shared'), acts.join(','));
  check('Lịch sử ghi tên người thực hiện', r.json.data?.activities?.[0]?.userId?.fullName === 'Stat a');

  r = await call('GET', `/tasks/${soonId}/activities`, B.token);
  check('Người được giao xem được lịch sử (200)', r.status === 200);

  const outsider = await reg('d');
  r = await call('GET', `/tasks/${soonId}/activities`, outsider.token);
  check('Người ngoài không xem được lịch sử (404)', r.status === 404);

  r = await call('GET', '/statistics/overview', B.token);
  check('Người được giao: assignedToMe = 1', r.json.data?.assignedToMe === 1, JSON.stringify(r.json.data));
  check('Người được giao: primaryActive = 1', r.json.data?.primaryActive === 1, JSON.stringify(r.json.data));

  r = await call('GET', '/statistics/overview', C.token);
  check('Người được chia sẻ: sharedWithMe = 1', r.json.data?.sharedWithMe === 1, JSON.stringify(r.json.data));

  console.log(`\nKết quả: ${pass} đạt, ${fail} lỗi`);
  process.exit(fail ? 1 : 0);
})();

