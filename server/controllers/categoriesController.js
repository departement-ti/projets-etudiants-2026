const db = require("../db");

// ===== CATEGORIES =====

const getCategories = (req, res) => {
  db.query("SELECT * FROM categories ORDER BY id DESC", (err, result) => {
    if (err) return res.status(500).json({ message: "DB error", error: err.message });
    res.status(200).json(result);
  });
};

const createCategory = (req, res) => {
  const { name, description } = req.body;
  if (!name || name.trim() === "") return res.status(400).json({ message: "Name is required" });

  db.query("INSERT INTO categories (name, description) VALUES (?, ?)", [name, description || null], (err, result) => {
    if (err) return res.status(500).json({ message: "DB error", error: err.message });
    res.status(201).json({ message: "Category created", id: result.insertId });
  });
};

const updateCategory = (req, res) => {
  const { id } = req.params;
  const { name, description } = req.body;
  if (!name || name.trim() === "") return res.status(400).json({ message: "Name is required" });

  db.query("UPDATE categories SET name = ?, description = ? WHERE id = ?", [name, description || null, id], (err, result) => {
    if (err) return res.status(500).json({ message: "DB error", error: err.message });
    if (result.affectedRows === 0) return res.status(404).json({ message: "Category not found" });
    res.status(200).json({ message: "Category updated" });
  });
};

const deleteCategory = (req, res) => {
  const { id } = req.params;
  db.query("DELETE FROM categories WHERE id = ?", [id], (err, result) => {
    if (err) return res.status(500).json({ message: "DB error", error: err.message });
    if (result.affectedRows === 0) return res.status(404).json({ message: "Category not found" });
    res.status(200).json({ message: "Category deleted" });
  });
};

// ===== SUB CATEGORIES =====

const getSubCategories = (req, res) => {
  const sql = `
    SELECT sub_categories.*, categories.name AS category_name
    FROM sub_categories
    LEFT JOIN categories ON sub_categories.category_id = categories.id
    ORDER BY sub_categories.id DESC
  `;
  db.query(sql, (err, result) => {
    if (err) return res.status(500).json({ message: "DB error", error: err.message });
    res.status(200).json(result);
  });
};

const getSubCategoriesByCategory = (req, res) => {
  const { category_id } = req.params;
  db.query("SELECT * FROM sub_categories WHERE category_id = ? ORDER BY id DESC", [category_id], (err, result) => {
    if (err) return res.status(500).json({ message: "DB error", error: err.message });
    res.status(200).json(result);
  });
};

const createSubCategory = (req, res) => {
  const { name, description, category_id } = req.body;
  if (!name || name.trim() === "") return res.status(400).json({ message: "Name is required" });
  if (!category_id) return res.status(400).json({ message: "Category is required" });

  db.query("INSERT INTO sub_categories (name, description, category_id) VALUES (?, ?, ?)", [name, description || null, category_id], (err, result) => {
    if (err) return res.status(500).json({ message: "DB error", error: err.message });
    res.status(201).json({ message: "Sub-category created", id: result.insertId });
  });
};

const updateSubCategory = (req, res) => {
  const { id } = req.params;
  const { name, description, category_id } = req.body;
  if (!name || name.trim() === "") return res.status(400).json({ message: "Name is required" });
  if (!category_id) return res.status(400).json({ message: "Category is required" });

  db.query("UPDATE sub_categories SET name = ?, description = ?, category_id = ? WHERE id = ?", [name, description || null, category_id, id], (err, result) => {
    if (err) return res.status(500).json({ message: "DB error", error: err.message });
    if (result.affectedRows === 0) return res.status(404).json({ message: "Sub-category not found" });
    res.status(200).json({ message: "Sub-category updated" });
  });
};

const deleteSubCategory = (req, res) => {
  const { id } = req.params;
  db.query("DELETE FROM sub_categories WHERE id = ?", [id], (err, result) => {
    if (err) return res.status(500).json({ message: "DB error", error: err.message });
    if (result.affectedRows === 0) return res.status(404).json({ message: "Sub-category not found" });
    res.status(200).json({ message: "Sub-category deleted" });
  });
};

module.exports = {
  getCategories, createCategory, updateCategory, deleteCategory,
  getSubCategories, getSubCategoriesByCategory, createSubCategory, updateSubCategory, deleteSubCategory,
};