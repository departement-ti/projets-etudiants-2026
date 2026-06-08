package com.recrutement.recrutement.service.Impl;

import com.recrutement.recrutement.service.EmailService;
import java.io.UnsupportedEncodingException;
import java.net.ConnectException;
import java.net.SocketTimeoutException;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import jakarta.mail.AuthenticationFailedException;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
public class EmailServiceImpl implements EmailService {
    private static final Logger logger = LoggerFactory.getLogger(EmailServiceImpl.class);

    private final JavaMailSender mailSender;

    @Value("${app.frontend.url}")
    private String frontendUrl;

    @Value("${spring.mail.username}")
    private String fromEmail;

    public EmailServiceImpl(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    @Override
    public void sendActivationEmail(String toEmail, String fullName, String activationToken) {
        String activationLink = frontendUrl + "/verify-email?token=" + activationToken;
        sendHtmlEmail(
                toEmail,
                "Activation de votre compte - SmartRecruit",
                buildActivationEmailTemplate(fullName, activationLink),
                "email d'activation"
        );
    }

    @Override
    public void sendRecruiterPendingApprovalEmail(String toEmail, String adminName, String recruiterName, String recruiterEmail) {
        sendHtmlEmail(
                toEmail,
                "Nouveau compte recruteur en attente - SmartRecruit",
                buildRecruiterPendingApprovalTemplate(adminName, recruiterName, recruiterEmail),
                "email de notification admin"
        );
    }

    @Override
    public void sendRecruiterApprovedEmail(String toEmail, String fullName) {
        sendHtmlEmail(
                toEmail,
                "Votre compte recruteur est actif - SmartRecruit",
                buildRecruiterApprovedTemplate(fullName),
                "email d'approbation recruteur"
        );
    }

    @Override
    public void sendRecruiterRejectedEmail(String toEmail, String fullName) {
        sendHtmlEmail(
                toEmail,
                "Votre demande recruteur a ete refusee - SmartRecruit",
                buildRecruiterRejectedTemplate(fullName),
                "email de refus recruteur"
        );
    }

    @Override
    public void sendWelcomeEmail(String toEmail, String fullName) {
        try {
            sendHtmlEmail(
                    toEmail,
                    "Bienvenue sur SmartRecruit",
                    buildWelcomeEmailTemplate(fullName),
                    "email de bienvenue"
            );
        } catch (RuntimeException ex) {
            logger.error("Erreur lors de l'envoi de l'email de bienvenue a {}: {}", toEmail, ex.getMessage(), ex);
        }
    }

    @Override
    public void sendPasswordResetEmail(String toEmail, String fullName, String resetToken) {
        String resetLink = frontendUrl + "/reset-password?token=" + resetToken;
        sendHtmlEmail(
                toEmail,
                "Reinitialisation de votre mot de passe - SmartRecruit",
                buildPasswordResetTemplate(fullName, resetLink),
                "email de reinitialisation"
        );
    }

    @Override
    public void sendAiTestRejectionEmail(String toEmail, String subject, String emailBody) {
        sendHtmlEmail(
                toEmail,
                hasText(subject) ? subject : "Suite a votre candidature - SmartRecruit",
                buildAiRejectionTemplate(emailBody),
                "email de refus apres test IA"
        );
    }

    @Override
    public void sendInterviewInvitationEmail(String toEmail, String subject, String emailBody) {
        sendHtmlEmail(
                toEmail,
                hasText(subject) ? subject : "Invitation entretien - SmartRecruit",
                buildInterviewEmailTemplate("Invitation a un entretien", emailBody),
                "email d'invitation entretien"
        );
    }

    @Override
    public void sendInterviewReminderEmail(String toEmail, String subject, String emailBody) {
        sendHtmlEmail(
                toEmail,
                hasText(subject) ? subject : "Rappel entretien - SmartRecruit",
                buildInterviewEmailTemplate("Rappel entretien", emailBody),
                "email de rappel entretien"
        );
    }

    @Override
    public void sendInterviewAbsenceRejectedEmail(String toEmail, String subject, String emailBody) {
        sendHtmlEmail(
                toEmail,
                hasText(subject) ? subject : "Suite a votre entretien - SmartRecruit",
                buildInterviewEmailTemplate("Suite a votre entretien", emailBody),
                "email de refus apres absence"
        );
    }

    @Override
    public void sendCandidateInvitationEmail(String toEmail, String subject, String emailBody) {
        sendHtmlEmail(
                toEmail,
                hasText(subject) ? subject : "Invitation a postuler - SmartRecruit",
                buildInterviewEmailTemplate("Invitation a postuler", emailBody),
                "email d'invitation candidat"
        );
    }

    @Override
    public void sendContactMessageEmail(String toEmail, String subject, String emailBody) {
        sendHtmlEmail(
                toEmail,
                hasText(subject) ? subject : "Nouveau message contact - SmartRecruit",
                buildInterviewEmailTemplate("Message contact", emailBody),
                "email de contact admin"
        );
    }

    private void sendHtmlEmail(String toEmail, String subject, String htmlBody, String emailLabel) {
        validateEmailRequest(toEmail, subject);

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(
                    message,
                    MimeMessageHelper.MULTIPART_MODE_MIXED_RELATED,
                    StandardCharsets.UTF_8.name()
            );

            helper.setValidateAddresses(true);
            helper.setFrom(fromEmail, "Smart Recruit");
            helper.setTo(toEmail.trim());
            helper.setSubject(subject);
            helper.setText(htmlBody, true);
            message.setSentDate(new Date());

            mailSender.send(message);
            logger.info("{} envoye a {}", emailLabel, toEmail);
        } catch (MailException | MessagingException | UnsupportedEncodingException ex) {
            String failureMessage = resolveMailFailureMessage(ex, emailLabel);
            logger.error("Echec de l'envoi de {} a {}: {}", emailLabel, toEmail, failureMessage, ex);
            throw new RuntimeException(failureMessage, ex);
        }
    }

    private void validateEmailRequest(String toEmail, String subject) {
        if (!hasText(fromEmail)) {
            throw new RuntimeException("Configuration email manquante : spring.mail.username n'est pas defini.");
        }

        if (!hasText(toEmail)) {
            throw new RuntimeException("Adresse email destinataire manquante.");
        }

        if (!hasText(subject)) {
            throw new RuntimeException("Sujet de l'email manquant.");
        }
    }

    private boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }

    private String resolveMailFailureMessage(Throwable throwable, String emailLabel) {
        Throwable current = throwable;
        while (current != null) {
            if (current instanceof AuthenticationFailedException) {
                return "Echec de l'envoi de " + emailLabel + " : authentification Gmail invalide. Verifiez spring.mail.username et le mot de passe d'application Gmail.";
            }

            if (current instanceof ConnectException || current instanceof SocketTimeoutException) {
                return "Echec de l'envoi de " + emailLabel + " : le serveur SMTP Gmail est inaccessible depuis cette machine. Verifiez l'acces reseau vers smtp.gmail.com sur les ports 587 ou 465.";
            }

            String message = current.getMessage();
            if (message != null) {
                String normalized = message.toLowerCase();
                if (normalized.contains("could not connect")
                        || normalized.contains("connection timed out")
                        || normalized.contains("connect timed out")
                        || normalized.contains("connection refused")) {
                    return "Echec de l'envoi de " + emailLabel + " : le serveur SMTP Gmail est inaccessible depuis cette machine. Verifiez l'acces reseau vers smtp.gmail.com sur les ports 587 ou 465.";
                }

                if (normalized.contains("authentication failed")
                        || normalized.contains("535-5.7.8")
                        || normalized.contains("535 5.7.8")
                        || normalized.contains("534-5.7.9")
                        || normalized.contains("username and password not accepted")) {
                    return "Echec de l'envoi de " + emailLabel + " : authentification Gmail invalide. Verifiez spring.mail.username et le mot de passe d'application Gmail.";
                }
            }

            current = current.getCause();
        }

        return "Echec de l'envoi de " + emailLabel;
    }

    private String buildActivationEmailTemplate(String fullName, String activationLink) {
        return baseTemplate(
                "Verification de votre email",
                "Bonjour " + fullName + ",",
                """
                <p>Merci de vous etre inscrit sur SmartRecruit. Cliquez sur le bouton ci-dessous pour activer votre compte.</p>
                """,
                activationLink,
                "Activer mon compte",
                """
                <p>Ce lien d'activation est valable pendant 24 heures.</p>
                """
        );
    }

    private String buildRecruiterPendingApprovalTemplate(String adminName, String recruiterName, String recruiterEmail) {
        String safeAdminName = (adminName == null || adminName.isBlank()) ? "Administrateur" : adminName;

        return baseTemplate(
                "Validation d'un nouveau recruteur",
                "Bonjour " + safeAdminName + ",",
                String.format(
                        """
                        <p>Un nouveau compte recruteur vient d'etre cree et attend votre validation.</p>
                        <ul>
                            <li><strong>Nom :</strong> %s</li>
                            <li><strong>Email :</strong> %s</li>
                        </ul>
                        <p>Veuillez verifier ce compte puis l'activer depuis l'espace administrateur.</p>
                        """,
                        recruiterName,
                        recruiterEmail
                ),
                frontendUrl + "/admin-dashboard",
                "Ouvrir le dashboard admin",
                """
                <p>Apres activation, le recruteur recevra automatiquement un email de confirmation.</p>
                """
        );
    }

    private String buildRecruiterApprovedTemplate(String fullName) {
        return baseTemplate(
                "Compte recruteur active",
                "Bonjour " + fullName + ",",
                """
                <p>Votre compte recruteur a ete verifie et active par l'administration.</p>
                <p>Vous pouvez maintenant vous connecter et utiliser toutes les fonctionnalites recruteur.</p>
                """,
                frontendUrl + "/auth/login",
                "Se connecter",
                """
                <p>Bienvenue sur SmartRecruit, votre espace recrutement est maintenant operationnel.</p>
                """
        );
    }

    private String buildRecruiterRejectedTemplate(String fullName) {
        return baseTemplate(
                "Demande recruteur refusee",
                "Bonjour " + fullName + ",",
                """
                <p>Apres verification par l'administration, votre demande de compte recruteur n'a pas ete retenue.</p>
                <p>Si vous pensez qu'il s'agit d'une erreur, vous pouvez contacter l'administration ou soumettre une nouvelle demande avec des informations completes.</p>
                """,
                frontendUrl + "/register",
                "Revenir a l'inscription",
                """
                <p>Merci pour votre interet pour SmartRecruit.</p>
                """
        );
    }

    private String buildPasswordResetTemplate(String fullName, String resetLink) {
        return baseTemplate(
                "Mot de passe oublie",
                "Bonjour " + fullName + ",",
                """
                <p>Nous avons recu une demande de reinitialisation de mot de passe pour votre compte SmartRecruit.</p>
                <p>Si vous etes a l'origine de cette demande, utilisez le bouton ci-dessous pour definir un nouveau mot de passe.</p>
                """,
                resetLink,
                "Reinitialiser mon mot de passe",
                """
                <p>Ce lien est valable pendant 30 minutes. Si vous n'avez pas demande cette action, ignorez simplement cet email.</p>
                """
        );
    }

    private String buildWelcomeEmailTemplate(String fullName) {
        return baseTemplate(
                "Compte active avec succes",
                "Felicitations " + fullName + ",",
                """
                <p>Votre compte SmartRecruit est maintenant actif. Vous pouvez des a present vous connecter a la plateforme.</p>
                """,
                frontendUrl + "/auth/login",
                "Se connecter",
                """
                <p>Merci de votre confiance et bienvenue sur SmartRecruit.</p>
                """
        );
    }

    private String buildAiRejectionTemplate(String emailBody) {
        String sanitizedBody = hasText(emailBody)
                ? emailBody.trim().replace("\r\n", "\n").replace("\n", "<br>")
                : "Bonjour,<br><br>Nous vous remercions pour votre interet pour Smart Recruit.<br><br>Cordialement,<br>Smart Recruit";

        return String.format(
                """
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="UTF-8">
                    <style>
                        body { font-family: Arial, sans-serif; line-height: 1.7; color: #24324a; background: #f4f7fb; margin: 0; padding: 24px; }
                        .container { max-width: 640px; margin: 0 auto; background: #ffffff; border-radius: 20px; overflow: hidden; box-shadow: 0 14px 32px rgba(24, 39, 75, 0.12); }
                        .header { padding: 28px 32px; background: linear-gradient(135deg, #255fd0 0%%, #27b0d7 100%%); color: #ffffff; }
                        .content { padding: 32px; }
                        .footer { color: #6f7c95; font-size: 13px; margin-top: 24px; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="header">
                            <h1>SmartRecruit</h1>
                            <p>Suite a votre candidature</p>
                        </div>
                        <div class="content">
                            <div>%s</div>
                            <p class="footer">Cet email a ete envoye depuis Smart Recruit.</p>
                        </div>
                    </div>
                </body>
                </html>
                """,
                sanitizedBody
        );
    }

    private String buildInterviewEmailTemplate(String title, String emailBody) {
        String sanitizedBody = hasText(emailBody)
                ? emailBody.trim().replace("\r\n", "\n").replace("\n", "<br>")
                : "Bonjour,<br><br>Smart Recruit vous contacte au sujet de votre entretien.<br><br>Cordialement,<br>Smart Recruit";

        return String.format(
                """
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="UTF-8">
                    <style>
                        body { font-family: Arial, sans-serif; line-height: 1.7; color: #24324a; background: #f4f7fb; margin: 0; padding: 24px; }
                        .container { max-width: 640px; margin: 0 auto; background: #ffffff; border-radius: 20px; overflow: hidden; box-shadow: 0 14px 32px rgba(24, 39, 75, 0.12); }
                        .header { padding: 28px 32px; background: linear-gradient(135deg, #214f97 0%%, #2a89d6 100%%); color: #ffffff; }
                        .content { padding: 32px; }
                        .footer { color: #6f7c95; font-size: 13px; margin-top: 24px; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="header">
                            <h1>SmartRecruit</h1>
                            <p>%s</p>
                        </div>
                        <div class="content">
                            <div>%s</div>
                            <p class="footer">Cet email a ete envoye depuis Smart Recruit.</p>
                        </div>
                    </div>
                </body>
                </html>
                """,
                title,
                sanitizedBody
        );
    }

    private String baseTemplate(
            String title,
            String greeting,
            String introHtml,
            String actionLink,
            String actionLabel,
            String footerHtml
    ) {
        return String.format(
                """
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="UTF-8">
                    <style>
                        body { font-family: Arial, sans-serif; line-height: 1.6; color: #24324a; background: #f4f7fb; margin: 0; padding: 24px; }
                        .container { max-width: 640px; margin: 0 auto; background: #ffffff; border-radius: 20px; overflow: hidden; box-shadow: 0 14px 32px rgba(24, 39, 75, 0.12); }
                        .header { padding: 28px 32px; background: linear-gradient(135deg, #255fd0 0%%, #27b0d7 100%%); color: #ffffff; }
                        .content { padding: 32px; }
                        .button-wrap { text-align: center; margin: 28px 0; }
                        .btn { display: inline-block; padding: 14px 28px; background: linear-gradient(135deg, #255fd0, #27b0d7); color: #ffffff !important; text-decoration: none; border-radius: 999px; font-weight: 700; }
                        .link-box { margin-top: 24px; padding: 16px; background: #f4f8ff; border-radius: 14px; font-size: 14px; word-break: break-all; }
                        .footer { color: #6f7c95; font-size: 13px; margin-top: 24px; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="header">
                            <h1>%s</h1>
                            <p>SmartRecruit</p>
                        </div>
                        <div class="content">
                            <h2>%s</h2>
                            %s
                            <div class="button-wrap">
                                <a href="%s" class="btn">%s</a>
                            </div>
                            %s
                            <div class="link-box">
                                <strong>Lien direct :</strong><br>
                                <a href="%s">%s</a>
                            </div>
                            <p class="footer">Cet email a ete envoye automatiquement. Merci de ne pas y repondre.</p>
                        </div>
                    </div>
                </body>
                </html>
                """,
                title,
                greeting,
                introHtml,
                actionLink,
                actionLabel,
                footerHtml,
                actionLink,
                actionLink
        );
    }
}
