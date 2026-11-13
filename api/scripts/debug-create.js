const BASE = "http://127.0.0.1:3000/api";
const post = async (path, token, body) => {
  const res = await fetch(BASE + path, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(token && { Authorization: `Bearer ${token}` }),
    },
    body: JSON.stringify(body),
  });
  return { status: res.status, text: await res.text() };
};
(async () => {
  const reg = await post("/auth/register", null, {
    fullName: "Debug",
    email: `d${Date.now()}@test.com`,
    password: "Test123456",
  });
  console.log("REGISTER", reg.status, reg.text.slice(0, 200));
  const token = JSON.parse(reg.text)?.data?.token;
  const t = await post("/tasks", token, {
    title: "Thu tao task",
    priority: "high",
  });
  console.log("\nCREATE TASK", t.status);
  console.log(t.text);
})();
