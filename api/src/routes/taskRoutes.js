const express = require("express");
const router = express.Router();
const taskController = require("../controllers/taskController");
const authMiddleware = require("../middleware/authMiddleware");
const validateMiddleware = require("../middleware/validateMiddleware");
const {
  createTaskValidator,
  updateTaskValidator,
  statusValidator,
} = require("../validators/taskValidator");

// Mọi API công việc đều cần đăng nhập
router.use(authMiddleware);

router.get("/", taskController.listTasks);
router.post(
  "/",
  createTaskValidator,
  validateMiddleware,
  taskController.createTask,
);
router.get("/:id", taskController.getTask);
router.put(
  "/:id",
  updateTaskValidator,
  validateMiddleware,
  taskController.updateTask,
);
router.patch(
  "/:id/status",
  statusValidator,
  validateMiddleware,
  taskController.updateStatus,
);
router.delete("/:id", taskController.deleteTask);

module.exports = router;
