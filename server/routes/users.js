const express = require("express");
const router = express.Router();
const db = require("../db");
const { protect, adminOnly } = require("../middleware/authMiddleware");

// GET /api/users — جلب كل المستخدمين (للمدير فقط)
router.get("/", protect, adminOnly, (req, res) => {
  const sql = `
    SELECT id, full_name, email, role, phone, created_at
    FROM users
    ORDER BY role, full_name
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

module.exports = router;