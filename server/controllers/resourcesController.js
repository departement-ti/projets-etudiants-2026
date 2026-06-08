const db = require("../db");

const getResources = (req, res) => {
  const { group_id } = req.query;
  let sql = `
    SELECT resources.*, levels.name AS level_name, teachers.name AS teacher_name
    FROM resources
    LEFT JOIN levels ON resources.level_id = levels.id
    LEFT JOIN teachers ON resources.teacher_id = teachers.id
  `;
  const params = [];
  if (group_id) {
    sql += ` WHERE resources.group_id = ?`;
    params.push(group_id);
  }
  sql += ` ORDER BY resources.created_at DESC`;
  db.query(sql, params, (err, result) => {
    if (err) return res.status(500).json({ message: "Failed to fetch resources", error: err.message });
    res.status(200).json(result);
  });
};

const createResource = (req, res) => {
  const { title, description, type, file_url, external_url, group_id, level_id } = req.body;

  // الأستاذ: teacher_id من الـ token | المدير: null
  const teacher_id = req.user.role === "teacher" ? req.user.teacher_id : null;

  const sql = `
    INSERT INTO resources (title, description, type, file_url, external_url, group_id, level_id, teacher_id)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `;
  db.query(sql,
    [title, description, type, file_url || null, external_url || null, group_id || null, level_id || null, teacher_id],
    (err, result) => {
      if (err) return res.status(500).json({ message: "Failed to create resource", error: err.message });
      res.status(201).json({ message: "Resource created successfully", id: result.insertId });
    }
  );
};

const updateResource = (req, res) => {
  const { id } = req.params;
  const { title, description, type, file_url, external_url, group_id, level_id } = req.body;
  const { role, teacher_id } = req.user;

  db.query("SELECT teacher_id FROM resources WHERE id = ?", [id], (err, rows) => {
    if (err) return res.status(500).json({ message: "Erreur serveur" });
    if (rows.length === 0) return res.status(404).json({ message: "Resource not found" });

    // المدير يعدل أي مورد | الأستاذ يعدل موارده فقط
    if (role !== "admin" && rows[0].teacher_id !== teacher_id) {
      return res.status(403).json({ message: "Vous ne pouvez modifier que vos propres ressources" });
    }

    const sql = `
      UPDATE resources 
      SET title = ?, description = ?, type = ?, file_url = ?, external_url = ?, group_id = ?, level_id = ?
      WHERE id = ?
    `;
    db.query(sql,
      [title, description, type, file_url || null, external_url || null, group_id || null, level_id || null, id],
      (err2) => {
        if (err2) return res.status(500).json({ message: "Failed to update resource", error: err2.message });
        res.status(200).json({ message: "Resource updated successfully" });
      }
    );
  });
};

const deleteResource = (req, res) => {
  const { id } = req.params;
  const { role, teacher_id } = req.user;

  db.query("SELECT teacher_id FROM resources WHERE id = ?", [id], (err, rows) => {
    if (err) return res.status(500).json({ message: "Erreur serveur" });
    if (rows.length === 0) return res.status(404).json({ message: "Resource not found" });

    // المدير يحذف أي مورد | الأستاذ يحذف موارده فقط
    if (role !== "admin" && rows[0].teacher_id !== teacher_id) {
      return res.status(403).json({ message: "Vous ne pouvez supprimer que vos propres ressources" });
    }

    db.query("DELETE FROM resources WHERE id = ?", [id], (err2) => {
      if (err2) return res.status(500).json({ message: "Failed to delete resource", error: err2.message });
      res.status(200).json({ message: "Resource deleted successfully" });
    });
  });
};

module.exports = { getResources, createResource, updateResource, deleteResource };