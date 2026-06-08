const express = require("express");
const router = express.Router();
const { getProfile, updateProfile, changePassword } = require("../controllers/profileController");
// استيراد حماية المسارات
const { protect } = require("../middleware/authMiddleware");

// إضافة protect لكل المسارات لضمان أن المستخدم مسجل دخول
router.get("/", protect, getProfile);
router.put("/", protect, updateProfile);
router.put("/password", protect, changePassword);

module.exports = router;