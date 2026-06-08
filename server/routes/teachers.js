const express = require("express");
const router = express.Router();
const db = require("../db");
const { protect, adminOnly } = require("../middleware/authMiddleware");

// GET all teachers
router.get("/", protect, adminOnly, (req, res) => {
  db.query("SELECT * FROM teachers ORDER BY id DESC", (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(result);
  });
});

// POST create teacher
router.post("/", protect, adminOnly, (req, res) => {
  const { name, email, phone, specialty } = req.body;
  if (!name) return res.status(400).json({ error: "Name is required" });
  db.query(
    "INSERT INTO teachers (name, email, phone, specialty) VALUES (?, ?, ?, ?)",
    [name, email || null, phone || null, specialty || null],
    (err, result) => {
      if (err) return res.status(500).json({ error: err.message });
      res.status(201).json({ id: result.insertId, message: "Teacher created" });
    }
  );
});

// PUT update teacher
router.put("/:id", protect, adminOnly, (req, res) => {
  const { name, email, phone, specialty } = req.body;
  db.query(
    "UPDATE teachers SET name=?, email=?, phone=?, specialty=? WHERE id=?",
    [name, email || null, phone || null, specialty || null, req.params.id],
    (err) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ message: "Teacher updated" });
    }
  );
});

// DELETE teacher
router.delete("/:id", protect, adminOnly, (req, res) => {
  db.query("DELETE FROM teachers WHERE id=?", [req.params.id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Teacher deleted" });
  });
});

module.exports = router;