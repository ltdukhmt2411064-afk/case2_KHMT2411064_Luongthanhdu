const { body } = require("express-validator");

const STATUS = ["todo", "in_progress", "done"];
const PRIORITY = ["low", "medium", "high"];

const dateRule = (field) =>
  body(field)
    .optional({ nullable: true, checkFalsy: true })
    .isISO8601()
    .withMessage(`${field} phải là ngày hợp lệ (ISO 8601)`);

const checkDateOrder = body("dueDate").custom((value, { req }) => {
  if (
    value &&
    req.body.startDate &&
    new Date(value) < new Date(req.body.startDate)
  ) {
    throw new Error("Hạn hoàn thành phải sau hoặc bằng ngày bắt đầu");
  }
  return true;
});

const createTaskValidator = [
  body("title")
    .trim()
    .notEmpty()
    .withMessage("Tên công việc không được để trống")
    .isLength({ max: 200 })
    .withMessage("Tên công việc tối đa 200 ký tự"),
  body("description").optional().isString().isLength({ max: 5000 }),
  body("priority")
    .optional()
    .isIn(PRIORITY)
    .withMessage("Ưu tiên phải là low, medium hoặc high"),
  body("status")
    .optional()
    .isIn(STATUS)
    .withMessage("Trạng thái phải là todo, in_progress hoặc done"),
  dateRule("startDate"),
  dateRule("dueDate"),
  checkDateOrder,
];

const updateTaskValidator = [
  body("title")
    .optional()
    .trim()
    .notEmpty()
    .withMessage("Tên công việc không được để trống")
    .isLength({ max: 200 })
    .withMessage("Tên công việc tối đa 200 ký tự"),
  body("description").optional().isString().isLength({ max: 5000 }),
  body("priority")
    .optional()
    .isIn(PRIORITY)
    .withMessage("Ưu tiên phải là low, medium hoặc high"),
  body("status")
    .optional()
    .isIn(STATUS)
    .withMessage("Trạng thái phải là todo, in_progress hoặc done"),
  dateRule("startDate"),
  dateRule("dueDate"),
  checkDateOrder,
];

const statusValidator = [
  body("status")
    .isIn(STATUS)
    .withMessage("Trạng thái phải là todo, in_progress hoặc done"),
];

module.exports = { createTaskValidator, updateTaskValidator, statusValidator };
