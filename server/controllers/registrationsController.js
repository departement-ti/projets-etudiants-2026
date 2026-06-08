const db = require("../db");
const bcrypt = require("bcrypt");
const { sendWelcomeEmail } = require("../utils/mailer");

// دالة لتوليد كلمة مرور عشوائية
const generatePassword = (length = 10) => {
  const chars = "ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789";
  let password = "";
  for (let i = 0; i < length; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return password;
};

// GET all registrations
const getRegistrations = (req, res) => {
  const sql = `
    SELECT registrations.*, levels.name AS level_name
    FROM registrations
    LEFT JOIN levels ON registrations.level_id = levels.id
    ORDER BY registrations.id DESC
  `;
  db.query(sql, (err, result) => {
    if (err) return res.status(500).json({ message: "Failed to fetch registrations", error: err.message });
    res.status(200).json(result);
  });
};

// GET registration by id
const getRegistrationById = (req, res) => {
  const { id } = req.params;
  const sql = `
    SELECT registrations.*, levels.name AS level_name
    FROM registrations
    LEFT JOIN levels ON registrations.level_id = levels.id
    WHERE registrations.id = ?
    LIMIT 1
  `;
  db.query(sql, [id], (err, result) => {
    if (err) return res.status(500).json({ message: "Failed to fetch registration", error: err.message });
    if (result.length === 0) return res.status(404).json({ message: "Registration not found" });
    res.status(200).json(result[0]);
  });
};

// CREATE registration
const createRegistration = (req, res) => {
  const { full_name, email, phone, level_id, message } = req.body;
  if (!full_name || full_name.trim() === "") return res.status(400).json({ message: "Full name is required" });
  if (!email || email.trim() === "") return res.status(400).json({ message: "Email is required" });

  const sql = `INSERT INTO registrations (full_name, email, phone, level_id, message) VALUES (?, ?, ?, ?, ?)`;
  db.query(sql, [full_name, email, phone || null, level_id || null, message || null], (err, result) => {
    if (err) return res.status(500).json({ message: "Failed to create registration", error: err.message });
    res.status(201).json({ message: "Registration created successfully", id: result.insertId });
  });
};

// UPDATE registration status
const updateRegistration = (req, res) => {
  const { id } = req.params;
  const { status, rejection_reason } = req.body;

  const allowedStatuses = ["pending", "approved", "rejected"];
  if (!allowedStatuses.includes(status)) {
    return res.status(400).json({ message: "Invalid status value" });
  }

  const getSql = `
    SELECT registrations.*, levels.name AS level_name
    FROM registrations
    LEFT JOIN levels ON registrations.level_id = levels.id
    WHERE registrations.id = ?
    LIMIT 1
  `;

  db.query(getSql, [id], (err, result) => {
    if (err) return res.status(500).json({ message: "DB error", error: err.message });
    if (result.length === 0) return res.status(404).json({ message: "Registration not found" });

    const registration = result[0];

    const updateSql = `UPDATE registrations SET status = ?, rejection_reason = ? WHERE id = ?`;
    db.query(updateSql, [status, rejection_reason || null, id], (err2) => {
      if (err2) return res.status(500).json({ message: "Failed to update status", error: err2.message });

      if (status !== "approved") {
        return res.status(200).json({ message: "Registration status updated successfully" });
      }

      const checkUserSql = "SELECT id FROM users WHERE email = ? LIMIT 1";
      db.query(checkUserSql, [registration.email], (err3, existingUser) => {
        if (err3) return res.status(500).json({ message: "DB error", error: err3.message });

        if (existingUser.length > 0) {
          return res.status(200).json({ message: "Approved — account already exists" });
        }

        const insertStudentSql = `INSERT INTO students (name, email, phone, level_id) VALUES (?, ?, ?, ?)`;
        db.query(
          insertStudentSql,
          [registration.full_name, registration.email, registration.phone || null, registration.level_id || null],
          (err4, studentResult) => {
            if (err4) return res.status(500).json({ message: "Failed to create student", error: err4.message });

            const studentId = studentResult.insertId;
            const plainPassword = generatePassword();

            bcrypt.hash(plainPassword, 10, (err5, hashedPassword) => {
              if (err5) return res.status(500).json({ message: "Failed to hash password", error: err5.message });

              const insertUserSql = `
                INSERT INTO users (full_name, email, password, phone, role, student_id)
                VALUES (?, ?, ?, ?, 'student', ?)
              `;
              db.query(
                insertUserSql,
                [registration.full_name, registration.email, hashedPassword, registration.phone || null, studentId],
                (err6) => {
                  if (err6) return res.status(500).json({ message: "Failed to create user account", error: err6.message });

                  sendWelcomeEmail(registration.email, registration.full_name, registration.email, plainPassword)
                    .then(() => {
                      res.status(200).json({ message: "Approved — account created and email sent successfully" });
                    })
                    .catch((mailErr) => {
                      res.status(200).json({
                        message: "Approved — account created but email failed",
                        emailError: mailErr.message,
                      });
                    });
                }
              );
            });
          }
        );
      });
    });
  });
};

// DELETE registration
const deleteRegistration = (req, res) => {
  const { id } = req.params;
  db.query("DELETE FROM registrations WHERE id = ?", [id], (err, result) => {
    if (err) return res.status(500).json({ message: "Failed to delete registration", error: err.message });
    if (result.affectedRows === 0) return res.status(404).json({ message: "Registration not found" });
    res.status(200).json({ message: "Registration deleted successfully" });
  });
};

module.exports = {
  getRegistrations,
  getRegistrationById,
  createRegistration,
  updateRegistration,
  deleteRegistration,
};