package com.recrutement.recrutement.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.recrutement.recrutement.dto.AdminActivityResponse;
import com.recrutement.recrutement.dto.AdminOverviewStatsResponse;
import com.recrutement.recrutement.dto.AiInsightResponse;
import com.recrutement.recrutement.dto.AiTestStatsResponse;
import com.recrutement.recrutement.dto.ChartDataResponse;
import com.recrutement.recrutement.dto.OffreCompetenceRequest;
import com.recrutement.recrutement.dto.ServiceHealthResponse;
import com.recrutement.recrutement.dto.TopOfferActivityResponse;
import com.recrutement.recrutement.dto.TopSkillResponse;
import com.recrutement.recrutement.entities.AiTest;
import com.recrutement.recrutement.entities.AiTestResult;
import com.recrutement.recrutement.entities.Candidature;
import com.recrutement.recrutement.entities.Competence;
import com.recrutement.recrutement.entities.Offre;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.repositories.AiTestRepository;
import com.recrutement.recrutement.repositories.AiTestResultRepository;
import com.recrutement.recrutement.repositories.CandidatureRepository;
import com.recrutement.recrutement.repositories.CompetenceRepository;
import com.recrutement.recrutement.repositories.InterviewRepository;
import com.recrutement.recrutement.repositories.OffreRepository;
import com.recrutement.recrutement.repositories.UserRepository;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collection;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Comparator;
import java.text.Normalizer;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.beans.factory.ObjectProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class AdminStatisticsService {
    private static final Logger logger = LoggerFactory.getLogger(AdminStatisticsService.class);
    private static final DateTimeFormatter MONTH_FORMATTER = DateTimeFormatter.ofPattern("MMM yyyy", Locale.FRANCE);
    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm", Locale.FRANCE);

    private final UserRepository userRepository;
    private final OffreRepository offreRepository;
    private final CandidatureRepository candidatureRepository;
    private final InterviewRepository interviewRepository;
    private final AiTestRepository aiTestRepository;
    private final AiTestResultRepository aiTestResultRepository;
    private final CompetenceRepository competenceRepository;
    private final ObjectMapper objectMapper;
    private final MatchingService matchingService;
    private final AssistantAgentService assistantAgentService;
    private final PythonGroqAgentService pythonGroqAgentService;
    private final ObjectProvider<EmailService> emailServiceProvider;
    private final ObjectProvider<NotificationService> notificationServiceProvider;

    public AdminStatisticsService(
            UserRepository userRepository,
            OffreRepository offreRepository,
            CandidatureRepository candidatureRepository,
            InterviewRepository interviewRepository,
            AiTestRepository aiTestRepository,
            AiTestResultRepository aiTestResultRepository,
            CompetenceRepository competenceRepository,
            ObjectMapper objectMapper,
            MatchingService matchingService,
            AssistantAgentService assistantAgentService,
            PythonGroqAgentService pythonGroqAgentService,
            ObjectProvider<EmailService> emailServiceProvider,
            ObjectProvider<NotificationService> notificationServiceProvider
    ) {
        this.userRepository = userRepository;
        this.offreRepository = offreRepository;
        this.candidatureRepository = candidatureRepository;
        this.interviewRepository = interviewRepository;
        this.aiTestRepository = aiTestRepository;
        this.aiTestResultRepository = aiTestResultRepository;
        this.competenceRepository = competenceRepository;
        this.objectMapper = objectMapper;
        this.matchingService = matchingService;
        this.assistantAgentService = assistantAgentService;
        this.pythonGroqAgentService = pythonGroqAgentService;
        this.emailServiceProvider = emailServiceProvider;
        this.notificationServiceProvider = notificationServiceProvider;
    }

    public AdminOverviewStatsResponse getOverview() {
        List<User> users = userRepository.findAll().stream().filter(Objects::nonNull).toList();
        List<Offre> offers = offreRepository.findAll().stream().filter(Objects::nonNull).toList();
        List<Candidature> applications = candidatureRepository.findAll().stream().filter(Objects::nonNull).toList();
        List<AiTest> aiTests = aiTestRepository.findAll().stream().filter(Objects::nonNull).toList();

        AdminOverviewStatsResponse response = new AdminOverviewStatsResponse();
        response.setTotalUsers(users.size());
        response.setTotalCandidates(users.stream().filter(user -> user.getRole() != null && "CANDIDATE".equals(user.getRole().name())).count());
        response.setTotalRecruiters(users.stream().filter(user -> user.getRole() != null && "RECRUITER".equals(user.getRole().name())).count());
        response.setTotalOffers(offers.size());
        response.setTotalApplications(applications.size());
        response.setTotalPlannedInterviews(interviewRepository.count());
        response.setTotalRejectedApplications(applications.stream().filter(application -> "REJECTED".equals(AiTestService.normalizeApplicationStatus(application.getStatut()))).count());
        response.setTotalRetainedCandidates(applications.stream().filter(application -> "RETENU".equals(AiTestService.normalizeApplicationStatus(application.getStatut()))).count());
        response.setTotalCompletedAiTests(aiTests.stream().filter(this::isCompletedAiTest).count());
        response.setAverageMatchingScore(round2(
                applications.stream()
                        .map(Candidature::getScoreCandidat)
                        .filter(Objects::nonNull)
                        .mapToDouble(Double::doubleValue)
                        .average()
                        .orElse(0d)
        ));
        response.setAiTestSuccessRate(computeAiSuccessRate(aiTests));
        response.setTopSkills(getTopSkills());
        response.setTopOffers(getTopOffersFrom(offers, applications));
        return response;
    }

    public ChartDataResponse getApplicationsByStatus() {
        Map<String, Long> grouped = candidatureRepository.findAll().stream()
                .filter(Objects::nonNull)
                .collect(Collectors.groupingBy(
                        application -> readableStatus(AiTestService.normalizeApplicationStatus(application.getStatut())),
                        LinkedHashMap::new,
                        Collectors.counting()
                ));
        return toChart("Candidatures par statut", grouped);
    }

    public ChartDataResponse getOffersByMonth() {
        try {
            Map<String, Long> grouped = groupByMonth(
                    offreRepository.findAll().stream()
                            .filter(Objects::nonNull)
                            .map(Offre::getDate)
                            .filter(Objects::nonNull)
                            .toList()
            );
            return toChart("Offres publiees par mois", grouped);
        } catch (RuntimeException ex) {
            logger.warn("Impossible de calculer les offres par mois : {}", ex.getMessage());
            return toChart("Offres publiees par mois", Map.of());
        }
    }

    public ChartDataResponse getApplicationsByMonth() {
        try {
            Map<String, Long> grouped = groupByMonth(
                    candidatureRepository.findAll().stream()
                            .filter(Objects::nonNull)
                            .map(Candidature::getDateDepot)
                            .filter(Objects::nonNull)
                            .toList()
            );
            return toChart("Candidatures par mois", grouped);
        } catch (RuntimeException ex) {
            logger.warn("Impossible de calculer les candidatures par mois : {}", ex.getMessage());
            return toChart("Candidatures par mois", Map.of());
        }
    }

    public List<TopSkillResponse> getTopSkills() {
        Map<String, SkillCount> counts = new LinkedHashMap<>();
        for (Offre offer : offreRepository.findAll()) {
            if (offer == null) {
                continue;
            }
            Set<String> skillsInOffer = new LinkedHashSet<>(readOfferSkillNames(offer.getCompetencesJson()));
            for (String name : skillsInOffer) {
                String key = normalizeSkillKey(name);
                if (!key.isBlank()) {
                    counts.computeIfAbsent(key, ignored -> new SkillCount(formatSkillName(name)))
                            .increment();
                }
            }
        }
        return counts.values().stream()
                .sorted(Comparator.comparingLong(SkillCount::count).reversed().thenComparing(SkillCount::name))
                .limit(8)
                .map(skill -> new TopSkillResponse(skill.name(), skill.count()))
                .toList();
    }

    public AiTestStatsResponse getAiTestStats() {
        List<AiTest> aiTests = aiTestRepository.findAll().stream().filter(Objects::nonNull).toList();
        List<AiTestResult> results = aiTestResultRepository.findAll().stream().filter(Objects::nonNull).toList();
        long completed = aiTests.stream().filter(this::isCompletedAiTest).count();
        long passed = aiTests.stream().filter(this::isPassedAiTest).count();
        long failed = aiTests.stream().filter(this::isCompletedAiTest).filter(test -> !isPassedAiTest(test)).count();
        long expired = aiTests.stream()
                .filter(test -> "EXPIRED".equals(AiTestService.normalizeAiTestStatus(test.getStatus())))
                .count();
        long cheating = aiTests.stream().filter(test -> Boolean.TRUE.equals(test.getCheatingSuspicion())).count();
        double averageScore = round2(aiTests.stream().map(AiTest::getScore).filter(Objects::nonNull).mapToDouble(Double::doubleValue).average().orElse(0d));

        AiTestStatsResponse response = new AiTestStatsResponse();
        response.setTotalTests(aiTests.size());
        response.setCompletedTests(completed);
        response.setPassedTests(passed);
        response.setFailedTests(failed);
        response.setExpiredTests(expired);
        response.setCheatingSuspicions(cheating);
        response.setAverageScore(averageScore);
        response.setSuccessRate(completed == 0 ? 0d : round2((passed * 100d) / completed));
        if (!results.isEmpty() && response.getCompletedTests() == 0) {
            response.setCompletedTests(results.size());
        }
        return response;
    }

    public List<AiInsightResponse> getAiInsights() {
        AdminOverviewStatsResponse overview = getOverview();
        AiTestStatsResponse aiStats = getAiTestStats();
        List<TopSkillResponse> topSkills = overview.getTopSkills() == null ? List.of() : overview.getTopSkills();
        String topOffer = overview.getTopOffers() != null && !overview.getTopOffers().isEmpty()
                ? safe(overview.getTopOffers().get(0).getTitle())
                : "les offres les plus récentes";

        List<AiInsightResponse> insights = new ArrayList<>();
        if (!topSkills.isEmpty()) {
            String leadingSkills = topSkills.stream()
                    .limit(2)
                    .map(TopSkillResponse::getName)
                    .filter(Objects::nonNull)
                    .collect(Collectors.joining(" et "));
            insights.add(new AiInsightResponse(
                    "Compétences moteur du mois",
                    leadingSkills + " ressortent comme les compétences les plus demandées dans les offres publiées.",
                    "primary"
            ));
        }

        insights.add(new AiInsightResponse(
                "Tests IA et sélection",
                aiStats.getSuccessRate() >= 60
                        ? "Le taux de réussite des Tests IA est solide. Les profils performants progressent mieux dans le pipeline."
                        : "Le taux de réussite des Tests IA est en retrait. Un calibrage des questions ou du seuil mérite d’être revu.",
                aiStats.getSuccessRate() >= 60 ? "success" : "warning"
        ));

        insights.add(new AiInsightResponse(
                "Matching global",
                overview.getAverageMatchingScore() >= 70
                        ? "Le score moyen de matching reste élevé, signe d’un bon alignement entre offres et candidatures."
                        : "Le score moyen de matching est modéré. Les tags et la qualité des fiches offre sont un levier immédiat.",
                overview.getAverageMatchingScore() >= 70 ? "success" : "warning"
        ));

        insights.add(new AiInsightResponse(
                "Offres les plus actives",
                topOffer + " concentre actuellement le plus grand volume de candidatures et mérite un suivi prioritaire.",
                "neutral"
        ));

        return insights;
    }

    public List<ServiceHealthResponse> getSystemHealth() {
        List<ServiceHealthResponse> rows = new ArrayList<>();
        rows.add(new ServiceHealthResponse(
                "Matching Engine",
                matchingService != null ? "OK" : "Indisponible",
                matchingService != null ? "Le moteur de matching est chargé et prêt à calculer les scores." : "Le moteur de matching n’est pas accessible.",
                matchingService != null ? "success" : "danger"
        ));
        rows.add(new ServiceHealthResponse(
                "Assistant IA",
                assistantAgentService != null ? "Actif" : "Indisponible",
                assistantAgentService != null ? "Le service d’orchestration IA est prêt à répondre." : "Le service d’orchestration IA n’est pas chargé.",
                assistantAgentService != null ? "success" : "danger"
        ));
        rows.add(new ServiceHealthResponse(
                "Python AI Agent",
                pythonGroqAgentService != null && pythonGroqAgentService.isConfigured() ? "Groq API connectée" : "Configuration Groq requise",
                pythonGroqAgentService != null && pythonGroqAgentService.isConfigured()
                        ? "Le backend utilise Groq API comme fournisseur IA principal."
                        : "Ajoutez une clé GROQ_API_KEY ou assistant.groq.api.key pour activer Groq API.",
                pythonGroqAgentService != null && pythonGroqAgentService.isConfigured() ? "success" : "danger"
        ));
        rows.add(new ServiceHealthResponse(
                "Email Service",
                emailServiceProvider.getIfAvailable() != null ? "OK" : "Indisponible",
                emailServiceProvider.getIfAvailable() != null ? "Le service email est injecté et disponible pour les notifications." : "Le service email n’est pas disponible dans ce runtime.",
                emailServiceProvider.getIfAvailable() != null ? "success" : "danger"
        ));
        rows.add(new ServiceHealthResponse(
                "Notification Service",
                notificationServiceProvider.getIfAvailable() != null ? "OK" : "Indisponible",
                notificationServiceProvider.getIfAvailable() != null ? "Le service de notifications applicatives est opérationnel." : "Le service de notifications applicatives est absent.",
                notificationServiceProvider.getIfAvailable() != null ? "success" : "danger"
        ));
        return rows;
    }

    public List<AdminActivityResponse> getRecentActivity() {
        List<ActivitySeed> seeds = new ArrayList<>();

        offreRepository.findAll().stream()
                .filter(Objects::nonNull)
                .sorted(Comparator.comparing((Offre offer) -> instantOf(offer.getDate())).reversed())
                .limit(4)
                .forEach(offer -> seeds.add(new ActivitySeed(
                        instantOf(offer.getDate()),
                        "offre",
                        "Offre publiée",
                        safe(offer.getTitre()) + " a été publiée ou remise en avant."
                )));

        aiTestResultRepository.findAll().stream()
                .filter(Objects::nonNull)
                .filter(result -> result.getSubmittedAt() != null || result.getStartedAt() != null)
                .sorted(Comparator.comparing((AiTestResult result) -> instantOf(result.getSubmittedAt() != null ? result.getSubmittedAt() : result.getStartedAt())).reversed())
                .limit(4)
                .forEach(result -> seeds.add(new ActivitySeed(
                        instantOf(result.getSubmittedAt() != null ? result.getSubmittedAt() : result.getStartedAt()),
                        "ai-test",
                        "Test IA terminé",
                        safe(result.getCandidate() == null ? "" : result.getCandidate().getNom()) + " a complété un Test IA."
                )));

        candidatureRepository.findAll().stream()
                .filter(Objects::nonNull)
                .filter(application -> application.getDateDepot() != null)
                .sorted(Comparator.comparing((Candidature application) -> instantOf(application.getDateDepot())).reversed())
                .limit(4)
                .forEach(application -> seeds.add(new ActivitySeed(
                        instantOf(application.getDateDepot()),
                        "candidature",
                        "Candidature reçue",
                        safe(application.getCandidate() == null ? "" : application.getCandidate().getNom())
                                + " a postulé à "
                                + safe(application.getOffre() == null ? "" : application.getOffre().getTitre()) + "."
                )));

        return seeds.stream()
                .sorted(Comparator.comparing(ActivitySeed::instant).reversed())
                .limit(8)
                .map(seed -> new AdminActivityResponse(
                        seed.title(),
                        seed.description(),
                        formatDateTime(Date.from(seed.instant())),
                        toneForActivity(seed.type())
                ))
                .toList();
    }

    private List<TopOfferActivityResponse> getTopOffersFrom(List<Offre> offers, List<Candidature> applications) {
        Map<Long, Long> counts = applications.stream()
                .filter(Objects::nonNull)
                .filter(application -> application.getOffre() != null && application.getOffre().getId() != null)
                .collect(Collectors.groupingBy(application -> application.getOffre().getId(), Collectors.counting()));

        return offers.stream()
                .filter(Objects::nonNull)
                .map(offer -> new TopOfferActivityResponse(offer.getId(), safe(offer.getTitre()), counts.getOrDefault(offer.getId(), 0L)))
                .sorted((left, right) -> Long.compare(right.getApplicationsCount(), left.getApplicationsCount()))
                .limit(6)
                .toList();
    }

    private Instant instantOf(Date date) {
        return toLocalDateTime(date).atZone(ZoneId.systemDefault()).toInstant();
    }

    private LocalDateTime toLocalDateTime(Date date) {
        if (date == null) {
            return LocalDateTime.now();
        }
        if (date instanceof java.sql.Date sqlDate) {
            return sqlDate.toLocalDate().atStartOfDay();
        }
        try {
            return LocalDateTime.ofInstant(date.toInstant(), ZoneId.systemDefault());
        } catch (RuntimeException ex) {
            Calendar calendar = Calendar.getInstance();
            calendar.setTime(date);
            return LocalDateTime.of(
                    calendar.get(Calendar.YEAR),
                    calendar.get(Calendar.MONTH) + 1,
                    calendar.get(Calendar.DAY_OF_MONTH),
                    calendar.get(Calendar.HOUR_OF_DAY),
                    calendar.get(Calendar.MINUTE),
                    calendar.get(Calendar.SECOND)
            );
        }
    }

    private Map<String, Long> groupByMonth(Collection<Date> dates) {
        Map<String, Long> grouped = new LinkedHashMap<>();
        for (Date date : dates) {
            try {
                LocalDate localDate = toLocalDate(date);
                String key = MONTH_FORMATTER.format(localDate);
                grouped.merge(key, 1L, Long::sum);
            } catch (RuntimeException ex) {
                logger.warn("Date ignoree dans les statistiques mensuelles : {}", ex.getMessage());
            }
        }
        return grouped;
    }

    private LocalDate toLocalDate(Date date) {
        if (date == null) {
            return LocalDate.now();
        }
        if (date instanceof java.sql.Date sqlDate) {
            return sqlDate.toLocalDate();
        }
        try {
            return date.toInstant().atZone(ZoneId.systemDefault()).toLocalDate();
        } catch (RuntimeException ex) {
            Calendar calendar = Calendar.getInstance();
            calendar.setTime(date);
            return LocalDate.of(
                    calendar.get(Calendar.YEAR),
                    calendar.get(Calendar.MONTH) + 1,
                    calendar.get(Calendar.DAY_OF_MONTH)
            );
        }
    }

    private ChartDataResponse toChart(String title, Map<String, Long> grouped) {
        return new ChartDataResponse(title, new ArrayList<>(grouped.keySet()), new ArrayList<>(grouped.values()));
    }

    private double computeAiSuccessRate(List<AiTest> tests) {
        long completed = tests.stream().filter(this::isCompletedAiTest).count();
        if (completed == 0) {
            return 0d;
        }
        long passed = tests.stream().filter(this::isPassedAiTest).count();
        return round2((passed * 100d) / completed);
    }

    private boolean isCompletedAiTest(AiTest aiTest) {
        if (aiTest == null) {
            return false;
        }
        String status = AiTestService.normalizeAiTestStatus(aiTest.getStatus());
        return "SUBMITTED".equals(status) || "INTERVIEW".equals(status) || "REJECTION_SUGGESTED".equals(status) || "REJECTED".equals(status);
    }

    private boolean isPassedAiTest(AiTest aiTest) {
        if (aiTest == null) {
            return false;
        }
        if (!isCompletedAiTest(aiTest) || aiTest.getScore() == null) {
            return false;
        }
        double threshold = aiTest.getPassingScore() == null ? (aiTest.getThreshold() == null ? 70d : aiTest.getThreshold()) : aiTest.getPassingScore();
        return aiTest.getScore() >= threshold;
    }

    private String readableStatus(String normalizedStatus) {
        return switch (safe(normalizedStatus)) {
            case "APPLIED" -> "A trier";
            case "AI_TEST_SENT" -> "Test IA envoye";
            case "INTERVIEW" -> "Entretien a planifier";
            case "ENTRETIEN_PLANIFIE" -> "Entretien planifie";
            case "ENTRETIEN_EN_COURS" -> "Entretien en cours";
            case "ABSENCE_A_VERIFIER" -> "Absence a verifier";
            case "REJECTION_SUGGESTED" -> "Refus propose";
            case "REJECTED" -> "Refuse";
            case "RETENU" -> "Retenu";
            default -> safe(normalizedStatus).isBlank() ? "Non defini" : normalizedStatus;
        };
    }

    private List<OffreCompetenceRequest> readOfferSkills(String competencesJson) {
        if (safe(competencesJson).isBlank()) {
            return List.of();
        }
        try {
            return objectMapper.readValue(competencesJson, new TypeReference<List<OffreCompetenceRequest>>() { });
        } catch (Exception ex) {
            return List.of();
        }
    }

    private List<String> readOfferSkillNames(String competencesJson) {
        if (safe(competencesJson).isBlank()) {
            return List.of();
        }

        List<String> names = new ArrayList<>();
        try {
            JsonNode root = objectMapper.readTree(competencesJson);
            if (root.isArray()) {
                root.forEach(node -> addSkillName(names, node));
            } else {
                addSkillName(names, root);
            }
        } catch (Exception ignored) {
            for (OffreCompetenceRequest skill : readOfferSkills(competencesJson)) {
                String name = safe(skill == null ? "" : skill.getNom());
                if (!name.isBlank()) {
                    names.add(name);
                }
            }
            if (names.isEmpty()) {
                for (String name : competencesJson.split("[,;\\n|]+")) {
                    String cleaned = safe(name)
                            .replace("[", "")
                            .replace("]", "")
                            .replace("\"", "");
                    if (!cleaned.isBlank()) {
                        addSkillNames(names, cleaned);
                    }
                }
            }
        }

        return names;
    }

    private void addSkillName(List<String> names, JsonNode node) {
        if (node == null || node.isNull()) {
            return;
        }

        if (node.isArray()) {
            node.forEach(child -> addSkillName(names, child));
            return;
        }

        if (node.isTextual()) {
            String value = safe(node.asText());
            if (!value.isBlank()) {
                addSkillNames(names, value);
            }
            return;
        }

        if (!node.isObject()) {
            return;
        }

        String value = firstTextValue(node, "nom", "title", "name", "label", "libelle", "competenceName", "value");
        if (!value.isBlank()) {
            addSkillNames(names, value);
            return;
        }

        Long competenceId = firstLongValue(node, "competenceId", "id", "skillId");
        if (competenceId != null) {
            competenceRepository.findById(competenceId)
                    .map(Competence::getNom)
                    .map(this::safe)
                    .filter(name -> !name.isBlank())
                    .ifPresent(name -> addSkillNames(names, name));
            return;
        }

        for (String field : List.of("competences", "skills", "requiredSkills", "preferredSkills", "mandatorySkills", "optionalSkills")) {
            JsonNode child = node.get(field);
            if (child != null && !child.isNull()) {
                addSkillName(names, child);
            }
        }
    }

    private String firstTextValue(JsonNode node, String... fields) {
        for (String field : fields) {
            JsonNode child = node.get(field);
            if (child != null && !child.isNull()) {
                String value = safe(child.asText());
                if (!value.isBlank()) {
                    return value;
                }
            }
        }
        return "";
    }

    private void addSkillNames(List<String> names, String rawValue) {
        String value = safe(rawValue).replaceAll("\\s+", " ");
        if (value.isBlank()) {
            return;
        }

        if (value.matches(".*[,;\\n|/]+.*")) {
            for (String part : value.split("[,;\\n|/]+")) {
                addSkillNames(names, part);
            }
            return;
        }

        String normalized = normalizeSkillKey(value);
        Map<String, String> exactSkills = Map.of(
                "powerbi", "Power BI",
                "python", "Python",
                "sql", "SQL",
                "docker", "Docker",
                "springboot", "Spring Boot",
                "angular", "Angular",
                "postgresql", "PostgreSQL",
                "postgres", "PostgreSQL"
        );
        if (exactSkills.containsKey(normalized)) {
            names.add(exactSkills.get(normalized));
            return;
        }

        String searchable = Normalizer.normalize(value, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9]+", " ")
                .trim();
        Set<String> detected = new LinkedHashSet<>();
        if (searchable.matches(".*\\bpower\\s*bi\\b.*")) detected.add("Power BI");
        if (searchable.matches(".*\\bpython\\b.*")) detected.add("Python");
        if (searchable.matches(".*\\bsql\\b.*")) detected.add("SQL");
        if (searchable.matches(".*\\bdocker\\b.*")) detected.add("Docker");
        if (searchable.matches(".*\\bspring\\s*boot\\b.*")) detected.add("Spring Boot");
        if (searchable.matches(".*\\bangular\\b.*")) detected.add("Angular");
        if (searchable.matches(".*\\bpostgresql\\b.*") || searchable.matches(".*\\bpostgres\\b.*")) detected.add("PostgreSQL");

        if (detected.isEmpty()) {
            names.add(value);
        } else {
            names.addAll(detected);
        }
    }

    private Long firstLongValue(JsonNode node, String... fields) {
        for (String field : fields) {
            JsonNode child = node.get(field);
            if (child == null || child.isNull()) {
                continue;
            }

            if (child.canConvertToLong()) {
                return child.asLong();
            }

            try {
                return Long.parseLong(safe(child.asText()));
            } catch (NumberFormatException ignored) {
            }
        }
        return null;
    }

    private String normalizeSkillKey(String value) {
        String normalized = Normalizer.normalize(safe(value), Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9]+", "");
        return normalized.trim();
    }

    private String formatSkillName(String value) {
        String cleaned = safe(value).replaceAll("\\s+", " ");
        if (cleaned.isBlank()) {
            return "Non defini";
        }

        return switch (normalizeSkillKey(cleaned)) {
            case "powerbi" -> "Power BI";
            case "sql" -> "SQL";
            case "docker" -> "Docker";
            case "springboot" -> "Spring Boot";
            case "angular" -> "Angular";
            case "postgresql", "postgres" -> "PostgreSQL";
            case "python" -> "Python";
            default -> cleaned;
        };
    }

    private double round2(double value) {
        return Math.round(value * 100d) / 100d;
    }

    private String safe(String value) {
        return value == null ? "" : value.trim();
    }

    private String formatDateTime(Date date) {
        return date == null ? "" : DATE_TIME_FORMATTER.format(toLocalDateTime(date));
    }

    private String toneForActivity(String type) {
        return switch (safe(type)) {
            case "ai-test" -> "primary";
            case "offre" -> "success";
            default -> "neutral";
        };
    }

    private record ActivitySeed(Instant instant, String type, String title, String description) {
    }

    private static final class SkillCount {
        private final String name;
        private long count;

        private SkillCount(String name) {
            this.name = name;
        }

        private void increment() {
            this.count++;
        }

        private String name() {
            return name;
        }

        private long count() {
            return count;
        }
    }
}
