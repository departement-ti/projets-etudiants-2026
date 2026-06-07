package com.recrutement.recrutement.service;

import com.recrutement.recrutement.dto.ConversationMessageResponse;
import com.recrutement.recrutement.dto.ConversationSummaryResponse;
import com.recrutement.recrutement.entities.Candidate;
import com.recrutement.recrutement.entities.Candidature;
import com.recrutement.recrutement.entities.ConversationMessage;
import com.recrutement.recrutement.entities.Entreprise;
import com.recrutement.recrutement.entities.Offre;
import com.recrutement.recrutement.entities.Recruiter;
import com.recrutement.recrutement.entities.Role;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.repositories.CandidateRepository;
import com.recrutement.recrutement.repositories.CandidatureRepository;
import com.recrutement.recrutement.repositories.ConversationMessageRepository;
import com.recrutement.recrutement.repositories.RecruiterRepository;
import com.recrutement.recrutement.repositories.UserRepository;
import jakarta.transaction.Transactional;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class MessagingService {
    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
    private static final Logger logger = LoggerFactory.getLogger(MessagingService.class);

    private final CandidatureRepository candidatureRepository;
    private final CandidateRepository candidateRepository;
    private final RecruiterRepository recruiterRepository;
    private final ConversationMessageRepository conversationMessageRepository;
    private final NotificationService notificationService;
    private final UserRepository userRepository;

    public MessagingService(
            CandidatureRepository candidatureRepository,
            CandidateRepository candidateRepository,
            RecruiterRepository recruiterRepository,
            ConversationMessageRepository conversationMessageRepository,
            NotificationService notificationService,
            UserRepository userRepository
    ) {
        this.candidatureRepository = candidatureRepository;
        this.candidateRepository = candidateRepository;
        this.recruiterRepository = recruiterRepository;
        this.conversationMessageRepository = conversationMessageRepository;
        this.notificationService = notificationService;
        this.userRepository = userRepository;
    }

    public List<ConversationSummaryResponse> getConversations(User currentUser) {
        List<Candidature> candidatures = loadAccessibleApplications(currentUser);
        if (candidatures.isEmpty()) {
            return new ArrayList<>();
        }

        List<Long> applicationIds = candidatures.stream()
                .map(Candidature::getId)
                .filter(Objects::nonNull)
                .toList();

        var latestMessages = conversationMessageRepository.findByCandidature_IdInOrderBySentAtDesc(applicationIds)
                .stream()
                .collect(Collectors.toMap(
                        message -> message.getCandidature().getId(),
                        message -> message,
                        (existing, ignored) -> existing,
                        LinkedHashMap::new
                ));

        return candidatures.stream()
                .map(candidature -> safeConversationSummary(currentUser, candidature, latestMessages.get(candidature.getId())))
                .filter(Objects::nonNull)
                .sorted((left, right) -> safe(right.getLastMessageAt()).compareTo(safe(left.getLastMessageAt())))
                .collect(Collectors.toList());
    }

    @Transactional
    public List<ConversationMessageResponse> getConversationMessages(User currentUser, Long applicationId) {
        Candidature candidature = getAccessibleApplication(currentUser, applicationId);
        markConversationAsRead(currentUser, candidature.getId());

        return conversationMessageRepository.findByCandidature_IdOrderBySentAtAsc(candidature.getId()).stream()
                .map(message -> toConversationMessageResponse(currentUser, message))
                .collect(Collectors.toList());
    }

    @Transactional
    public ConversationMessageResponse sendMessage(User currentUser, Long applicationId, String content) {
        String normalizedContent = safe(content);
        if (normalizedContent.isBlank()) {
            throw new RuntimeException("Le message ne peut pas etre vide.");
        }

        Candidature candidature = getAccessibleApplication(currentUser, applicationId);
        User recipient = resolveRecipient(candidature, currentUser);

        ConversationMessage message = new ConversationMessage();
        message.setCandidature(candidature);
        message.setSender(currentUser);
        message.setRecipient(recipient);
        message.setContent(normalizedContent);
        message.setSentAt(new Date());
        message.setLue(false);

        ConversationMessage savedMessage = conversationMessageRepository.save(message);
        notificationService.notifyUser(
                recipient,
                nonEmpty(currentUser.getNom(), "Nouvel utilisateur")
                        + " vous a envoye un message au sujet de l'offre \""
                        + safe(candidature.getOffre() == null ? "" : candidature.getOffre().getTitre())
                        + "\"."
        );

        return toConversationMessageResponse(currentUser, savedMessage);
    }

    @Transactional
    public void markConversationAsRead(User currentUser, Long applicationId) {
        Candidature candidature = getAccessibleApplication(currentUser, applicationId);
        List<ConversationMessage> unreadMessages = conversationMessageRepository
                .findByCandidature_IdAndRecipient_IdAndLueFalseOrderBySentAtAsc(candidature.getId(), currentUser.getId());

        if (unreadMessages.isEmpty()) {
            return;
        }

        unreadMessages.forEach(message -> message.setLue(true));
        conversationMessageRepository.saveAll(unreadMessages);
    }

    private List<Candidature> loadAccessibleApplications(User currentUser) {
        if (currentUser == null || currentUser.getRole() == null) {
            throw new RuntimeException("Utilisateur non authentifie.");
        }

        if (currentUser.getRole() == Role.CANDIDATE) {
            Candidate candidate = getCurrentCandidate(currentUser);
            return candidatureRepository.findByCandidate_IdOrderByDateDepotDesc(candidate.getId());
        }

        if (currentUser.getRole() == Role.RECRUITER) {
            Recruiter recruiter = getCurrentRecruiter(currentUser);
            return candidatureRepository.findByOffre_Recruiter_IdOrderByScoreCandidatDescDateDepotDesc(recruiter.getId());
        }

        throw new RuntimeException("La messagerie integree est reservee aux candidats et aux recruteurs.");
    }

    private Candidature getAccessibleApplication(User currentUser, Long applicationId) {
        if (currentUser == null || applicationId == null) {
            throw new RuntimeException("Conversation introuvable.");
        }

        if (currentUser.getRole() == Role.CANDIDATE) {
            Candidate candidate = getCurrentCandidate(currentUser);
            return candidatureRepository.findByIdAndCandidate_Id(applicationId, candidate.getId())
                    .orElseThrow(() -> new RuntimeException("Conversation introuvable ou non autorisee."));
        }

        if (currentUser.getRole() == Role.RECRUITER) {
            Recruiter recruiter = getCurrentRecruiter(currentUser);
            return candidatureRepository.findByIdAndOffre_Recruiter_Id(applicationId, recruiter.getId())
                    .orElseThrow(() -> new RuntimeException("Conversation introuvable ou non autorisee."));
        }

        throw new RuntimeException("La messagerie integree est reservee aux candidats et aux recruteurs.");
    }

    private Candidate getCurrentCandidate(User currentUser) {
        Candidate candidate = currentUser.getId() == null
                ? null
                : candidateRepository.findById(currentUser.getId()).orElse(null);

        if (candidate == null) {
            candidate = candidateRepository.findByEmail(currentUser.getEmail());
        }

        if (candidate == null) {
            candidate = createMissingCandidateProfile(currentUser);
        }

        if (candidate == null) {
            throw new RuntimeException("Profil candidat introuvable.");
        }

        return candidate;
    }

    private Recruiter getCurrentRecruiter(User currentUser) {
        Recruiter recruiter = currentUser.getId() == null
                ? null
                : recruiterRepository.findById(currentUser.getId()).orElse(null);

        if (recruiter == null) {
            recruiter = recruiterRepository.findByEmail(currentUser.getEmail());
        }

        if (recruiter == null) {
            recruiter = createMissingRecruiterProfile(currentUser);
        }

        if (recruiter == null) {
            throw new RuntimeException("Profil recruteur introuvable.");
        }

        return recruiter;
    }

    private ConversationSummaryResponse toConversationSummary(User currentUser, Candidature candidature, ConversationMessage lastMessage) {
        ConversationSummaryResponse response = new ConversationSummaryResponse();
        Offre offer = safeOffre(candidature);
        User counterpart = resolveRecipient(candidature, currentUser);

        response.setApplicationId(candidature.getId());
        response.setOfferId(offer == null ? null : offer.getId());
        response.setOfferTitle(safe(offer == null ? "" : offer.getTitre()));
        response.setCompanyName(resolveCompanyName(offer == null ? null : offer.getRecruiter()));
        response.setCounterpartName(nonEmpty(counterpart == null ? null : counterpart.getNom(), "Conversation"));
        response.setCounterpartEmail(safe(counterpart == null ? "" : counterpart.getEmail()));
        response.setCounterpartRole(counterpart == null || counterpart.getRole() == null ? "" : counterpart.getRole().name());
        response.setStatus(safe(candidature.getStatut()));
        response.setScore(Math.round(candidature.getScoreCandidat() * 10d) / 10d);
        response.setUnreadCount(
                currentUser.getId() == null
                        ? 0
                        : conversationMessageRepository.countByCandidature_IdAndRecipient_IdAndLueFalse(
                                candidature.getId(),
                                currentUser.getId()
                        )
        );

        if (lastMessage != null) {
            response.setLastMessage(safe(lastMessage.getContent()));
            response.setLastMessageAt(formatDateTime(lastMessage.getSentAt()));
        } else {
            response.setLastMessage(buildDefaultConversationHint(candidature));
            response.setLastMessageAt(formatDateTime(candidature.getDateDepot()));
        }

        return response;
    }

    private ConversationMessageResponse toConversationMessageResponse(User currentUser, ConversationMessage message) {
        ConversationMessageResponse response = new ConversationMessageResponse();
        response.setId(message.getId());
        response.setApplicationId(message.getCandidature() == null ? null : message.getCandidature().getId());
        response.setSenderId(message.getSender() == null ? null : message.getSender().getId());
        response.setSenderName(nonEmpty(message.getSender() == null ? null : message.getSender().getNom(), "Utilisateur"));
        response.setSenderRole(message.getSender() == null || message.getSender().getRole() == null ? "" : message.getSender().getRole().name());
        response.setRecipientId(message.getRecipient() == null ? null : message.getRecipient().getId());
        response.setContent(safe(message.getContent()));
        response.setSentAt(formatDateTime(message.getSentAt()));
        response.setRead(message.isLue());
        response.setOwnMessage(currentUser != null
                && currentUser.getId() != null
                && message.getSender() != null
                && currentUser.getId().equals(message.getSender().getId()));
        return response;
    }

    private User resolveRecipient(Candidature candidature, User currentUser) {
        if (candidature == null) {
            return null;
        }

        try {
            if (currentUser != null && currentUser.getRole() == Role.CANDIDATE) {
                Offre offer = safeOffre(candidature);
                return offer == null ? null : safeRecruiter(offer);
            }
            return safeCandidate(candidature);
        } catch (RuntimeException ex) {
            logger.warn("Impossible de resoudre le destinataire pour la candidature {}", candidature.getId(), ex);
            return null;
        }
    }

    private String buildDefaultConversationHint(Candidature candidature) {
        Offre offer = safeOffre(candidature);
        String offerTitle = safe(offer == null ? "" : offer.getTitre());
        return offerTitle.isBlank()
                ? "Cette conversation est prete a demarrer."
                : "Conversation liee a l'offre \"" + offerTitle + "\".";
    }

    private ConversationSummaryResponse safeConversationSummary(User currentUser, Candidature candidature, ConversationMessage lastMessage) {
        try {
            return toConversationSummary(currentUser, candidature, lastMessage);
        } catch (RuntimeException ex) {
            logger.warn("Conversation ignoree car les donnees sont invalides pour la candidature {}", candidature == null ? null : candidature.getId(), ex);
            return null;
        }
    }

    private Offre safeOffre(Candidature candidature) {
        try {
            return candidature == null ? null : candidature.getOffre();
        } catch (RuntimeException ex) {
            logger.warn("Offre inaccessible pour la candidature {}", candidature == null ? null : candidature.getId(), ex);
            return null;
        }
    }

    private Candidate safeCandidate(Candidature candidature) {
        try {
            return candidature == null ? null : candidature.getCandidate();
        } catch (RuntimeException ex) {
            logger.warn("Candidat inaccessible pour la candidature {}", candidature == null ? null : candidature.getId(), ex);
            return null;
        }
    }

    private Recruiter safeRecruiter(Offre offre) {
        try {
            return offre == null ? null : offre.getRecruiter();
        } catch (RuntimeException ex) {
            logger.warn("Recruteur inaccessible pour l'offre {}", offre == null ? null : offre.getId(), ex);
            return null;
        }
    }

    private String resolveCompanyName(Recruiter recruiter) {
        if (recruiter == null) {
            return "";
        }

        Entreprise entreprise = recruiter.getEntreprise();
        if (entreprise != null && !safe(entreprise.getNomEntreprise()).isBlank()) {
            return safe(entreprise.getNomEntreprise());
        }

        return safe(recruiter.getNom());
    }

    private Candidate createMissingCandidateProfile(User authenticatedUser) {
        User persistedUser = resolvePersistedUser(authenticatedUser);
        if (persistedUser == null) {
            return null;
        }

        if (persistedUser.getRole() != Role.CANDIDATE) {
            return null;
        }

        Candidate candidate = new Candidate();
        candidate.setId(persistedUser.getId());
        candidate.setEmail(persistedUser.getEmail());
        candidate.setNom(persistedUser.getNom());
        candidate.setPassword(persistedUser.getPassword());
        candidate.setRole(persistedUser.getRole());
        candidate.setStatutCompte(persistedUser.getStatutCompte());
        candidate.setApprovalStatus(persistedUser.getApprovalStatus());
        candidate.setEmailVerified(persistedUser.getEmailverified());
        candidate.setActivationToken(persistedUser.getActivationToken());
        candidate.setResetPasswordToken(persistedUser.getResetPasswordToken());
        candidate.setResetPasswordTokenExpiresAt(persistedUser.getResetPasswordTokenExpiresAt());
        candidate.setNumTelephone("");
        candidate.setPosteRecherche("");
        candidate.setLocalisation("");
        candidate.setAdresse("");
        candidate.setGenre("");
        candidate.setDescription("");
        candidate.setProfession("");
        candidate.setExperiencesJson("[]");
        candidate.setEducationJson("[]");
        candidate.setSkillsJson("[]");
        candidate.setPhotoProfilUrl("");
        candidate.setPhotoProfilPublicId("");
        candidate.setPhotoCouvertureUrl("");
        candidate.setPhotoCouverturePublicId("");
        return candidateRepository.save(candidate);
    }

    private Recruiter createMissingRecruiterProfile(User authenticatedUser) {
        User persistedUser = resolvePersistedUser(authenticatedUser);
        if (persistedUser == null) {
            return null;
        }

        if (persistedUser.getRole() != Role.RECRUITER) {
            return null;
        }

        Recruiter recruiter = new Recruiter();
        recruiter.setId(persistedUser.getId());
        recruiter.setEmail(persistedUser.getEmail());
        recruiter.setNom(persistedUser.getNom());
        recruiter.setPassword(persistedUser.getPassword());
        recruiter.setRole(persistedUser.getRole());
        recruiter.setStatutCompte(persistedUser.getStatutCompte());
        recruiter.setApprovalStatus(persistedUser.getApprovalStatus());
        recruiter.setEmailVerified(persistedUser.getEmailverified());
        recruiter.setActivationToken(persistedUser.getActivationToken());
        recruiter.setResetPasswordToken(persistedUser.getResetPasswordToken());
        recruiter.setResetPasswordTokenExpiresAt(persistedUser.getResetPasswordTokenExpiresAt());
        recruiter.setFonction("");
        recruiter.setPoste("");
        recruiter.setDepartement("");
        recruiter.setEntreprise(null);
        return recruiterRepository.save(recruiter);
    }

    private User resolvePersistedUser(User authenticatedUser) {
        if (authenticatedUser == null) {
            return null;
        }

        if (authenticatedUser.getId() != null) {
            User persistedUser = userRepository.findById(authenticatedUser.getId()).orElse(null);
            if (persistedUser != null) {
                return persistedUser;
            }
        }

        if (authenticatedUser.getEmail() != null && !authenticatedUser.getEmail().isBlank()) {
            return userRepository.findByEmail(authenticatedUser.getEmail()).orElse(null);
        }

        return null;
    }

    private String formatDateTime(Date date) {
        if (date == null) {
            return "";
        }

        return toLocalDateTime(date)
                .format(DATE_TIME_FORMATTER);
    }

    private LocalDateTime toLocalDateTime(Date value) {
        if (value instanceof java.sql.Timestamp sqlTimestamp) {
            return sqlTimestamp.toLocalDateTime();
        }

        if (value instanceof java.sql.Date sqlDate) {
            return sqlDate.toLocalDate().atStartOfDay();
        }

        return value.toInstant()
                .atZone(ZoneId.systemDefault())
                .toLocalDateTime();
    }

    private String nonEmpty(String value, String fallback) {
        String safeValue = safe(value);
        return safeValue.isBlank() ? fallback : safeValue;
    }

    private String safe(String value) {
        return value == null ? "" : value.trim();
    }
}
