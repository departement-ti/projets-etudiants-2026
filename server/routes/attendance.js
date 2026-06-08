// server/routes/attendance.js
const express = require('express');
const router = express.Router();
const attendanceController = require('../controllers/attendanceController');
const { protect } = require('../middleware/authMiddleware');

// جلب الطلاب في مجموعة
router.get('/students/:group_id', protect, attendanceController.getStudentsByGroup);

// حفظ الحضور (POST)
router.post('/', protect, attendanceController.saveAttendance);

// جلب حضور يوم معين (GET /api/attendance?group_id=...&date=...)
router.get('/', protect, attendanceController.getAttendanceByDate);

// جلب تاريخ الحضور للمجموعة
router.get('/history/:group_id', protect, attendanceController.getGroupHistory);

module.exports = router;