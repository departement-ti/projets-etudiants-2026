package com.recrutement.recrutement.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.recrutement.recrutement.dto.AiAnswerSubmissionRequest;
import com.recrutement.recrutement.dto.AiTestQuestionAnswerRequest;
import com.recrutement.recrutement.dto.AiTestQuestionUpdateRequest;
import com.recrutement.recrutement.dto.AiQuestionResponse;
import com.recrutement.recrutement.dto.AiTestSecurityEventRequest;
import com.recrutement.recrutement.dto.AiTestResponse;
import com.recrutement.recrutement.dto.CreateAiTestRequest;
import com.recrutement.recrutement.dto.MessageResponse;
import com.recrutement.recrutement.dto.OffreCompetenceRequest;
import com.recrutement.recrutement.dto.RejectAfterAiTestRequest;
import com.recrutement.recrutement.dto.SubmitAiTestRequest;
import com.recrutement.recrutement.entities.AiAnswer;
import com.recrutement.recrutement.entities.AiQuestion;
import com.recrutement.recrutement.entities.AiTest;
import com.recrutement.recrutement.entities.AiTestResult;
import com.recrutement.recrutement.entities.Candidate;
import com.recrutement.recrutement.entities.Candidature;
import com.recrutement.recrutement.entities.Entreprise;
import com.recrutement.recrutement.entities.Offre;
import com.recrutement.recrutement.entities.Recruiter;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.repositories.AiAnswerRepository;
import com.recrutement.recrutement.repositories.AiQuestionRepository;
import com.recrutement.recrutement.repositories.AiTestRepository;
import com.recrutement.recrutement.repositories.AiTestResultRepository;
import com.recrutement.recrutement.repositories.CandidateRepository;
import com.recrutement.recrutement.repositories.CandidatureRepository;
import com.recrutement.recrutement.repositories.OffreRepository;
import com.recrutement.recrutement.repositories.RecruiterRepository;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AiTestService {
    private static final Logger logger = LoggerFactory.getLogger(AiTestService.class);
    private static final String APP_STATUS_APPLIED = "APPLIED";
    private static final String APP_STATUS_AI_TEST_SENT = "AI_TEST_SENT";
    private static final String APP_STATUS_AI_TEST_COMPLETED = "AI_TEST_COMPLETED";
    private static final String APP_STATUS_INTERVIEW = "INTERVIEW";
    private static final String APP_STATUS_REJECTION_SUGGESTED = "REJECTION_SUGGESTED";
    private static final String APP_STATUS_REJECTED = "REJECTED";
    private static final String APP_STATUS_RETAINED = "RETENU";
    private static final String TEST_STATUS_NOT_STARTED = "NOT_STARTED";
    private static final String TEST_STATUS_IN_PROGRESS = "IN_PROGRESS";
    private static final String TEST_STATUS_SUBMITTED = "SUBMITTED";
    private static final String TEST_STATUS_EXPIRED = "EXPIRED";
    private static final String TEST_STATUS_CHEATING_SUSPECTED = "CHEATING_SUSPECTED";
    private static final String TEST_STATUS_CLOSED = "CLOSED";
    private static final String TEST_STATUS_DRAFT = "DRAFT";
    private static final String TEST_STATUS_GENERATED = "GENERATED";
    private static final String TEST_STATUS_VALIDATED = "VALIDATED";
    private static final String TEST_STATUS_PUBLISHED = "PUBLISHED";
    private static final String EVENT_TAB_SWITCH = "TAB_SWITCH";
    private static final String EVENT_PAGE_LEAVE = "PAGE_LEAVE";
    private static final String EVENT_WINDOW_BLUR = "WINDOW_BLUR";
    private static final String EVENT_RELOAD_ATTEMPT = "RELOAD_ATTEMPT";
    private static final String EVENT_ROUTE_LEAVE = "ROUTE_LEAVE";
    private static final String QUESTION_TYPE_MCQ = "MCQ";
    private static final String QUESTION_TYPE_QCM = "QCM";
    private static final String QUESTION_TYPE_SHORT = "SHORT_TEXT";
    private static final String QUESTION_TYPE_SCENARIO = "SCENARIO";
    private static final int DEFAULT_TEST_DURATION_MINUTES = 20;
    private static final int DEFAULT_QUESTION_TIME_SECONDS = 180;
    private static final int MAX_WARNING_COUNT = 2;
    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    private final AiTestRepository aiTestRepository;
    private final AiQuestionRepository aiQuestionRepository;
    private final AiAnswerRepository aiAnswerRepository;
    private final AiTestResultRepository aiTestResultRepository;
    private final CandidatureRepository candidatureRepository;
    private final CandidateRepository candidateRepository;
    private final OffreRepository offreRepository;
    private final RecruiterRepository recruiterRepository;
    private final NotificationService notificationService;
    private final EmailService emailService;
    private final PythonGroqAgentService pythonGroqAgentService;
    private final ObjectMapper objectMapper;

    public AiTestService(
            AiTestRepository aiTestRepository,
            AiQuestionRepository aiQuestionRepository,
            AiAnswerRepository aiAnswerRepository,
            AiTestResultRepository aiTestResultRepository,
            CandidatureRepository candidatureRepository,
            CandidateRepository candidateRepository,
            OffreRepository offreRepository,
            RecruiterRepository recruiterRepository,
            NotificationService notificationService,
            EmailService emailService,
            PythonGroqAgentService pythonGroqAgentService,
            ObjectMapper objectMapper
    ) {
        this.aiTestRepository = aiTestRepository;
        this.aiQuestionRepository = aiQuestionRepository;
        this.aiAnswerRepository = aiAnswerRepository;
        this.aiTestResultRepository = aiTestResultRepository;
        this.candidatureRepository = candidatureRepository;
        this.candidateRepository = candidateRepository;
        this.offreRepository = offreRepository;
        this.recruiterRepository = recruiterRepository;
        this.notificationService = notificationService;
        this.emailService = emailService;
        this.pythonGroqAgentService = pythonGroqAgentService;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public AiTestResponse configureOfferAiTest(User currentUser, Long offerId, CreateAiTestRequest request) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        Offre offer = resolveRecruiterOffer(recruiter, offerId);

        AiTest aiTest = aiTestRepository.findTopByJobOffer_IdAndApplicationIsNullOrderByCreatedAtDesc(offerId)
                .orElseGet(() -> AiTest.builder()
                        .jobOffer(offer)
                        .recruiter(recruiter)
                        .createdAt(new Date())
                        .build());

        applyOfferTestConfiguration(aiTest, offer, recruiter, request, false);
        aiTest.setUpdatedAt(new Date());
        if (safe(aiTest.getStatus()).isBlank()) {
            aiTest.setStatus(TEST_STATUS_DRAFT);
        }

        AiTest saved = aiTestRepository.save(aiTest);
        return toResponse(saved, aiQuestionRepository.findByAiTest_IdOrderByOrderIndexAscIdAsc(saved.getId()), List.of(), aiTestResultRepository.findByAiTest_Id(saved.getId()).orElse(null), true);
    }

    @Transactional
    public AiTestResponse generateOfferAiTest(User currentUser, Long offerId, CreateAiTestRequest request) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        Offre offer = resolveRecruiterOffer(recruiter, offerId);
        AiTest aiTest = aiTestRepository.findTopByJobOffer_IdAndApplicationIsNullOrderByCreatedAtDesc(offerId)
                .orElseGet(() -> AiTest.builder()
                        .jobOffer(offer)
                        .recruiter(recruiter)
                        .createdAt(new Date())
                        .build());

        applyOfferTestConfiguration(aiTest, offer, recruiter, request, true);
        aiTest.setStatus(TEST_STATUS_GENERATED);
        aiTest.setUpdatedAt(new Date());
        AiTest saved = aiTestRepository.save(aiTest);

        aiQuestionRepository.deleteAll(aiQuestionRepository.findByAiTest_IdOrderByIdAsc(saved.getId()));
        List<GeneratedQuestionPayload> generatedQuestions = generateOfferTemplatePayload(offer, saved);
        List<AiQuestion> persisted = new ArrayList<>();
        int index = 0;
        for (GeneratedQuestionPayload item : generatedQuestions) {
            persisted.add(toEntity(saved, item, index++));
        }
        aiQuestionRepository.saveAll(persisted);
        saved.setTotalDurationSeconds(computeTotalDurationSeconds(persisted));
        saved.setUpdatedAt(new Date());
        aiTestRepository.save(saved);

        return toResponse(saved, persisted, List.of(), aiTestResultRepository.findByAiTest_Id(saved.getId()).orElse(null), true);
    }

    @Transactional
    public AiTestResponse getRecruiterOfferAiTest(User currentUser, Long offerId) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        resolveRecruiterOffer(recruiter, offerId);
        AiTest aiTest = aiTestRepository.findTopByJobOffer_IdAndApplicationIsNullOrderByCreatedAtDesc(offerId)
                .orElseThrow(() -> new RuntimeException("Aucun Test IA n'est associe a cette offre."));
        return toResponse(aiTest, aiQuestionRepository.findByAiTest_IdOrderByOrderIndexAscIdAsc(aiTest.getId()), List.of(), aiTestResultRepository.findByAiTest_Id(aiTest.getId()).orElse(null), true);
    }

    @Transactional
    public AiTestResponse updateRecruiterAiTest(User currentUser, Long testId, CreateAiTestRequest request) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        AiTest aiTest = aiTestRepository.findByIdAndJobOffer_Recruiter_Id(testId, recruiter.getId())
                .orElseThrow(() -> new RuntimeException("Test IA introuvable."));
        applyOfferTestConfiguration(aiTest, aiTest.getJobOffer(), recruiter, request, false);
        aiTest.setUpdatedAt(new Date());
        if (TEST_STATUS_PUBLISHED.equals(normalizeAiTestStatus(aiTest.getStatus()))) {
            aiTest.setStatus(TEST_STATUS_DRAFT);
        }
        AiTest saved = aiTestRepository.save(aiTest);
        return toResponse(saved, aiQuestionRepository.findByAiTest_IdOrderByOrderIndexAscIdAsc(saved.getId()), List.of(), aiTestResultRepository.findByAiTest_Id(saved.getId()).orElse(null), true);
    }

    @Transactional
    public AiTestResponse updateRecruiterAiQuestion(User currentUser, Long questionId, AiTestQuestionUpdateRequest request) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        AiQuestion question = aiQuestionRepository.findById(questionId)
                .orElseThrow(() -> new RuntimeException("Question introuvable."));
        AiTest aiTest = question.getAiTest();
        if (aiTest == null || aiTest.getJobOffer() == null || aiTest.getJobOffer().getRecruiter() == null
                || !Objects.equals(aiTest.getJobOffer().getRecruiter().getId(), recruiter.getId())) {
            throw new RuntimeException("Vous ne pouvez modifier que les questions de vos propres tests.");
        }

        question.setQuestionText(nonEmpty(request.getQuestionText(), safe(question.getQuestionText())));
        question.setQuestionType(normalizeQuestionType(nonEmpty(request.getQuestionType(), safe(question.getQuestionType()))));
        question.setOptionsJson(writeStringList(request.getOptions()));
        question.setCorrectAnswer(safe(request.getCorrectAnswer()));
        question.setExpectedKeywordsJson(writeStringList(splitExpectedAnswer(request.getExpectedAnswer())));
        question.setPoints(request.getPoints() == null ? question.getPoints() : Math.max(1d, request.getPoints()));
        question.setOrderIndex(request.getOrderIndex() == null ? safeInteger(question.getOrderIndex()) : Math.max(0, request.getOrderIndex()));
        question.setTimeLimitSeconds(request.getTimeLimitSeconds() == null ? safeInteger(question.getTimeLimitSeconds()) : Math.max(30, request.getTimeLimitSeconds()));
        question.setAcceptedByRecruiter(request.getAcceptedByRecruiter() == null ? question.getAcceptedByRecruiter() : request.getAcceptedByRecruiter());
        question.setUpdatedAt(new Date());
        aiQuestionRepository.save(question);

        recalculateOfferTestDurations(aiTest);
        return toResponse(aiTestRepository.save(aiTest), aiQuestionRepository.findByAiTest_IdOrderByOrderIndexAscIdAsc(aiTest.getId()), List.of(), aiTestResultRepository.findByAiTest_Id(aiTest.getId()).orElse(null), true);
    }

    @Transactional
    public AiTestResponse regenerateRecruiterAiQuestion(User currentUser, Long questionId) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        AiQuestion question = aiQuestionRepository.findById(questionId)
                .orElseThrow(() -> new RuntimeException("Question introuvable."));
        AiTest aiTest = question.getAiTest();
        if (aiTest == null || aiTest.getJobOffer() == null || aiTest.getJobOffer().getRecruiter() == null
                || !Objects.equals(aiTest.getJobOffer().getRecruiter().getId(), recruiter.getId())) {
            throw new RuntimeException("Vous ne pouvez regenerer que les questions de vos propres tests.");
        }

        GeneratedQuestionPayload regenerated = generateSingleQuestion(aiTest.getJobOffer(), aiTest, safeInteger(question.getOrderIndex()));
        question.setQuestionText(regenerated.questionText());
        question.setQuestionType(normalizeQuestionType(regenerated.questionType()));
        question.setOptionsJson(writeStringList(regenerated.options()));
        question.setCorrectAnswer(regenerated.correctAnswer());
        question.setExpectedKeywordsJson(writeStringList(regenerated.expectedKeywords()));
        question.setPoints(regenerated.points());
        question.setAcceptedByRecruiter(false);
        question.setUpdatedAt(new Date());
        aiQuestionRepository.save(question);

        recalculateOfferTestDurations(aiTest);
        return toResponse(aiTestRepository.save(aiTest), aiQuestionRepository.findByAiTest_IdOrderByOrderIndexAscIdAsc(aiTest.getId()), List.of(), aiTestResultRepository.findByAiTest_Id(aiTest.getId()).orElse(null), true);
    }

    @Transactional
    public MessageResponse deleteRecruiterAiQuestion(User currentUser, Long questionId) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        AiQuestion question = aiQuestionRepository.findById(questionId)
                .orElseThrow(() -> new RuntimeException("Question introuvable."));
        AiTest aiTest = question.getAiTest();
        if (aiTest == null || aiTest.getJobOffer() == null || aiTest.getJobOffer().getRecruiter() == null
                || !Objects.equals(aiTest.getJobOffer().getRecruiter().getId(), recruiter.getId())) {
            throw new RuntimeException("Vous ne pouvez supprimer que les questions de vos propres tests.");
        }

        aiQuestionRepository.delete(question);
        recalculateOfferTestDurations(aiTest);
        aiTestRepository.save(aiTest);
        return new MessageResponse(true, "La question du Test IA a ete supprimee.");
    }

    @Transactional
    public AiTestResponse validateRecruiterAiTest(User currentUser, Long testId) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        AiTest aiTest = aiTestRepository.findByIdAndJobOffer_Recruiter_Id(testId, recruiter.getId())
                .orElseThrow(() -> new RuntimeException("Test IA introuvable."));
        List<AiQuestion> questions = aiQuestionRepository.findByAiTest_IdOrderByOrderIndexAscIdAsc(aiTest.getId());
        if (questions.isEmpty()) {
            throw new RuntimeException("Le test doit contenir au moins une question avant validation.");
        }

        aiTest.setNumberOfQuestions(questions.size());
        aiTest.setTotalDurationSeconds(computeTotalDurationSeconds(questions));
        aiTest.setStatus(TEST_STATUS_VALIDATED);
        aiTest.setUpdatedAt(new Date());
        AiTest saved = aiTestRepository.save(aiTest);
        return toResponse(saved, questions, List.of(), aiTestResultRepository.findByAiTest_Id(saved.getId()).orElse(null), true);
    }

    @Transactional
    public AiTestResponse getCandidateAiTestByApplication(User currentUser, Long applicationId) {
        Candidate candidate = getCurrentCandidate(currentUser);
        Candidature application = candidatureRepository.findById(applicationId)
                .orElseThrow(() -> new RuntimeException("Candidature introuvable."));
        if (application.getCandidate() == null || !Objects.equals(application.getCandidate().getId(), candidate.getId())) {
            throw new RuntimeException("Vous ne pouvez consulter que vos propres tests.");
        }
        AiTest aiTest = aiTestRepository.findTopByApplication_IdOrderByCreatedAtDesc(applicationId)
                .orElseGet(() -> createApplicationAiTestFromValidatedOffer(application));
        if (aiTest == null) {
            throw new RuntimeException("Aucun Test IA disponible pour cette candidature.");
        }
        aiTest = syncNotStartedApplicationTestWithOfferTemplate(aiTest);
        return toResponse(refreshExpiredIfNeeded(aiTest), null, null, null, false);
    }

    @Transactional
    public AiTest createApplicationAiTestFromValidatedOffer(Candidature application) {
        if (application == null || application.getId() == null || application.getOffre() == null) {
            return null;
        }

        AiTest existing = aiTestRepository.findTopByApplication_IdOrderByCreatedAtDesc(application.getId()).orElse(null);
        if (existing != null) {
            return existing;
        }

        AiTest template = aiTestRepository.findTopByJobOffer_IdAndApplicationIsNullOrderByCreatedAtDesc(application.getOffre().getId())
                .orElse(null);
        String templateStatus = template == null ? "" : normalizeAiTestStatus(template.getStatus());
        if (template == null || (!TEST_STATUS_VALIDATED.equals(templateStatus) && !TEST_STATUS_PUBLISHED.equals(templateStatus))) {
            return null;
        }

        Date now = new Date();
        AiTest cloned = AiTest.builder()
                .application(application)
                .jobOffer(application.getOffre())
                .candidate(application.getCandidate())
                .recruiter(application.getOffre().getRecruiter())
                .title(template.getTitle())
                .description(template.getDescription())
                .numberOfQuestions(template.getNumberOfQuestions())
                .passingScore(template.getPassingScore())
                .totalDurationSeconds(template.getTotalDurationSeconds())
                .difficulty(template.getDifficulty())
                .allowPreviousQuestion(template.getAllowPreviousQuestion())
                .evaluationSkillsJson(template.getEvaluationSkillsJson())
                .status(TEST_STATUS_NOT_STARTED)
                .threshold(template.getThreshold() == null ? template.getPassingScore() : template.getThreshold())
                .durationMinutes(template.getDurationMinutes())
                .score(null)
                .report("")
                .recommendation("")
                .proposedRejectionEmail("")
                .createdAt(now)
                .updatedAt(now)
                .closedReason("")
                .cheatingSuspicion(false)
                .tabSwitchCount(0)
                .warningCount(0)
                .build();
        AiTest savedTest = aiTestRepository.save(cloned);

        List<AiQuestion> templateQuestions = aiQuestionRepository.findByAiTest_IdOrderByOrderIndexAscIdAsc(template.getId());
        List<AiQuestion> copiedQuestions = templateQuestions.stream()
                .map(question -> AiQuestion.builder()
                        .aiTest(savedTest)
                        .questionText(question.getQuestionText())
                        .questionType(question.getQuestionType())
                        .optionsJson(question.getOptionsJson())
                        .correctAnswer(question.getCorrectAnswer())
                        .expectedKeywordsJson(question.getExpectedKeywordsJson())
                        .points(question.getPoints())
                        .orderIndex(question.getOrderIndex())
                        .timeLimitSeconds(question.getTimeLimitSeconds())
                        .acceptedByRecruiter(Boolean.TRUE)
                        .createdAt(now)
                        .updatedAt(now)
                        .build())
                .collect(Collectors.toList());
        aiQuestionRepository.saveAll(copiedQuestions);

        savedTest.setTotalDurationSeconds(computeTotalDurationSeconds(copiedQuestions));
        savedTest.setDurationMinutes((int) Math.ceil(savedTest.getTotalDurationSeconds() / 60d));
        savedTest.setNumberOfQuestions(copiedQuestions.size());
        return aiTestRepository.save(savedTest);
    }

    private AiTest syncNotStartedApplicationTestWithOfferTemplate(AiTest aiTest) {
        if (aiTest == null || aiTest.getApplication() == null || aiTest.getJobOffer() == null) {
            return aiTest;
        }
        if (!TEST_STATUS_NOT_STARTED.equals(normalizeAiTestStatus(aiTest.getStatus()))) {
            return aiTest;
        }

        AiTest template = aiTestRepository.findTopByJobOffer_IdAndApplicationIsNullOrderByCreatedAtDesc(aiTest.getJobOffer().getId())
                .orElse(null);
        String templateStatus = template == null ? "" : normalizeAiTestStatus(template.getStatus());
        if (template == null || (!TEST_STATUS_VALIDATED.equals(templateStatus) && !TEST_STATUS_PUBLISHED.equals(templateStatus))) {
            return aiTest;
        }

        List<AiQuestion> templateQuestions = aiQuestionRepository.findByAiTest_IdOrderByOrderIndexAscIdAsc(template.getId());
        if (templateQuestions.isEmpty()) {
            return aiTest;
        }

        Date now = new Date();
        aiQuestionRepository.deleteAll(aiQuestionRepository.findByAiTest_IdOrderByIdAsc(aiTest.getId()));
        List<AiQuestion> copiedQuestions = templateQuestions.stream()
                .map(question -> AiQuestion.builder()
                        .aiTest(aiTest)
                        .questionText(question.getQuestionText())
                        .questionType(question.getQuestionType())
                        .optionsJson(question.getOptionsJson())
                        .correctAnswer(question.getCorrectAnswer())
                        .expectedKeywordsJson(question.getExpectedKeywordsJson())
                        .points(question.getPoints())
                        .orderIndex(question.getOrderIndex())
                        .timeLimitSeconds(question.getTimeLimitSeconds())
                        .acceptedByRecruiter(Boolean.TRUE)
                        .createdAt(now)
                        .updatedAt(now)
                        .build())
                .collect(Collectors.toList());
        aiQuestionRepository.saveAll(copiedQuestions);

        aiTest.setTitle(template.getTitle());
        aiTest.setDescription(template.getDescription());
        aiTest.setPassingScore(template.getPassingScore());
        aiTest.setThreshold(template.getThreshold() == null ? template.getPassingScore() : template.getThreshold());
        aiTest.setDifficulty(template.getDifficulty());
        aiTest.setAllowPreviousQuestion(template.getAllowPreviousQuestion());
        aiTest.setEvaluationSkillsJson(template.getEvaluationSkillsJson());
        aiTest.setNumberOfQuestions(copiedQuestions.size());
        aiTest.setTotalDurationSeconds(computeTotalDurationSeconds(copiedQuestions));
        aiTest.setDurationMinutes(resolveDurationMinutes(aiTest.getTotalDurationSeconds(), template.getDurationMinutes()));
        aiTest.setUpdatedAt(now);
        return aiTestRepository.save(aiTest);
    }

    @Transactional
    public AiTestResponse createRecruiterAiTest(
            User currentUser,
            Long applicationId,
            Double requestedThreshold,
            Integer requestedDurationMinutes
) {
    Recruiter recruiter = getCurrentRecruiter(currentUser);
    Candidature application = candidatureRepository.findByIdAndOffre_Recruiter_Id(applicationId, recruiter.getId())
            .orElseThrow(() -> new RuntimeException("Candidature introuvable."));

        Candidate candidate = application.getCandidate();
        Offre offer = application.getOffre();
        if (candidate == null || offer == null) {
            throw new RuntimeException("Impossible de generer un test pour une candidature incomplete.");
        }

        AiTest latestExisting = aiTestRepository.findTopByApplication_IdOrderByCreatedAtDesc(applicationId).orElse(null);
        if (latestExisting != null && isActiveAiTest(latestExisting)) {
            throw new RuntimeException("Un test IA est deja en attente pour cette candidature.");
        }

        double threshold = normalizeThreshold(requestedThreshold);
        int durationMinutes = normalizeDurationMinutes(requestedDurationMinutes);
        Integer requestedQuestionCount = resolveOfferTemplateQuestionCount(offer);
        GeneratedTestPayload generatedTestPayload = generateTestPayload(application, threshold, requestedQuestionCount);

        AiTest aiTest = AiTest.builder()
                .application(application)
                .jobOffer(offer)
                .candidate(candidate)
                .recruiter(recruiter)
                .status(TEST_STATUS_NOT_STARTED)
                .threshold(threshold)
                .durationMinutes(durationMinutes)
                .score(null)
                .report(generatedTestPayload.message())
                .recommendation("")
                .proposedRejectionEmail("")
                .createdAt(new Date())
                .startedAt(null)
                .expiresAt(null)
                .submittedAt(null)
                .completedAt(null)
                .closedReason("")
                .cheatingSuspicion(false)
                .tabSwitchCount(0)
                .warningCount(0)
                .build();

        AiTest savedTest = aiTestRepository.save(aiTest);
        List<AiQuestion> questions = generatedTestPayload.questions().stream()
                .map(item -> toEntity(savedTest, item))
                .toList();
        aiQuestionRepository.saveAll(questions);
        savedTest.setTotalDurationSeconds(computeTotalDurationSeconds(questions));
        savedTest.setDurationMinutes(resolveDurationMinutes(savedTest.getTotalDurationSeconds(), savedTest.getDurationMinutes()));
        savedTest.setNumberOfQuestions(questions.size());
        savedTest.setUpdatedAt(new Date());
        AiTest refreshedTest = aiTestRepository.save(savedTest);

        application.setStatut(APP_STATUS_AI_TEST_SENT);
        candidatureRepository.save(application);

        notificationService.notifyUser(
                candidate,
                "Un test IA vous a ete envoye pour l'offre \"" + safe(offer.getTitre()) + "\"."
        );

        return toResponse(refreshedTest, questions, List.of(), null, false);
    }

    @Transactional
    public List<AiTestResponse> getCandidateAiTests(User currentUser) {
        Candidate candidate = getCurrentCandidate(currentUser);
        return aiTestRepository.findByCandidate_IdOrderByCreatedAtDesc(candidate.getId()).stream()
                .map(this::refreshExpiredIfNeeded)
                .map(test -> toResponse(test, null, null, null, false))
                .toList();
    }

    @Transactional
    public AiTestResponse getCandidateAiTest(User currentUser, Long testId) {
        Candidate candidate = getCurrentCandidate(currentUser);
        AiTest aiTest = aiTestRepository.findByIdAndCandidate_Id(testId, candidate.getId())
                .orElseThrow(() -> new RuntimeException("Test IA introuvable."));
        aiTest = syncNotStartedApplicationTestWithOfferTemplate(aiTest);
        aiTest = refreshExpiredIfNeeded(aiTest);
        return toResponse(aiTest, null, null, null, false);
    }

    @Transactional
    public AiTestResponse startCandidateAiTest(User currentUser, Long testId) {
        Candidate candidate = getCurrentCandidate(currentUser);
        AiTest aiTest = aiTestRepository.findByIdAndCandidate_Id(testId, candidate.getId())
                .orElseThrow(() -> new RuntimeException("Test IA introuvable."));
        aiTest = refreshExpiredIfNeeded(aiTest);

        String status = normalizeAiTestStatus(aiTest.getStatus());
        if (TEST_STATUS_SUBMITTED.equals(status)) {
            throw new RuntimeException("Ce test IA a deja ete soumis.");
        }
        if (TEST_STATUS_EXPIRED.equals(status) || TEST_STATUS_CHEATING_SUSPECTED.equals(status) || TEST_STATUS_CLOSED.equals(status)) {
            throw new RuntimeException("Ce test IA n'est plus disponible.");
        }

        if (!TEST_STATUS_IN_PROGRESS.equals(status)) {
            Date now = new Date();
            int durationSeconds = resolveTestDurationSeconds(aiTest);
            aiTest.setStatus(TEST_STATUS_IN_PROGRESS);
            aiTest.setStartedAt(now);
            aiTest.setExpiresAt(new Date(now.getTime() + (durationSeconds * 1000L)));
            aiTest.setClosedReason("");
            aiTest.setWarningCount(safeInteger(aiTest.getWarningCount()));
            aiTest.setTabSwitchCount(safeInteger(aiTest.getTabSwitchCount()));
            aiTest.setCheatingSuspicion(false);
            aiTestRepository.save(aiTest);
        }
        AiTestResult result = initializeOrResumeResult(aiTest, candidate);
        result.setStatus(TEST_STATUS_IN_PROGRESS);
        result.setUpdatedAt(new Date());
        aiTestResultRepository.save(result);
        aiTest.setResult(result);
        if (aiTest.getApplication() != null) {
            aiTest.getApplication().setStatut("AI_TEST_IN_PROGRESS");
            candidatureRepository.save(aiTest.getApplication());
        }
        aiTestRepository.save(aiTest);
        return toResponse(aiTest, null, null, result, false);
    }

    @Transactional
    public AiTestResponse getCurrentQuestion(User currentUser, Long resultId) {
        Candidate candidate = getCurrentCandidate(currentUser);
        AiTestResult result = aiTestResultRepository.findByIdAndCandidate_Id(resultId, candidate.getId())
                .orElseThrow(() -> new RuntimeException("Session de test introuvable."));
        AiTest aiTest = refreshExpiredIfNeeded(result.getAiTest());
        if (TEST_STATUS_EXPIRED.equals(normalizeAiTestStatus(aiTest.getStatus()))) {
            result.setStatus(TEST_STATUS_EXPIRED);
            aiTestResultRepository.save(result);
        }
        return buildCurrentQuestionResponse(aiTest, result, false);
    }

    @Transactional
    public AiTestResponse answerCurrentQuestion(User currentUser, Long resultId, AiTestQuestionAnswerRequest request) {
        Candidate candidate = getCurrentCandidate(currentUser);
        AiTestResult result = aiTestResultRepository.findByIdAndCandidate_Id(resultId, candidate.getId())
                .orElseThrow(() -> new RuntimeException("Session de test introuvable."));
        AiTest aiTest = refreshExpiredIfNeeded(result.getAiTest());
        ensureResultEditable(aiTest, result);

        AiQuestion question = resolveCurrentQuestion(aiTest, result);
        if (request != null && request.getQuestionId() != null && !Objects.equals(request.getQuestionId(), question.getId())) {
            throw new RuntimeException("La question soumise ne correspond pas a la question courante.");
        }

        String submittedAnswer = safe(request == null ? "" : request.getCandidateAnswer());
        persistAnswer(result, aiTest, question, submittedAnswer, request == null ? null : request.getTimeSpentSeconds());
        return buildCurrentQuestionResponse(aiTest, result, false);
    }

    @Transactional
    public AiTestResponse moveToNextQuestion(User currentUser, Long resultId) {
        Candidate candidate = getCurrentCandidate(currentUser);
        AiTestResult result = aiTestResultRepository.findByIdAndCandidate_Id(resultId, candidate.getId())
                .orElseThrow(() -> new RuntimeException("Session de test introuvable."));
        AiTest aiTest = refreshExpiredIfNeeded(result.getAiTest());
        ensureResultEditable(aiTest, result);

        List<AiQuestion> questions = aiQuestionRepository.findByAiTest_IdOrderByOrderIndexAscIdAsc(aiTest.getId());
        int nextIndex = Math.min(questions.size() - 1, safeInteger(result.getCurrentQuestionIndex()) + 1);
        result.setCurrentQuestionIndex(nextIndex);
        stampCurrentQuestionWindow(result, questions.get(nextIndex));
        result.setUpdatedAt(new Date());
        aiTestResultRepository.save(result);

        return buildCurrentQuestionResponse(aiTest, result, false);
    }

    @Transactional
    public AiTestResponse submitCandidateAiTestResult(User currentUser, Long resultId) {
        Candidate candidate = getCurrentCandidate(currentUser);
        AiTestResult result = aiTestResultRepository.findByIdAndCandidate_Id(resultId, candidate.getId())
                .orElseThrow(() -> new RuntimeException("Session de test introuvable."));
        AiTest aiTest = refreshExpiredIfNeeded(result.getAiTest());

        List<AiAnswer> answers = aiAnswerRepository.findByAiTestResult_IdOrderByIdAsc(resultId);
        List<AiAnswerSubmissionRequest> submissions = answers.stream().map(answer -> {
            AiAnswerSubmissionRequest item = new AiAnswerSubmissionRequest();
            item.setQuestionId(answer.getQuestion() == null ? null : answer.getQuestion().getId());
            item.setCandidateAnswer(answer.getCandidateAnswer());
            item.setTimeSpentSeconds(answer.getTimeSpentSeconds());
            return item;
        }).toList();

        SubmitAiTestRequest request = new SubmitAiTestRequest();
        request.setAnswers(submissions);
        return submitCandidateAiTest(currentUser, aiTest.getId(), request);
    }

    @Transactional
    public AiTestResponse registerSecurityEvent(User currentUser, Long testId, AiTestSecurityEventRequest request) {
        Candidate candidate = getCurrentCandidate(currentUser);
        AiTest aiTest = aiTestRepository.findByIdAndCandidate_Id(testId, candidate.getId())
                .orElseThrow(() -> new RuntimeException("Test IA introuvable."));
        aiTest = refreshExpiredIfNeeded(aiTest);

        String status = normalizeAiTestStatus(aiTest.getStatus());
        if (!TEST_STATUS_IN_PROGRESS.equals(status)) {
            return toResponse(aiTest, null, null, null, false);
        }

        String eventType = safe(request == null ? "" : request.getEventType()).toUpperCase(Locale.ROOT);
        String description = safe(request == null ? "" : request.getDescription());

        if (EVENT_TAB_SWITCH.equals(eventType)) {
            aiTest.setTabSwitchCount(safeInteger(aiTest.getTabSwitchCount()) + 1);
        }

        int warningCount = safeInteger(aiTest.getWarningCount()) + 1;
        aiTest.setWarningCount(warningCount);

        if (warningCount >= MAX_WARNING_COUNT) {
            aiTest = closeForCheatingSuspicion(
                    aiTest,
                    description.isBlank()
                            ? "Le candidat a quitte la page du test ou change d'onglet pendant l'examen."
                            : description
            );
        } else {
            aiTestRepository.save(aiTest);
        }

        return toResponse(aiTest, null, null, null, false);
    }

    @Transactional
    public AiTestResponse reopenRecruiterAiTest(User currentUser, Long testId) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        AiTest aiTest = aiTestRepository.findByIdAndRecruiter_Id(testId, recruiter.getId())
                .orElseThrow(() -> new RuntimeException("Test IA introuvable."));

        String status = normalizeAiTestStatus(aiTest.getStatus());
        if (!TEST_STATUS_CHEATING_SUSPECTED.equals(status)
                && !TEST_STATUS_EXPIRED.equals(status)
                && !TEST_STATUS_CLOSED.equals(status)) {
            throw new RuntimeException("Ce test IA ne peut pas etre reouvert dans son etat actuel.");
        }

        aiAnswerRepository.deleteAll(aiAnswerRepository.findByAiTest_IdOrderByIdAsc(aiTest.getId()));
        aiTestResultRepository.findByAiTest_Id(aiTest.getId()).ifPresent(aiTestResultRepository::delete);

        aiTest.setStatus(TEST_STATUS_NOT_STARTED);
        aiTest.setScore(null);
        aiTest.setRecommendation("");
        aiTest.setReport(nonEmpty(aiTest.getReport(), "Le test IA a ete reouvert par le recruteur."));
        aiTest.setProposedRejectionEmail("");
        aiTest.setStartedAt(null);
        aiTest.setExpiresAt(null);
        aiTest.setSubmittedAt(null);
        aiTest.setCompletedAt(null);
        aiTest.setClosedReason("");
        aiTest.setCheatingSuspicion(false);
        aiTest.setTabSwitchCount(0);
        aiTest.setWarningCount(0);
        aiTest.setResult(null);
        AiTest saved = aiTestRepository.save(aiTest);

        if (aiTest.getApplication() != null) {
            aiTest.getApplication().setStatut(APP_STATUS_AI_TEST_SENT);
            candidatureRepository.save(aiTest.getApplication());
        }

        if (aiTest.getCandidate() != null) {
            notificationService.notifyUser(
                    aiTest.getCandidate(),
                    "Votre test IA pour l'offre \"" + safe(aiTest.getJobOffer() == null ? "" : aiTest.getJobOffer().getTitre())
                            + "\" a ete reouvert par le recruteur."
            );
        }

        return toResponse(saved, null, List.of(), null, false);
    }

    @Transactional
    public AiTestResponse submitCandidateAiTest(User currentUser, Long testId, SubmitAiTestRequest request) {
        Candidate candidate = getCurrentCandidate(currentUser);
        AiTest aiTest = aiTestRepository.findByIdAndCandidate_Id(testId, candidate.getId())
                .orElseThrow(() -> new RuntimeException("Test IA introuvable."));
        aiTest = refreshExpiredIfNeeded(aiTest);

        String aiTestStatus = normalizeAiTestStatus(aiTest.getStatus());
        if (TEST_STATUS_SUBMITTED.equals(aiTestStatus)) {
            throw new RuntimeException("Ce test IA a deja ete soumis.");
        }
        if (TEST_STATUS_CHEATING_SUSPECTED.equals(aiTestStatus) || TEST_STATUS_CLOSED.equals(aiTestStatus)) {
            throw new RuntimeException("Ce test IA a ete ferme et ne peut plus etre soumis.");
        }
        if (TEST_STATUS_EXPIRED.equals(aiTestStatus) && !Boolean.TRUE.equals(request == null ? null : request.getAutoSubmit())) {
            throw new RuntimeException("Le temps du test est termine.");
        }

        List<AiQuestion> questions = aiQuestionRepository.findByAiTest_IdOrderByIdAsc(aiTest.getId());
        if (questions.isEmpty()) {
            throw new RuntimeException("Le test IA ne contient aucune question.");
        }

        List<AiAnswerSubmissionRequest> submittedAnswers = request == null || request.getAnswers() == null
                ? List.of()
                : request.getAnswers();

        boolean autoSubmit = Boolean.TRUE.equals(request == null ? null : request.getAutoSubmit());

        EvaluationPayload evaluation = evaluateAnswers(aiTest, questions, submittedAnswers);
        final AiTest targetAiTest = aiTest;
        AiTestResult result = aiTestResultRepository.findByAiTest_Id(aiTest.getId()).orElseGet(AiTestResult::new);
        result.setAiTest(aiTest);
        result.setCandidature(aiTest.getApplication());
        result.setCandidate(aiTest.getCandidate());
        result.setStartedAt(aiTest.getStartedAt());
        result.setSubmittedAt(new Date());
        result.setUpdatedAt(new Date());
        result.setStatus(TEST_STATUS_SUBMITTED);

        aiAnswerRepository.deleteAll(aiAnswerRepository.findByAiTest_IdOrderByIdAsc(targetAiTest.getId()));

        List<AiAnswer> persistedAnswers = evaluation.answerDetails().stream()
                .map(detail -> AiAnswer.builder()
                        .aiTest(targetAiTest)
                        .aiTestResult(result)
                        .question(detail.question())
                        .candidateAnswer(detail.candidateAnswer())
                        .correct(detail.correct())
                        .pointsObtained(detail.pointsObtained())
                        .answeredAt(new Date())
                        .timeSpentSeconds(findTimeSpentSeconds(submittedAnswers, detail.question().getId()))
                        .build())
                .collect(Collectors.toList());
        AiTestResult savedResult = aiTestResultRepository.save(result);
        persistedAnswers.forEach(answer -> answer.setAiTestResult(savedResult));
        aiAnswerRepository.saveAll(persistedAnswers);
        savedResult.setGlobalScore(evaluation.globalScore());
        savedResult.setScore(evaluation.globalScore());
        savedResult.setStrengths(writeStringList(evaluation.strengths()));
        savedResult.setWeaknesses(writeStringList(evaluation.weaknesses()));
        savedResult.setRecommendation(evaluation.recommendation());
        savedResult.setGeneratedReport(evaluation.generatedReport());
        savedResult.setCurrentQuestionIndex(questions.isEmpty() ? 0 : questions.size() - 1);
        savedResult.setCurrentQuestionStartedAt(null);
        savedResult.setCurrentQuestionExpiresAt(null);
        aiTestResultRepository.save(savedResult);

        aiTest.setScore(evaluation.globalScore());
        aiTest.setStatus(TEST_STATUS_SUBMITTED);
        aiTest.setSubmittedAt(new Date());
        aiTest.setCompletedAt(new Date());
        aiTest.setUpdatedAt(new Date());
        aiTest.setRecommendation(evaluation.recommendation());
        aiTest.setReport(buildCompletionSummary(evaluation.summaryMessage(), autoSubmit, request == null ? null : request.getSubmitReason()));
        aiTest.setProposedRejectionEmail(evaluation.proposedRejectionEmail());
        aiTest.setClosedReason(autoSubmit ? safe(request == null ? "" : request.getSubmitReason()) : "");
        aiTest.setResult(savedResult);
        AiTest savedTest = aiTestRepository.save(aiTest);

        Candidature application = aiTest.getApplication();
        if (application != null) {
            application.setStatut(
                    APP_STATUS_INTERVIEW.equals(evaluation.recommendation())
                            ? APP_STATUS_INTERVIEW
                            : APP_STATUS_REJECTION_SUGGESTED
            );
            candidatureRepository.save(application);
        }

        Recruiter recruiter = aiTest.getRecruiter();
        if (recruiter != null) {
            String candidateName = candidate.getNom() == null || candidate.getNom().isBlank() ? "Le candidat" : candidate.getNom();
            String offerTitle = aiTest.getJobOffer() == null ? "" : safe(aiTest.getJobOffer().getTitre());
            notificationService.notifyUser(
                    recruiter,
                    candidateName + " a termine son test IA pour l'offre \"" + offerTitle + "\". Score : "
                            + Math.round(evaluation.globalScore()) + "%."
            );
        }

        return toResponse(savedTest, questions, persistedAnswers, savedResult, true);
    }

    @Transactional
    public AiTestResponse getRecruiterAiTestResult(User currentUser, Long testId) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        AiTest aiTest = aiTestRepository.findByIdAndRecruiter_Id(testId, recruiter.getId())
                .orElseThrow(() -> new RuntimeException("Resultat de test IA introuvable."));
        aiTest = refreshExpiredIfNeeded(aiTest);
        return toResponse(aiTest, null, null, null, true);
    }

    @Transactional
    public MessageResponse rejectAfterAiTest(User currentUser, Long applicationId, RejectAfterAiTestRequest request) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        Candidature application = candidatureRepository.findByIdAndOffre_Recruiter_Id(applicationId, recruiter.getId())
                .orElseThrow(() -> new RuntimeException("Candidature introuvable."));

        AiTest aiTest = aiTestRepository.findTopByApplication_IdOrderByCreatedAtDesc(applicationId)
                .orElseThrow(() -> new RuntimeException("Aucun test IA n'est associe a cette candidature."));

        String recommendation = safe(aiTest.getRecommendation()).toUpperCase(Locale.ROOT);
        if (!APP_STATUS_REJECTION_SUGGESTED.equals(recommendation) && !APP_STATUS_REJECTION_SUGGESTED.equals(normalizeApplicationStatus(application.getStatut()))) {
            throw new RuntimeException("Le systeme n'a pas propose de refus pour cette candidature.");
        }

        String emailBody = safe(request == null ? "" : request.getEmailBody());
        if (emailBody.isBlank()) {
            emailBody = safe(aiTest.getProposedRejectionEmail());
        }
        if (emailBody.isBlank()) {
            emailBody = buildDefaultRejectionEmail(aiTest);
        }

        boolean emailSent = true;
        try {
            emailService.sendAiTestRejectionEmail(
                    aiTest.getCandidate() == null ? "" : aiTest.getCandidate().getEmail(),
                    "Suite a votre candidature - " + safe(aiTest.getJobOffer() == null ? "" : aiTest.getJobOffer().getTitre()),
                    emailBody
            );
        } catch (RuntimeException ex) {
            emailSent = false;
            logger.error("Echec d'envoi de l'email de refus apres test IA pour la candidature {}", applicationId, ex);
        }

        application.setStatut(APP_STATUS_REJECTED);
        candidatureRepository.save(application);

        if (aiTest.getCandidate() != null) {
            notificationService.notifyUser(
                    aiTest.getCandidate(),
                    "Votre candidature pour \"" + safe(aiTest.getJobOffer() == null ? "" : aiTest.getJobOffer().getTitre())
                            + "\" n'a pas ete retenue pour la suite du processus."
            );
        }

        return new MessageResponse(
                true,
                emailSent
                        ? "Le refus a ete valide et l'email a ete envoye au candidat."
                        : "Le refus a ete valide, mais l'email n'a pas pu etre envoye."
        );
    }

    public static String normalizeApplicationStatus(String value) {
        String normalized = safe(value).toUpperCase(Locale.ROOT);
        return switch (normalized) {
            case "A_TRIER", "APPLIED" -> APP_STATUS_APPLIED;
            case APP_STATUS_AI_TEST_SENT, "TEST_IA_ENVOYE" -> APP_STATUS_AI_TEST_SENT;
            case "AI_TEST_IN_PROGRESS", "TEST_IA_EN_COURS" -> "AI_TEST_IN_PROGRESS";
            case APP_STATUS_AI_TEST_COMPLETED, "TEST_IA_TERMINE" -> APP_STATUS_AI_TEST_COMPLETED;
            case "ENTRETIEN", APP_STATUS_INTERVIEW -> APP_STATUS_INTERVIEW;
            case "ENTRETIEN_PLANIFIE", "INTERVIEW_SCHEDULED" -> InterviewService.APP_STATUS_INTERVIEW_SCHEDULED;
            case "ENTRETIEN_EN_COURS", "INTERVIEW_IN_PROGRESS" -> InterviewService.APP_STATUS_INTERVIEW_IN_PROGRESS;
            case "ABSENCE_A_VERIFIER", "ABSENCE_TO_VERIFY" -> InterviewService.APP_STATUS_ABSENCE_TO_VERIFY;
            case "REFUS_PROPOSE", "SUSPICION_TRICHE", APP_STATUS_REJECTION_SUGGESTED -> APP_STATUS_REJECTION_SUGGESTED;
            case "REFUSE", APP_STATUS_REJECTED -> APP_STATUS_REJECTED;
            case "RETAINED", APP_STATUS_RETAINED -> APP_STATUS_RETAINED;
            default -> normalized;
        };
    }

    public static String normalizeAiTestStatus(String value) {
        String normalized = safe(value).toUpperCase(Locale.ROOT);
        return switch (normalized) {
            case APP_STATUS_AI_TEST_SENT -> TEST_STATUS_NOT_STARTED;
            case APP_STATUS_AI_TEST_COMPLETED -> TEST_STATUS_SUBMITTED;
            case APP_STATUS_REJECTION_SUGGESTED -> TEST_STATUS_CHEATING_SUSPECTED;
            default -> normalized;
        };
    }

    private boolean isActiveAiTest(AiTest aiTest) {
        if (aiTest == null) {
            return false;
        }

        String status = normalizeAiTestStatus(aiTest.getStatus());
        return TEST_STATUS_NOT_STARTED.equals(status) || TEST_STATUS_IN_PROGRESS.equals(status);
    }

    private AiTest refreshExpiredIfNeeded(AiTest aiTest) {
        if (aiTest == null) {
            return null;
        }

        String status = normalizeAiTestStatus(aiTest.getStatus());
        Date expiresAt = aiTest.getExpiresAt();
        if (expiresAt != null
                && TEST_STATUS_IN_PROGRESS.equals(status)
                && expiresAt.before(new Date())) {
            return expireAiTest(aiTest, "Le temps du test est termine.");
        }

        return aiTest;
    }

    private AiTest expireAiTest(AiTest aiTest, String reason) {
        Date now = new Date();
        String closeReason = nonEmpty(reason, "Le temps du test est termine.");
        aiTest.setStatus(TEST_STATUS_EXPIRED);
        aiTest.setCompletedAt(now);
        aiTest.setClosedReason(closeReason);
        aiTest.setCheatingSuspicion(false);
        aiTest.setRecommendation(APP_STATUS_REJECTION_SUGGESTED);
        aiTest.setReport("Le test IA a expire avant la soumission complete du candidat. Un refus est propose au recruteur.");
        aiTest.setProposedRejectionEmail(buildExpiredTestRejectionEmail(aiTest));
        AiTest saved = aiTestRepository.save(aiTest);

        if (saved.getApplication() != null) {
            saved.getApplication().setStatut(APP_STATUS_REJECTION_SUGGESTED);
            candidatureRepository.save(saved.getApplication());
        }

        if (saved.getRecruiter() != null) {
            notificationService.notifyUser(
                    saved.getRecruiter(),
                    "Le test IA du candidat " + safe(saved.getCandidate() == null ? "" : saved.getCandidate().getNom())
                            + " a expire. La candidature est placee en refus propose."
            );
        }

        return saved;
    }

    private AiTest closeForCheatingSuspicion(AiTest aiTest, String reason) {
        Date now = new Date();
        aiTest.setStatus(TEST_STATUS_CHEATING_SUSPECTED);
        aiTest.setCompletedAt(now);
        aiTest.setCheatingSuspicion(true);
        aiTest.setClosedReason(nonEmpty(reason, "Le candidat a quitte la page du test ou change d'onglet."));
        aiTest.setRecommendation(APP_STATUS_REJECTION_SUGGESTED);
        aiTest.setReport("Le test a ete ferme automatiquement suite a une suspicion de triche.");
        aiTest.setProposedRejectionEmail(buildSuspicionRejectionEmail(aiTest));
        AiTest saved = aiTestRepository.save(aiTest);

        Candidature application = saved.getApplication();
        if (application != null) {
            application.setStatut(APP_STATUS_REJECTION_SUGGESTED);
            candidatureRepository.save(application);
        }

        if (saved.getRecruiter() != null) {
            notificationService.notifyUser(
                    saved.getRecruiter(),
                    "Le test IA du candidat " + safe(saved.getCandidate() == null ? "" : saved.getCandidate().getNom())
                            + " a ete ferme automatiquement suite a une suspicion de triche."
            );
        }

        return saved;
    }

    private static int normalizeDurationMinutes(Integer value) {
        if (value == null) {
            return DEFAULT_TEST_DURATION_MINUTES;
        }
        return Math.max(5, Math.min(120, value));
    }

    private int resolveQuestionCount(Integer requestedValue, Integer fallbackValue) {
        Integer source = requestedValue != null ? requestedValue : fallbackValue;
        if (source == null) {
            return 1;
        }
        return Math.max(1, Math.min(120, source));
    }

    private Integer resolveOfferTemplateQuestionCount(Offre offer) {
        if (offer == null || offer.getId() == null) {
            return null;
        }
        return aiTestRepository.findTopByJobOffer_IdAndApplicationIsNullOrderByCreatedAtDesc(offer.getId())
                .map(AiTest::getNumberOfQuestions)
                .map(value -> resolveQuestionCount(value, null))
                .orElse(null);
    }

    private String normalizeQuestionType(String value) {
        String normalized = safe(value).trim().toUpperCase(Locale.ROOT);
        if (QUESTION_TYPE_QCM.equals(normalized) || QUESTION_TYPE_MCQ.equals(normalized)) {
            return QUESTION_TYPE_MCQ;
        }
        if (QUESTION_TYPE_SCENARIO.equals(normalized)) {
            return QUESTION_TYPE_SCENARIO;
        }
        return QUESTION_TYPE_SHORT;
    }

    private List<GeneratedQuestionPayload> enforceQuestionCount(
            List<GeneratedQuestionPayload> generatedQuestions,
            Offre offer,
            Integer requestedQuestionCount
    ) {
        int desiredCount = resolveQuestionCount(requestedQuestionCount, generatedQuestions == null ? null : generatedQuestions.size());
        List<GeneratedQuestionPayload> sanitized = generatedQuestions == null ? new ArrayList<>() : new ArrayList<>(generatedQuestions);
        if (sanitized.size() > desiredCount) {
            return new ArrayList<>(sanitized.subList(0, desiredCount));
        }
        if (sanitized.size() == desiredCount) {
            return sanitized;
        }

        List<GeneratedQuestionPayload> fallbackQuestions = buildLocalOfferQuestions(offer, desiredCount);
        int fallbackIndex = 0;
        while (sanitized.size() < desiredCount && !fallbackQuestions.isEmpty()) {
            sanitized.add(fallbackQuestions.get(fallbackIndex % fallbackQuestions.size()));
            fallbackIndex++;
        }
        return sanitized;
    }

    private static int resolveDurationMinutes(Integer totalDurationSeconds, Integer fallbackDurationMinutes) {
        if (totalDurationSeconds != null && totalDurationSeconds > 0) {
            return (int) Math.ceil(totalDurationSeconds / 60d);
        }
        if (fallbackDurationMinutes != null && fallbackDurationMinutes > 0) {
            return Math.max(1, fallbackDurationMinutes);
        }
        return 0;
    }

    private static int safeInteger(Integer value) {
        return value == null ? 0 : Math.max(0, value);
    }

    private static Long computeTimeRemainingSeconds(AiTest aiTest) {
        if (aiTest == null || aiTest.getExpiresAt() == null) {
            return null;
        }

        long remaining = (aiTest.getExpiresAt().getTime() - System.currentTimeMillis()) / 1000L;
        return Math.max(0L, remaining);
    }

    private GeneratedTestPayload generateTestPayload(Candidature application, double threshold, Integer requestedQuestionCount) {
        if (pythonGroqAgentService.isConfigured()) {
            try {
                JsonNode response = pythonGroqAgentService.invoke("generate_ai_test", buildAiGenerationPayload(application, threshold));
                List<GeneratedQuestionPayload> questions = parseGeneratedQuestions(response.get("questions"));
                if (!questions.isEmpty()) {
                    return new GeneratedTestPayload(
                            readText(response, "message", "Test IA genere avec succes."),
                            enforceQuestionCount(questions, application.getOffre(), requestedQuestionCount)
                    );
                }
            } catch (RuntimeException ex) {
                logger.warn("Generation Groq du test IA indisponible, fallback local active : {}", ex.getMessage());
            }
        }

        return buildLocalGeneratedTest(application, threshold, requestedQuestionCount);
    }

    private EvaluationPayload evaluateAnswers(
            AiTest aiTest,
            List<AiQuestion> questions,
            List<AiAnswerSubmissionRequest> submittedAnswers
    ) {
        Map<Long, String> answersByQuestionId = submittedAnswers.stream()
                .filter(item -> item.getQuestionId() != null)
                .collect(Collectors.toMap(
                        AiAnswerSubmissionRequest::getQuestionId,
                        item -> safe(item.getCandidateAnswer()),
                        (existing, replacement) -> replacement,
                        LinkedHashMap::new
                ));

        if (pythonGroqAgentService.isConfigured()) {
            try {
                JsonNode response = pythonGroqAgentService.invoke("evaluate_ai_test", buildAiEvaluationPayload(aiTest, questions, answersByQuestionId));
                EvaluationPayload aiEvaluation = parseAiEvaluation(aiTest, questions, answersByQuestionId, response);
                if (aiEvaluation != null) {
                    return aiEvaluation;
                }
            } catch (RuntimeException ex) {
                logger.warn("Evaluation Groq du test IA indisponible, fallback local active : {}", ex.getMessage());
            }
        }

        return evaluateLocally(aiTest, questions, answersByQuestionId);
    }

    private Map<String, Object> buildAiGenerationPayload(Candidature application, double threshold) {
        Offre offer = application.getOffre();
        List<OffreCompetenceRequest> skills = readOfferSkills(offer == null ? null : offer.getCompetencesJson());

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("applicationId", application.getId());
        payload.put("threshold", threshold);
        payload.put("offerTitle", offer == null ? "" : safe(offer.getTitre()));
        payload.put("offerDescription", offer == null ? "" : safe(offer.getDescription()));
        payload.put("experienceLevel", offer == null ? "" : safe(offer.getExperienceRequise()));
        payload.put("contractType", offer == null ? "" : safe(offer.getTypeContrat()));
        payload.put("companyName", resolveCompanyName(offer == null ? null : offer.getRecruiter()));
        payload.put("skills", skills.stream().map(skill -> Map.of(
                "name", safe(skill.getNom()),
                "type", safe(skill.getType()),
                "level", safe(skill.getNiveau()),
                "weight", skill.getPonderation() == null ? 50 : skill.getPonderation()
        )).toList());
        return payload;
    }

    private Map<String, Object> buildAiEvaluationPayload(AiTest aiTest, List<AiQuestion> questions, Map<Long, String> answersByQuestionId) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("testId", aiTest.getId());
        payload.put("threshold", aiTest.getThreshold());
        payload.put("offerTitle", aiTest.getJobOffer() == null ? "" : safe(aiTest.getJobOffer().getTitre()));
        payload.put("candidateName", aiTest.getCandidate() == null ? "" : safe(aiTest.getCandidate().getNom()));
        payload.put("questions", questions.stream().map(question -> Map.of(
                "id", question.getId(),
                "questionText", safe(question.getQuestionText()),
                "questionType", safe(question.getQuestionType()),
                "options", readStringList(question.getOptionsJson()),
                "correctAnswer", safe(question.getCorrectAnswer()),
                "expectedKeywords", readStringList(question.getExpectedKeywordsJson()),
                "points", question.getPoints() == null ? 0d : question.getPoints(),
                "candidateAnswer", answersByQuestionId.getOrDefault(question.getId(), "")
        )).toList());
        return payload;
    }

    private EvaluationPayload parseAiEvaluation(
            AiTest aiTest,
            List<AiQuestion> questions,
            Map<Long, String> answersByQuestionId,
            JsonNode response
    ) {
        JsonNode answersNode = response.get("answers");
        if (answersNode == null || !answersNode.isArray()) {
            return null;
        }

        Map<Long, AiQuestion> questionsById = questions.stream()
                .collect(Collectors.toMap(AiQuestion::getId, item -> item));

        List<AnswerEvaluationDetail> answerDetails = new ArrayList<>();
        for (JsonNode item : answersNode) {
            Long questionId = item.path("questionId").isNumber() ? item.path("questionId").asLong() : null;
            if (questionId == null || !questionsById.containsKey(questionId)) {
                continue;
            }

            AiQuestion question = questionsById.get(questionId);
            answerDetails.add(new AnswerEvaluationDetail(
                    question,
                    answersByQuestionId.getOrDefault(questionId, ""),
                    item.path("isCorrect").asBoolean(false),
                    clampScore(item.path("pointsObtained").asDouble(0d), question.getPoints())
            ));
        }

        if (answerDetails.isEmpty()) {
            return null;
        }

        double totalPoints = questions.stream().mapToDouble(question -> question.getPoints() == null ? 0d : question.getPoints()).sum();
        double obtainedPoints = answerDetails.stream().mapToDouble(AnswerEvaluationDetail::pointsObtained).sum();
        double parsedScore = response.path("globalScore").asDouble(roundPercentage(totalPoints == 0d ? 0d : (obtainedPoints / totalPoints) * 100d));
        double globalScore = roundPercentage(parsedScore);
        String recommendation = globalScore >= normalizeThreshold(aiTest.getThreshold()) ? APP_STATUS_INTERVIEW : APP_STATUS_REJECTION_SUGGESTED;
        String report = readText(response, "generatedReport", buildLocalNarrativeReport(globalScore, recommendation, readStringList(response.get("strengths")), readStringList(response.get("weaknesses"))));
        String summary = readText(response, "message", globalScore >= normalizeThreshold(aiTest.getThreshold())
                ? "Le candidat atteint le niveau attendu pour un entretien."
                : "Le systeme propose un refus apres analyse du test.");
        List<String> strengths = ensureNonEmptyList(readStringList(response.get("strengths")), "Bonne restitution sur plusieurs points attendus.");
        List<String> weaknesses = ensureNonEmptyList(readStringList(response.get("weaknesses")), "Des approfondissements restent necessaires sur les competences critiques.");

        return new EvaluationPayload(
                answerDetails,
                globalScore,
                strengths,
                weaknesses,
                recommendation,
                report,
                buildDefaultRejectionEmail(aiTest),
                summary
        );
    }

    private EvaluationPayload evaluateLocally(AiTest aiTest, List<AiQuestion> questions, Map<Long, String> answersByQuestionId) {
        List<AnswerEvaluationDetail> details = new ArrayList<>();
        double totalPoints = 0d;
        double obtainedPoints = 0d;
        List<String> strengths = new ArrayList<>();
        List<String> weaknesses = new ArrayList<>();

        for (AiQuestion question : questions) {
            double maxPoints = question.getPoints() == null ? 0d : question.getPoints();
            totalPoints += maxPoints;
            String candidateAnswer = answersByQuestionId.getOrDefault(question.getId(), "");
            AnswerEvaluationDetail evaluationDetail = evaluateQuestionLocally(question, candidateAnswer);
            details.add(evaluationDetail);
            obtainedPoints += evaluationDetail.pointsObtained();

            if (Boolean.TRUE.equals(evaluationDetail.correct()) || evaluationDetail.pointsObtained() >= (maxPoints * 0.7d)) {
                strengths.add(shortenQuestion(question.getQuestionText()));
            } else {
                weaknesses.add(shortenQuestion(question.getQuestionText()));
            }
        }

        double globalScore = totalPoints == 0d ? 0d : roundPercentage((obtainedPoints / totalPoints) * 100d);
        String recommendation = globalScore >= normalizeThreshold(aiTest.getThreshold()) ? APP_STATUS_INTERVIEW : APP_STATUS_REJECTION_SUGGESTED;

        strengths = ensureNonEmptyList(strengths, "Le candidat maitrise une partie des attendus techniques.");
        weaknesses = ensureNonEmptyList(weaknesses, "Le candidat doit renforcer plusieurs points du test.");

        return new EvaluationPayload(
                details,
                globalScore,
                strengths,
                weaknesses,
                recommendation,
                buildLocalNarrativeReport(globalScore, recommendation, strengths, weaknesses),
                buildDefaultRejectionEmail(aiTest),
                recommendation.equals(APP_STATUS_INTERVIEW)
                        ? "Le candidat atteint le seuil defini pour passer a l'entretien."
                        : "Le score est inferieur au seuil. Un refus est propose au recruteur."
        );
    }

    private AnswerEvaluationDetail evaluateQuestionLocally(AiQuestion question, String candidateAnswer) {
        String questionType = normalizeQuestionType(question.getQuestionType());
        double maxPoints = question.getPoints() == null ? 0d : question.getPoints();
        String sanitizedAnswer = safe(candidateAnswer);

        if (QUESTION_TYPE_MCQ.equals(questionType)) {
            boolean correct = safe(question.getCorrectAnswer()).equalsIgnoreCase(sanitizedAnswer);
            return new AnswerEvaluationDetail(question, sanitizedAnswer, correct, correct ? maxPoints : 0d);
        }

        List<String> keywords = readStringList(question.getExpectedKeywordsJson());
        if (keywords.isEmpty()) {
            boolean answered = !sanitizedAnswer.isBlank();
            double points = answered ? roundPoints(maxPoints * 0.6d) : 0d;
            return new AnswerEvaluationDetail(question, sanitizedAnswer, answered, points);
        }

        long matchedKeywords = keywords.stream()
                .map(AiTestService::normalizeToken)
                .filter(token -> !token.isBlank())
                .filter(token -> normalizeToken(sanitizedAnswer).contains(token))
                .count();

        double ratio = Math.min(1d, matchedKeywords / (double) keywords.size());
        double points = roundPoints(maxPoints * ratio);
        boolean correct = ratio >= 0.7d;
        return new AnswerEvaluationDetail(question, sanitizedAnswer, correct, points);
    }

    private GeneratedTestPayload buildLocalGeneratedTest(Candidature application, double threshold, Integer requestedQuestionCount) {
        Offre offer = application.getOffre();
        List<OffreCompetenceRequest> skills = readOfferSkills(offer == null ? null : offer.getCompetencesJson());
        List<GeneratedQuestionPayload> questions = new ArrayList<>();

        List<OffreCompetenceRequest> sortedSkills = new ArrayList<>(skills);
        sortedSkills.sort((left, right) -> Integer.compare(
                right.getPonderation() == null ? 50 : right.getPonderation(),
                left.getPonderation() == null ? 50 : left.getPonderation()
        ));

        if (sortedSkills.isEmpty()) {
            questions.add(buildDefaultScenarioQuestion(offer));
        } else {
            int index = 0;
            for (OffreCompetenceRequest skill : sortedSkills.stream().limit(2).toList()) {
                questions.add(buildMcqQuestion(offer, skill, index++));
            }
            for (OffreCompetenceRequest skill : sortedSkills.stream().skip(2).limit(2).toList()) {
                questions.add(buildShortQuestion(offer, skill));
            }
            questions.add(buildScenarioQuestion(offer, sortedSkills));
        }

        return new GeneratedTestPayload(
                "Test IA genere a partir des competences et du contexte de l'offre. Seuil d'entretien : " + Math.round(threshold) + "%.",
                enforceQuestionCount(questions, offer, requestedQuestionCount)
        );
    }

    private GeneratedQuestionPayload buildMcqQuestion(Offre offer, OffreCompetenceRequest skill, int index) {
        String skillName = safe(skill.getNom());
        String title = offer == null ? "ce poste" : safe(offer.getTitre());

        List<String> options = new ArrayList<>();
        String correctAnswer = "Structurer une solution fiable en " + skillName + " et verifier son adequation avec le besoin metier du poste.";
        options.add(correctAnswer);
        options.add("Eviter toute validation technique afin d'accelerer la livraison du poste " + title + ".");
        options.add("Ignorer completement les contraintes metier et ne se concentrer que sur l'outil.");
        options.add("Reporter toute decision technique importante a la fin du projet sans preparation.");
        Collections.rotate(options, index % options.size());

        return new GeneratedQuestionPayload(
                "QCM - " + title + " : quelle pratique est la plus pertinente pour exploiter " + skillName + " dans un contexte professionnel ?",
                QUESTION_TYPE_MCQ,
                options,
                correctAnswer,
                List.of(skillName, safe(skill.getNiveau()), "besoin metier"),
                20d
        );
    }

    private GeneratedQuestionPayload buildShortQuestion(Offre offer, OffreCompetenceRequest skill) {
        String skillName = safe(skill.getNom());
        String title = offer == null ? "le poste" : safe(offer.getTitre());
        return new GeneratedQuestionPayload(
                "Question courte - decrivez une action concrete pour mobiliser " + skillName + " dans le cadre de " + title + ".",
                QUESTION_TYPE_SHORT,
                List.of(),
                "",
                List.of(skillName, safe(skill.getNiveau()), safe(offer == null ? "" : offer.getCategorie())),
                20d
        );
    }

    private GeneratedQuestionPayload buildScenarioQuestion(Offre offer, List<OffreCompetenceRequest> skills) {
        List<String> keywords = new ArrayList<>();
        keywords.add(safe(offer == null ? "" : offer.getTitre()));
        keywords.add(safe(offer == null ? "" : offer.getExperienceRequise()));
        skills.stream().limit(2).map(OffreCompetenceRequest::getNom).map(AiTestService::safe).forEach(keywords::add);

        return new GeneratedQuestionPayload(
                "Mini scenario - vous rejoignez le poste \"" + safe(offer == null ? "" : offer.getTitre())
                        + "\". Expliquez comment vous priorisez vos actions pendant la premiere semaine pour livrer un resultat fiable.",
                QUESTION_TYPE_SCENARIO,
                List.of(),
                "",
                keywords,
                20d
        );
    }

    private GeneratedQuestionPayload buildDefaultScenarioQuestion(Offre offer) {
        return new GeneratedQuestionPayload(
                "Mini scenario - presentez votre approche pour prendre en main le poste \"" + safe(offer == null ? "" : offer.getTitre())
                        + "\" et livrer rapidement de la valeur.",
                QUESTION_TYPE_SCENARIO,
                List.of(),
                "",
                List.of(safe(offer == null ? "" : offer.getTitre()), safe(offer == null ? "" : offer.getDescription())),
                20d
        );
    }

    private Offre resolveRecruiterOffer(Recruiter recruiter, Long offerId) {
        Offre offer = offreRepository.findById(offerId)
                .orElseThrow(() -> new RuntimeException("Offre introuvable."));
        if (offer.getRecruiter() == null || !Objects.equals(offer.getRecruiter().getId(), recruiter.getId())) {
            throw new RuntimeException("Vous ne pouvez gerer que les tests IA de vos propres offres.");
        }
        return offer;
    }

    private void applyOfferTestConfiguration(
            AiTest aiTest,
            Offre offer,
            Recruiter recruiter,
            CreateAiTestRequest request,
            boolean preserveGeneratedStatus
    ) {
        aiTest.setJobOffer(offer);
        aiTest.setRecruiter(recruiter);
        aiTest.setApplication(null);
        aiTest.setCandidate(null);
        aiTest.setResult(null);
        aiTest.setTitle(nonEmpty(request == null ? null : request.getTitle(), "Test IA - " + safe(offer == null ? "" : offer.getTitre())));
        aiTest.setDescription(nonEmpty(
                request == null ? null : request.getDescription(),
                "Evaluation technique et metier associee a l'offre " + safe(offer == null ? "" : offer.getTitre()) + "."
        ));
        aiTest.setNumberOfQuestions(resolveQuestionCount(
                request == null ? null : request.getNumberOfQuestions(),
                aiTest.getNumberOfQuestions()
        ));
        double passingScore = normalizeThreshold(request == null ? null : request.getThreshold());
        aiTest.setThreshold(passingScore);
        aiTest.setPassingScore(passingScore);
        aiTest.setDifficulty(nonEmpty(request == null ? null : request.getDifficulty(), "INTERMEDIAIRE").toUpperCase(Locale.ROOT));
        aiTest.setAllowPreviousQuestion(Boolean.TRUE.equals(request == null ? null : request.getAllowPreviousQuestion()));
        aiTest.setEvaluationSkillsJson(writeStringList(request == null ? List.of() : request.getEvaluationSkills()));
        aiTest.setCheatingSuspicion(false);
        aiTest.setWarningCount(0);
        aiTest.setTabSwitchCount(0);
        aiTest.setClosedReason("");
        aiTest.setStartedAt(null);
        aiTest.setExpiresAt(null);
        aiTest.setSubmittedAt(null);
        aiTest.setCompletedAt(null);
        aiTest.setScore(null);
        aiTest.setRecommendation("");
        aiTest.setReport("");
        aiTest.setProposedRejectionEmail("");
        if (!preserveGeneratedStatus || safe(aiTest.getStatus()).isBlank()) {
            aiTest.setStatus(Boolean.TRUE.equals(request == null ? null : request.getEnabled()) ? TEST_STATUS_DRAFT : TEST_STATUS_DRAFT);
        }
    }

    private List<GeneratedQuestionPayload> generateOfferTemplatePayload(Offre offer, AiTest aiTest) {
        int desiredCount = resolveQuestionCount(aiTest.getNumberOfQuestions(), null);
        if (pythonGroqAgentService.isConfigured()) {
            try {
                JsonNode response = pythonGroqAgentService.invoke("generate_ai_test", buildOfferGenerationPayload(offer, aiTest));
                List<GeneratedQuestionPayload> generated = parseGeneratedQuestions(response.get("questions"));
                if (!generated.isEmpty()) {
                    return enforceQuestionCount(generated, offer, desiredCount);
                }
            } catch (RuntimeException ex) {
                logger.warn("Generation Groq du test IA offre indisponible, fallback local active : {}", ex.getMessage());
            }
        }
        return buildLocalOfferQuestions(offer, aiTest);
    }

    private Map<String, Object> buildOfferGenerationPayload(Offre offer, AiTest aiTest) {
        List<OffreCompetenceRequest> skills = readOfferSkills(offer == null ? null : offer.getCompetencesJson());
        List<String> explicitSkills = readStringList(aiTest.getEvaluationSkillsJson());
        List<String> targetSkills = explicitSkills.isEmpty()
                ? skills.stream().map(OffreCompetenceRequest::getNom).map(AiTestService::safe).filter(item -> !item.isBlank()).toList()
                : explicitSkills;

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("offerId", offer == null ? null : offer.getId());
        payload.put("offerTitle", offer == null ? "" : safe(offer.getTitre()));
        payload.put("offerDescription", offer == null ? "" : safe(offer.getDescription()));
        payload.put("experienceLevel", offer == null ? "" : safe(offer.getExperienceRequise()));
        payload.put("difficulty", safe(aiTest.getDifficulty()));
        payload.put("questionCount", resolveQuestionCount(aiTest.getNumberOfQuestions(), null));
        payload.put("passingScore", aiTest.getPassingScore());
        payload.put("skills", targetSkills);
        payload.put("offerSkills", skills.stream().map(skill -> Map.of(
                "name", safe(skill.getNom()),
                "type", safe(skill.getType()),
                "level", safe(skill.getNiveau()),
                "weight", skill.getPonderation() == null ? 50 : skill.getPonderation()
        )).toList());
        return payload;
    }

    private List<GeneratedQuestionPayload> buildLocalOfferQuestions(Offre offer, AiTest aiTest) {
        return buildLocalOfferQuestions(offer, aiTest, resolveQuestionCount(aiTest == null ? null : aiTest.getNumberOfQuestions(), null));
    }

    private List<GeneratedQuestionPayload> buildLocalOfferQuestions(Offre offer, int desiredCount) {
        return buildLocalOfferQuestions(offer, null, desiredCount);
    }

    private List<GeneratedQuestionPayload> buildLocalOfferQuestions(Offre offer, AiTest aiTest, int desiredCount) {
        List<OffreCompetenceRequest> offerSkills = readOfferSkills(offer == null ? null : offer.getCompetencesJson());
        List<String> selectedSkills = aiTest == null ? List.of() : readStringList(aiTest.getEvaluationSkillsJson());
        List<OffreCompetenceRequest> filteredSkills = offerSkills.stream()
                .filter(skill -> selectedSkills.isEmpty() || selectedSkills.stream().anyMatch(item -> item.equalsIgnoreCase(safe(skill.getNom()))))
                .toList();
        List<OffreCompetenceRequest> sourceSkills = filteredSkills.isEmpty() ? offerSkills : filteredSkills;
        List<GeneratedQuestionPayload> base = new ArrayList<>();

        List<OffreCompetenceRequest> sortedSkills = new ArrayList<>(sourceSkills);
        sortedSkills.sort((left, right) -> Integer.compare(
                right.getPonderation() == null ? 50 : right.getPonderation(),
                left.getPonderation() == null ? 50 : left.getPonderation()
        ));

        if (sortedSkills.isEmpty()) {
            base.add(buildDefaultScenarioQuestion(offer));
        } else {
            int index = 0;
            for (OffreCompetenceRequest skill : sortedSkills.stream().limit(2).toList()) {
                base.add(buildMcqQuestion(offer, skill, index++));
            }
            for (OffreCompetenceRequest skill : sortedSkills.stream().skip(2).limit(2).toList()) {
                base.add(buildShortQuestion(offer, skill));
            }
            base.add(buildScenarioQuestion(offer, sortedSkills));
        }

        List<GeneratedQuestionPayload> expanded = new ArrayList<>();
        for (int index = 0; index < desiredCount; index++) {
            GeneratedQuestionPayload source = base.get(index % base.size());
            expanded.add(new GeneratedQuestionPayload(
                    source.questionText(),
                    source.questionType(),
                    source.options(),
                    source.correctAnswer(),
                    source.expectedKeywords(),
                    source.points()
            ));
        }
        return expanded;
    }

    private GeneratedQuestionPayload generateSingleQuestion(Offre offer, AiTest aiTest, int orderIndex) {
        List<GeneratedQuestionPayload> generatedQuestions = generateOfferTemplatePayload(offer, aiTest);
        if (generatedQuestions.isEmpty()) {
            return buildDefaultScenarioQuestion(offer);
        }
        return generatedQuestions.get(Math.min(Math.max(orderIndex, 0), generatedQuestions.size() - 1));
    }

    private List<String> splitExpectedAnswer(String value) {
        String sanitized = safe(value);
        if (sanitized.isBlank()) {
            return List.of();
        }
        String[] tokens = sanitized.split("[,;\\n]+");
        List<String> keywords = new ArrayList<>();
        for (String token : tokens) {
            String item = safe(token);
            if (!item.isBlank()) {
                keywords.add(item);
            }
        }
        return keywords;
    }

    private int computeTotalDurationSeconds(List<AiQuestion> questions) {
        return questions == null
                ? 0
                : questions.stream()
                        .map(AiQuestion::getTimeLimitSeconds)
                        .mapToInt(value -> Math.max(30, safeInteger(value)))
                        .sum();
    }

    private void recalculateOfferTestDurations(AiTest aiTest) {
        List<AiQuestion> questions = aiQuestionRepository.findByAiTest_IdOrderByOrderIndexAscIdAsc(aiTest.getId());
        int totalDurationSeconds = computeTotalDurationSeconds(questions);
        aiTest.setNumberOfQuestions(questions.size());
        aiTest.setTotalDurationSeconds(totalDurationSeconds);
        aiTest.setDurationMinutes(resolveDurationMinutes(totalDurationSeconds, aiTest.getDurationMinutes()));
        aiTest.setUpdatedAt(new Date());
    }

    private int resolveTestDurationSeconds(AiTest aiTest) {
        if (aiTest == null) {
            return DEFAULT_TEST_DURATION_MINUTES * 60;
        }
        List<AiQuestion> questions = aiQuestionRepository.findByAiTest_IdOrderByOrderIndexAscIdAsc(aiTest.getId());
        int computed = computeTotalDurationSeconds(questions);
        if (computed > 0) {
            aiTest.setTotalDurationSeconds(computed);
            aiTest.setDurationMinutes(resolveDurationMinutes(computed, aiTest.getDurationMinutes()));
            return computed;
        }
        if (aiTest.getTotalDurationSeconds() != null && aiTest.getTotalDurationSeconds() > 0) {
            return aiTest.getTotalDurationSeconds();
        }
        return normalizeDurationMinutes(aiTest.getDurationMinutes()) * 60;
    }

    private AiTestResult initializeOrResumeResult(AiTest aiTest, Candidate candidate) {
        AiTestResult result = aiTestResultRepository.findByAiTest_Id(aiTest.getId()).orElseGet(AiTestResult::new);
        boolean isNew = result.getId() == null;
        Date now = new Date();
        result.setAiTest(aiTest);
        result.setCandidature(aiTest.getApplication());
        result.setCandidate(candidate);
        result.setCreatedAt(isNew ? now : result.getCreatedAt());
        result.setUpdatedAt(now);
        result.setStartedAt(aiTest.getStartedAt() == null ? now : aiTest.getStartedAt());
        result.setSubmittedAt(null);
        result.setScore(aiTest.getScore());
        result.setStatus(TEST_STATUS_IN_PROGRESS);
        result.setClosedReason("");

        List<AiQuestion> questions = aiQuestionRepository.findByAiTest_IdOrderByOrderIndexAscIdAsc(aiTest.getId());
        if (questions.isEmpty()) {
            throw new RuntimeException("Le test IA ne contient aucune question.");
        }
        int currentIndex = Math.min(Math.max(safeInteger(result.getCurrentQuestionIndex()), 0), questions.size() - 1);
        result.setCurrentQuestionIndex(currentIndex);
        if (result.getCurrentQuestionStartedAt() == null || result.getCurrentQuestionExpiresAt() == null) {
            stampCurrentQuestionWindow(result, questions.get(currentIndex));
        }
        return aiTestResultRepository.save(result);
    }

    private AiTestResponse buildCurrentQuestionResponse(AiTest aiTest, AiTestResult result, boolean includeAnswerAudit) {
        List<AiQuestion> questions = aiQuestionRepository.findByAiTest_IdOrderByOrderIndexAscIdAsc(aiTest.getId());
        if (questions.isEmpty()) {
            throw new RuntimeException("Le test IA ne contient aucune question.");
        }
        int currentIndex = Math.min(Math.max(safeInteger(result.getCurrentQuestionIndex()), 0), questions.size() - 1);
        AiQuestion currentQuestion = questions.get(currentIndex);
        List<AiAnswer> answers = aiAnswerRepository.findByAiTestResult_IdOrderByIdAsc(result.getId());
        AiTestResponse response = toResponse(aiTest, List.of(currentQuestion), answers, result, includeAnswerAudit);
        int totalDurationSeconds = computeTotalDurationSeconds(questions);
        response.setTotalDurationSeconds(totalDurationSeconds);
        response.setDurationMinutes(resolveDurationMinutes(totalDurationSeconds, aiTest.getDurationMinutes()));
        response.setResultId(result.getId());
        response.setCurrentQuestionIndex(currentIndex);
        response.setTotalQuestions(questions.size());
        response.setQuestionStartedAt(formatDateTime(result.getCurrentQuestionStartedAt()));
        response.setQuestionExpiresAt(formatDateTime(result.getCurrentQuestionExpiresAt()));
        response.setTimeRemainingSeconds(computeQuestionTimeRemainingSeconds(result));
        return response;
    }

    private void ensureResultEditable(AiTest aiTest, AiTestResult result) {
        String status = normalizeAiTestStatus(aiTest.getStatus());
        if (TEST_STATUS_SUBMITTED.equals(status)) {
            throw new RuntimeException("Ce test IA a deja ete soumis.");
        }
        if (TEST_STATUS_EXPIRED.equals(status) || TEST_STATUS_CHEATING_SUSPECTED.equals(status) || TEST_STATUS_CLOSED.equals(status)) {
            throw new RuntimeException("Ce test IA n'est plus modifiable.");
        }
    }

    private AiQuestion resolveCurrentQuestion(AiTest aiTest, AiTestResult result) {
        List<AiQuestion> questions = aiQuestionRepository.findByAiTest_IdOrderByOrderIndexAscIdAsc(aiTest.getId());
        if (questions.isEmpty()) {
            throw new RuntimeException("Le test IA ne contient aucune question.");
        }
        int currentIndex = Math.min(Math.max(safeInteger(result.getCurrentQuestionIndex()), 0), questions.size() - 1);
        return questions.get(currentIndex);
    }

    private void persistAnswer(AiTestResult result, AiTest aiTest, AiQuestion question, String candidateAnswer, Integer timeSpentSeconds) {
        AiAnswer answer = aiAnswerRepository.findByAiTestResult_IdAndQuestion_Id(result.getId(), question.getId());
        if (answer == null) {
            answer = AiAnswer.builder()
                    .aiTest(aiTest)
                    .aiTestResult(result)
                    .question(question)
                    .build();
        }
        answer.setCandidateAnswer(candidateAnswer);
        answer.setAnsweredAt(new Date());
        answer.setTimeSpentSeconds(timeSpentSeconds == null ? null : Math.max(0, timeSpentSeconds));
        aiAnswerRepository.save(answer);
    }

    private void stampCurrentQuestionWindow(AiTestResult result, AiQuestion question) {
        Date now = new Date();
        int timeLimitSeconds = Math.max(30, safeInteger(question.getTimeLimitSeconds()));
        result.setCurrentQuestionStartedAt(now);
        result.setCurrentQuestionExpiresAt(new Date(now.getTime() + (timeLimitSeconds * 1000L)));
    }

    private long computeQuestionTimeRemainingSeconds(AiTestResult result) {
        if (result == null || result.getCurrentQuestionExpiresAt() == null) {
            return 0L;
        }
        return Math.max(0L, (result.getCurrentQuestionExpiresAt().getTime() - System.currentTimeMillis()) / 1000L);
    }

    private Integer findTimeSpentSeconds(List<AiAnswerSubmissionRequest> submittedAnswers, Long questionId) {
        if (submittedAnswers == null || questionId == null) {
            return null;
        }
        return submittedAnswers.stream()
                .filter(item -> Objects.equals(item.getQuestionId(), questionId))
                .map(AiAnswerSubmissionRequest::getTimeSpentSeconds)
                .filter(Objects::nonNull)
                .findFirst()
                .orElse(null);
    }

    private List<GeneratedQuestionPayload> parseGeneratedQuestions(JsonNode node) {
        if (node == null || !node.isArray()) {
            return List.of();
        }

        List<GeneratedQuestionPayload> questions = new ArrayList<>();
        for (JsonNode item : node) {
            String text = readText(item, "questionText", "");
            String questionType = normalizeQuestionType(readText(item, "questionType", QUESTION_TYPE_SHORT));
            if (text.isBlank()) {
                continue;
            }

            questions.add(new GeneratedQuestionPayload(
                    text,
                    questionType,
                    readStringList(item.get("options")),
                    readText(item, "correctAnswer", ""),
                    readStringList(item.get("expectedKeywords")),
                    item.path("points").asDouble(20d)
            ));
        }
        return questions;
    }

    private AiQuestion toEntity(AiTest aiTest, GeneratedQuestionPayload payload) {
        return toEntity(aiTest, payload, safeInteger(aiTest.getQuestions() == null ? 0 : aiTest.getQuestions().size()));
    }

    private AiQuestion toEntity(AiTest aiTest, GeneratedQuestionPayload payload, int orderIndex) {
        Date now = new Date();
        return AiQuestion.builder()
                .aiTest(aiTest)
                .questionText(payload.questionText())
                .questionType(normalizeQuestionType(payload.questionType()))
                .optionsJson(writeStringList(payload.options()))
                .correctAnswer(payload.correctAnswer())
                .expectedKeywordsJson(writeStringList(payload.expectedKeywords()))
                .points(payload.points())
                .orderIndex(orderIndex)
                .timeLimitSeconds(DEFAULT_QUESTION_TIME_SECONDS)
                .acceptedByRecruiter(false)
                .createdAt(now)
                .updatedAt(now)
                .build();
    }

    private AiTestResponse toResponse(
            AiTest aiTest,
            List<AiQuestion> eagerQuestions,
            List<AiAnswer> eagerAnswers,
            AiTestResult eagerResult,
            boolean includeAnswerAudit
    ) {
        List<AiQuestion> questions = eagerQuestions != null ? eagerQuestions : aiQuestionRepository.findByAiTest_IdOrderByOrderIndexAscIdAsc(aiTest.getId());
        AiTestResult result = eagerResult != null ? eagerResult : aiTestResultRepository.findByAiTest_Id(aiTest.getId()).orElse(null);
        List<AiAnswer> answers = eagerAnswers != null
                ? eagerAnswers
                : result != null
                        ? aiAnswerRepository.findByAiTestResult_IdOrderByIdAsc(result.getId())
                        : aiAnswerRepository.findByAiTest_IdOrderByIdAsc(aiTest.getId());

        Map<Long, AiAnswer> answersByQuestionId = answers.stream()
                .filter(answer -> answer.getQuestion() != null && answer.getQuestion().getId() != null)
                .collect(Collectors.toMap(
                        answer -> answer.getQuestion().getId(),
                        answer -> answer,
                        (existing, replacement) -> replacement,
                        LinkedHashMap::new
                ));

        AiTestResponse response = new AiTestResponse();
        response.setId(aiTest.getId());
        response.setApplicationId(aiTest.getApplication() == null ? null : aiTest.getApplication().getId());
        response.setOfferId(aiTest.getJobOffer() == null ? null : aiTest.getJobOffer().getId());
        response.setCandidateId(aiTest.getCandidate() == null ? null : aiTest.getCandidate().getId());
        response.setRecruiterId(aiTest.getRecruiter() == null ? null : aiTest.getRecruiter().getId());
        response.setOfferTitle(aiTest.getJobOffer() == null ? "" : safe(aiTest.getJobOffer().getTitre()));
        response.setCompanyName(resolveCompanyName(aiTest.getRecruiter()));
        response.setCandidateName(aiTest.getCandidate() == null ? "" : safe(aiTest.getCandidate().getNom()));
        response.setTitle(safe(aiTest.getTitle()));
        response.setDescription(safe(aiTest.getDescription()));
        response.setStatus(normalizeAiTestStatus(aiTest.getStatus()));
        response.setThreshold(aiTest.getThreshold());
        response.setPassingScore(aiTest.getPassingScore() == null ? aiTest.getThreshold() : aiTest.getPassingScore());
        int computedDurationSeconds = computeTotalDurationSeconds(questions);
        int totalDurationSeconds = computedDurationSeconds > 0
                ? computedDurationSeconds
                : safeInteger(aiTest.getTotalDurationSeconds());
        response.setDurationMinutes(resolveDurationMinutes(totalDurationSeconds, aiTest.getDurationMinutes()));
        response.setTotalDurationSeconds(totalDurationSeconds);
        response.setNumberOfQuestions(aiTest.getNumberOfQuestions() == null ? questions.size() : aiTest.getNumberOfQuestions());
        response.setScore(aiTest.getScore());
        response.setRecommendation(safe(aiTest.getRecommendation()));
        response.setDifficulty(safe(aiTest.getDifficulty()));
        response.setAllowPreviousQuestion(Boolean.TRUE.equals(aiTest.getAllowPreviousQuestion()));
        response.setCreatedAt(formatDateTime(aiTest.getCreatedAt()));
        response.setUpdatedAt(formatDateTime(aiTest.getUpdatedAt()));
        response.setStartedAt(formatDateTime(aiTest.getStartedAt()));
        response.setExpiresAt(formatDateTime(aiTest.getExpiresAt()));
        response.setSubmittedAt(formatDateTime(aiTest.getSubmittedAt()));
        response.setCompletedAt(formatDateTime(aiTest.getCompletedAt()));
        response.setTimeRemainingSeconds(computeTimeRemainingSeconds(aiTest));
        response.setClosedReason(safe(aiTest.getClosedReason()));
        response.setCheatingSuspicion(Boolean.TRUE.equals(aiTest.getCheatingSuspicion()));
        response.setTabSwitchCount(safeInteger(aiTest.getTabSwitchCount()));
        response.setWarningCount(safeInteger(aiTest.getWarningCount()));
        response.setReport(safe(aiTest.getReport()));
        response.setProposedRejectionEmail(safe(aiTest.getProposedRejectionEmail()));
        response.setStrengths(readStringList(result == null ? "" : result.getStrengths()));
        response.setWeaknesses(readStringList(result == null ? "" : result.getWeaknesses()));
        response.setGeneratedReport(result == null ? "" : safe(result.getGeneratedReport()));
        response.setEvaluationSkills(readStringList(aiTest.getEvaluationSkillsJson()));
        response.setResultId(result == null ? null : result.getId());
        response.setCurrentQuestionIndex(result == null ? 0 : safeInteger(result.getCurrentQuestionIndex()));
        response.setTotalQuestions(questions.size());
        response.setQuestionStartedAt(result == null ? "" : formatDateTime(result.getCurrentQuestionStartedAt()));
        response.setQuestionExpiresAt(result == null ? "" : formatDateTime(result.getCurrentQuestionExpiresAt()));
        response.setQuestions(questions.stream().map(question -> {
            AiAnswer answer = answersByQuestionId.get(question.getId());
            AiQuestionResponse item = new AiQuestionResponse();
            item.setId(question.getId());
            item.setQuestionText(safe(question.getQuestionText()));
            item.setQuestionType(safe(question.getQuestionType()));
            item.setOptions(readStringList(question.getOptionsJson()));
            item.setPoints(question.getPoints());
             item.setOrderIndex(question.getOrderIndex());
             item.setTimeLimitSeconds(question.getTimeLimitSeconds());
             item.setAcceptedByRecruiter(question.getAcceptedByRecruiter());
            item.setCandidateAnswer(answer == null ? "" : safe(answer.getCandidateAnswer()));

            if (includeAnswerAudit) {
                item.setCorrect(answer == null ? null : answer.getCorrect());
                item.setPointsObtained(answer == null ? null : answer.getPointsObtained());
                item.setCorrectAnswer(safe(question.getCorrectAnswer()));
                item.setExpectedAnswer(String.join(", ", readStringList(question.getExpectedKeywordsJson())));
            }
            return item;
        }).toList());

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

    private List<OffreCompetenceRequest> readOfferSkills(String competencesJson) {
        if (safe(competencesJson).isBlank()) {
            return List.of();
        }

        try {
            return objectMapper.readValue(competencesJson, new TypeReference<List<OffreCompetenceRequest>>() { });
        } catch (JsonProcessingException ex) {
            return List.of();
        }
    }

    private String buildDefaultRejectionEmail(AiTest aiTest) {
        String candidateName = safe(aiTest.getCandidate() == null ? "" : aiTest.getCandidate().getNom());
        String offerTitle = safe(aiTest.getJobOffer() == null ? "" : aiTest.getJobOffer().getTitre());
        String recruiterName = safe(aiTest.getRecruiter() == null ? "" : aiTest.getRecruiter().getNom());
        String companyName = resolveCompanyName(aiTest.getRecruiter());

        return "Bonjour " + (candidateName.isBlank() ? "[Nom du candidat]" : candidateName) + ",\n\n"
                + "Nous vous remercions pour l'interet porte a notre offre de "
                + (offerTitle.isBlank() ? "[Titre du poste]" : offerTitle) + ".\n\n"
                + "Apres analyse de votre candidature et des resultats du test de preselection, "
                + "nous sommes au regret de vous informer que votre profil n'a pas ete retenu pour la suite du processus.\n\n"
                + "Nous vous encourageons a continuer a developper vos competences et nous vous souhaitons beaucoup de reussite dans vos prochaines demarches.\n\n"
                + "Cordialement,\n"
                + (recruiterName.isBlank() ? "[Nom du recruteur]" : recruiterName) + "\n"
                + (companyName.isBlank() ? "[Nom de l'entreprise]" : companyName);
    }

    private String buildSuspicionRejectionEmail(AiTest aiTest) {
        String candidateName = safe(aiTest.getCandidate() == null ? "" : aiTest.getCandidate().getNom());
        String offerTitle = safe(aiTest.getJobOffer() == null ? "" : aiTest.getJobOffer().getTitre());
        String recruiterName = safe(aiTest.getRecruiter() == null ? "" : aiTest.getRecruiter().getNom());
        String companyName = resolveCompanyName(aiTest.getRecruiter());

        return "Bonjour " + (candidateName.isBlank() ? "[Nom du candidat]" : candidateName) + ",\n\n"
                + "Nous vous informons que votre test de preselection pour le poste de "
                + (offerTitle.isBlank() ? "[Titre du poste]" : offerTitle)
                + " a ete interrompu suite a une sortie de la page d'examen detectee par la plateforme.\n\n"
                + "Votre dossier reste en attente de validation finale par le recruteur, qui examinera la situation avant toute decision definitive.\n\n"
                + "Cordialement,\n"
                + (recruiterName.isBlank() ? "[Nom du recruteur]" : recruiterName) + "\n"
                + (companyName.isBlank() ? "[Nom de l'entreprise]" : companyName);
    }

    private String buildExpiredTestRejectionEmail(AiTest aiTest) {
        String candidateName = safe(aiTest.getCandidate() == null ? "" : aiTest.getCandidate().getNom());
        String offerTitle = safe(aiTest.getJobOffer() == null ? "" : aiTest.getJobOffer().getTitre());
        String recruiterName = safe(aiTest.getRecruiter() == null ? "" : aiTest.getRecruiter().getNom());
        String companyName = resolveCompanyName(aiTest.getRecruiter());

        return "Bonjour " + (candidateName.isBlank() ? "[Nom du candidat]" : candidateName) + ",\n\n"
                + "Nous vous remercions pour l'interet porte a notre offre de "
                + (offerTitle.isBlank() ? "[Titre du poste]" : offerTitle) + ".\n\n"
                + "Le test de preselection associe a votre candidature n'a pas ete finalise dans le temps imparti.\n"
                + "Le recruteur va verifier la situation avant toute decision definitive sur votre dossier.\n\n"
                + "Cordialement,\n"
                + (recruiterName.isBlank() ? "[Nom du recruteur]" : recruiterName) + "\n"
                + (companyName.isBlank() ? "[Nom de l'entreprise]" : companyName);
    }

    private String buildCompletionSummary(String summary, boolean autoSubmit, String reason) {
        if (!autoSubmit) {
            return summary;
        }

        String suffix = safe(reason).isBlank() ? "Le test a ete soumis automatiquement a la fin du temps imparti." : safe(reason);
        return summary + " " + suffix;
    }

    private String buildLocalNarrativeReport(double score, String recommendation, List<String> strengths, List<String> weaknesses) {
        StringBuilder builder = new StringBuilder();
        builder.append("Score global : ").append(Math.round(score)).append("%.\n");
        if (APP_STATUS_INTERVIEW.equals(recommendation)) {
            builder.append("Le candidat atteint le seuil attendu et peut passer a l'entretien.\n");
        } else {
            builder.append("Le score reste inferieur au seuil attendu. Le systeme propose un refus a valider par le recruteur.\n");
        }
        builder.append("Points forts : ").append(String.join(", ", strengths)).append(".\n");
        builder.append("Points faibles : ").append(String.join(", ", weaknesses)).append(".");
        return builder.toString();
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

    private static String formatDateTime(Date value) {
        if (value == null) {
            return "";
        }

        return value.toInstant()
                .atZone(ZoneId.systemDefault())
                .toLocalDateTime()
                .format(DATE_TIME_FORMATTER);
    }

    private static double normalizeThreshold(Double value) {
        if (value == null) {
            return 70d;
        }
        return Math.max(0d, Math.min(100d, value));
    }

    private static double roundPercentage(double value) {
        return Math.round(value * 10d) / 10d;
    }

    private static double roundPoints(double value) {
        return Math.round(value * 100d) / 100d;
    }

    private static double clampScore(double value, Double maxPoints) {
        double max = maxPoints == null ? 0d : maxPoints;
        return Math.max(0d, Math.min(max, roundPoints(value)));
    }

    private List<String> readStringList(String json) {
        if (safe(json).isBlank()) {
            return List.of();
        }

        try {
            return objectMapper.readValue(json, new TypeReference<List<String>>() { });
        } catch (JsonProcessingException ex) {
            return List.of();
        }
    }

    private static List<String> readStringList(JsonNode node) {
        if (node == null || !node.isArray()) {
            return List.of();
        }

        List<String> values = new ArrayList<>();
        for (JsonNode item : node) {
            String value = safe(item.asText());
            if (!value.isBlank()) {
                values.add(value);
            }
        }
        return values;
    }

    private String writeStringList(List<String> values) {
        try {
            return objectMapper.writeValueAsString(values == null ? List.of() : values);
        } catch (JsonProcessingException ex) {
            return "[]";
        }
    }

    private String readText(JsonNode node, String field, String fallback) {
        if (node == null) {
            return fallback;
        }

        String value = safe(node.path(field).asText());
        return value.isBlank() ? fallback : value;
    }

    private static List<String> ensureNonEmptyList(List<String> values, String fallback) {
        List<String> sanitized = values == null
                ? List.of()
                : values.stream().map(AiTestService::safe).filter(item -> !item.isBlank()).toList();
        return sanitized.isEmpty() ? List.of(fallback) : sanitized;
    }

    private static String shortenQuestion(String value) {
        String sanitized = safe(value);
        if (sanitized.length() <= 90) {
            return sanitized;
        }
        return sanitized.substring(0, 87).trim() + "...";
    }

    private static String normalizeToken(String value) {
        return safe(value)
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9]+", " ")
                .trim();
    }

    private static String safe(String value) {
        return value == null ? "" : value.trim();
    }

    private static String nonEmpty(String value, String fallback) {
        String sanitized = safe(value);
        return sanitized.isBlank() ? fallback : sanitized;
    }

    private record GeneratedQuestionPayload(
            String questionText,
            String questionType,
            List<String> options,
            String correctAnswer,
            List<String> expectedKeywords,
            Double points
    ) {
    }

    private record GeneratedTestPayload(
            String message,
            List<GeneratedQuestionPayload> questions
    ) {
    }

    private record AnswerEvaluationDetail(
            AiQuestion question,
            String candidateAnswer,
            Boolean correct,
            Double pointsObtained
    ) {
    }

    private record EvaluationPayload(
            List<AnswerEvaluationDetail> answerDetails,
            Double globalScore,
            List<String> strengths,
            List<String> weaknesses,
            String recommendation,
            String generatedReport,
            String proposedRejectionEmail,
            String summaryMessage
    ) {
    }
}
