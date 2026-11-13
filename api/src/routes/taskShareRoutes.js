const express = require("express");
const router = express.Router({ mergeParams: true });
const taskShareController = require("../controllers/taskShareController");
const authMiddleware = require("../middleware/authMiddleware");

router.use(authMiddleware);

router.get("/", taskShareController.getShares);
router.post("/", taskShareController.shareTask);
router.patch("/:shareId", taskShareController.updateSharePermission);
router.delete("/:shareId", taskShareController.revokeShare);

module.exports = router;
