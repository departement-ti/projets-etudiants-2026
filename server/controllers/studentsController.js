const db = require("../db");

// GET all students
const getStudents = (req, res) => {
  const sql = `
    SELECT students.*, levels.name AS level_name
    FROM students
    LEFT JOIN levels ON students.level_id = levels.id
    ORDER BY students.id DESC
  `;

  db.query(sql, (err, result) => {
    if (err) {
      return res.status(500).json({
        message: "Failed to fetch students",
        error: err.message,
      });
    }

    res.status(200).json(result);
  });
};

// GET single student by id
const getStudentById = (req, res) => {
  const { id } = req.params;

  const sql = `
    SELECT students.*, levels.name AS level_name
    FROM students
    LEFT JOIN levels ON students.level_id = levels.id
    WHERE students.id = ?
    LIMIT 1
  `;

  db.query(sql, [id], (err, result) => {
    if (err) {
      return res.status(500).json({
        message: "Failed to fetch student",
        error: err.message,
      });
    }

    if (result.length === 0) {
      return res.status(404).json({
        message: "Student not found",
      });
    }

    res.status(200).json(result[0]);
  });
};

// CREATE student
const createStudent = (req, res) => {
  const { name, email, phone, level_id } = req.body;

  if (!name || name.trim() === "") {
    return res.status(400).json({
      message: "Student name is required",
    });
  }

  const sql =
    "INSERT INTO students (name, email, phone, level_id) VALUES (?, ?, ?, ?)";

  db.query(
    sql,
    [name, email || null, phone || null, level_id || null],
    (err, result) => {
      if (err) {
        return res.status(500).json({
          message: "Failed to create student",
          error: err.message,
        });
      }

      res.status(201).json({
        message: "Student created successfully",
        id: result.insertId,
      });
    }
  );
};

// UPDATE student
const updateStudent = (req, res) => {
  const { id } = req.params;
  const { name, email, phone, level_id } = req.body;

  if (!name || name.trim() === "") {
    return res.status(400).json({
      message: "Student name is required",
    });
  }

  const sql = `
    UPDATE students
    SET name = ?, email = ?, phone = ?, level_id = ?
    WHERE id = ?
  `;

  db.query(
    sql,
    [name, email || null, phone || null, level_id || null, id],
    (err, result) => {
      if (err) {
        return res.status(500).json({
          message: "Failed to update student",
          error: err.message,
        });
      }

      if (result.affectedRows === 0) {
        return res.status(404).json({
          message: "Student not found",
        });
      }

      res.status(200).json({
        message: "Student updated successfully",
      });
    }
  );
};

// DELETE student
const deleteStudent = (req, res) => {
  const { id } = req.params;

  const sql = "DELETE FROM students WHERE id = ?";

  db.query(sql, [id], (err, result) => {
    if (err) {
      return res.status(500).json({
        message: "Failed to delete student",
        error: err.message,
      });
    }

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: "Student not found",
      });
    }

    res.status(200).json({
      message: "Student deleted successfully",
    });
  });
};

module.exports = {
  getStudents,
  getStudentById,
  createStudent,
  updateStudent,
  deleteStudent,
};