const db = require("../db");

const getLevels = (req, res) => {
  db.query("SELECT * FROM levels ORDER BY id DESC", (err, result) => {
    if (err) return res.status(500).json({ message: "Failed to fetch levels", error: err.message });
    res.status(200).json(result);
  });
};

const getLevelById = (req, res) => {
  const { id } = req.params;
  db.query("SELECT * FROM levels WHERE id = ? LIMIT 1", [id], (err, result) => {
    if (err) return res.status(500).json({ message: "Failed to fetch level", error: err.message });
    if (result.length === 0) return res.status(404).json({ message: "Level not found" });
    res.status(200).json(result[0]);
  });
};

const createLevel = (req, res) => {
  const { name, description, image, price, duration } = req.body;
  if (!name || name.trim() === "") return res.status(400).json({ message: "Level name is required" });

  const sql = "INSERT INTO levels (name, description, image, price, duration) VALUES (?, ?, ?, ?, ?)";
  db.query(sql, [name, description || null, image || null, price || null, duration || null], (err, result) => {
    if (err) return res.status(500).json({ message: "Failed to create level", error: err.message });
    res.status(201).json({ message: "Level created successfully", id: result.insertId });
  });
};

const updateLevel = (req, res) => {
  const { id } = req.params;
  const { name, description, image, price, duration } = req.body;
  if (!name || name.trim() === "") return res.status(400).json({ message: "Level name is required" });

  const sql = `UPDATE levels SET name = ?, description = ?, image = ?, price = ?, duration = ? WHERE id = ?`;
  db.query(sql, [name, description || null, image || null, price || null, duration || null, id], (err, result) => {
    if (err) return res.status(500).json({ message: "Failed to update level", error: err.message });
    if (result.affectedRows === 0) return res.status(404).json({ message: "Level not found" });
    res.status(200).json({ message: "Level updated successfully" });
  });
};

const deleteLevel = (req, res) => {
  const { id } = req.params;
  db.query("DELETE FROM levels WHERE id = ?", [id], (err, result) => {
    if (err) return res.status(500).json({ message: "Failed to delete level", error: err.message });
    if (result.affectedRows === 0) return res.status(404).json({ message: "Level not found" });
    res.status(200).json({ message: "Level deleted successfully" });
  });
};

module.exports = { getLevels, getLevelById, createLevel, updateLevel, deleteLevel };