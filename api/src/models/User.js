const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      required: [true, 'Họ và tên là bắt buộc'],
      trim: true,
      maxlength: [100, 'Họ tên không được vượt quá 100 ký tự'],
    },
    email: {
      type: String,
      required: [true, 'Email là bắt buộc'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [
        /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
        'Địa chỉ email không hợp lệ',
      ],
    },
    passwordHash: {
      type: String,
      required: [true, 'Mật khẩu là bắt buộc'],
    },
    avatarUrl: {
      type: String,
      default: '',
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

// Tự động băm mật khẩu trước khi lưu nếu passwordHash thay đổi
userSchema.pre('save', async function (next) {
  if (!this.isModified('passwordHash')) {
    return next();
  }

  // Nếu mật khẩu chưa băm (độ dài ngắn hoặc chưa bắt đầu bằng $2)
  if (!this.passwordHash.startsWith('$2a$') && !this.passwordHash.startsWith('$2b$')) {
    const salt = await bcrypt.genSalt(10);
    this.passwordHash = await bcrypt.hash(this.passwordHash, salt);
  }
  next();
});

// So khớp mật khẩu nhập vào với mật khẩu đã băm
userSchema.methods.comparePassword = async function (candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.passwordHash);
};

// Loại bỏ passwordHash và __v khi chuyển đổi sang JSON
userSchema.methods.toJSON = function () {
  const userObject = this.toObject();
  delete userObject.passwordHash;
  delete userObject.__v;
  return userObject;
};

const User = mongoose.model('User', userSchema);

module.exports = User;
