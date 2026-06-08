const express = require("express");
const router = express.Router();
const {
  getStats,
  getRecentRegistrations,
  updateRegistrationStatus,
  getStudentsPerGroup,
  getAttendanceStats,
  getStudentsPerLevel,
} = require("../controllers/dashboardController");

const { protect, adminOnly } = require("../middleware/authMiddleware");

router.get("/stats", protect, adminOnly, getStats);
router.get("/recent-registrations", protect, adminOnly, getRecentRegistrations);
router.put("/registration/:id", protect, adminOnly, updateRegistrationStatus);
router.get("/students-per-group", protect, adminOnly, getStudentsPerGroup);
router.get("/attendance-stats", protect, adminOnly, getAttendanceStats);
router.get("/students-per-level", protect, adminOnly, getStudentsPerLevel);

module.exports = router;