const express = require("express");
const router = express.Router();

const {
  getRegistrations,
  getRegistrationById,
  createRegistration,
  updateRegistration,
  deleteRegistration,
} = require("../controllers/registrationsController");

router.get("/", getRegistrations);
router.get("/:id", getRegistrationById);
router.post("/", createRegistration);
router.put("/:id", updateRegistration);
router.delete("/:id", deleteRegistration);

module.exports = router;