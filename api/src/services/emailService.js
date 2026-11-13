const nodemailer = require("nodemailer");
const EmailLog = require("../models/EmailLog");
const { buildEmailTemplate } = require("../utils/emailTemplates");

function createTransporter() {
  if (
    !process.env.SMTP_HOST ||
    !process.env.SMTP_USER ||
    !process.env.SMTP_PASS
  ) {
    return null;
  }
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: Number(process.env.SMTP_PORT) === 465,
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });
}

async function sendTaskEmail({
  taskId = null,
  recipientEmail,
  eventType,
  payload = {},
}) {
  const { subject, html } = buildEmailTemplate(eventType, payload);

  const log = await EmailLog.create({
    taskId,
    recipientEmail,
    eventType,
    subject,
    status: "pending",
    attempts: 1,
  });

  const transporter = createTransporter();
  if (!transporter) {
    // Nếu chưa cấu hình SMTP thật trong .env, ghi nhận trạng thái để không lỗi luồng chính
    log.status = "failed";
    log.errorMessage = "Chưa cấu hình SMTP trong biến môi trường (.env)";
    await log.save();
    return log;
  }

  try {
    await transporter.sendMail({
      from: process.env.SMTP_FROM || process.env.SMTP_USER,
      to: recipientEmail,
      subject,
      html,
    });
    log.status = "sent";
    log.sentAt = new Date();
    log.errorMessage = "";
    await log.save();
  } catch (err) {
    log.status = "failed";
    log.errorMessage = err.message || "Lỗi gửi email";
    await log.save();
  }

  return log;
}

module.exports = { sendTaskEmail };
