const db = require("../db");

// GET all teachers
const getTeachers = (req, res) => {
  const sql = "SELECT * FROM teachers ORDER BY id DESC";

  db.query(sql, (err, result) => {
    if (err) {
      return res.status(500).json({
        message: "Failed to fetch teachers",
        error: err.message,
      });
    }

    res.status(200).json(result);
  });
};

// GET single teacher by id
const getTeacherById = (req, res) => {
  const { id } = req.params;

  const sql = "SELECT * FROM teachers WHERE id = ? LIMIT 1";

  db.query(sql, [id], (err, result) => {
    if (err) {
      return res.status(500).json({
        message: "Failed to fetch teacher",
        error: err.message,
      });
    }

    if (result.length === 0) {
      return res.status(404).json({
        message: "Teacher not found",
      });
    }

    res.status(200).json(result[0]);
  });
};

// CREATE teacher
const createTeacher = (req, res) => {
  const { name, email, phone, specialty } = req.body;

  if (!name || name.trim() === "") {
    return res.status(400).json({
      message: "Teacher name is required",
    });
  }

  const sql =
    "INSERT INTO teachers (name, email, phone, specialty) VALUES (?, ?, ?, ?)";

  db.query(
    sql,
    [name, email || null, phone || null, specialty || null],
    (err, result) => {
      if (err) {
        return res.status(500).json({
          message: "Failed to create teacher",
          error: err.message,
        });
      }

      res.status(201).json({
        message: "Teacher created successfully",
        id: result.insertId,
      });
    }
  );
};

// UPDATE teacher
const updateTeacher = (req, res) => {
  const { id } = req.params;
  const { name, email, phone, specialty } = req.body;

  if (!name || name.trim() === "") {
    return res.status(400).json({
      message: "Teacher name is required",
    });
  }

  const sql = `
    UPDATE teachers
    SET name = ?, email = ?, phone = ?, specialty = ?
    WHERE id = ?
  `;

  db.query(
    sql,
    [name, email || null, phone || null, specialty || null, id],
    (err, result) => {
      if (err) {
        return res.status(500).json({
          message: "Failed to update teacher",
          error: err.message,
        });
      }

      if (result.affectedRows === 0) {
        return res.status(404).json({
          message: "Teacher not found",
        });
      }

      res.status(200).json({
        message: "Teacher updated successfully",
      });
    }
  );
};

// DELETE teacher
const deleteTeacher = (req, res) => {
  const { id } = req.params;

  const sql = "DELETE FROM teachers WHERE id = ?";

  db.query(sql, [id], (err, result) => {
    if (err) {
      return res.status(500).json({
        message: "Failed to delete teacher",
        error: err.message,
      });
    }

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: "Teacher not found",
      });
    }

    res.status(200).json({
      message: "Teacher deleted successfully",
    });
  });
};

module.exports = {
  getTeachers,
  getTeacherById,
  createTeacher,
  updateTeacher,
  deleteTeacher,
};