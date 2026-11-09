const { body } = require('express-validator');

const registerValidator = [
  body('fullName')
    .trim()
    .notEmpty()
    .withMessage('Họ và tên không được để trống')
    .isLength({ min: 2, max: 100 })
    .withMessage('Họ và tên phải có từ 2 đến 100 ký tự'),
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email không được để trống')
    .isEmail()
    .withMessage('Email không hợp lệ')
    .normalizeEmail(),
  body('password')
    .notEmpty()
    .withMessage('Mật khẩu không được để trống')
    .isLength({ min: 6 })
    .withMessage('Mật khẩu phải có ít nhất 6 ký tự'),
];

const loginValidator = [
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email không được để trống')
    .isEmail()
    .withMessage('Email không hợp lệ')
    .normalizeEmail(),
  body('password')
    .notEmpty()
    .withMessage('Mật khẩu không được để trống'),
];

const updateMeValidator = [
  body('fullName')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Họ và tên không được để trống nếu cung cấp')
    .isLength({ min: 2, max: 100 })
    .withMessage('Họ và tên phải có từ 2 đến 100 ký tự'),
  body('avatarUrl')
    .optional({ checkFalsy: true })
    .trim()
    .isURL()
    .withMessage('Đường dẫn ảnh đại diện phải là URL hợp lệ'),
];

const changePasswordValidator = [
  body('currentPassword')
    .notEmpty()
    .withMessage('Vui lòng nhập mật khẩu hiện tại'),
  body('newPassword')
    .notEmpty()
    .withMessage('Vui lòng nhập mật khẩu mới')
    .isLength({ min: 6 })
    .withMessage('Mật khẩu mới phải có ít nhất 6 ký tự')
    .custom((value, { req }) => {
      if (value === req.body.currentPassword) {
        throw new Error('Mật khẩu mới không được trùng với mật khẩu hiện tại');
      }
      return true;
    }),
];

module.exports = {
  registerValidator,
  loginValidator,
  updateMeValidator,
  changePasswordValidator,
};
