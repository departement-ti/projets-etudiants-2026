const express = require("express");
const router = express.Router();
const { protect } = require("../middleware/authMiddleware");
const {
  getConversations,
  createConversation,
  getOrCreatePrivateConversation,
  deleteConversation,
  getMessages,
  sendMessage,
} = require("../controllers/messagesController");

router.get("/conversations", protect, getConversations);
router.post("/conversations", protect, createConversation);
router.post("/conversations/private", protect, getOrCreatePrivateConversation);
router.delete("/conversations/:id", protect, deleteConversation);
router.get("/conversations/:conversationId/messages", protect, getMessages);
router.post("/conversations/:conversationId/messages", protect, sendMessage);

module.exports = router;