const jwt = require('jsonwebtoken');
const User = require('../models/User');

const authMiddleware = async (req, res, next) => {
  try {
    let token;

    if (
      req.headers.authorization &&
      req.headers.authorization.startsWith('Bearer ')
    ) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({
        status: 'fail',
        message: 'Bạn chưa đăng nhập. Vui lòng cung cấp token xác thực!',
      });
    }

    const secret = process.env.JWT_SECRET || 'task_manager_jwt_secret_default';
    const decoded = jwt.verify(token, secret);

    const user = await User.findById(decoded.id);
    if (!user) {
      return res.status(401).json({
        status: 'fail',
        message: 'Tài khoản liên kết với token này không còn tồn tại.',
      });
    }

    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        status: 'fail',
        message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      });
    }

    return res.status(401).json({
      status: 'fail',
      message: 'Token không hợp lệ hoặc đã bị lỗi xác thực.',
    });
  }
};

module.exports = authMiddleware;
