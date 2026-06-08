const db = require("../db");

// جلب كل المحادثات حسب المستخدم
const getConversations = (req, res) => {
  const userId = req.user.id;

  const sql = `
    SELECT * FROM conversations 
    WHERE type_detail = 'group' 
    OR user1_id = ? 
    OR user2_id = ?
    ORDER BY created_at DESC
  `;

  db.query(sql, [userId, userId], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
};

// إنشاء محادثة جديدة (جماعية)
const createConversation = (req, res) => {
  const { title, type, group_id } = req.body;
  if (!title) return res.status(400).json({ error: "Title is required" });

  const sql = `INSERT INTO conversations (title, type, group_id, type_detail) VALUES (?, ?, ?, 'group')`;
  db.query(sql, [title, type || "Groupe", group_id || null], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({
      id: result.insertId,
      title,
      type: type || "Groupe",
      type_detail: "group",
      created_at: new Date(),
    });
  });
};

// إنشاء أو جلب محادثة خاصة
const getOrCreatePrivateConversation = (req, res) => {
  const userId = req.user.id;
  const { targetUserId } = req.body;

  if (!targetUserId) return res.status(400).json({ error: "targetUserId is required" });

  const checkSql = `
    SELECT * FROM conversations 
    WHERE type_detail = 'private' 
    AND ((user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?))
    LIMIT 1
  `;

  db.query(checkSql, [userId, targetUserId, targetUserId, userId], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });

    if (results.length > 0) {
      return res.json(results[0]);
    }

    db.query("SELECT full_name FROM users WHERE id = ? LIMIT 1", [targetUserId], (err2, userResults) => {
      if (err2) return res.status(500).json({ error: err2.message });
      if (userResults.length === 0) return res.status(404).json({ error: "User not found" });

      const targetName = userResults[0].full_name;

      const createSql = `
        INSERT INTO conversations (title, type, type_detail, user1_id, user2_id)
        VALUES (?, 'Privé', 'private', ?, ?)
      `;

      db.query(createSql, [targetName, userId, targetUserId], (err3, result) => {
        if (err3) return res.status(500).json({ error: err3.message });
        res.json({
          id: result.insertId,
          title: targetName,
          type: "Privé",
          type_detail: "private",
          user1_id: userId,
          user2_id: targetUserId,
          created_at: new Date(), // ✅ تم إضافتها
        });
      });
    });
  });
};

// حذف محادثة
const deleteConversation = (req, res) => {
  const { id } = req.params;
  db.query(`DELETE FROM conversations WHERE id = ?`, [id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Conversation supprimée" });
  });
};

// جلب رسائل محادثة معينة
const getMessages = (req, res) => {
  const { conversationId } = req.params;
  const sql = `SELECT * FROM messages WHERE conversation_id = ? ORDER BY created_at ASC`;
  db.query(sql, [conversationId], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
};

// إرسال رسالة
const sendMessage = (req, res) => {
  const { conversationId } = req.params;
  const { content, sender_name } = req.body;
  if (!content) return res.status(400).json({ error: "Content is required" });

  const sql = `INSERT INTO messages (conversation_id, sender_name, content) VALUES (?, ?, ?)`;
  db.query(sql, [conversationId, sender_name || "Admin", content], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({
      id: result.insertId,
      conversation_id: conversationId,
      content,
      sender_name: sender_name || "Admin",
      created_at: new Date(),
    });
  });
};

module.exports = {
  getConversations,
  createConversation,
  getOrCreatePrivateConversation,
  deleteConversation,
  getMessages,
  sendMessage,
};