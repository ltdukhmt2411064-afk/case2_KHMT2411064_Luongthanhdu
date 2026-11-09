const User = require('../models/User');

// Tìm người dùng theo tên hoặc email (GET /api/users/search?q=)
const searchUsers = async (req, res, next) => {
  try {
    const { q } = req.query;

    if (!q || q.trim() === '') {
      return res.status(200).json({
        status: 'success',
        data: {
          users: [],
        },
      });
    }

    const keyword = q.trim();
    const regex = new RegExp(keyword, 'i');

    const users = await User.find({
      $or: [{ fullName: regex }, { email: regex }],
    })
      .select('_id fullName email avatarUrl')
      .limit(20);

    res.status(200).json({
      status: 'success',
      results: users.length,
      data: {
        users,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Xem thông tin người dùng theo ID (GET /api/users/:id)
const getUserById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const user = await User.findById(id).select('_id fullName email avatarUrl createdAt');
    if (!user) {
      return res.status(404).json({
        status: 'fail',
        message: 'Không tìm thấy người dùng này',
      });
    }

    res.status(200).json({
      status: 'success',
      data: {
        user,
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  searchUsers,
  getUserById,
};
