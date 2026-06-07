package com.recrutement.recrutement.service;

import com.recrutement.recrutement.dto.ContactMessageRequest;
import com.recrutement.recrutement.dto.ContactMessageResponse;
import com.recrutement.recrutement.entities.ContactMessage;
import com.recrutement.recrutement.entities.Role;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.repositories.ContactMessageRepository;
import com.recrutement.recrutement.repositories.UserRepository;
import java.util.Date;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ContactMessageService {
    private static final Logger logger = LoggerFactory.getLogger(ContactMessageService.class);

    private final ContactMessageRepository contactMessageRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final EmailService emailService;

    public ContactMessageService(
            ContactMessageRepository contactMessageRepository,
            UserRepository userRepository,
            NotificationService notificationService,
            EmailService emailService
    ) {
        this.contactMessageRepository = contactMessageRepository;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
        this.emailService = emailService;
    }

    @Transactional
    public ContactMessageResponse submit(ContactMessageRequest request) {
        validate(request);

        ContactMessage message = new ContactMessage();
        message.setFullName(resolveName(request));
        message.setEmail(clean(request.getEmail()));
        message.setSubject(clean(request.getSubject()));
        message.setMessage(clean(request.getMessage()));
        message.setCreatedAt(new Date());
        contactMessageRepository.save(message);

        String adminNotification = "Nouveau message contact de " + message.getFullName()
                + " - Sujet : " + message.getSubject();
        notificationService.notifyAdmins(adminNotification);

        String emailBody = buildAdminEmailBody(message);
        List<User> admins = userRepository.findAllByRole(Role.ADMIN);
        for (User admin : admins) {
            try {
                emailService.sendContactMessageEmail(admin.getEmail(), "Nouveau message contact - " + message.getSubject(), emailBody);
            } catch (RuntimeException ex) {
                logger.warn("Echec d'envoi du message contact a l'admin {}: {}", admin.getEmail(), ex.getMessage());
            }
        }

        return new ContactMessageResponse(true, "Votre message a été envoyé avec succès.");
    }

    private void validate(ContactMessageRequest request) {
        if (request == null) {
            throw new RuntimeException("Les informations du message sont obligatoires.");
        }

        if (resolveName(request).isBlank()) {
            throw new RuntimeException("Le nom est obligatoire.");
        }

        String email = clean(request.getEmail());
        if (email.isBlank() || !email.contains("@")) {
            throw new RuntimeException("Une adresse e-mail valide est obligatoire.");
        }

        if (clean(request.getSubject()).isBlank()) {
            throw new RuntimeException("Le sujet est obligatoire.");
        }

        if (clean(request.getMessage()).length() < 12) {
            throw new RuntimeException("Le message doit contenir au moins 12 caractères.");
        }
    }

    private String buildAdminEmailBody(ContactMessage message) {
        return "Bonjour,\n\n"
                + "Un nouveau message a été envoyé depuis la page Contact Smart-Recruit.\n\n"
                + "Nom : " + message.getFullName() + "\n"
                + "Email : " + message.getEmail() + "\n"
                + "Sujet : " + message.getSubject() + "\n\n"
                + "Message :\n" + message.getMessage() + "\n\n"
                + "Cordialement,\nSmart-Recruit";
    }

    private String resolveName(ContactMessageRequest request) {
        String fullName = clean(request.getFullName());
        return fullName.isBlank() ? clean(request.getNom()) : fullName;
    }

    private String clean(String value) {
        return value == null ? "" : value.trim();
    }
}
