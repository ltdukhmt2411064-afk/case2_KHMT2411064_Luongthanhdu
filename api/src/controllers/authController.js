const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../models/User');

// Tạo JWT token
const signToken = (id) => {
  return jwt.sign(
    { id },
    process.env.JWT_SECRET || 'task_manager_jwt_secret_default',
    {
      expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    }
  );
};

// Đăng ký tài khoản mới (POST /api/auth/register)
const register = async (req, res, next) => {
  try {
    const { fullName, email, password, avatarUrl } = req.body;

    // Kiểm tra email đã tồn tại hay chưa
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({
        status: 'fail',
        message: 'Địa chỉ email này đã được sử dụng. Vui lòng chọn email khác.',
      });
    }

    // Tạo người dùng mới (password sẽ tự động được băm qua hook pre-save)
    const newUser = await User.create({
      fullName,
      email,
      passwordHash: password,
      avatarUrl: avatarUrl || '',
    });

    const token = signToken(newUser._id);

    res.status(201).json({
      status: 'success',
      message: 'Đăng ký tài khoản thành công',
      data: {
        user: newUser,
        token,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Đăng nhập (POST /api/auth/login)
const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Tìm người dùng theo email (chọn thêm passwordHash)
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({
        status: 'fail',
        message: 'Email hoặc mật khẩu không chính xác',
      });
    }

    // Kiểm tra mật khẩu
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({
        status: 'fail',
        message: 'Email hoặc mật khẩu không chính xác',
      });
    }

    const token = signToken(user._id);

    res.status(200).json({
      status: 'success',
      message: 'Đăng nhập thành công',
      data: {
        user,
        token,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Lấy thông tin người dùng hiện tại (GET /api/auth/me)
const getMe = async (req, res) => {
  res.status(200).json({
    status: 'success',
    data: {
      user: req.user,
    },
  });
};

// Cập nhật thông tin cá nhân (PUT /api/auth/me)
const updateMe = async (req, res, next) => {
  try {
    const { fullName, avatarUrl } = req.body;
    const updates = {};

    if (fullName) updates.fullName = fullName;
    if (avatarUrl !== undefined) updates.avatarUrl = avatarUrl;

    const updatedUser = await User.findByIdAndUpdate(
      req.user._id,
      { $set: updates },
      { new: true, runValidators: true }
    );

    res.status(200).json({
      status: 'success',
      message: 'Cập nhật thông tin cá nhân thành công',
      data: {
        user: updatedUser,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Đổi mật khẩu (PUT /api/auth/change-password)
const changePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;

    // Lấy user kèm theo trường passwordHash
    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({
        status: 'fail',
        message: 'Không tìm thấy thông tin tài khoản',
      });
    }

    // Kiểm tra mật khẩu hiện tại
    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      return res.status(400).json({
        status: 'fail',
        message: 'Mật khẩu hiện tại không chính xác',
      });
    }

    // Gán mật khẩu mới (hook pre-save sẽ tự động băm)
    user.passwordHash = newPassword;
    await user.save();

    res.status(200).json({
      status: 'success',
      message: 'Đổi mật khẩu thành công. Vui lòng đăng nhập lại với mật khẩu mới.',
    });
  } catch (error) {
    next(error);
  }
};

// Đăng xuất (POST /api/auth/logout)
const logout = async (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'Đăng xuất thành công',
  });
};

module.exports = {
  register,
  login,
  getMe,
  updateMe,
  changePassword,
  logout,
};
