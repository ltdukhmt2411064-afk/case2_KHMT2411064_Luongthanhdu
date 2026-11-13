const Notification = require("../models/Notification");
const User = require("../models/User");
const { sendTaskEmail } = require("./emailService");

async function notifyAndEmail({
  userId,
  taskId,
  type,
  title,
  message,
  emailPayload = {},
}) {
  if (!userId) return null;

  const notification = await Notification.create({
    userId,
    taskId,
    type,
    title,
    message,
  });

  const recipient = await User.findById(userId).select("email").lean();
  if (recipient && recipient.email) {
    // Gửi bất đồng bộ để không làm chậm response trả về cho client
    sendTaskEmail({
      taskId,
      recipientEmail: recipient.email,
      eventType: type,
      payload: emailPayload,
    }).catch((err) => console.error("[Email Error]:", err.message));
  }

  return notification;
}

module.exports = { notifyAndEmail };
