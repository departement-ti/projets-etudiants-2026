const db = require("../db");

exports.getContactSettings = (req, res) => {
    db.query('SELECT * FROM site_contact_settings WHERE id = 1', (err, rows) => {
        if (err) return res.status(500).json({ message: "Error", error: err.message });
        res.json(rows[0]);
    });
};

exports.updateContactSettings = (req, res) => {
  const { primary_phone, email, address, topbar_logo, footer_logo } = req.body;
  db.query(
    'UPDATE site_contact_settings SET primary_phone=?, email=?, address=?, topbar_logo=?, footer_logo=? WHERE id=1',
    [primary_phone, email, address, topbar_logo || null, footer_logo || null],
    (err) => {
      if (err) return res.status(500).json({ message: "Error", error: err.message });
      res.json({ message: "Settings updated successfully" });
    }
  );
};
exports.getSocialLinks = (req, res) => {
    db.query('SELECT * FROM social_links ORDER BY id ASC', (err, rows) => {
        if (err) return res.status(500).json({ message: "Error", error: err.message });
        res.json(rows);
    });
};

exports.createSocialLink = (req, res) => {
    const { name, url, icon } = req.body;
    db.query('INSERT INTO social_links (name, url, icon) VALUES (?, ?, ?)', [name, url, icon || null], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ id: result.insertId, name, url });
    });
};

exports.updateSocialLink = (req, res) => {
    const { name, url, icon } = req.body;
    db.query('UPDATE social_links SET name=?, url=?, icon=? WHERE id=?', [name, url, icon || null, req.params.id], (err) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: "Updated" });
    });
};

exports.deleteSocialLink = (req, res) => {
    db.query('DELETE FROM social_links WHERE id=?', [req.params.id], (err) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: "Deleted" });
    });
};

exports.getReviews = (req, res) => {
    db.query("SELECT * FROM reviews ORDER BY id ASC", (err, rows) => {
        if (err) return res.status(500).json({ message: "Error", error: err.message });
        res.json(rows);
    });
};

exports.createReview = (req, res) => {
    const { full_name, job_title, content, status } = req.body;
    db.query('INSERT INTO reviews (full_name, job_title, content, status) VALUES (?, ?, ?, ?)',
        [full_name, job_title || null, content, status || 'Active'],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ id: result.insertId });
        });
};

exports.updateReview = (req, res) => {
    const { full_name, job_title, content, status } = req.body;
    db.query('UPDATE reviews SET full_name=?, job_title=?, content=?, status=? WHERE id=?',
        [full_name, job_title || null, content, status, req.params.id],
        (err) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ message: "Updated" });
        });
};

exports.deleteReview = (req, res) => {
    db.query('DELETE FROM reviews WHERE id=?', [req.params.id], (err) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: "Deleted" });
    });
};

exports.getSections = (req, res) => {
    db.query('SELECT * FROM home_sections ORDER BY sort_order ASC', (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
};

exports.createSection = (req, res) => {
    const { title, subtitle, image, sort_order, is_active } = req.body;
    db.query('INSERT INTO home_sections (title, subtitle, image, sort_order, is_active) VALUES (?, ?, ?, ?, ?)',
        [title, subtitle || null, image || null, sort_order || 1, is_active ?? 1],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ id: result.insertId });
        });
};

exports.updateSection = (req, res) => {
    const { title, subtitle, image, sort_order, is_active } = req.body;
    db.query('UPDATE home_sections SET title=?, subtitle=?, image=?, sort_order=?, is_active=? WHERE id=?',
        [title, subtitle || null, image || null, sort_order, is_active, req.params.id],
        (err) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ message: "Updated" });
        });
};

exports.deleteSection = (req, res) => {
    db.query('DELETE FROM home_sections WHERE id=?', [req.params.id], (err) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: "Deleted" });
    });
};