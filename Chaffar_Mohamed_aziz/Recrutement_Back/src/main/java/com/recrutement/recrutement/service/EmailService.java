package com.recrutement.recrutement.service;

public interface EmailService {
    void sendActivationEmail(String toEmail, String fullName, String activationToken);
    void sendRecruiterPendingApprovalEmail(String toEmail, String adminName, String recruiterName, String recruiterEmail);
    void sendRecruiterApprovedEmail(String toEmail, String fullName);
    void sendRecruiterRejectedEmail(String toEmail, String fullName);
    void sendWelcomeEmail(String toEmail, String fullName );
    void sendPasswordResetEmail(String toEmail, String fullName, String resetToken);
    void sendAiTestRejectionEmail(String toEmail, String subject, String emailBody);
    void sendInterviewInvitationEmail(String toEmail, String subject, String emailBody);
    void sendInterviewReminderEmail(String toEmail, String subject, String emailBody);
    void sendInterviewAbsenceRejectedEmail(String toEmail, String subject, String emailBody);
    void sendCandidateInvitationEmail(String toEmail, String subject, String emailBody);
    void sendContactMessageEmail(String toEmail, String subject, String emailBody);

}
