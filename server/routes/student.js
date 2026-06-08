const express = require("express");
const router = express.Router();
const db = require("../db");
const { protect } = require("../middleware/authMiddleware");

// GET /api/student/info
router.get("/info", protect, (req, res) => {
  const userId = req.user.id;

  db.query(`SELECT student_id FROM users WHERE id = ?`, [userId], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!results[0]?.student_id) return res.status(404).json({ error: "Student not found" });

    const studentId = results[0].student_id;

    const sql = `
      SELECT s.*, g.name as group_name, g.schedule, g.meeting_link,
             l.name as level_name, t.name as teacher_name
      FROM students s
      LEFT JOIN groups_table g ON s.group_id = g.id
      LEFT JOIN levels l ON g.level_id = l.id
      LEFT JOIN teachers t ON g.teacher_id = t.id
      WHERE s.id = ?
    `;
    db.query(sql, [studentId], (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(rows[0] || {});
    });
  });
});



// GET /api/student/resources
router.get("/resources", protect, (req, res) => {
  const userId = req.user.id;
  db.query(`SELECT student_id FROM users WHERE id = ?`, [userId], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!results[0]?.student_id) return res.json([]);

    const studentId = results[0].student_id;

    // جلب group_id و level_id للطالب
    db.query(`
      SELECT s.group_id, g.level_id 
      FROM students s
      LEFT JOIN groups_table g ON s.group_id = g.id
      WHERE s.id = ?
    `, [studentId], (err, studentData) => {
      if (err) return res.status(500).json({ error: err.message });
      if (!studentData[0]) return res.json([]);

      const { group_id, level_id } = studentData[0];

      // جلب الموارد بـ group_id أو level_id
      const sql = `
        SELECT r.*, t.name as teacher_name
        FROM resources r
        LEFT JOIN teachers t ON r.teacher_id = t.id
        WHERE r.group_id = ? OR r.level_id = ?
        ORDER BY r.created_at DESC
      `;
      db.query(sql, [group_id, level_id], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
      });
    });
  });
});

// GET /api/student/attendance
router.get("/attendance", protect, (req, res) => {
  const userId = req.user.id;

  db.query(`SELECT student_id FROM users WHERE id = ?`, [userId], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!results[0]?.student_id) return res.json([]);

    const studentId = results[0].student_id;

    const sql = `
      SELECT * FROM attendance
      WHERE student_id = ?
      ORDER BY attendance_date DESC
    `;
    db.query(sql, [studentId], (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(rows);
    });
  });
});

// GET /api/student/teachers — للمحادثات الخاصة
router.get("/teachers", protect, (req, res) => {
  const userId = req.user.id;

  db.query(`SELECT student_id FROM users WHERE id = ?`, [userId], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!results[0]?.student_id) return res.json([]);

    const studentId = results[0].student_id;

    const sql = `
      SELECT u.id as user_id, u.full_name
      FROM users u
      INNER JOIN teachers t ON u.teacher_id = t.id
      INNER JOIN groups_table g ON g.teacher_id = t.id
      INNER JOIN students s ON s.group_id = g.id
      WHERE s.id = ?
    `;
    db.query(sql, [studentId], (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(rows);
    });
  });
});

module.exports = router;