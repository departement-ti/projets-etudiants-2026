const express = require("express");
const router = express.Router();

const {
  getGroups,
  getGroupById,
  createGroup,
  updateGroup,
  deleteGroup,
} = require("../controllers/groupsController");

router.get("/", getGroups);
router.get("/:id", getGroupById);
router.post("/", createGroup);
router.put("/:id", updateGroup);
router.delete("/:id", deleteGroup);

module.exports = router;