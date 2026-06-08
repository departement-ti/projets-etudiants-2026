const express = require("express");
const router = express.Router();

const {
  getLevels,
  getLevelById,
  createLevel,
  updateLevel,
  deleteLevel,
} = require("../controllers/levelsController");

router.get("/", getLevels);
router.get("/:id", getLevelById);
router.post("/", createLevel);
router.put("/:id", updateLevel);
router.delete("/:id", deleteLevel);

module.exports = router;