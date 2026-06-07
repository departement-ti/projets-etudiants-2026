package com.recrutement.recrutement.service;

import com.recrutement.recrutement.dto.ApplicationResponse;
import com.recrutement.recrutement.entities.AiTest;
import com.recrutement.recrutement.entities.Candidate;
import com.recrutement.recrutement.entities.Candidature;
import com.recrutement.recrutement.entities.CV;
import com.recrutement.recrutement.entities.Entreprise;
import com.recrutement.recrutement.entities.Interview;
import com.recrutement.recrutement.entities.Offre;
import com.recrutement.recrutement.entities.Recruiter;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.repositories.CVRepository;
import com.recrutement.recrutement.repositories.AiTestRepository;
import com.recrutement.recrutement.repositories.CandidateRepository;
import com.recrutement.recrutement.repositories.CandidatureRepository;
import com.recrutement.recrutement.repositories.InterviewRepository;
import com.recrutement.recrutement.repositories.OffreRepository;
import com.recrutement.recrutement.repositories.RecruiterRepository;
import jakarta.transaction.Transactional;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Base64;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;

@Service
public class ApplicationService {
    private static final String STATUS_APPLIED = "APPLIED";
    private static final String STATUS_AI_TEST_SENT = "AI_TEST_SENT";
    private static final String STATUS_AI_TEST_COMPLETED = "AI_TEST_COMPLETED";
    private static final String STATUS_INTERVIEW = "INTERVIEW";
    private static final String STATUS_REJECTION_SUGGESTED = "REJECTION_SUGGESTED";
    private static final String STATUS_REJECTED = "REJECTED";
    private static final String STATUS_RETAINED = "RETENU";

    private final CandidateRepository candidateRepository;
    private final RecruiterRepository recruiterRepository;
    private final OffreRepository offreRepository;
    private final CandidatureRepository candidatureRepository;
    private final CVRepository cvRepository;
    private final AiTestRepository aiTestRepository;
    private final InterviewRepository interviewRepository;
    private final MatchingService matchingService;
    private final NotificationService notificationService;
    private final AiTestService aiTestService;

    public ApplicationService(
            CandidateRepository candidateRepository,
            RecruiterRepository recruiterRepository,
            OffreRepository offreRepository,
            CandidatureRepository candidatureRepository,
            CVRepository cvRepository,
            AiTestRepository aiTestRepository,
            InterviewRepository interviewRepository,
            MatchingService matchingService,
            NotificationService notificationService,
            AiTestService aiTestService
    ) {
        this.candidateRepository = candidateRepository;
        this.recruiterRepository = recruiterRepository;
        this.offreRepository = offreRepository;
        this.candidatureRepository = candidatureRepository;
        this.cvRepository = cvRepository;
        this.aiTestRepository = aiTestRepository;
        this.interviewRepository = interviewRepository;
        this.matchingService = matchingService;
        this.notificationService = notificationService;
        this.aiTestService = aiTestService;
    }

    @Transactional
    public ApplicationResponse applyToOffer(User currentUser, Long offerId) {
        Candidate candidate = getCurrentCandidate(currentUser);
        Offre offer = getActiveOffer(offerId);

        candidatureRepository.findByCandidate_IdAndOffre_Id(candidate.getId(), offerId)
                .ifPresent(existing -> {
                    throw new RuntimeException("Vous avez deja postule a cette offre.");
                });

        MatchingService.MatchResult matchResult = matchingService.evaluate(candidate, offer);

        Candidature candidature = Candidature.builder()
                .candidate(candidate)
                .offre(offer)
                .dateDepot(new Date())
                .statut(STATUS_APPLIED)
                .scoreCandidat(matchResult.getScore())
                .build();

        Candidature savedCandidature = candidatureRepository.save(candidature);
        notifyRecruiterForNewApplication(savedCandidature);
        return toResponse(savedCandidature, matchResult);
    }

    public List<ApplicationResponse> getCandidateApplications(User currentUser) {
        Candidate candidate = getCurrentCandidate(currentUser);
        return candidatureRepository.findByCandidate_IdOrderByDateDepotDesc(candidate.getId()).stream()
                .map(candidature -> toResponse(candidature, null))
                .collect(Collectors.toList());
    }

    public List<ApplicationResponse> getRecruiterApplications(User currentUser, Long offerId, Double minScore) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        List<Candidature> candidatures = offerId == null
                ? candidatureRepository.findByOffre_Recruiter_IdOrderByScoreCandidatDescDateDepotDesc(recruiter.getId())
                : candidatureRepository.findByOffre_Recruiter_IdAndOffre_IdOrderByScoreCandidatDescDateDepotDesc(recruiter.getId(), offerId);

        double effectiveMinScore = minScore == null ? 0d : minScore;

        return candidatures.stream()
                .filter(candidature -> candidature.getScoreCandidat() >= effectiveMinScore)
                .map(candidature -> toResponse(candidature, null))
                .collect(Collectors.toList());
    }

    public ApplicationResponse getRecruiterApplicationById(User currentUser, Long applicationId) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        Candidature candidature = candidatureRepository.findByIdAndOffre_Recruiter_Id(applicationId, recruiter.getId())
                .orElseThrow(() -> new RuntimeException("Candidature introuvable."));
        return toResponse(candidature, null);
    }

    public CvDownloadPayload getRecruiterCandidateCv(User currentUser, Long applicationId) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        Candidature candidature = candidatureRepository.findByIdAndOffre_Recruiter_Id(applicationId, recruiter.getId())
                .orElseThrow(() -> new RuntimeException("Candidature introuvable."));

        Candidate candidate = candidature.getCandidate();
        if (candidate == null) {
            throw new RuntimeException("Profil candidat introuvable.");
        }

        CV cv = cvRepository.findTopByCandidateOrderByDateImportDesc(candidate)
                .orElseThrow(() -> new RuntimeException("Aucun CV n'est disponible pour ce candidat."));

        String fileName = nonEmpty(cv.getNomFichier(), "cv-candidat");
        return new CvDownloadPayload(fileName, detectContentType(fileName), readCvBytes(candidate, cv));
    }

    public CvDownloadPayload getRecruiterCandidateCvByCandidateId(User currentUser, Long candidateId) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        if (recruiter == null) {
            throw new RuntimeException("Profil recruteur introuvable.");
        }

        Candidate candidate = candidateRepository.findById(candidateId)
                .orElseThrow(() -> new RuntimeException("Profil candidat introuvable."));

        CV cv = cvRepository.findTopByCandidateOrderByDateImportDesc(candidate)
                .orElseThrow(() -> new RuntimeException("Aucun CV n'est disponible pour ce candidat."));

        String fileName = nonEmpty(cv.getNomFichier(), "cv-candidat");
        return new CvDownloadPayload(fileName, detectContentType(fileName), readCvBytes(candidate, cv));
    }

    @Transactional
    public ApplicationResponse updateRecruiterApplicationStatus(User currentUser, Long applicationId, String status) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        Candidature candidature = candidatureRepository.findByIdAndOffre_Recruiter_Id(applicationId, recruiter.getId())
                .orElseThrow(() -> new RuntimeException("Candidature introuvable."));

        candidature.setStatut(normalizeStatus(status));
        Candidature savedCandidature = candidatureRepository.save(candidature);
        notifyCandidateForStatusChange(savedCandidature);
        return toResponse(savedCandidature, null);
    }

    public boolean hasApplied(Long offerId, Long candidateId) {
        if (offerId == null || candidateId == null) {
            return false;
        }
        return candidatureRepository.findByCandidate_IdAndOffre_Id(candidateId, offerId).isPresent();
    }

    public String getApplicationStatus(Long offerId, Long candidateId) {
        if (offerId == null || candidateId == null) {
            return null;
        }
        return candidatureRepository.findByCandidate_IdAndOffre_Id(candidateId, offerId)
                .map(Candidature::getStatut)
                .orElse(null);
    }

    private ApplicationResponse toResponse(Candidature candidature, MatchingService.MatchResult matchResult) {
        Candidate candidate = candidature.getCandidate();
        Offre offer = candidature.getOffre();
        MatchingService.MatchResult effectiveMatch = matchResult != null ? matchResult : matchingService.evaluate(candidate, offer);

        ApplicationResponse response = new ApplicationResponse();
        response.setId(candidature.getId());
        response.setOfferId(offer == null ? null : offer.getId());
        response.setOfferTitle(offer == null ? "" : safe(offer.getTitre()));
        response.setCompanyName(resolveCompanyName(offer == null ? null : offer.getRecruiter()));
        response.setOfferLocation(offer == null ? "" : safe(offer.getLocalisation()));
        response.setContractType(offer == null ? "" : safe(offer.getTypeContrat()));
        response.setAppliedAt(formatDate(candidature.getDateDepot()));
        response.setStatus(normalizeStatus(candidature.getStatut()));
        response.setScore(roundScore(candidature.getScoreCandidat()));
        response.setCandidateId(candidate == null ? null : candidate.getId());
        response.setCandidateName(candidate == null ? "" : safe(candidate.getNom()));
        response.setCandidateEmail(candidate == null ? "" : safe(candidate.getEmail()));
        response.setCandidateJobTitle(candidate == null ? "" : safe(nonEmpty(candidate.getPosteRecherche(), candidate.getProfession())));
        response.setCandidateLocation(candidate == null ? "" : safe(candidate.getLocalisation()));
        response.setCandidateExperience(candidate == null ? 0 : candidate.getExperience());
        response.setCandidateSummary(candidate == null ? "" : safe(candidate.getDescription()));
        response.setCandidateProfilePhotoUrl(candidate == null ? "" : resolveCandidateImageUrl(
                candidate.getPhotoProfilUrl(),
                candidate.getId(),
                candidate.getPhotoProfilNom()
        ));
        response.setCandidateCoverPhotoUrl(candidate == null ? "" : resolveCandidateImageUrl(
                candidate.getPhotoCouvertureUrl(),
                candidate.getId(),
                candidate.getPhotoCouvertureNom()
        ));
        response.setCandidateLinkedinUrl(candidate == null ? "" : safe(candidate.getLinkedinUrl()));
        response.setCandidateGithubUrl(candidate == null ? "" : safe(candidate.getGithubUrl()));
        response.setCandidateFacebookUrl(candidate == null ? "" : safe(candidate.getFacebookUrl()));
        response.setCandidateInstagramUrl(candidate == null ? "" : safe(candidate.getInstagramUrl()));
        if (candidate != null) {
            cvRepository.findTopByCandidateOrderByDateImportDesc(candidate)
                    .ifPresent(cv -> {
                        response.setCandidateCvFileName(safe(cv.getNomFichier()));
                        response.setCandidateCvFileUrl("/api/recruiter/candidatures/" + candidature.getId() + "/cv");
                    });
        }
        applyAiTestAvailability(response, candidature);
        interviewRepository.findTopByCandidature_IdOrderByCreatedAtDesc(candidature.getId()).ifPresent(interview -> applyInterviewSummary(response, interview));
        response.setMatchingSkills(effectiveMatch.getMatchingSkills());
        response.setMissingSkills(effectiveMatch.getMissingSkills());
        response.setSkills(effectiveMatch.getSkills());
        return response;
    }

    private Candidate getCurrentCandidate(User currentUser) {
        Candidate candidate = currentUser.getId() == null
                ? null
                : candidateRepository.findById(currentUser.getId()).orElse(null);

        if (candidate == null) {
            candidate = candidateRepository.findByEmail(currentUser.getEmail());
        }

        if (candidate == null) {
            throw new RuntimeException("Profil candidat introuvable.");
        }
        return candidate;
    }

    private Recruiter getCurrentRecruiter(User currentUser) {
        Recruiter recruiter = recruiterRepository.findByEmail(currentUser.getEmail());
        if (recruiter == null) {
            throw new RuntimeException("Profil recruteur introuvable.");
        }
        return recruiter;
    }

    private Offre getActiveOffer(Long offerId) {
        Offre offer = offreRepository.findById(offerId)
                .orElseThrow(() -> new RuntimeException("Offre introuvable."));

        if (!isOfferActive(offer)) {
            throw new RuntimeException("Cette offre n'est plus active.");
        }

        return offer;
    }

    private boolean isOfferActive(Offre offer) {
        String status = safe(offer.getStatut()).toUpperCase(Locale.ROOT);
        if ("BROUILLON".equals(status) || "ARCHIVEE".equals(status) || "FERMEE".equals(status)) {
            return false;
        }

        Date expirationDate = offer.getDateExpiration();
        if (expirationDate == null) {
            return true;
        }

        LocalDate expiry = toLocalDate(expirationDate);
        return !expiry.isBefore(LocalDate.now());
    }

    private String normalizeStatus(String status) {
        return AiTestService.normalizeApplicationStatus(status);
    }

    private String resolveCompanyName(Recruiter recruiter) {
        if (recruiter == null) {
            return "";
        }

        Entreprise entreprise = recruiter.getEntreprise();
        if (entreprise != null && entreprise.getNomEntreprise() != null && !entreprise.getNomEntreprise().isBlank()) {
            return entreprise.getNomEntreprise();
        }

        return safe(recruiter.getNom());
    }

    private void notifyRecruiterForNewApplication(Candidature candidature) {
        if (candidature == null || candidature.getOffre() == null || candidature.getOffre().getRecruiter() == null) {
            return;
        }

        Recruiter recruiter = candidature.getOffre().getRecruiter();
        Candidate candidate = candidature.getCandidate();
        String offerTitle = safe(candidature.getOffre().getTitre());
        String candidateName = candidate == null ? "Un candidat" : nonEmpty(candidate.getNom(), "Un candidat");

        notificationService.notifyUser(
                recruiter,
                candidateName + " a postule a votre offre \"" + offerTitle + "\"."
        );
    }

    private void notifyCandidateForStatusChange(Candidature candidature) {
        if (candidature == null || candidature.getCandidate() == null || candidature.getOffre() == null) {
            return;
        }

        String normalizedStatus = normalizeStatus(candidature.getStatut());
        if (!STATUS_INTERVIEW.equals(normalizedStatus)
                && !STATUS_REJECTED.equals(normalizedStatus)
                && !STATUS_RETAINED.equals(normalizedStatus)) {
            return;
        }

        Candidate candidate = candidature.getCandidate();
        String offerTitle = safe(candidature.getOffre().getTitre());
        String companyName = resolveCompanyName(candidature.getOffre().getRecruiter());
        String message;

        if (STATUS_INTERVIEW.equals(normalizedStatus)) {
            message = "Votre candidature pour \"" + offerTitle + "\" chez " + companyName + " est passee au statut Entretien.";
        } else if (STATUS_REJECTED.equals(normalizedStatus)) {
            message = "Votre candidature pour \"" + offerTitle + "\" chez " + companyName + " a ete refusee.";
        } else {
            message = "Bonne nouvelle. Votre candidature pour \"" + offerTitle + "\" chez " + companyName + " a ete retenue.";
        }

        notificationService.notifyUser(candidate, message);
    }

    private void applyAiTestSummary(ApplicationResponse response, AiTest aiTest) {
        response.setAiTestId(aiTest.getId());
        response.setAiTestStatus(AiTestService.normalizeAiTestStatus(aiTest.getStatus()));
        response.setAiTestThreshold(aiTest.getThreshold());
        response.setAiTestScore(aiTest.getScore());
        response.setAiTestRecommendation(normalizeStatus(aiTest.getRecommendation()));
        response.setAiTestDurationMinutes(aiTest.getDurationMinutes());
        response.setAiTestStartedAt(formatDateTime(aiTest.getStartedAt()));
        response.setAiTestExpiresAt(formatDateTime(aiTest.getExpiresAt()));
        response.setAiTestSubmittedAt(formatDateTime(aiTest.getSubmittedAt()));
        response.setAiTestCompletedAt(formatDateTime(aiTest.getCompletedAt()));
        response.setAiTestClosedReason(safe(aiTest.getClosedReason()));
        response.setAiTestCheatingSuspicion(Boolean.TRUE.equals(aiTest.getCheatingSuspicion()));
        response.setAiTestTabSwitchCount(aiTest.getTabSwitchCount() == null ? 0 : aiTest.getTabSwitchCount());
        response.setAiTestWarningCount(aiTest.getWarningCount() == null ? 0 : aiTest.getWarningCount());
    }

    private void applyAiTestAvailability(ApplicationResponse response, Candidature candidature) {
        AiTest applicationAiTest = aiTestRepository.findTopByApplication_IdOrderByCreatedAtDesc(candidature.getId()).orElse(null);
        AiTest offerTemplate = candidature.getOffre() == null
                ? null
                : aiTestRepository.findTopByJobOffer_IdAndApplicationIsNullOrderByCreatedAtDesc(candidature.getOffre().getId()).orElse(null);

        String templateStatus = offerTemplate == null ? null : AiTestService.normalizeAiTestStatus(offerTemplate.getStatus());
        boolean templateAvailable = "VALIDATED".equals(templateStatus) || "PUBLISHED".equals(templateStatus);
        String effectiveStatus = applicationAiTest != null
                ? AiTestService.normalizeAiTestStatus(applicationAiTest.getStatus())
                : templateStatus;
        boolean canPassAiTest = templateAvailable
                && ("".equals(safe(effectiveStatus)) || "NOT_STARTED".equals(effectiveStatus) || "VALIDATED".equals(effectiveStatus) || "PUBLISHED".equals(effectiveStatus));

        response.setHasAiTest(templateAvailable || applicationAiTest != null);
        response.setAiTestAvailable(templateAvailable || applicationAiTest != null);
        response.setCanPassAiTest(canPassAiTest);

        if (applicationAiTest != null) {
            applyAiTestSummary(response, applicationAiTest);
        } else {
            response.setAiTestId(null);
            response.setAiTestStatus(effectiveStatus);
            response.setAiTestThreshold(offerTemplate == null ? null : offerTemplate.getThreshold());
            response.setAiTestScore(null);
            response.setAiTestRecommendation("");
            response.setAiTestDurationMinutes(offerTemplate == null ? null : offerTemplate.getDurationMinutes());
            response.setAiTestStartedAt("");
            response.setAiTestExpiresAt("");
            response.setAiTestSubmittedAt("");
            response.setAiTestCompletedAt("");
            response.setAiTestClosedReason("");
            response.setAiTestCheatingSuspicion(Boolean.FALSE);
            response.setAiTestTabSwitchCount(0);
            response.setAiTestWarningCount(0);
        }
    }

    private void applyInterviewSummary(ApplicationResponse response, Interview interview) {
        response.setInterviewId(interview.getId());
        response.setInterviewStatus(interview.getStatus() == null ? "" : interview.getStatus().name());
        response.setInterviewDateTime(formatDateTime(interview.getInterviewDateTime()));
        response.setInterviewDurationMinutes(interview.getDurationMinutes());
        response.setInterviewType(interview.getInterviewType() == null ? "" : interview.getInterviewType().name());
        response.setInterviewMode(interview.getMode() == null ? "" : interview.getMode().name());
        response.setInterviewMeetingLink(safe(interview.getMeetingLink()));
        response.setInterviewLocation(safe(interview.getLocation()));
        response.setInterviewReminder24hSent(Boolean.TRUE.equals(interview.getReminder24hSent()));
        response.setInterviewReminder1hSent(Boolean.TRUE.equals(interview.getReminder1hSent()));
        response.setInterviewAttendanceStatus(interview.getAttendanceStatus() == null ? "" : interview.getAttendanceStatus().name());
    }

    private byte[] readCvBytes(Candidate candidate, CV cv) {
        String remoteUrl = safe(cv.getUrlFichier());
        if (!remoteUrl.isBlank()) {
            try (InputStream inputStream = URI.create(remoteUrl).toURL().openStream()) {
                return inputStream.readAllBytes();
            } catch (IOException | IllegalArgumentException ex) {
                // Fallback local si l'URL distante n'est plus accessible.
            }
        }

        String fileName = safe(cv.getNomFichier());
        if (candidate.getId() != null && !fileName.isBlank()) {
            Path filePath = Paths.get("uploads", "candidates", String.valueOf(candidate.getId()), fileName).normalize();
            if (Files.exists(filePath)) {
                try {
                    return Files.readAllBytes(filePath);
                } catch (IOException ex) {
                    throw new RuntimeException("Lecture du CV impossible.");
                }
            }
        }

        throw new RuntimeException("Le CV du candidat est introuvable.");
    }

    private String detectContentType(String fileName) {
        String lowerCaseName = safe(fileName).toLowerCase(Locale.ROOT);
        if (lowerCaseName.endsWith(".pdf")) {
            return "application/pdf";
        }
        if (lowerCaseName.endsWith(".docx")) {
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
        }
        if (lowerCaseName.endsWith(".doc")) {
            return "application/msword";
        }
        if (lowerCaseName.endsWith(".txt")) {
            return "text/plain";
        }
        return "application/octet-stream";
    }

    private String resolveCandidateImageUrl(String remoteUrl, Long candidateId, String fileName) {
        String sanitizedRemoteUrl = safe(remoteUrl);
        if (!sanitizedRemoteUrl.isBlank()) {
            return sanitizedRemoteUrl;
        }

        if (candidateId == null || safe(fileName).isBlank()) {
            return "";
        }

        Path filePath = Paths.get("uploads", "candidates", String.valueOf(candidateId), fileName).normalize();
        if (!Files.exists(filePath)) {
            return "";
        }

        try {
            String contentType = Files.probeContentType(filePath);
            if (contentType == null || !contentType.startsWith("image/")) {
                contentType = guessImageContentType(fileName);
            }

            byte[] bytes = Files.readAllBytes(filePath);
            return "data:" + contentType + ";base64," + Base64.getEncoder().encodeToString(bytes);
        } catch (IOException ex) {
            return "";
        }
    }

    private String guessImageContentType(String fileName) {
        String lowerCaseName = safe(fileName).toLowerCase(Locale.ROOT);
        if (lowerCaseName.endsWith(".png")) {
            return "image/png";
        }
        if (lowerCaseName.endsWith(".gif")) {
            return "image/gif";
        }
        if (lowerCaseName.endsWith(".webp")) {
            return "image/webp";
        }
        return "image/jpeg";
    }

    private String formatDate(Date value) {
        if (value == null) {
            return "";
        }

        return toLocalDate(value).toString();
    }

    private String formatDateTime(Date value) {
        if (value == null) {
            return "";
        }

        return value.toInstant()
                .atZone(ZoneId.systemDefault())
                .toLocalDateTime()
                .toString();
    }

    private LocalDate toLocalDate(Date value) {
        if (value instanceof java.sql.Date sqlDate) {
            return sqlDate.toLocalDate();
        }

        return value.toInstant()
                .atZone(ZoneId.systemDefault())
                .toLocalDate();
    }

    private double roundScore(double value) {
        return Math.round(value * 10d) / 10d;
    }

    private String nonEmpty(String primary, String fallback) {
        String normalized = safe(primary);
        return normalized.isEmpty() ? safe(fallback) : normalized;
    }

    private String safe(String value) {
        return value == null ? "" : value.trim();
    }

    public record CvDownloadPayload(String fileName, String contentType, byte[] bytes) {
    }
}
