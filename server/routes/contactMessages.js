const express = require("express");
const router = express.Router();
const { getContactMessages, deleteContactMessage, createContactMessage } = require("../controllers/contactMessagesController");

// مسار GET لعرض جميع الرسائل
router.get("/", getContactMessages);

// مسار DELETE لحذف رسالة معينة باستخدام الـ ID
router.delete("/:id", deleteContactMessage);

// مسار POST لإرسال رسالة جديدة عبر نموذج الاتصال
router.post("/", createContactMessage);

module.exports = router;