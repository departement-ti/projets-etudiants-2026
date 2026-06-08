const express = require("express");
const router = express.Router();
const { protect } = require("../middleware/authMiddleware");
const upload = require("../utils/upload");
const {
  getResources,
  createResource,
  updateResource,
  deleteResource,
} = require("../controllers/resourcesController");

function teacherOrAdmin(req, res, next) {
  if (req.user.role !== "teacher" && req.user.role !== "admin") {
    return res.status(403).json({ message: "Accès non autorisé" });
  }
  next();
}

// route رفع الملف
router.post("/upload", protect, teacherOrAdmin, upload.single("file"), (req, res) => {
  if (!req.file) return res.status(400).json({ message: "Aucun fichier reçu" });
  const fileUrl = `http://localhost:5000/uploads/${req.file.filename}`;
  res.status(200).json({ file_url: fileUrl });
});

router.get("/", protect, getResources);
router.post("/", protect, teacherOrAdmin, createResource);
router.put("/:id", protect, teacherOrAdmin, updateResource);
router.delete("/:id", protect, teacherOrAdmin, deleteResource);

module.exports = router;