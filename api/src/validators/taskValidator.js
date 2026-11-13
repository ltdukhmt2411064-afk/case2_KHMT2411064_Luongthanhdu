const { body } = require('express-validator');

exports.createTaskRules = [
  body('title').trim().notEmpty().withMessage('Tên công việc không được để trống'),
  body('description').optional().isString().withMessage('Mô tả không hợp lệ'),
  body('priority')
    .optional()
    .isIn(['low', 'medium', 'high'])
    .withMessage('Mức độ ưu tiên không hợp lệ'),
  body('startDate').optional({ nullable: true }).isISO8601().withMessage('Ngày bắt đầu không hợp lệ'),
  body('dueDate').optional({ nullable: true }).isISO8601().withMessage('Hạn hoàn thành không hợp lệ'),
  body('dueDate').custom((value, { req }) => {
    if (value && req.body.startDate && new Date(value) < new Date(req.body.startDate)) {
      throw new Error('Hạn hoàn thành phải sau ngày bắt đầu');
    }
    return true;
  }),
];

exports.updateTaskRules = [
  body('title').optional().trim().notEmpty().withMessage('Tên công việc không được để trống'),
  body('description').optional().isString().withMessage('Mô tả không hợp lệ'),
  body('priority')
    .optional()
    .isIn(['low', 'medium', 'high'])
    .withMessage('Mức độ ưu tiên không hợp lệ'),
  body('startDate').optional({ nullable: true }).isISO8601().withMessage('Ngày bắt đầu không hợp lệ'),
  body('dueDate').optional({ nullable: true }).isISO8601().withMessage('Hạn hoàn thành không hợp lệ'),
];

exports.updateStatusRules = [
  body('status')
    .isIn(['todo', 'in_progress', 'completed'])
    .withMessage('Trạng thái không hợp lệ'),
];