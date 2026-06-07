package com.recrutement.recrutement.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.recrutement.recrutement.dto.ConfirmInterviewAbsenceRequest;
import com.recrutement.recrutement.dto.InterviewPlannerDraftResponse;
import com.recrutement.recrutement.dto.InterviewResponse;
import com.recrutement.recrutement.dto.MessageResponse;
import com.recrutement.recrutement.dto.OffreCompetenceRequest;
import com.recrutement.recrutement.dto.RescheduleInterviewRequest;
import com.recrutement.recrutement.dto.ScheduleInterviewRequest;
import com.recrutement.recrutement.entities.AiTest;
import com.recrutement.recrutement.entities.AttendanceStatus;
import com.recrutement.recrutement.entities.Candidate;
import com.recrutement.recrutement.entities.Candidature;
import com.recrutement.recrutement.entities.Entreprise;
import com.recrutement.recrutement.entities.Interview;
import com.recrutement.recrutement.entities.InterviewMode;
import com.recrutement.recrutement.entities.InterviewStatus;
import com.recrutement.recrutement.entities.InterviewType;
import com.recrutement.recrutement.entities.Offre;
import com.recrutement.recrutement.entities.Recruiter;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.repositories.AiTestRepository;
import com.recrutement.recrutement.repositories.CandidateRepository;
import com.recrutement.recrutement.repositories.CandidatureRepository;
import com.recrutement.recrutement.repositories.InterviewRepository;
import com.recrutement.recrutement.repositories.RecruiterRepository;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Date;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class InterviewService {
    private static final Logger logger = LoggerFactory.getLogger(InterviewService.class);
    public static final String APP_STATUS_INTERVIEW_READY = "INTERVIEW";
    public static final String APP_STATUS_INTERVIEW_SCHEDULED = "ENTRETIEN_PLANIFIE";
    public static final String APP_STATUS_INTERVIEW_IN_PROGRESS = "ENTRETIEN_EN_COURS";
    public static final String APP_STATUS_ABSENCE_TO_VERIFY = "ABSENCE_A_VERIFIER";
    public static final String APP_STATUS_REJECTED = "REJECTED";

    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
    private static final ZoneId ZONE_ID = ZoneId.systemDefault();

    private final InterviewRepository interviewRepository;
    private final CandidatureRepository candidatureRepository;
    private final RecruiterRepository recruiterRepository;
    private final CandidateRepository candidateRepository;
    private final AiTestRepository aiTestRepository;
    private final NotificationService notificationService;
    private final EmailService emailService;
    private final PythonGroqAgentService pythonGroqAgentService;
    private final ObjectMapper objectMapper;

    public InterviewService(
            InterviewRepository interviewRepository,
            CandidatureRepository candidatureRepository,
            RecruiterRepository recruiterRepository,
            CandidateRepository candidateRepository,
            AiTestRepository aiTestRepository,
            NotificationService notificationService,
            EmailService emailService,
            PythonGroqAgentService pythonGroqAgentService,
            ObjectMapper objectMapper
    ) {
        this.interviewRepository = interviewRepository;
        this.candidatureRepository = candidatureRepository;
        this.recruiterRepository = recruiterRepository;
        this.candidateRepository = candidateRepository;
        this.aiTestRepository = aiTestRepository;
        this.notificationService = notificationService;
        this.emailService = emailService;
        this.pythonGroqAgentService = pythonGroqAgentService;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    public InterviewPlannerDraftResponse getPlannerDraft(User currentUser, Long applicationId) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        Candidature application = getRecruiterOwnedApplication(recruiter, applicationId);
        AiTest aiTest = aiTestRepository.findTopByApplication_IdOrderByCreatedAtDesc(applicationId).orElse(null);

        InterviewPlannerDraftResponse response = new InterviewPlannerDraftResponse();
        response.setApplicationId(application.getId());
        response.setCandidateName(safe(application.getCandidate() == null ? null : application.getCandidate().getNom()));
        response.setOfferTitle(safe(application.getOffre() == null ? null : application.getOffre().getTitre()));
        response.setAiTestScore(aiTest == null ? null : aiTest.getScore());
        response.setAiRecommendation(aiTest == null ? "" : safe(aiTest.getRecommendation()));
        response.setSuggestedInterviewType(resolveSuggestedInterviewType(application, aiTest).name());
        response.setSuggestedQuestions(generateInterviewQuestions(application, aiTest, resolveSuggestedInterviewType(application, aiTest)));
        response.setDefaultInvitationMessage(buildDraftInvitationMessage(application, recruiter));
        return response;
    }

    @Transactional
    public InterviewResponse scheduleInterview(User currentUser, Long applicationId, ScheduleInterviewRequest request) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        Candidature application = getRecruiterOwnedApplication(recruiter, applicationId);
        validateSchedulableApplication(application);

        Interview interview = interviewRepository.findTopByCandidature_IdOrderByCreatedAtDesc(applicationId)
                .orElseGet(Interview::new);

        AiTest aiTest = aiTestRepository.findTopByApplication_IdOrderByCreatedAtDesc(applicationId).orElse(null);
        applyInterviewScheduling(interview, application, recruiter, request, aiTest, false);

        Interview savedInterview = interviewRepository.save(interview);
        application.setStatut(APP_STATUS_INTERVIEW_SCHEDULED);
        candidatureRepository.save(application);

        notifyCandidateForInvitation(savedInterview, false);
        return toResponse(savedInterview);
    }

    @Transactional
    public InterviewResponse markCandidatePresent(User currentUser, Long interviewId) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        Interview interview = getRecruiterOwnedInterview(recruiter, interviewId);

        interview.setAttendanceStatus(AttendanceStatus.PRESENT);
        interview.setStatus(InterviewStatus.IN_PROGRESS);
        Interview savedInterview = interviewRepository.save(interview);

        Candidature application = savedInterview.getCandidature();
        if (application != null) {
            application.setStatut(APP_STATUS_INTERVIEW_IN_PROGRESS);
            candidatureRepository.save(application);
        }

        if (savedInterview.getCandidate() != null) {
            notificationService.notifyUser(
                    savedInterview.getCandidate(),
                    "Votre entretien pour l'offre \"" + safe(savedInterview.getOffre() == null ? null : savedInterview.getOffre().getTitre())
                            + "\" est maintenant marque comme demarre."
            );
        }

        return toResponse(savedInterview);
    }

    @Transactional
    public MessageResponse confirmAbsence(User currentUser, Long interviewId, ConfirmInterviewAbsenceRequest request) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        Interview interview = getRecruiterOwnedInterview(recruiter, interviewId);

        interview.setAttendanceStatus(AttendanceStatus.ABSENT_CONFIRMED);
        interview.setStatus(InterviewStatus.CANCELLED);
        interview.setAbsenceCheckedAt(new Date());
        Interview savedInterview = interviewRepository.save(interview);

        Candidature application = savedInterview.getCandidature();
        if (application != null) {
            application.setStatut(APP_STATUS_REJECTED);
            candidatureRepository.save(application);
        }

        String emailBody = safe(request == null ? null : request.getEmailBody());
        if (emailBody.isBlank()) {
            emailBody = buildDefaultAbsenceRejectionEmail(savedInterview);
        }

        try {
            emailService.sendInterviewAbsenceRejectedEmail(
                    safe(savedInterview.getCandidate() == null ? null : savedInterview.getCandidate().getEmail()),
                    "Absence a l'entretien - " + safe(savedInterview.getOffre() == null ? null : savedInterview.getOffre().getTitre()),
                    emailBody
            );
        } catch (RuntimeException ex) {
            logger.warn("Email de refus apres absence non envoye pour l'entretien {}: {}", savedInterview.getId(), ex.getMessage());
        }

        if (savedInterview.getCandidate() != null) {
            notificationService.notifyUser(
                    savedInterview.getCandidate(),
                    "Votre candidature pour \"" + safe(savedInterview.getOffre() == null ? null : savedInterview.getOffre().getTitre())
                            + "\" a ete cloturee apres confirmation de votre absence a l'entretien."
            );
        }

        return new MessageResponse(true, "Absence confirmee. La candidature est maintenant refusee.");
    }

    @Transactional
    public InterviewResponse rescheduleInterview(User currentUser, Long interviewId, RescheduleInterviewRequest request) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        Interview interview = getRecruiterOwnedInterview(recruiter, interviewId);
        Candidature application = interview.getCandidature();
        if (application == null) {
            throw new RuntimeException("Candidature introuvable pour cet entretien.");
        }

        AiTest aiTest = aiTestRepository.findTopByApplication_IdOrderByCreatedAtDesc(application.getId()).orElse(null);
        applyInterviewScheduling(interview, application, recruiter, request, aiTest, true);
        Interview savedInterview = interviewRepository.save(interview);

        application.setStatut(APP_STATUS_INTERVIEW_SCHEDULED);
        candidatureRepository.save(application);

        notifyCandidateForInvitation(savedInterview, true);
        return toResponse(savedInterview);
    }

    @Transactional(readOnly = true)
    public List<InterviewResponse> getCandidateInterviews(User currentUser) {
        Candidate candidate = getCurrentCandidate(currentUser);
        return interviewRepository.findByCandidate_IdOrderByInterviewDateTimeDesc(candidate.getId()).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public void processScheduledInterviews() {
        Collection<InterviewStatus> monitoredStatuses = List.of(
                InterviewStatus.PLANNED,
                InterviewStatus.REMINDER_SENT,
                InterviewStatus.RESCHEDULED,
                InterviewStatus.IN_PROGRESS
        );

        LocalDateTime now = LocalDateTime.now(ZONE_ID);
        List<Interview> interviews = interviewRepository.findByStatusInOrderByInterviewDateTimeAsc(monitoredStatuses);
        for (Interview interview : interviews) {
            LocalDateTime start = toLocalDateTime(interview.getInterviewDateTime());
            if (start == null) {
                continue;
            }

            if (!Boolean.TRUE.equals(interview.getReminder24hSent()) && now.isBefore(start)
                    && Duration.between(now, start).toHours() <= 24) {
                sendReminder(interview, "24h");
                interview.setReminder24hSent(Boolean.TRUE);
                if (interview.getStatus() == InterviewStatus.PLANNED) {
                    interview.setStatus(InterviewStatus.REMINDER_SENT);
                }
            }

            if (!Boolean.TRUE.equals(interview.getReminder1hSent()) && now.isBefore(start)
                    && Duration.between(now, start).toMinutes() <= 60) {
                sendReminder(interview, "1h");
                interview.setReminder1hSent(Boolean.TRUE);
                if (interview.getStatus() == InterviewStatus.PLANNED) {
                    interview.setStatus(InterviewStatus.REMINDER_SENT);
                }
            }

            if (interview.getAttendanceStatus() == AttendanceStatus.UNKNOWN && now.isAfter(start.minusMinutes(1))
                    && (interview.getStatus() == InterviewStatus.PLANNED
                    || interview.getStatus() == InterviewStatus.REMINDER_SENT
                    || interview.getStatus() == InterviewStatus.RESCHEDULED)) {
                interview.setStatus(InterviewStatus.IN_PROGRESS);
                updateApplicationStatus(interview.getCandidature(), APP_STATUS_INTERVIEW_IN_PROGRESS);
            }

            if (interview.getAttendanceStatus() == AttendanceStatus.UNKNOWN && now.isAfter(start.plusMinutes(30))
                    && interview.getStatus() == InterviewStatus.IN_PROGRESS) {
                interview.setStatus(InterviewStatus.ABSENCE_TO_VERIFY);
                interview.setAbsenceCheckedAt(new Date());
                updateApplicationStatus(interview.getCandidature(), APP_STATUS_ABSENCE_TO_VERIFY);
                notifyRecruiterForAbsence(interview);
            }

            interviewRepository.save(interview);
        }
    }

    private void applyInterviewScheduling(
            Interview interview,
            Candidature application,
            Recruiter recruiter,
            ScheduleInterviewRequest request,
            AiTest aiTest,
            boolean reschedule
    ) {
        if (request == null) {
            throw new RuntimeException("Les informations de planification sont obligatoires.");
        }

        Candidate candidate = application.getCandidate();
        Offre offer = application.getOffre();
        if (candidate == null || offer == null) {
            throw new RuntimeException("Impossible de planifier un entretien pour une candidature incomplete.");
        }

        InterviewType interviewType = parseInterviewType(request.getInterviewType(), resolveSuggestedInterviewType(application, aiTest));
        InterviewMode mode = parseInterviewMode(request.getMode());
        LocalDateTime interviewDateTime = parseInterviewDateTime(request.getDate(), request.getStartTime());
        int duration = normalizeDuration(request.getDurationMinutes());
        validateModeSpecificFields(mode, request.getMeetingLink(), request.getLocation());

        List<String> suggestedQuestions = generateInterviewQuestions(application, aiTest, interviewType);
        String invitationMessage = safe(request.getInvitationMessage());
        if (invitationMessage.isBlank()) {
            invitationMessage = buildInvitationMessage(application, recruiter, interviewDateTime, duration, mode, request.getMeetingLink(), request.getLocation());
        }

        interview.setCandidature(application);
        interview.setRecruiter(recruiter);
        interview.setCandidate(candidate);
        interview.setOffre(offer);
        interview.setInterviewDateTime(toDate(interviewDateTime));
        interview.setDurationMinutes(duration);
        interview.setInterviewType(interviewType);
        interview.setMode(mode);
        interview.setMeetingLink(safe(request.getMeetingLink()));
        interview.setLocation(safe(request.getLocation()));
        interview.setInvitationMessage(invitationMessage);
        interview.setAiSuggestedQuestionsJson(writeStringList(suggestedQuestions));
        interview.setStatus(reschedule ? InterviewStatus.RESCHEDULED : InterviewStatus.PLANNED);
        interview.setReminder24hSent(Boolean.FALSE);
        interview.setReminder1hSent(Boolean.FALSE);
        interview.setAttendanceStatus(AttendanceStatus.UNKNOWN);
        interview.setAbsenceCheckedAt(null);
    }

    private void notifyCandidateForInvitation(Interview interview, boolean rescheduled) {
        Candidate candidate = interview.getCandidate();
        if (candidate == null) {
            return;
        }

        try {
            emailService.sendInterviewInvitationEmail(
                    safe(candidate.getEmail()),
                    "Invitation entretien - " + safe(interview.getOffre() == null ? null : interview.getOffre().getTitre()),
                    interview.getInvitationMessage()
            );
        } catch (RuntimeException ex) {
            logger.warn("Email d'invitation entretien non envoye pour l'entretien {}: {}", interview.getId(), ex.getMessage());
        }

        String verb = rescheduled ? "a ete replanifie" : "a ete planifie";
        notificationService.notifyUser(
                candidate,
                "Un entretien " + verb + " pour l'offre \"" + safe(interview.getOffre() == null ? null : interview.getOffre().getTitre())
                        + "\" le " + formatDateTime(interview.getInterviewDateTime()) + "."
        );
    }

    private void sendReminder(Interview interview, String label) {
        Candidate candidate = interview.getCandidate();
        if (candidate == null) {
            return;
        }

        String body = buildReminderMessage(interview, label);
        try {
            emailService.sendInterviewReminderEmail(
                    safe(candidate.getEmail()),
                    "Rappel entretien - " + safe(interview.getOffre() == null ? null : interview.getOffre().getTitre()),
                    body
            );
        } catch (RuntimeException ex) {
            logger.warn("Email de rappel {} non envoye pour l'entretien {}: {}", label, interview.getId(), ex.getMessage());
        }

        notificationService.notifyUser(
                candidate,
                "Rappel : votre entretien pour \"" + safe(interview.getOffre() == null ? null : interview.getOffre().getTitre())
                        + "\" est prevu le " + formatDateTime(interview.getInterviewDateTime()) + "."
        );
    }

    private void notifyRecruiterForAbsence(Interview interview) {
        Recruiter recruiter = interview.getRecruiter();
        if (recruiter == null) {
            return;
        }

        notificationService.notifyUser(
                recruiter,
                "L'entretien de " + safe(interview.getCandidate() == null ? null : interview.getCandidate().getNom())
                        + " pour \"" + safe(interview.getOffre() == null ? null : interview.getOffre().getTitre())
                        + "\" est passe en absence a verifier."
        );
    }

    private void updateApplicationStatus(Candidature application, String status) {
        if (application == null) {
            return;
        }

        application.setStatut(status);
        candidatureRepository.save(application);
    }

    private void validateSchedulableApplication(Candidature application) {
        String normalized = AiTestService.normalizeApplicationStatus(application.getStatut());
        if (APP_STATUS_REJECTED.equals(normalized)) {
            throw new RuntimeException("Impossible de planifier un entretien pour une candidature deja refusee.");
        }
    }

    private List<String> generateInterviewQuestions(Candidature application, AiTest aiTest, InterviewType interviewType) {
        if (pythonGroqAgentService.isConfigured()) {
            try {
                JsonNode response = pythonGroqAgentService.invoke("suggest_questions", buildQuestionPayload(application, aiTest, interviewType));
                List<String> questions = readQuestionList(response.get("questions"));
                if (!questions.isEmpty()) {
                    return questions.stream().limit(5).toList();
                }
            } catch (RuntimeException ex) {
                logger.warn("Generation IA des questions d'entretien indisponible: {}", ex.getMessage());
            }
        }

        return buildFallbackQuestions(application, aiTest, interviewType);
    }

    private Object buildQuestionPayload(Candidature application, AiTest aiTest, InterviewType interviewType) {
        Offre offer = application.getOffre();
        Candidate candidate = application.getCandidate();
        return objectMapper.createObjectNode()
                .put("offerTitle", safe(offer == null ? null : offer.getTitre()))
                .put("offerDescription", safe(offer == null ? null : offer.getDescription()))
                .put("experienceRequired", safe(offer == null ? null : offer.getExperienceRequise()))
                .put("candidateName", safe(candidate == null ? null : candidate.getNom()))
                .put("candidateJobTitle", safe(candidate == null ? null : candidate.getPosteRecherche()))
                .put("candidateSummary", safe(candidate == null ? null : candidate.getDescription()))
                .put("interviewType", interviewType.name())
                .put("aiScore", aiTest == null || aiTest.getScore() == null ? 0d : aiTest.getScore())
                .putPOJO("skills", readOfferCompetenceNames(offer))
                .putPOJO("weaknesses", readWeaknesses(aiTest));
    }

    private List<String> buildFallbackQuestions(Candidature application, AiTest aiTest, InterviewType interviewType) {
        Offre offer = application.getOffre();
        List<String> skillNames = readOfferCompetenceNames(offer);
        String primarySkill = skillNames.isEmpty() ? "les competences cles du poste" : skillNames.get(0);
        String weakArea = readWeaknesses(aiTest).stream().findFirst().orElse("les points techniques a renforcer");

        List<String> questions = new ArrayList<>();
        questions.add("Pouvez-vous nous presenter une experience concrete liee a " + primarySkill + " ?");
        questions.add("Comment abordez-vous un projet similaire au poste de " + safe(offer == null ? null : offer.getTitre()) + " ?");
        questions.add("Quelles actions mettez-vous en place pour progresser sur " + weakArea + " ?");
        if (interviewType == InterviewType.TECHNIQUE) {
            questions.add("Expliquez votre methode pour deboguer un probleme complexe en environnement de production.");
            questions.add("Comment priorisez-vous qualite, performance et maintenabilite dans vos choix techniques ?");
        } else if (interviewType == InterviewType.RH) {
            questions.add("Quelles motivations vous poussent a rejoindre cette entreprise et ce role ?");
            questions.add("Comment collaborez-vous avec une equipe pluridisciplinaire sous contrainte de delai ?");
        } else {
            questions.add("Quelle valeur immediate pouvez-vous apporter a cette opportunite si vous rejoignez l'equipe ?");
            questions.add("Comment prenez-vous des decisions quand plusieurs priorites business s'opposent ?");
        }

        return questions.stream().limit(5).toList();
    }

    private List<String> readQuestionList(JsonNode node) {
        if (node == null || !node.isArray()) {
            return List.of();
        }

        List<String> questions = new ArrayList<>();
        node.forEach(item -> {
            String value = safe(item.isTextual() ? item.asText() : item.path("question").asText());
            if (!value.isBlank()) {
                questions.add(value);
            }
        });
        return questions;
    }

    private List<String> readOfferCompetenceNames(Offre offer) {
        if (offer == null || safe(offer.getCompetencesJson()).isBlank()) {
            return List.of();
        }

        try {
            List<OffreCompetenceRequest> items = objectMapper.readValue(
                    offer.getCompetencesJson(),
                    new TypeReference<List<OffreCompetenceRequest>>() {
                    }
            );
            Set<String> values = new LinkedHashSet<>();
            for (OffreCompetenceRequest item : items) {
                String skill = safe(item.getNom());
                if (!skill.isBlank()) {
                    values.add(skill);
                }
            }
            return new ArrayList<>(values);
        } catch (JsonProcessingException ex) {
            return List.of();
        }
    }

    private List<String> readWeaknesses(AiTest aiTest) {
        if (aiTest == null || aiTest.getResult() == null || safe(aiTest.getResult().getWeaknesses()).isBlank()) {
            return List.of();
        }

        return readStringList(aiTest.getResult().getWeaknesses());
    }

    private InterviewType resolveSuggestedInterviewType(Candidature application, AiTest aiTest) {
        Double score = aiTest == null ? null : aiTest.getScore();
        if (score != null && score >= 85) {
            return InterviewType.FINAL;
        }

        String experience = safe(application.getOffre() == null ? null : application.getOffre().getExperienceRequise()).toLowerCase(Locale.ROOT);
        if (experience.contains("senior") || experience.contains("avance")) {
            return InterviewType.TECHNIQUE;
        }

        return InterviewType.RH;
    }

    private String buildDraftInvitationMessage(Candidature application, Recruiter recruiter) {
        String candidateName = safe(application.getCandidate() == null ? null : application.getCandidate().getNom());
        String offerTitle = safe(application.getOffre() == null ? null : application.getOffre().getTitre());
        return "Bonjour " + candidateName + ",\n\n"
                + "Suite a votre candidature pour le poste de " + offerTitle + ", nous avons le plaisir de vous inviter a un entretien.\n\n"
                + "Date : [Date]\n"
                + "Heure : [Heure]\n"
                + "Duree : [Duree]\n"
                + "Mode : [Mode]\n"
                + "Lien ou lieu : [Lien ou Adresse]\n\n"
                + "Merci d'etre present a l'heure prevue.\n\n"
                + "Cordialement,\n"
                + safe(recruiter.getNom()) + "\n"
                + resolveCompanyName(recruiter);
    }

    private String buildInvitationMessage(
            Candidature application,
            Recruiter recruiter,
            LocalDateTime dateTime,
            int duration,
            InterviewMode mode,
            String meetingLink,
            String location
    ) {
        String candidateName = safe(application.getCandidate() == null ? null : application.getCandidate().getNom());
        String offerTitle = safe(application.getOffre() == null ? null : application.getOffre().getTitre());
        return "Bonjour " + candidateName + ",\n\n"
                + "Suite a votre candidature pour le poste de " + offerTitle + ", nous avons le plaisir de vous inviter a un entretien.\n\n"
                + "Date : " + dateTime.toLocalDate() + "\n"
                + "Heure : " + dateTime.toLocalTime().withSecond(0).withNano(0) + "\n"
                + "Duree : " + duration + " minutes\n"
                + "Mode : " + formatMode(mode) + "\n"
                + "Lien ou lieu : " + resolveContactPoint(mode, meetingLink, location) + "\n\n"
                + "Merci d'etre present a l'heure prevue.\n\n"
                + "Cordialement,\n"
                + safe(recruiter.getNom()) + "\n"
                + resolveCompanyName(recruiter);
    }

    private String buildReminderMessage(Interview interview, String label) {
        String candidateName = safe(interview.getCandidate() == null ? null : interview.getCandidate().getNom());
        return "Bonjour " + candidateName + ",\n\n"
                + "Nous vous rappelons que votre entretien pour le poste de "
                + safe(interview.getOffre() == null ? null : interview.getOffre().getTitre())
                + " est prevu le " + formatDateTime(interview.getInterviewDateTime()) + ".\n\n"
                + "Mode : " + formatMode(interview.getMode()) + "\n"
                + "Lien ou lieu : " + resolveContactPoint(interview.getMode(), interview.getMeetingLink(), interview.getLocation()) + "\n\n"
                + "Rappel automatique Smart Recruit (" + label + " avant l'entretien).\n\n"
                + "Cordialement,\n"
                + safe(interview.getRecruiter() == null ? null : interview.getRecruiter().getNom()) + "\n"
                + resolveCompanyName(interview.getRecruiter());
    }

    private String buildDefaultAbsenceRejectionEmail(Interview interview) {
        return "Bonjour " + safe(interview.getCandidate() == null ? null : interview.getCandidate().getNom()) + ",\n\n"
                + "Nous vous informons que vous n'avez pas ete present a l'entretien prevu pour le poste de "
                + safe(interview.getOffre() == null ? null : interview.getOffre().getTitre()) + ".\n\n"
                + "Apres verification par le recruteur, votre candidature ne sera pas poursuivie pour cette opportunite.\n\n"
                + "Nous vous remercions pour votre interet et vous souhaitons une bonne continuation dans vos recherches.\n\n"
                + "Cordialement,\n"
                + safe(interview.getRecruiter() == null ? null : interview.getRecruiter().getNom()) + "\n"
                + resolveCompanyName(interview.getRecruiter());
    }

    private Recruiter getCurrentRecruiter(User currentUser) {
        Recruiter recruiter = currentUser != null && currentUser.getId() != null
                ? recruiterRepository.findById(currentUser.getId()).orElse(null)
                : null;

        if (recruiter == null && currentUser != null) {
            recruiter = recruiterRepository.findByEmail(currentUser.getEmail());
        }

        if (recruiter == null) {
            throw new RuntimeException("Profil recruteur introuvable.");
        }
        return recruiter;
    }

    private Candidate getCurrentCandidate(User currentUser) {
        Candidate candidate = currentUser != null && currentUser.getId() != null
                ? candidateRepository.findById(currentUser.getId()).orElse(null)
                : null;

        if (candidate == null && currentUser != null) {
            candidate = candidateRepository.findByEmail(currentUser.getEmail());
        }

        if (candidate == null) {
            throw new RuntimeException("Profil candidat introuvable.");
        }
        return candidate;
    }

    private Candidature getRecruiterOwnedApplication(Recruiter recruiter, Long applicationId) {
        return candidatureRepository.findByIdAndOffre_Recruiter_Id(applicationId, recruiter.getId())
                .orElseThrow(() -> new RuntimeException("Candidature introuvable."));
    }

    private Interview getRecruiterOwnedInterview(Recruiter recruiter, Long interviewId) {
        return interviewRepository.findByIdAndRecruiter_Id(interviewId, recruiter.getId())
                .orElseThrow(() -> new RuntimeException("Entretien introuvable."));
    }

    private InterviewType parseInterviewType(String value, InterviewType fallback) {
        String normalized = safe(value).toUpperCase(Locale.ROOT);
        if (normalized.isBlank()) {
            return fallback;
        }

        try {
            return InterviewType.valueOf(normalized);
        } catch (IllegalArgumentException ex) {
            throw new RuntimeException("Le type d'entretien est invalide.");
        }
    }

    private InterviewMode parseInterviewMode(String value) {
        String normalized = safe(value).toUpperCase(Locale.ROOT);
        if (normalized.isBlank()) {
            throw new RuntimeException("Le mode d'entretien est obligatoire.");
        }

        try {
            return InterviewMode.valueOf(normalized);
        } catch (IllegalArgumentException ex) {
            throw new RuntimeException("Le mode d'entretien est invalide.");
        }
    }

    private LocalDateTime parseInterviewDateTime(String dateValue, String timeValue) {
        try {
            LocalDate date = LocalDate.parse(safe(dateValue));
            LocalTime time = LocalTime.parse(safe(timeValue));
            return LocalDateTime.of(date, time);
        } catch (DateTimeParseException ex) {
            throw new RuntimeException("La date ou l'heure de l'entretien est invalide.");
        }
    }

    private int normalizeDuration(Integer durationMinutes) {
        if (durationMinutes == null || durationMinutes <= 0) {
            return 60;
        }
        return Math.min(durationMinutes, 240);
    }

    private void validateModeSpecificFields(InterviewMode mode, String meetingLink, String location) {
        if (mode == InterviewMode.EN_LIGNE && safe(meetingLink).isBlank()) {
            throw new RuntimeException("Le lien de reunion est obligatoire pour un entretien en ligne.");
        }

        if (mode == InterviewMode.PRESENTIEL && safe(location).isBlank()) {
            throw new RuntimeException("L'adresse est obligatoire pour un entretien en presentiel.");
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

    private String resolveContactPoint(InterviewMode mode, String meetingLink, String location) {
        if (mode == InterviewMode.EN_LIGNE) {
            return safe(meetingLink);
        }
        if (mode == InterviewMode.PRESENTIEL) {
            return safe(location);
        }
        return "Echange telephonique";
    }

    private String formatMode(InterviewMode mode) {
        if (mode == null) {
            return "";
        }

        return switch (mode) {
            case EN_LIGNE -> "En ligne";
            case PRESENTIEL -> "Presentiel";
            case TELEPHONE -> "Telephone";
        };
    }

    private InterviewResponse toResponse(Interview interview) {
        InterviewResponse response = new InterviewResponse();
        response.setId(interview.getId());
        response.setApplicationId(interview.getCandidature() == null ? null : interview.getCandidature().getId());
        response.setOfferId(interview.getOffre() == null ? null : interview.getOffre().getId());
        response.setCandidateId(interview.getCandidate() == null ? null : interview.getCandidate().getId());
        response.setRecruiterId(interview.getRecruiter() == null ? null : interview.getRecruiter().getId());
        response.setCandidateName(safe(interview.getCandidate() == null ? null : interview.getCandidate().getNom()));
        response.setOfferTitle(safe(interview.getOffre() == null ? null : interview.getOffre().getTitre()));
        response.setCompanyName(resolveCompanyName(interview.getRecruiter()));
        response.setInterviewDateTime(formatDateTime(interview.getInterviewDateTime()));
        response.setDurationMinutes(interview.getDurationMinutes());
        response.setInterviewType(interview.getInterviewType() == null ? "" : interview.getInterviewType().name());
        response.setMode(interview.getMode() == null ? "" : interview.getMode().name());
        response.setMeetingLink(safe(interview.getMeetingLink()));
        response.setLocation(safe(interview.getLocation()));
        response.setInvitationMessage(safe(interview.getInvitationMessage()));
        response.setAiSuggestedQuestions(readStringList(interview.getAiSuggestedQuestionsJson()));
        response.setStatus(interview.getStatus() == null ? "" : interview.getStatus().name());
        response.setReminder24hSent(Boolean.TRUE.equals(interview.getReminder24hSent()));
        response.setReminder1hSent(Boolean.TRUE.equals(interview.getReminder1hSent()));
        response.setAttendanceStatus(interview.getAttendanceStatus() == null ? "" : interview.getAttendanceStatus().name());
        response.setAbsenceCheckedAt(formatDateTime(interview.getAbsenceCheckedAt()));
        response.setCreatedAt(formatDateTime(interview.getCreatedAt()));
        response.setUpdatedAt(formatDateTime(interview.getUpdatedAt()));
        return response;
    }

    private String writeStringList(List<String> values) {
        try {
            return objectMapper.writeValueAsString(values == null ? List.of() : values);
        } catch (JsonProcessingException ex) {
            return "[]";
        }
    }

    private List<String> readStringList(String value) {
        if (safe(value).isBlank()) {
            return List.of();
        }

        try {
            return objectMapper.readValue(value, new TypeReference<List<String>>() {
            });
        } catch (JsonProcessingException ex) {
            return List.of();
        }
    }

    private Date toDate(LocalDateTime value) {
        return value == null ? null : Date.from(value.atZone(ZONE_ID).toInstant());
    }

    private LocalDateTime toLocalDateTime(Date value) {
        return value == null ? null : value.toInstant().atZone(ZONE_ID).toLocalDateTime();
    }

    private String formatDateTime(Date value) {
        LocalDateTime dateTime = toLocalDateTime(value);
        return dateTime == null ? "" : dateTime.format(DATE_TIME_FORMATTER);
    }

    private String safe(String value) {
        return value == null ? "" : value.trim();
    }
}
