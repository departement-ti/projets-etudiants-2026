
const db = require("../db");

// جلب الرسائل
const getContactMessages = (req, res) => {
  db.query(`SELECT * FROM contact_messages ORDER BY created_at DESC`, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
};

// حذف رسالة
const deleteContactMessage = (req, res) => {
  const { id } = req.params;
  db.query(`DELETE FROM contact_messages WHERE id = ?`, [id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Message supprimé" });
  });
};

// إضافة رسالة جديدة
const createContactMessage = (req, res) => {
  const { full_name, email, phone, subject, message } = req.body;

  // التحقق من وجود الحقول الإلزامية
  if (!full_name || !email || !message) {
    return res.status(400).json({ error: "Champs obligatoires manquants" });
  }

  // إدخال البيانات في قاعدة البيانات
  db.query(
    `INSERT INTO contact_messages (full_name, email, subject, message) VALUES (?, ?, ?, ?)`,
    [full_name, email, subject || null, message],
    (err, result) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ message: "Message envoyé avec succès" });
    }
  );
};

module.exports = { getContactMessages, deleteContactMessage, createContactMessage };