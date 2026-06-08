const db = require("../db");

// GET all groups
const getGroups = (req, res) => {
  const sql = `
    SELECT 
      groups_table.*,
      levels.name AS level_name,
      teachers.name AS teacher_name
    FROM groups_table
    LEFT JOIN levels ON groups_table.level_id = levels.id
    LEFT JOIN teachers ON groups_table.teacher_id = teachers.id
    ORDER BY groups_table.id DESC
  `;

  db.query(sql, (err, result) => {
    if (err) {
      return res.status(500).json({
        message: "Failed to fetch groups",
        error: err.message,
      });
    }

    res.status(200).json(result);
  });
};

// GET single group by id
const getGroupById = (req, res) => {
  const { id } = req.params;

  const sql = `
    SELECT 
      groups_table.*,
      levels.name AS level_name,
      teachers.name AS teacher_name
    FROM groups_table
    LEFT JOIN levels ON groups_table.level_id = levels.id
    LEFT JOIN teachers ON groups_table.teacher_id = teachers.id
    WHERE groups_table.id = ?
    LIMIT 1
  `;

  db.query(sql, [id], (err, result) => {
    if (err) {
      return res.status(500).json({
        message: "Failed to fetch group",
        error: err.message,
      });
    }

    if (result.length === 0) {
      return res.status(404).json({
        message: "Group not found",
      });
    }

    res.status(200).json(result[0]);
  });
};

// CREATE group
const createGroup = (req, res) => {
  const { name, level_id, teacher_id, schedule, meeting_link } = req.body;

  if (!name || name.trim() === "") {
    return res.status(400).json({
      message: "Group name is required",
    });
  }

  const sql = `
    INSERT INTO groups_table (name, level_id, teacher_id, schedule, meeting_link)
    VALUES (?, ?, ?, ?, ?)
  `;

  db.query(
    sql,
    [
      name,
      level_id || null,
      teacher_id || null,
      schedule || null,
      meeting_link || null,
    ],
    (err, result) => {
      if (err) {
        return res.status(500).json({
          message: "Failed to create group",
          error: err.message,
        });
      }

      res.status(201).json({
        message: "Group created successfully",
        id: result.insertId,
      });
    }
  );
};

// UPDATE group
const updateGroup = (req, res) => {
  const { id } = req.params;
  const { name, level_id, teacher_id, schedule, meeting_link } = req.body;

  if (!name || name.trim() === "") {
    return res.status(400).json({
      message: "Group name is required",
    });
  }

  const sql = `
    UPDATE groups_table
    SET name = ?, level_id = ?, teacher_id = ?, schedule = ?, meeting_link = ?
    WHERE id = ?
  `;

  db.query(
    sql,
    [
      name,
      level_id || null,
      teacher_id || null,
      schedule || null,
      meeting_link || null,
      id,
    ],
    (err, result) => {
      if (err) {
        return res.status(500).json({
          message: "Failed to update group",
          error: err.message,
        });
      }

      if (result.affectedRows === 0) {
        return res.status(404).json({
          message: "Group not found",
        });
      }

      res.status(200).json({
        message: "Group updated successfully",
      });
    }
  );
};

// DELETE group
const deleteGroup = (req, res) => {
  const { id } = req.params;

  const sql = "DELETE FROM groups_table WHERE id = ?";

  db.query(sql, [id], (err, result) => {
    if (err) {
      return res.status(500).json({
        message: "Failed to delete group",
        error: err.message,
      });
    }

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: "Group not found",
      });
    }

    res.status(200).json({
      message: "Group deleted successfully",
    });
  });
};

module.exports = {
  getGroups,
  getGroupById,
  createGroup,
  updateGroup,
  deleteGroup,
};