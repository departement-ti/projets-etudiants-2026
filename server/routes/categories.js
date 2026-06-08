const express = require("express");
const router = express.Router();
const { protect, adminOnly } = require("../middleware/authMiddleware");

const {
  getCategories, createCategory, updateCategory, deleteCategory,
  getSubCategories, getSubCategoriesByCategory, createSubCategory, updateSubCategory, deleteSubCategory,
} = require("../controllers/categoriesController");

// Categories
router.get("/", protect, adminOnly, getCategories);
router.post("/", protect, adminOnly, createCategory);
router.put("/:id", protect, adminOnly, updateCategory);
router.delete("/:id", protect, adminOnly, deleteCategory);

// Sub-categories
router.get("/sub", protect, adminOnly, getSubCategories);
router.get("/sub/by-category/:category_id", protect, adminOnly, getSubCategoriesByCategory);
router.post("/sub", protect, adminOnly, createSubCategory);
router.put("/sub/:id", protect, adminOnly, updateSubCategory);
router.delete("/sub/:id", protect, adminOnly, deleteSubCategory);

module.exports = router;