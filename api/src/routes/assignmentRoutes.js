const express = require("express");
const router = express.Router({ mergeParams: true });
const assignmentController = require("../controllers/assignmentController");
const authMiddleware = require("../middleware/authMiddleware");

router.use(authMiddleware);

router.get("/", assignmentController.getAssignees);
router.post("/", assignmentController.assignUsers);
router.patch("/:userId", assignmentController.updatePrimaryAssignee);
router.delete("/:userId", assignmentController.removeAssignee);

module.exports = router;
