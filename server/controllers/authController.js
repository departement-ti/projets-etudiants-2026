const db = require("../db");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const { sendWelcomeEmail } = require("../utils/mailer");

const JWT_SECRET = process.env.JWT_SECRET || "edulive_secret_key";

const login = (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: "Email et mot de passe sont obligatoires" });
  }

  db.query(`SELECT * FROM users WHERE email = ?`, [email], async (err, results) => {
    if (err) return res.status(500).json({ error: err.message });

    if (results.length === 0) {
      return res.status(401).json({ error: "Email ou mot de passe incorrect" });
    }

    const user = results[0];

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ error: "Email ou mot de passe incorrect" });
    }

    const token = jwt.sign(
     { id: user.id, email: user.email, role: user.role, teacher_id: user.teacher_id || null, student_id: user.student_id || null },
      JWT_SECRET,
      { expiresIn: "24h" }
    );

    res.json({
      token,
      user: {
        id: user.id,
        full_name: user.full_name,
        email: user.email,
        role: user.role,
      },
    });
  });
};


const getMe = (req, res) => {
  db.query(
    `SELECT id, full_name, email, role, phone FROM users WHERE id = ?`,
    [req.user.id],
    (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      if (results.length === 0) return res.status(404).json({ error: "User not found" });
      res.json(results[0]);
    }
  );
};

// FORGOT PASSWORD — إرسال رابط إعادة التعيين
const forgotPassword = (req, res) => {
  const { email } = req.body;

  if (!email) return res.status(400).json({ error: "Email est obligatoire" });

  // التحقق من وجود البريد
  db.query("SELECT * FROM users WHERE email = ? LIMIT 1", [email], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });

    // نرسل نفس الرسالة حتى لو البريد غير موجود (أمان)
    if (results.length === 0) {
      return res.status(200).json({ message: "Si cet email existe, un lien vous a été envoyé." });
    }

    const user = results[0];

    // توليد token عشوائي
    const token = crypto.randomBytes(32).toString("hex");

    // تاريخ انتهاء الصلاحية: ساعة واحدة
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000)
      .toISOString()
      .slice(0, 19)
      .replace("T", " ");

    // حذف أي token قديم لنفس البريد
    db.query("DELETE FROM password_resets WHERE email = ?", [email], (err2) => {
      if (err2) return res.status(500).json({ error: err2.message });

      // إدخال token جديد
      db.query(
        "INSERT INTO password_resets (email, token, expires_at) VALUES (?, ?, ?)",
        [email, token, expiresAt],
        (err3) => {
          if (err3) return res.status(500).json({ error: err3.message });

          // إرسال البريد الإلكتروني
          const resetLink = `http://localhost:5173/reset-password?token=${token}`;

          const mailOptions = {
            from: `"EduLive" <${process.env.MAIL_USER}>`,
            to: email,
            subject: "Réinitialisation de votre mot de passe — EduLive",
            html: `
              <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 30px; border: 1px solid #e0e0e0; border-radius: 10px;">
                <h2 style="color: #4f46e5;">Réinitialisation du mot de passe</h2>
                <p>Bonjour <strong>${user.full_name}</strong>,</p>
                <p>Vous avez demandé à réinitialiser votre mot de passe. Cliquez sur le bouton ci-dessous :</p>
                <a href="${resetLink}"
                   style="display: inline-block; margin: 20px 0; background: #4f46e5; color: white; padding: 12px 25px; border-radius: 6px; text-decoration: none;">
                  Réinitialiser mon mot de passe
                </a>
                <p style="color: #9ca3af; font-size: 13px;">Ce lien expire dans <strong>1 heure</strong>.</p>
                <p style="color: #9ca3af; font-size: 13px;">Si vous n'avez pas fait cette demande, ignorez cet email.</p>
              </div>
            `,
          };

          const nodemailer = require("nodemailer");
          const transporter = nodemailer.createTransport({
            service: "gmail",
            auth: {
              user: process.env.MAIL_USER,
              pass: process.env.MAIL_PASS,
            },
          });

          transporter.sendMail(mailOptions, (mailErr) => {
            if (mailErr) {
              console.error("Mail error:", mailErr.message);
              return res.status(500).json({ error: "Erreur lors de l'envoi de l'email" });
            }
            res.status(200).json({ message: "Si cet email existe, un lien vous a été envoyé." });
          });
        }
      );
    });
  });
};

// RESET PASSWORD — تعيين كلمة مرور جديدة
const resetPassword = (req, res) => {
  const { token, password } = req.body;

  if (!token || !password) {
    return res.status(400).json({ error: "Token et mot de passe sont obligatoires" });
  }

  if (password.length < 6) {
    return res.status(400).json({ error: "Le mot de passe doit contenir au moins 6 caractères" });
  }

  // التحقق من صلاحية الـ token
  db.query(
    "SELECT * FROM password_resets WHERE token = ? AND expires_at > NOW() LIMIT 1",
    [token],
    (err, results) => {
      if (err) return res.status(500).json({ error: err.message });

      if (results.length === 0) {
        return res.status(400).json({ error: "Lien invalide ou expiré" });
      }

      const { email } = results[0];

      // تشفير كلمة المرور الجديدة
      bcrypt.hash(password, 10, (err2, hashedPassword) => {
        if (err2) return res.status(500).json({ error: err2.message });

        // تحديث كلمة المرور
        db.query(
          "UPDATE users SET password = ? WHERE email = ?",
          [hashedPassword, email],
          (err3) => {
            if (err3) return res.status(500).json({ error: err3.message });

            // حذف الـ token بعد الاستخدام
            db.query("DELETE FROM password_resets WHERE token = ?", [token], () => {
              res.status(200).json({ message: "Mot de passe réinitialisé avec succès" });
            });
          }
        );
      });
    }
  );
};

module.exports = { login, getMe, forgotPassword, resetPassword };