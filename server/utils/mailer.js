const nodemailer = require("nodemailer");

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.MAIL_USER,
    pass: process.env.MAIL_PASS,
  },
});

const sendWelcomeEmail = (to, full_name, email, password) => {
  const mailOptions = {
    from: `"EduLive" <${process.env.MAIL_USER}>`,
    to,
    subject: "تم قبول طلب تسجيلك في EduLive 🎉",
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 30px; border: 1px solid #e0e0e0; border-radius: 10px;">
        <h2 style="color: #4f46e5;">مرحباً ${full_name}!</h2>
        <p>تم قبول طلب تسجيلك في منصة <strong>EduLive</strong>.</p>
        <p>إليك بيانات الدخول الخاصة بك:</p>
        <div style="background: #f3f4f6; padding: 15px; border-radius: 8px; margin: 20px 0;">
          <p><strong>البريد الإلكتروني:</strong> ${email}</p>
          <p><strong>كلمة المرور:</strong> ${password}</p>
        </div>
        <p>يُرجى تغيير كلمة المرور بعد أول تسجيل دخول.</p>
        <a href="http://localhost:5173/auth" 
           style="background: #4f46e5; color: white; padding: 12px 25px; border-radius: 6px; text-decoration: none; display: inline-block; margin-top: 10px;">
          تسجيل الدخول الآن
        </a>
        <p style="margin-top: 30px; color: #9ca3af; font-size: 12px;">EduLive — منصة التعليم الإلكتروني</p>
      </div>
    `,
  };

  return transporter.sendMail(mailOptions);
};

module.exports = { sendWelcomeEmail };