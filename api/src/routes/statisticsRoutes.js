const express = require("express");
const router = express.Router();
const statisticsController = require("../controllers/statisticsController");
const authMiddleware = require("../middleware/authMiddleware");

router.use(authMiddleware);

router.get("/overview", statisticsController.getOverview);
router.get("/due-soon", statisticsController.getDueSoon);
router.get("/overdue", statisticsController.getOverdue);

module.exports = router;
