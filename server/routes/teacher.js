const express = require("express");
const router = express.Router();
const db = require("../db");
const { protect } = require("../middleware/authMiddleware");

// GET /api/teacher/classes
router.get("/classes", protect, (req, res) => {
  const userId = req.user.id;

  db.query(`SELECT teacher_id FROM users WHERE id = ?`, [userId], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!results[0]?.teacher_id) return res.json([]);

    const teacherId = results[0].teacher_id;

    const sql = `
      SELECT g.*, l.name as level_name
      FROM groups_table g
      LEFT JOIN levels l ON g.level_id = l.id
      WHERE g.teacher_id = ?
      ORDER BY g.id DESC
    `;
    db.query(sql, [teacherId], (err, classes) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(classes);
    });
  });
});

// GET /api/teacher/groups
router.get("/groups", protect, (req, res) => {
  const userId = req.user.id;

  db.query(`SELECT teacher_id FROM users WHERE id = ?`, [userId], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!results[0]?.teacher_id) return res.json([]);

    const teacherId = results[0].teacher_id;

    const sql = `
      SELECT g.id, g.name, l.name as level_name
      FROM groups_table g
      LEFT JOIN levels l ON g.level_id = l.id
      WHERE g.teacher_id = ?
      ORDER BY g.id DESC
    `;
    db.query(sql, [teacherId], (err, groups) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(groups);
    });
  });
});

// GET /api/teacher/students — للمحادثات الخاصة
router.get("/students", protect, (req, res) => {
  const userId = req.user.id;

  db.query(`SELECT teacher_id FROM users WHERE id = ?`, [userId], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!results[0]?.teacher_id) return res.json([]);

    const teacherId = results[0].teacher_id;

    const sql = `
      SELECT u.id as user_id, u.full_name
      FROM users u
      INNER JOIN students s ON u.student_id = s.id
      INNER JOIN groups_table g ON s.group_id = g.id
      WHERE g.teacher_id = ?
    `;
    db.query(sql, [teacherId], (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(rows);
    });
  });
});

module.exports = router;