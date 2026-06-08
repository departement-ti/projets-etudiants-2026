const db = require("../db");

const getStats = (req, res) => {
  const sql = `
    SELECT 
      (SELECT COUNT(*) FROM students) as students,
      (SELECT COUNT(*) FROM teachers) as teachers,
      (SELECT COUNT(*) FROM groups_table) as classes,
      (SELECT COUNT(*) FROM registrations WHERE status = 'pending') as pendingRequests
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results[0]);
  });
};

const getRecentRegistrations = (req, res) => {
  const sql = `
    SELECT r.*, l.name as course 
    FROM registrations r
    LEFT JOIN levels l ON r.level_id = l.id
    WHERE r.status = 'pending' 
    ORDER BY r.id DESC
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
};

const updateRegistrationStatus = (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  const sql = "UPDATE registrations SET status = ? WHERE id = ?";
  db.query(sql, [status, id], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Statut mis à jour avec succès" });
  });
};

const getStudentsPerGroup = (req, res) => {
  const sql = `
    SELECT g.name as group_name, COUNT(s.id) as count
    FROM groups_table g
    LEFT JOIN students s ON s.group_id = g.id
    GROUP BY g.id, g.name
    ORDER BY g.id
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
};

const getAttendanceStats = (req, res) => {
  const sql = `
    SELECT g.name as group_name,
      ROUND(
        SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END) * 100.0 
        / NULLIF(COUNT(a.id), 0), 1
      ) as rate
    FROM groups_table g
    LEFT JOIN attendance a ON a.group_id = g.id
    GROUP BY g.id, g.name
    ORDER BY g.id
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
};

const getStudentsPerLevel = (req, res) => {
  const sql = `
    SELECT l.name as level_name, COUNT(s.id) as count
    FROM levels l
    LEFT JOIN groups_table g ON g.level_id = l.id
    LEFT JOIN students s ON s.group_id = g.id
    GROUP BY l.id, l.name
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
};

module.exports = {
  getStats,
  getRecentRegistrations,
  updateRegistrationStatus,
  getStudentsPerGroup,
  getAttendanceStats,
  getStudentsPerLevel,
};