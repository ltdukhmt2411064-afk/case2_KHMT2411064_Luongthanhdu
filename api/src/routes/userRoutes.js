const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const authMiddleware = require('../middleware/authMiddleware');

// Tất cả route người dùng đều yêu cầu đăng nhập
router.use(authMiddleware);

router.get('/search', userController.searchUsers);
router.get('/:id', userController.getUserById);

module.exports = router;
