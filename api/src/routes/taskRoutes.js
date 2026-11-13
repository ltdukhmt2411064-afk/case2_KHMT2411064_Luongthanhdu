const express = require('express');
const taskController = require('../controllers/taskController');
const authMiddleware = require('../middleware/authMiddleware');
const validateMiddleware = require('../middleware/validateMiddleware');
const {
  createTaskRules,
  updateTaskRules,
  updateStatusRules,
} = require('../validators/taskValidator');

const router = express.Router();

router.use(authMiddleware);

router.get('/', taskController.listTasks);
router.post('/', createTaskRules, validateMiddleware, taskController.createTask);
router.get('/:id', taskController.getTask);
router.put('/:id', updateTaskRules, validateMiddleware, taskController.updateTask);
router.delete('/:id', taskController.deleteTask);
router.patch(
  '/:id/status',
  updateStatusRules,
  validateMiddleware,
  taskController.updateStatus
);

module.exports = router;