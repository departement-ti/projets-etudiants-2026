package com.recrutement.recrutement.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.recrutement.recrutement.dto.OffreCompetenceRequest;
import com.recrutement.recrutement.dto.OffreCompetenceResponse;
import com.recrutement.recrutement.dto.OffreRequest;
import com.recrutement.recrutement.dto.OffreResponse;
import com.recrutement.recrutement.dto.CandidateTopMatchingOfferResponse;
import com.recrutement.recrutement.dto.MatchingCandidateResponse;
import com.recrutement.recrutement.dto.MessageResponse;
import com.recrutement.recrutement.entities.AiTest;
import com.recrutement.recrutement.entities.AiTestResult;
import com.recrutement.recrutement.entities.CandidateInvitation;
import com.recrutement.recrutement.entities.Candidate;
import com.recrutement.recrutement.entities.Candidature;
import com.recrutement.recrutement.entities.Competence;
import com.recrutement.recrutement.entities.InvitationStatus;
import com.recrutement.recrutement.entities.Offre;
import com.recrutement.recrutement.entities.Recruiter;
import com.recrutement.recrutement.entities.Role;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.repositories.AiTestRepository;
import com.recrutement.recrutement.repositories.AiAnswerRepository;
import com.recrutement.recrutement.repositories.AiQuestionRepository;
import com.recrutement.recrutement.repositories.AiTestResultRepository;
import com.recrutement.recrutement.repositories.CandidateRepository;
import com.recrutement.recrutement.repositories.CandidateInvitationRepository;
import com.recrutement.recrutement.repositories.CandidatureRepository;
import com.recrutement.recrutement.repositories.ConversationMessageRepository;
import com.recrutement.recrutement.repositories.InterviewRepository;
import com.recrutement.recrutement.repositories.OffreRepository;
import com.recrutement.recrutement.repositories.RecruiterRepository;
import java.text.Normalizer;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OfferService {
    private final OffreRepository offreRepository;
    private final RecruiterRepository recruiterRepository;
    private final CandidateRepository candidateRepository;
    private final CandidatureRepository candidatureRepository;
    private final ConversationMessageRepository conversationMessageRepository;
    private final AiTestRepository aiTestRepository;
    private final AiAnswerRepository aiAnswerRepository;
    private final AiQuestionRepository aiQuestionRepository;
    private final AiTestResultRepository aiTestResultRepository;
    private final InterviewRepository interviewRepository;
    private final CandidateInvitationRepository candidateInvitationRepository;
    private final MatchingService matchingService;
    private final CompetenceService competenceService;
    private final NotificationService notificationService;
    private final EmailService emailService;
    private final ObjectMapper objectMapper;

    public OfferService(
            OffreRepository offreRepository,
            RecruiterRepository recruiterRepository,
            CandidateRepository candidateRepository,
            CandidatureRepository candidatureRepository,
            ConversationMessageRepository conversationMessageRepository,
            AiTestRepository aiTestRepository,
            AiAnswerRepository aiAnswerRepository,
            AiQuestionRepository aiQuestionRepository,
            AiTestResultRepository aiTestResultRepository,
            InterviewRepository interviewRepository,
            CandidateInvitationRepository candidateInvitationRepository,
            MatchingService matchingService,
            CompetenceService competenceService,
            NotificationService notificationService,
            EmailService emailService,
            ObjectMapper objectMapper
    ) {
        this.offreRepository = offreRepository;
        this.recruiterRepository = recruiterRepository;
        this.candidateRepository = candidateRepository;
        this.candidatureRepository = candidatureRepository;
        this.conversationMessageRepository = conversationMessageRepository;
        this.aiTestRepository = aiTestRepository;
        this.aiAnswerRepository = aiAnswerRepository;
        this.aiQuestionRepository = aiQuestionRepository;
        this.aiTestResultRepository = aiTestResultRepository;
        this.interviewRepository = interviewRepository;
        this.candidateInvitationRepository = candidateInvitationRepository;
        this.matchingService = matchingService;
        this.competenceService = competenceService;
        this.notificationService = notificationService;
        this.emailService = emailService;
        this.objectMapper = objectMapper;
    }

    public List<OffreResponse> getAllOffers(User currentUser) {
        Candidate candidate = resolveCandidate(currentUser);
        return offreRepository.findByStatutIgnoreCaseOrderByDateDesc("PUBLIEE").stream()
                .filter(this::isOfferActive)
                .map(offre -> toResponse(offre, candidate))
                .collect(Collectors.toList());
    }

    public List<CandidateTopMatchingOfferResponse> getTopMatchingOffersForCandidate(User currentUser, Double minScore) {
        Candidate candidate = resolveCandidate(currentUser);
        if (candidate == null) {
            throw new RuntimeException("Profil candidat introuvable.");
        }

        double effectiveMinScore = minScore == null ? 70d : Math.max(0d, Math.min(100d, minScore));
        List<CandidateTopMatchingOfferResponse> rankedOffers = offreRepository.findByStatutIgnoreCaseOrderByDateDesc("PUBLIEE").stream()
                .filter(this::isOfferActive)
                .map(offre -> toCandidateTopMatchingOfferResponse(offre, candidate))
                .sorted(Comparator.comparing(
                        CandidateTopMatchingOfferResponse::getMatchingScore,
                        Comparator.nullsLast(Double::compareTo)
                ).reversed())
                .collect(Collectors.toList());

        List<CandidateTopMatchingOfferResponse> filtered = rankedOffers.stream()
                .filter(item -> item.getMatchingScore() != null && item.getMatchingScore() >= effectiveMinScore)
                .collect(Collectors.toList());

        if (!filtered.isEmpty()) {
            return filtered;
        }

        return rankedOffers.stream().limit(3).collect(Collectors.toList());
    }

    public OffreResponse getOfferById(Long id, User currentUser) {
        Offre offre = offreRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Offre introuvable."));
        return toResponse(offre, resolveCandidate(currentUser));
    }

    public List<OffreResponse> getRecruiterOffers(User currentUser) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        return offreRepository.findByRecruiter_IdOrderByDateDesc(recruiter.getId()).stream()
                .map(offre -> toResponse(offre, null))
                .collect(Collectors.toList());
    }

    public OffreResponse createOffer(User currentUser, OffreRequest request) {
        if (request == null) {
            throw new RuntimeException("Les informations de l'offre sont obligatoires.");
        }

        Recruiter recruiter = getCurrentRecruiter(currentUser);

        Offre offre = new Offre();
        applyRequest(offre, request);
        offre.setStatut("EN_ATTENTE_TEST_IA");
        offre.setRecruiter(recruiter);
        offre.setDate(java.sql.Date.valueOf(LocalDate.now()));

        return toResponse(offreRepository.save(offre), null);
    }

    public OffreResponse updateOffer(User currentUser, Long offerId, OffreRequest request) {
        if (request == null) {
            throw new RuntimeException("Les informations de l'offre sont obligatoires.");
        }

        Offre offre = getRecruiterOwnedOffer(currentUser, offerId, "modifier");

        String currentStatus = normalizeStatus(offre.getStatut());
        applyRequest(offre, request);
        String requestedStatus = normalizeStatus(request.getStatut());
        if ("PUBLIEE".equals(requestedStatus)) {
            assertOfferCanBePublished(currentUser, offre);
            offre.setStatut("PUBLIEE");
        } else if ("PUBLIEE".equals(currentStatus)) {
            offre.setStatut("PUBLIEE");
        }
        return toResponse(offreRepository.save(offre), null);
    }

    public List<MatchingCandidateResponse> getMatchingCandidates(User currentUser, Long offerId, Double minScore) {
        Offre offer = getRecruiterOwnedOffer(currentUser, offerId, "consulter");
        double effectiveMinScore = minScore == null ? 70d : Math.max(0d, Math.min(100d, minScore));

        return candidateRepository.findAll().stream()
                .map(candidate -> toMatchingCandidateResponse(offer, candidate))
                .filter(item -> item.getMatchingScore() != null && item.getMatchingScore() >= effectiveMinScore)
                .sorted((left, right) -> Double.compare(
                        right.getMatchingScore() == null ? 0d : right.getMatchingScore(),
                        left.getMatchingScore() == null ? 0d : left.getMatchingScore()
                ))
                .collect(Collectors.toList());
    }

    @Transactional
    public MessageResponse inviteCandidateToOffer(User currentUser, Long offerId, Long candidateId) {
        Offre offer = getRecruiterOwnedOffer(currentUser, offerId, "inviter des candidats pour");
        Candidate candidate = candidateRepository.findById(candidateId)
                .orElseThrow(() -> new RuntimeException("Candidat introuvable."));

        CandidateInvitation existingInvitation = candidateInvitationRepository
                .findTopByOffer_IdAndCandidate_IdOrderByInvitedAtDesc(offerId, candidateId)
                .orElse(null);
        if (existingInvitation != null && existingInvitation.getStatus() == InvitationStatus.SENT) {
            return new MessageResponse(true, "Invitation déjà envoyée.");
        }

        MatchingService.MatchResult matchResult = matchingService.evaluate(candidate, offer);
        Recruiter recruiter = offer.getRecruiter();
        CandidateInvitation invitation = CandidateInvitation.builder()
                .offer(offer)
                .recruiter(recruiter)
                .candidate(candidate)
                .matchingScore(matchResult.getScore())
                .status(InvitationStatus.SENT)
                .invitedAt(new Date())
                .build();
        candidateInvitationRepository.save(invitation);

        String companyName = resolveCompanyName(recruiter);
        String recruiterName = safe(recruiter == null ? null : recruiter.getNom());
        String subject = "Invitation à postuler — " + safe(offer.getTitre());
        String emailBody = "Bonjour " + nonEmpty(candidate.getNom(), "Candidat") + ",\n\n"
                + "Votre profil correspond fortement à une offre publiée par " + nonEmpty(companyName, "notre entreprise") + ".\n\n"
                + "Poste : " + safe(offer.getTitre()) + "\n"
                + "Score de compatibilité estimé : " + roundScore(matchResult.getScore()) + " %\n\n"
                + "Nous vous invitons à consulter cette offre et à postuler si elle vous intéresse.\n\n"
                + "Cordialement,\n"
                + nonEmpty(recruiterName, "Recruteur") + "\n"
                + nonEmpty(companyName, "Entreprise");

        try {
            emailService.sendCandidateInvitationEmail(candidate.getEmail(), subject, emailBody);
        } catch (RuntimeException ex) {
            throw new RuntimeException(ex.getMessage() == null || ex.getMessage().isBlank()
                    ? "Invitation enregistrée, mais l'envoi d'email a échoué."
                    : ex.getMessage());
        }

        notificationService.notifyUser(
                candidate,
                "Invitation à postuler pour l'offre \"" + safe(offer.getTitre()) + "\" chez " + nonEmpty(companyName, "une entreprise") + "."
        );

        return new MessageResponse(true, "Invitation envoyée avec succès.");
    }

    @Transactional
    public OffreResponse archiveOffer(User currentUser, Long offerId) {
        Offre offre = getRecruiterOwnedOffer(currentUser, offerId, "archiver");
        String currentStatus = normalizeStatus(offre.getStatut());
        if ("ARCHIVEE".equals(currentStatus)) {
            return toResponse(offre, null);
        }

        offre.setStatut("ARCHIVEE");
        return toResponse(offreRepository.save(offre), null);
    }

    @Transactional
    public OffreResponse unarchiveOffer(User currentUser, Long offerId) {
        Offre offre = getRecruiterOwnedOffer(currentUser, offerId, "desarchiver");
        String currentStatus = normalizeStatus(offre.getStatut());
        if ("PUBLIEE".equals(currentStatus)) {
            return toResponse(offre, null);
        }

        assertOfferCanBePublished(currentUser, offre);
        offre.setStatut("PUBLIEE");
        if (offre.getDate() == null) {
            offre.setDate(java.sql.Date.valueOf(LocalDate.now()));
        }
        return toResponse(offreRepository.save(offre), null);
    }

    @Transactional
    public OffreResponse publishOffer(User currentUser, Long offerId) {
        Offre offre = getRecruiterOwnedOffer(currentUser, offerId, "publier");
        String currentStatus = normalizeStatus(offre.getStatut());
        if ("PUBLIEE".equals(currentStatus)) {
            return toResponse(offre, null);
        }

        assertOfferCanBePublished(currentUser, offre);
        offre.setStatut("PUBLIEE");
        if (offre.getDate() == null) {
            offre.setDate(java.sql.Date.valueOf(LocalDate.now()));
        }
        return toResponse(offreRepository.save(offre), null);
    }

    @Transactional
    public String deleteOffer(User currentUser, Long offerId) {
        Offre offre = getRecruiterOwnedOffer(currentUser, offerId, "supprimer");
        Long targetOfferId = offre.getId();

        deleteAiTestsForOffer(targetOfferId);
        interviewRepository.deleteByOfferId(targetOfferId);

        List<Long> candidatureIds = candidatureRepository.findIdsByOfferId(targetOfferId);
        if (!candidatureIds.isEmpty()) {
            conversationMessageRepository.deleteAllByCandidatureIds(candidatureIds);
            candidatureRepository.deleteAllForOffer(targetOfferId);
        }

        offreRepository.delete(offre);
        return "L'offre a ete supprimee avec succes.";
    }

    private void deleteAiTestsByIds(List<Long> aiTestIds) {
        if (aiTestIds == null || aiTestIds.isEmpty()) {
            return;
        }

        aiAnswerRepository.deleteByAiTestIds(aiTestIds);
        aiQuestionRepository.deleteByAiTestIds(aiTestIds);
        aiTestResultRepository.deleteByAiTestIds(aiTestIds);
        aiTestRepository.deleteByIds(aiTestIds);
        aiTestRepository.flush();
    }

    private void deleteAiTestsForOffer(Long offerId) {
        if (offerId == null) {
            return;
        }

        List<Long> aiTestIds = aiTestRepository.findIdsByOfferId(offerId);
        if (aiTestIds != null && !aiTestIds.isEmpty()) {
            aiAnswerRepository.deleteByAiTestIds(aiTestIds);
            aiQuestionRepository.deleteByAiTestIds(aiTestIds);
            aiTestResultRepository.deleteByAiTestIds(aiTestIds);
        }
        aiTestRepository.deleteByOfferId(offerId);
        aiTestRepository.flush();
    }

    private void applyRequest(Offre offre, OffreRequest request) {
        offre.setTitre(requireValue(request.getTitre(), "Le titre de l'offre est obligatoire."));
        offre.setCategorie(requireValue(request.getCategorie(), "La categorie de l'offre est obligatoire."));
        offre.setDescription(requireValue(request.getDescription(), "La description de l'offre est obligatoire."));
        offre.setLocalisation(requireValue(request.getLocalisation(), "La localisation est obligatoire."));
        offre.setTypeContrat(requireValue(request.getTypeContrat(), "Le type de contrat est obligatoire."));
        offre.setSalaire(request.getSalaire() == null ? 0d : request.getSalaire());
        offre.setDevise(defaultValue(request.getDevise(), "TND"));
        offre.setNombrePostes(request.getNombrePostes() == null ? 1 : request.getNombrePostes());
        offre.setExperienceRequise(defaultValue(request.getExperienceRequise(), "Non precisee"));
        offre.setStatut(normalizeStatus(defaultValue(request.getStatut(), "EN_ATTENTE_TEST_IA")));
        offre.setDateExpiration(parseDate(request.getDateExpiration()));
        offre.setCompetencesJson(writeCompetencesJson(request.getCompetences()));
    }

    private OffreResponse toResponse(Offre offre, Candidate candidate) {
        OffreResponse response = new OffreResponse();
        response.setId(offre.getId());
        response.setTitre(offre.getTitre());
        response.setCategorie(offre.getCategorie());
        response.setDescription(offre.getDescription());
        response.setLocalisation(offre.getLocalisation());
        response.setSalaire(offre.getSalaire());
        response.setDevise(offre.getDevise());
        response.setNombrePostes(offre.getNombrePostes());
        response.setExperienceRequise(offre.getExperienceRequise());
        response.setTypeContrat(offre.getTypeContrat());
        response.setStatut(offre.getStatut());
        response.setDatePublication(formatDate(offre.getDate()));
        response.setDateExpiration(formatDate(offre.getDateExpiration()));
        response.setCompetences(readCompetencesJson(offre.getCompetencesJson()));
        response.setCandidaturesCount(candidatureRepository.countByOffre_Id(offre.getId()));

        if (offre.getRecruiter() != null) {
            response.setRecruiterId(offre.getRecruiter().getId());
            if (offre.getRecruiter().getEntreprise() != null) {
                response.setNomEntreprise(offre.getRecruiter().getEntreprise().getNomEntreprise());
            } else {
                response.setNomEntreprise(offre.getRecruiter().getNom());
            }
        }

        if (candidate != null) {
            response.setCompatibilityScore(matchingService.evaluate(candidate, offre).getScore());
            Candidature application = candidatureRepository.findByCandidate_IdAndOffre_Id(candidate.getId(), offre.getId()).orElse(null);
            response.setAlreadyApplied(application != null);
            response.setApplicationId(application == null ? null : application.getId());
            response.setApplicationStatus(application == null ? null : AiTestService.normalizeApplicationStatus(application.getStatut()));
            applyAiTestState(response, offre, application);
        } else {
            response.setCompatibilityScore(null);
            response.setAlreadyApplied(Boolean.FALSE);
            response.setApplicationId(null);
            response.setApplicationStatus(null);
            AiTest offerTemplate = aiTestRepository.findTopByJobOffer_IdAndApplicationIsNullOrderByCreatedAtDesc(offre.getId()).orElse(null);
            String templateStatus = offerTemplate == null ? null : AiTestService.normalizeAiTestStatus(offerTemplate.getStatus());
            boolean hasValidatedTemplate = "VALIDATED".equals(templateStatus) || "PUBLISHED".equals(templateStatus);
            response.setHasAiTest(hasValidatedTemplate);
            response.setAiTestAvailable(Boolean.FALSE);
            response.setAiTestId(offerTemplate == null ? null : offerTemplate.getId());
            response.setAiTestStatus(templateStatus);
            response.setAiTestResultStatus(null);
            response.setCanPassAiTest(Boolean.FALSE);
        }

        return response;
    }

    private void applyAiTestState(OffreResponse response, Offre offre, Candidature application) {
        AiTest applicationAiTest = application == null
                ? null
                : aiTestRepository.findTopByApplication_IdOrderByCreatedAtDesc(application.getId()).orElse(null);

        AiTest offerTemplate = aiTestRepository.findTopByJobOffer_IdAndApplicationIsNullOrderByCreatedAtDesc(offre.getId()).orElse(null);
        String templateStatus = offerTemplate == null ? null : AiTestService.normalizeAiTestStatus(offerTemplate.getStatus());
        boolean hasValidatedTemplate = "VALIDATED".equals(templateStatus) || "PUBLISHED".equals(templateStatus);

        AiTest effectiveTest = applicationAiTest != null ? applicationAiTest : offerTemplate;
        AiTestResult result = applicationAiTest == null ? null : aiTestResultRepository.findByAiTest_Id(applicationAiTest.getId()).orElse(null);
        String aiTestStatus = effectiveTest == null ? null : AiTestService.normalizeAiTestStatus(effectiveTest.getStatus());
        String aiTestResultStatus = result == null ? null : AiTestService.normalizeAiTestStatus(result.getStatus());
        boolean aiTestAvailable = Boolean.TRUE.equals(response.getAlreadyApplied())
                && (hasValidatedTemplate || applicationAiTest != null);
        boolean canPassAiTest = Boolean.TRUE.equals(response.getAlreadyApplied())
                && hasValidatedTemplate
                && effectiveTest != null
                && !"SUBMITTED".equals(aiTestResultStatus)
                && !"EXPIRED".equals(aiTestResultStatus)
                && !"CHEATING_SUSPECTED".equals(aiTestResultStatus)
                && !"CLOSED".equals(aiTestResultStatus);

        response.setHasAiTest(hasValidatedTemplate || applicationAiTest != null);
        response.setAiTestAvailable(aiTestAvailable);
        response.setAiTestId(effectiveTest == null ? null : effectiveTest.getId());
        response.setAiTestStatus(aiTestStatus);
        response.setAiTestResultStatus(aiTestResultStatus);
        response.setCanPassAiTest(canPassAiTest);
    }

    private MatchingCandidateResponse toMatchingCandidateResponse(Offre offer, Candidate candidate) {
        MatchingService.MatchResult matchResult = matchingService.evaluate(candidate, offer);
        boolean hasApplied = candidate != null
                && candidate.getId() != null
                && candidatureRepository.findByCandidate_IdAndOffre_Id(candidate.getId(), offer.getId()).isPresent();
        boolean alreadyInvited = candidate != null
                && candidate.getId() != null
                && candidateInvitationRepository.findTopByOffer_IdAndCandidate_IdOrderByInvitedAtDesc(offer.getId(), candidate.getId())
                        .map(invitation -> invitation.getStatus() == InvitationStatus.SENT)
                        .orElse(false);

        MatchingCandidateResponse response = new MatchingCandidateResponse();
        response.setCandidateId(candidate.getId());
        response.setFullName(safe(candidate.getNom()));
        response.setEmail(safe(candidate.getEmail()));
        response.setProfileTitle(nonEmpty(candidate.getPosteRecherche(), nonEmpty(candidate.getProfession(), "Profil candidat")));
        response.setLocation(safe(candidate.getLocalisation()));
        response.setExperience(candidate.getExperience());
        response.setMatchingScore(matchResult.getScore());
        response.setCompatibleSkills(matchResult.getMatchingSkills());
        response.setMissingSkills(matchResult.getMissingSkills());
        response.setHasApplied(hasApplied);
        response.setAlreadyInvited(alreadyInvited);
        return response;
    }

    private CandidateTopMatchingOfferResponse toCandidateTopMatchingOfferResponse(Offre offer, Candidate candidate) {
        MatchingService.MatchResult matchResult = matchingService.evaluate(candidate, offer);

        CandidateTopMatchingOfferResponse response = new CandidateTopMatchingOfferResponse();
        response.setOfferId(offer.getId());
        response.setTitle(safe(offer.getTitre()));
        response.setCompanyName(resolveCompanyName(offer.getRecruiter()));
        response.setLocation(safe(offer.getLocalisation()));
        response.setContractType(safe(offer.getTypeContrat()));
        response.setMatchingScore(matchResult.getScore());
        response.setMatchingSkills(matchResult.getMatchingSkills());
        response.setMissingSkills(matchResult.getMissingSkills());
        return response;
    }

    private Recruiter getCurrentRecruiter(User currentUser) {
        Recruiter recruiter = currentUser != null && currentUser.getId() != null
                ? recruiterRepository.findById(currentUser.getId()).orElse(null)
                : null;

        if (recruiter == null && currentUser != null) {
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

    private Offre getRecruiterOwnedOffer(User currentUser, Long offerId, String actionLabel) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        Offre offre = offreRepository.findById(offerId)
                .orElseThrow(() -> new RuntimeException("Offre introuvable."));

        if (offre.getRecruiter() == null || !offre.getRecruiter().getId().equals(recruiter.getId())) {
            throw new RuntimeException("Vous ne pouvez " + actionLabel + " que vos propres offres.");
        }

        return offre;
    }

    private Candidate resolveCandidate(User currentUser) {
        if (currentUser == null || currentUser.getRole() == null || !"CANDIDATE".equals(currentUser.getRole().name())) {
            return null;
        }

        if (currentUser.getId() != null) {
            Candidate candidate = candidateRepository.findById(currentUser.getId()).orElse(null);
            if (candidate != null) {
                return candidate;
            }
        }

        return candidateRepository.findByEmail(currentUser.getEmail());
    }

    private boolean isOfferActive(Offre offre) {
        String status = normalizeStatus(offre.getStatut());
        if (!"PUBLIEE".equals(status)) {
            return false;
        }

        if (offre.getDateExpiration() == null) {
            return true;
        }

        LocalDate expiration = toLocalDate(offre.getDateExpiration());

        return !expiration.isBefore(LocalDate.now());
    }

    private void assertOfferCanBePublished(User currentUser, Offre offre) {
        if (!hasValidatedAiTestForOffer(offre == null ? null : offre.getId())) {
            throw new RuntimeException("Test IA requis avant publication. Vous devez préparer et valider le Test IA avant de publier cette offre.");
        }
    }

    private boolean hasValidatedAiTestForOffer(Long offerId) {
        if (offerId == null) {
            return false;
        }

        return aiTestRepository.findTopByJobOffer_IdAndApplicationIsNullOrderByCreatedAtDesc(offerId)
                .map(test -> AiTestService.normalizeAiTestStatus(test.getStatus()))
                .map(status -> "VALIDATED".equals(status) || "PUBLISHED".equals(status))
                .orElse(false);
    }

    private String writeCompetencesJson(List<OffreCompetenceRequest> competences) {
        List<OffreCompetenceRequest> safeList = synchronizeOfferCompetences(competences);

        try {
            return objectMapper.writeValueAsString(safeList);
        } catch (JsonProcessingException ex) {
            throw new RuntimeException("Impossible d'enregistrer les competences de l'offre.");
        }
    }

    private List<OffreCompetenceRequest> synchronizeOfferCompetences(List<OffreCompetenceRequest> competences) {
        if (competences == null || competences.isEmpty()) {
            return new ArrayList<>();
        }

        Map<String, OffreCompetenceRequest> uniqueCompetences = new LinkedHashMap<>();

        for (OffreCompetenceRequest competenceRequest : competences) {
            OffreCompetenceRequest normalized = normalizeOfferCompetence(competenceRequest);
            if (normalized == null || normalize(normalized.getNom()).isEmpty()) {
                continue;
            }

            Competence competence = resolveCompetence(normalized);
            if (competence != null) {
                normalized.setCompetenceId(competence.getId());
                normalized.setNom(competence.getNom());
            }

            String uniqueKey = competence != null
                    ? "id:" + competence.getId()
                    : "nom:" + normalizeToken(normalized.getNom());

            if (uniqueKey.endsWith(":")) {
                continue;
            }

            if (uniqueCompetences.containsKey(uniqueKey)) {
                mergeCompetence(uniqueCompetences.get(uniqueKey), normalized);
                continue;
            }

            uniqueCompetences.put(uniqueKey, normalized);
        }

        return new ArrayList<>(uniqueCompetences.values());
    }

    private OffreCompetenceRequest normalizeOfferCompetence(OffreCompetenceRequest source) {
        if (source == null) {
            return null;
        }

        OffreCompetenceRequest normalized = new OffreCompetenceRequest();
        normalized.setCompetenceId(source.getCompetenceId());
        normalized.setNom(normalize(source.getNom()));
        normalized.setType(defaultValue(source.getType(), "OBLIGATOIRE"));
        normalized.setNiveau(defaultValue(source.getNiveau(), "Intermediaire"));
        normalized.setPonderation(normalizeWeight(source.getPonderation()));
        return normalized;
    }

    private Competence resolveCompetence(OffreCompetenceRequest request) {
        if (request.getCompetenceId() != null) {
            Optional<Competence> competenceById = competenceService.findById(request.getCompetenceId());
            if (competenceById.isPresent()) {
                return competenceById.get();
            }
        }

        if (!normalize(request.getNom()).isEmpty()) {
            Optional<Competence> competenceByName = competenceService.findByNormalizedName(request.getNom());
            if (competenceByName.isPresent()) {
                return competenceByName.get();
            }

            return competenceService.resolveOrCreateCompetence(request.getNom());
        }

        return null;
    }

    private void mergeCompetence(OffreCompetenceRequest target, OffreCompetenceRequest source) {
        if (target.getCompetenceId() == null && source.getCompetenceId() != null) {
            target.setCompetenceId(source.getCompetenceId());
        }

        if (normalize(target.getNom()).isEmpty()) {
            target.setNom(source.getNom());
        }

        target.setPonderation(Math.max(normalizeWeight(target.getPonderation()), normalizeWeight(source.getPonderation())));
        target.setType(defaultValue(target.getType(), source.getType()));
        target.setNiveau(preferHigherLevel(target.getNiveau(), source.getNiveau()));
    }

    private int normalizeWeight(Integer value) {
        if (value == null) {
            return 50;
        }

        return Math.max(0, Math.min(100, value));
    }

    private String preferHigherLevel(String first, String second) {
        return skillLevelRank(second) > skillLevelRank(first) ? defaultValue(second, "Intermediaire") : defaultValue(first, "Intermediaire");
    }

    private int skillLevelRank(String value) {
        return switch (defaultValue(value, "Intermediaire").toLowerCase(Locale.ROOT)) {
            case "expert" -> 4;
            case "avance" -> 3;
            case "intermediaire" -> 2;
            default -> 1;
        };
    }

    private List<OffreCompetenceResponse> readCompetencesJson(String value) {
        if (value == null || value.isBlank()) {
            return new ArrayList<>();
        }

        try {
            List<OffreCompetenceRequest> items = objectMapper.readValue(value, new TypeReference<List<OffreCompetenceRequest>>() {
            });

            return items.stream().map(item -> {
                OffreCompetenceResponse response = new OffreCompetenceResponse();
                response.setCompetenceId(item.getCompetenceId());
                response.setNom(item.getNom());
                response.setType(item.getType());
                response.setPonderation(item.getPonderation());
                response.setNiveau(item.getNiveau());
                return response;
            }).collect(Collectors.toList());
        } catch (JsonProcessingException ex) {
            return new ArrayList<>();
        }
    }

    private Date parseDate(String value) {
        String normalized = normalize(value);
        if (normalized.isEmpty()) {
            return null;
        }

        try {
            LocalDate localDate = LocalDate.parse(normalized);
            return java.sql.Date.valueOf(localDate);
        } catch (DateTimeParseException ex) {
            throw new RuntimeException("La date d'expiration est invalide.");
        }
    }

    private String formatDate(Date value) {
        if (value == null) {
            return "";
        }

        return toLocalDate(value).toString();
    }

    private String resolveCompanyName(Recruiter recruiter) {
        if (recruiter == null) {
            return "";
        }

        if (recruiter.getEntreprise() != null && !safe(recruiter.getEntreprise().getNomEntreprise()).isBlank()) {
            return safe(recruiter.getEntreprise().getNomEntreprise());
        }

        return safe(recruiter.getNom());
    }

    private LocalDate toLocalDate(Date value) {
        if (value instanceof java.sql.Date sqlDate) {
            return sqlDate.toLocalDate();
        }

        return value.toInstant()
                .atZone(ZoneId.systemDefault())
                .toLocalDate();
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim();
    }

    private String safe(String value) {
        return value == null ? "" : value.trim();
    }

    private String nonEmpty(String primary, String fallback) {
        String normalized = safe(primary);
        return normalized.isEmpty() ? safe(fallback) : normalized;
    }

    private double roundScore(double value) {
        return Math.round(value * 10d) / 10d;
    }

    private String requireValue(String value, String message) {
        String normalized = normalize(value);
        if (normalized.isEmpty()) {
            throw new RuntimeException(message);
        }
        return normalized;
    }

    private String defaultValue(String value, String fallback) {
        String normalized = normalize(value);
        return normalized.isEmpty() ? fallback : normalized;
    }

    private String normalizeToken(String value) {
        String ascii = Normalizer.normalize(normalize(value), Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "");
        return ascii.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]+", "");
    }

    private String normalizeStatus(String value) {
        String normalized = normalize(value).toUpperCase(Locale.ROOT);
        return switch (normalized) {
            case "PUBLISHED" -> "PUBLIEE";
            case "PUBLIÉE" -> "PUBLIEE";
            case "DRAFT" -> "BROUILLON";
            case "PENDING_AI_TEST", "EN ATTENTE TEST IA", "EN_ATTENTE_TEST" -> "EN_ATTENTE_TEST_IA";
            case "ARCHIVED" -> "ARCHIVEE";
            default -> normalized;
        };
    }

    private Recruiter createMissingRecruiterProfile(User authenticatedUser) {
        if (authenticatedUser == null) {
            return null;
        }

        if (authenticatedUser.getRole() != Role.RECRUITER) {
            throw new RuntimeException("Seuls les comptes recruteurs peuvent publier une offre.");
        }

        Recruiter recruiter = new Recruiter();
        recruiter.setId(authenticatedUser.getId());
        recruiter.setEmail(authenticatedUser.getEmail());
        recruiter.setNom(authenticatedUser.getNom());
        recruiter.setPassword(authenticatedUser.getPassword());
        recruiter.setRole(authenticatedUser.getRole());
        recruiter.setStatutCompte(authenticatedUser.getStatutCompte());
        recruiter.setApprovalStatus(authenticatedUser.getApprovalStatus());
        recruiter.setEmailVerified(authenticatedUser.getEmailverified());
        recruiter.setActivationToken(authenticatedUser.getActivationToken());
        recruiter.setResetPasswordToken(authenticatedUser.getResetPasswordToken());
        recruiter.setResetPasswordTokenExpiresAt(authenticatedUser.getResetPasswordTokenExpiresAt());
        recruiter.setFonction("");
        recruiter.setPoste("");
        recruiter.setDepartement("");
        return recruiterRepository.save(recruiter);
    }
}
