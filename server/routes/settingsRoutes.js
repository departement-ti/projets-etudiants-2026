const express = require('express');
const router = express.Router();
const settingsController = require('../controllers/settingsController');

// --- 1. إعدادات الاتصال (Contact Settings) ---
router.get('/contact', settingsController.getContactSettings);
router.put('/contact', settingsController.updateContactSettings);

// --- 2. روابط التواصل الاجتماعي (Social Links) ---
router.get('/social', settingsController.getSocialLinks); // (موجود سابقاً)
router.post('/social', settingsController.createSocialLink); // إضافة جديد
router.put('/social/:id', settingsController.updateSocialLink); // تعديل
router.delete('/social/:id', settingsController.deleteSocialLink); // حذف

// --- 3. الآراء والتقييمات (Reviews) ---
router.get('/reviews', settingsController.getReviews); // (موجود سابقاً)
router.post('/reviews', settingsController.createReview); // إضافة جديد
router.put('/reviews/:id', settingsController.updateReview); // تعديل
router.delete('/reviews/:id', settingsController.deleteReview); // حذف

// --- 4. أقسام الصفحة الرئيسية (Sections) ---
router.get('/sections', settingsController.getSections);
router.post('/sections', settingsController.createSection);
router.put('/sections/:id', settingsController.updateSection);
router.delete('/sections/:id', settingsController.deleteSection);

module.exports = router;