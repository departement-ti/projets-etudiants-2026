// server/controllers/attendanceController.js
const db = require('../db');

// 1. جلب طلاب مجموعة معينة (لأخذ الحضور)
exports.getStudentsByGroup = (req, res) => {
    const { group_id } = req.params;
    const sql = "SELECT id, name as full_name FROM students WHERE group_id = ?";
    
    db.query(sql, [group_id], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
};

// 2. حفظ الحضور (إضافة أو تحديث)
exports.saveAttendance = (req, res) => {
    const { group_id, date, attendance } = req.body; // attendance is array of {student_id, status}

    // سنستخدم نظام الـ "Transaction" لضمان حذف القديم وإضافة الجديد لنفس التاريخ والمجموعة
    db.beginTransaction((err) => {
        if (err) throw err;

        const deleteSql = "DELETE FROM attendance WHERE group_id = ? AND attendance_date = ?";
        db.query(deleteSql, [group_id, date], (err) => {
            if (err) return db.rollback(() => res.status(500).json({ error: err.message }));

            if (attendance.length === 0) {
                return db.commit(() => res.json({ message: "تم تحديث السجل" }));
            }

            const values = attendance.map(a => [a.student_id, group_id, date, a.status]);
            const insertSql = "INSERT INTO attendance (student_id, group_id, attendance_date, status) VALUES ?";
            
            db.query(insertSql, [values], (err) => {
                if (err) return db.rollback(() => res.status(500).json({ error: err.message }));
                db.commit(() => res.json({ message: "تم حفظ الحضور بنجاح" }));
            });
        });
    });
};

// 3. جلب الحضور المسجل لتاريخ معين
exports.getAttendanceByDate = (req, res) => {
    const { group_id, date } = req.query;
    const sql = "SELECT student_id, status FROM attendance WHERE group_id = ? AND attendance_date = ?";
    
    db.query(sql, [group_id, date], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
};

// 4. جلب تاريخ الحضور (History) للمجموعة
exports.getGroupHistory = (req, res) => {
    const { group_id } = req.params;
    const sql = `
        SELECT 
            attendance_date, 
            COUNT(*) as total,
            SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END) as present_count,
            SUM(CASE WHEN status = 'absent' THEN 1 ELSE 0 END) as absent_count
        FROM attendance
        WHERE group_id = ?
        GROUP BY attendance_date
        ORDER BY attendance_date DESC
    `;
    
    db.query(sql, [group_id], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
};