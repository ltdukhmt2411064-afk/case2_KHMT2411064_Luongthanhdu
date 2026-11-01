const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');
const validateMiddleware = require('../middleware/validateMiddleware');
const {
  registerValidator,
  loginValidator,
  updateMeValidator,
  changePasswordValidator,
} = require('../validators/authValidator');

// Public routes
router.post('/register', registerValidator, validateMiddleware, authController.register);
router.post('/login', loginValidator, validateMiddleware, authController.login);

// Protected routes (yêu cầu JWT token)
router.use(authMiddleware);

router.get('/me', authController.getMe);
router.put('/me', updateMeValidator, validateMiddleware, authController.updateMe);
router.put('/change-password', changePasswordValidator, validateMiddleware, authController.changePassword);
router.post('/logout', authController.logout);

module.exports = router;
