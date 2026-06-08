package com.recrutement.recrutement.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.recrutement.recrutement.dto.AssistantCandidateSearchRequest;
import com.recrutement.recrutement.dto.AssistantCandidateSearchResponse;
import com.recrutement.recrutement.dto.AssistantCandidateSuggestionResponse;
import com.recrutement.recrutement.dto.AssistantCompanyDescriptionRequest;
import com.recrutement.recrutement.dto.AssistantCompanyDescriptionResponse;
import com.recrutement.recrutement.dto.AssistantChatRequest;
import com.recrutement.recrutement.dto.AssistantChatResponse;
import com.recrutement.recrutement.dto.AssistantInterviewQuestionsRequest;
import com.recrutement.recrutement.dto.AssistantInterviewQuestionsResponse;
import com.recrutement.recrutement.dto.AssistantOfferDraftRequest;
import com.recrutement.recrutement.dto.AssistantOfferDraftResponse;
import com.recrutement.recrutement.dto.CandidateProfileRequest;
import com.recrutement.recrutement.entities.Candidate;
import com.recrutement.recrutement.entities.Entreprise;
import com.recrutement.recrutement.entities.Offre;
import com.recrutement.recrutement.entities.Recruiter;
import com.recrutement.recrutement.entities.Role;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.repositories.CandidateRepository;
import com.recrutement.recrutement.repositories.OffreRepository;
import com.recrutement.recrutement.repositories.RecruiterRepository;
import java.io.IOException;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import org.springframework.stereotype.Service;

@Service
public class AssistantAgentService {
    private final ObjectMapper objectMapper;
    private final CandidateRepository candidateRepository;
    private final RecruiterRepository recruiterRepository;
    private final OffreRepository offreRepository;
    private final MatchingService matchingService;
    private final ApplicationService applicationService;
    private final PythonGroqAgentService pythonGroqAgentService;

    public AssistantAgentService(
            ObjectMapper objectMapper,
            CandidateRepository candidateRepository,
            RecruiterRepository recruiterRepository,
            OffreRepository offreRepository,
            MatchingService matchingService,
            ApplicationService applicationService,
            PythonGroqAgentService pythonGroqAgentService
    ) {
        this.objectMapper = objectMapper;
        this.candidateRepository = candidateRepository;
        this.recruiterRepository = recruiterRepository;
        this.offreRepository = offreRepository;
        this.matchingService = matchingService;
        this.applicationService = applicationService;
        this.pythonGroqAgentService = pythonGroqAgentService;
    }

    public AssistantOfferDraftResponse generateOfferDraft(User currentUser, AssistantOfferDraftRequest request) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        JsonNode response = pythonGroqAgentService.invoke("generate_offer", Map.of(
                "recruiter", buildRecruiterContext(recruiter),
                "offerDraft", buildOfferDraftContext(request)
        ));

        AssistantOfferDraftResponse result = new AssistantOfferDraftResponse();
        result.setMessage(readText(response, "message", "Description generee avec succes."));
        result.setGeneratedDescription(readText(response, "generatedDescription", ""));
        result.setHighlights(readStringList(response.get("highlights")));
        result.setKeywords(readStringList(response.get("keywords")));
        return result;
    }

    public AssistantInterviewQuestionsResponse suggestInterviewQuestions(User currentUser, AssistantInterviewQuestionsRequest request) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        JsonNode response = pythonGroqAgentService.invoke("suggest_questions", Map.of(
                "recruiter", buildRecruiterContext(recruiter),
                "interview", Map.of(
                        "offerTitle", safe(request.getOfferTitle()),
                        "jobDescription", safe(request.getJobDescription()),
                        "seniority", safe(request.getSeniority()),
                        "count", request.getCount() == null || request.getCount() <= 0 ? 6 : request.getCount(),
                        "focusSkills", defaultCollection(request.getFocusSkills())
                )
        ));

        AssistantInterviewQuestionsResponse result = new AssistantInterviewQuestionsResponse();
        result.setMessage(readText(response, "message", "Questions d'entretien generees."));
        result.setIntro(readText(response, "intro", ""));
        result.setQuestions(readStringList(response.get("questions")));
        return result;
    }

    public AssistantCandidateSearchResponse findCandidates(User currentUser, AssistantCandidateSearchRequest request) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        String query = safe(request.getQuery());
        if (query.isBlank()) {
            throw new RuntimeException("Veuillez saisir une recherche en langage naturel.");
        }

        Offre offer = resolveRecruiterOffer(recruiter, request.getOfferId());
        List<Map<String, Object>> candidates = candidateRepository.findAll().stream()
                .map(candidate -> buildCandidateContext(candidate, offer))
                .toList();

        JsonNode response = pythonGroqAgentService.invoke("find_candidates", Map.of(
                "recruiter", buildRecruiterContext(recruiter),
                "query", query,
                "limit", request.getLimit() == null || request.getLimit() <= 0 ? 6 : request.getLimit(),
                "offerContext", offer == null ? Map.of() : buildOfferContext(offer),
                "candidates", candidates
        ));

        AssistantCandidateSearchResponse result = new AssistantCandidateSearchResponse();
        result.setMessage(readText(response, "message", "Suggestions de candidats generees."));

        List<AssistantCandidateSuggestionResponse> suggestions = new ArrayList<>();
        Map<String, Map<String, Object>> candidatesByEmail = indexCandidatesBy(candidates, "email");
        Map<String, Map<String, Object>> candidatesByName = indexCandidatesBy(candidates, "name");
        JsonNode suggestionNode = response.get("suggestions");
        if (suggestionNode != null && suggestionNode.isArray()) {
            for (JsonNode item : suggestionNode) {
                AssistantCandidateSuggestionResponse suggestion =
                        objectMapper.convertValue(item, AssistantCandidateSuggestionResponse.class);
                hydrateCandidateIdentity(suggestion, candidatesByEmail, candidatesByName);
                suggestions.add(suggestion);
            }
        }
        result.setSuggestions(suggestions);
        return result;
    }

    public AssistantCompanyDescriptionResponse generateCompanyDescription(User currentUser, AssistantCompanyDescriptionRequest request) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        JsonNode response = pythonGroqAgentService.invoke("generate_company_description", Map.of(
                "recruiter", buildRecruiterContext(recruiter),
                "company", buildCompanyDescriptionContext(request, recruiter)
        ));

        AssistantCompanyDescriptionResponse result = new AssistantCompanyDescriptionResponse();
        result.setMessage(readText(response, "message", "Description entreprise generee avec succes."));
        result.setGeneratedDescription(readText(response, "generatedDescription", ""));
        result.setHighlights(readStringList(response.get("highlights")));
        return result;
    }

    public AssistantChatResponse coachCandidate(User currentUser, AssistantChatRequest request) {
        return chat(currentUser, request);
    }

    public AssistantChatResponse chat(User currentUser, AssistantChatRequest request) {
        if (currentUser == null) {
            throw new RuntimeException("Utilisateur introuvable pour l'assistant.");
        }

        String message = safe(request == null ? null : request.resolveMessage());
        if (message.isBlank()) {
            throw new RuntimeException("Veuillez saisir votre demande a l'assistant.");
        }

        if (currentUser.getRole() == Role.CANDIDATE) {
            return chatForCandidate(currentUser, request, message);
        }

        if (currentUser.getRole() == Role.RECRUITER) {
            return chatForRecruiter(currentUser, request, message);
        }

        throw new RuntimeException("Cette fonctionnalite IA est reservee aux candidats et aux recruteurs.");
    }

    private AssistantChatResponse chatForCandidate(User currentUser, AssistantChatRequest request, String message) {
        Candidate candidate = getCurrentCandidate(currentUser);
        Offre targetOffer = request != null
                && request.getTargetId() != null
                && "JOB_OFFER".equals(normalizeContextType(request.getContextType()))
                ? resolveCandidateOffer(request.getTargetId())
                : null;
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("role", "CANDIDATE");
        payload.put("contextType", normalizeContextType(request == null ? null : request.getContextType()));
        payload.put("targetId", request == null ? null : request.getTargetId());
        payload.put("message", message);
        payload.put("history", request == null ? List.of() : defaultCollection(request.getHistory()));
        payload.put("candidate", buildCandidateContext(candidate, targetOffer));
        payload.put("applications", applicationService.getCandidateApplications(currentUser));
        if (targetOffer != null) {
            payload.put("targetOffer", buildOfferContext(targetOffer));
        }

        try {
            JsonNode response = pythonGroqAgentService.invoke("assistant_chat", payload);
            return buildChatResponse(response, "groq");
        } catch (RuntimeException ex) {
            return buildFallbackChatResponse(
                    "Conseil candidat genere localement.",
                    buildCandidateFallback(message),
                    List.of(
                            "Mettez a jour votre profil avec des competences mesurables.",
                            "Ajoutez des experiences recentes avec resultats concrets.",
                            "Comparez votre profil aux exigences de l'offre ciblee."
                    ),
                    "fallback"
            );
        }
    }

    private AssistantChatResponse chatForRecruiter(User currentUser, AssistantChatRequest request, String message) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("role", "RECRUITER");
        payload.put("contextType", normalizeContextType(request == null ? null : request.getContextType()));
        payload.put("targetId", request == null ? null : request.getTargetId());
        payload.put("message", message);
        payload.put("history", request == null ? List.of() : defaultCollection(request.getHistory()));
        payload.put("recruiter", buildRecruiterContext(recruiter));
        payload.put("offers", buildRecruiterOfferSummaries(recruiter));

        if (request != null && request.getTargetId() != null && "JOB_OFFER".equals(normalizeContextType(request.getContextType()))) {
            Offre offer = resolveRecruiterOffer(recruiter, request.getTargetId());
            payload.put("targetOffer", buildOfferContext(offer));
        }

        try {
            JsonNode response = pythonGroqAgentService.invoke("assistant_chat", payload);
            return buildChatResponse(response, "groq");
        } catch (RuntimeException ex) {
            return buildFallbackChatResponse(
                    "Conseil recruteur genere localement.",
                    buildRecruiterFallback(message),
                    List.of(
                            "Donnez un titre de poste plus precis.",
                            "Ajoutez 5 a 8 competences prioritaires.",
                            "Indiquez le niveau d'experience et le contexte d'equipe."
                    ),
                    "fallback"
            );
        }
    }

    private Recruiter getCurrentRecruiter(User currentUser) {
        if (currentUser == null || currentUser.getRole() != Role.RECRUITER) {
            throw new RuntimeException("Cette fonctionnalite IA est reservee aux recruteurs.");
        }

        Recruiter recruiter = currentUser.getId() == null
                ? null
                : recruiterRepository.findById(currentUser.getId()).orElse(null);

        if (recruiter == null) {
            recruiter = recruiterRepository.findByEmail(currentUser.getEmail());
        }

        if (recruiter == null) {
            throw new RuntimeException("Profil recruteur introuvable.");
        }

        return recruiter;
    }

    private Candidate getCurrentCandidate(User currentUser) {
        if (currentUser == null || currentUser.getRole() != Role.CANDIDATE) {
            throw new RuntimeException("Cette fonctionnalite IA est reservee aux candidats.");
        }

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

    private Offre resolveCandidateOffer(Long offerId) {
        if (offerId == null) {
            return null;
        }

        Offre offer = offreRepository.findById(offerId)
                .orElseThrow(() -> new RuntimeException("Offre introuvable pour le conseil IA."));

        if (!"PUBLIEE".equals(safe(offer.getStatut()).toUpperCase())) {
            throw new RuntimeException("Cette offre n'est pas disponible pour le conseil IA.");
        }

        return offer;
    }

    private Offre resolveRecruiterOffer(Recruiter recruiter, Long offerId) {
        if (offerId == null) {
            return null;
        }

        Offre offer = offreRepository.findById(offerId)
                .orElseThrow(() -> new RuntimeException("Offre introuvable pour la recherche IA."));

        if (offer.getRecruiter() == null || !Objects.equals(offer.getRecruiter().getId(), recruiter.getId())) {
            throw new RuntimeException("Vous ne pouvez utiliser que vos propres offres pour la recherche IA.");
        }

        return offer;
    }

    private Map<String, Object> buildRecruiterContext(Recruiter recruiter) {
        Map<String, Object> context = new LinkedHashMap<>();
        context.put("name", safe(recruiter.getNom()));
        context.put("email", safe(recruiter.getEmail()));
        context.put("poste", safe(recruiter.getPoste()));
        context.put("fonction", safe(recruiter.getFonction()));
        context.put("departement", safe(recruiter.getDepartement()));
        context.put("companyName", resolveCompanyName(recruiter));
        return context;
    }

    private Map<String, Object> buildOfferDraftContext(AssistantOfferDraftRequest request) {
        Map<String, Object> context = new LinkedHashMap<>();
        context.put("title", safe(request.getTitle()));
        context.put("category", safe(request.getCategory()));
        context.put("location", safe(request.getLocation()));
        context.put("contractType", safe(request.getContractType()));
        context.put("experienceLevel", safe(request.getExperienceLevel()));
        context.put("tone", safe(request.getTone()));
        context.put("context", safe(request.getContext()));
        context.put("skills", defaultCollection(request.getSkills()));
        return context;
    }

    private Map<String, Object> buildCompanyDescriptionContext(AssistantCompanyDescriptionRequest request, Recruiter recruiter) {
        Map<String, Object> context = new LinkedHashMap<>();
        context.put("companyName", safe(request.getNomEntreprise()));
        context.put("sector", safe(request.getSecteur()));
        context.put("address", safe(request.getAdresse()));
        context.put("email", safe(request.getEmail()));
        context.put("subscriptionStatus", safe(request.getAbonnementActif()));
        context.put("website", safe(request.getSiteWeb()));
        context.put("currentDescription", safe(request.getCurrentDescription()));
        context.put("recruiterName", safe(recruiter.getNom()));
        context.put("recruiterRole", safe(recruiter.getPoste()));
        return context;
    }

    private Map<String, Object> buildOfferContext(Offre offer) {
        Map<String, Object> context = new LinkedHashMap<>();
        context.put("id", offer.getId());
        context.put("title", safe(offer.getTitre()));
        context.put("category", safe(offer.getCategorie()));
        context.put("description", safe(offer.getDescription()));
        context.put("location", safe(offer.getLocalisation()));
        context.put("experience", safe(offer.getExperienceRequise()));
        context.put("contractType", safe(offer.getTypeContrat()));
        context.put("skills", extractOfferSkillNames(offer.getCompetencesJson()));
        return context;
    }

    private List<Map<String, Object>> buildRecruiterOfferSummaries(Recruiter recruiter) {
        return offreRepository.findByRecruiter_IdOrderByDateDesc(recruiter.getId()).stream()
                .limit(8)
                .map(this::buildOfferContext)
                .toList();
    }

    private Map<String, Object> buildCandidateContext(Candidate candidate, Offre offer) {
        Map<String, Object> context = new LinkedHashMap<>();
        context.put("candidateId", candidate.getId());
        context.put("name", safe(candidate.getNom()));
        context.put("email", safe(candidate.getEmail()));
        context.put("jobTitle", nonEmpty(candidate.getPosteRecherche(), candidate.getProfession()));
        context.put("location", safe(candidate.getLocalisation()));
        context.put("experience", candidate.getExperience());
        context.put("summary", safe(candidate.getDescription()));
        context.put("skills", extractCandidateSkillTitles(candidate.getSkillsJson()));
        context.put("education", extractTextFields(candidate.getEducationJson(), List.of("title", "degree", "institute", "year")));
        context.put("experiences", extractTextFields(candidate.getExperiencesJson(), List.of("title", "company", "period", "description")));

        if (offer != null) {
            MatchingService.MatchResult match = matchingService.evaluate(candidate, offer);
            context.put("matchingScore", match.getScore());
            context.put("matchingSkills", match.getMatchingSkills());
            context.put("missingSkills", match.getMissingSkills());
        } else {
            context.put("matchingScore", null);
            context.put("matchingSkills", List.of());
            context.put("missingSkills", List.of());
        }

        return context;
    }

    private List<String> extractCandidateSkillTitles(String skillsJson) {
        if (safe(skillsJson).isBlank()) {
            return List.of();
        }

        try {
            List<CandidateProfileRequest.CandidateSkillRequest> skills = objectMapper.readValue(
                    skillsJson,
                    new TypeReference<List<CandidateProfileRequest.CandidateSkillRequest>>() { }
            );

            return skills.stream()
                    .map(skill -> safe(skill.getTitle()))
                    .filter(value -> !value.isBlank())
                    .distinct()
                    .toList();
        } catch (IOException ex) {
            return List.of();
        }
    }

    private List<String> extractOfferSkillNames(String competencesJson) {
        if (safe(competencesJson).isBlank()) {
            return List.of();
        }

        try {
            JsonNode node = objectMapper.readTree(competencesJson);
            if (!node.isArray()) {
                return List.of();
            }

            List<String> values = new ArrayList<>();
            for (JsonNode item : node) {
                String value = safe(item.path("nom").asText());
                if (!value.isBlank()) {
                    values.add(value);
                }
            }
            return values;
        } catch (IOException ex) {
            return List.of();
        }
    }

    private List<String> extractTextFields(String json, List<String> fieldOrder) {
        if (safe(json).isBlank()) {
            return List.of();
        }

        try {
            JsonNode node = objectMapper.readTree(json);
            if (!node.isArray()) {
                return List.of();
            }

            List<String> values = new ArrayList<>();
            for (JsonNode item : node) {
                List<String> parts = new ArrayList<>();
                for (String field : fieldOrder) {
                    String value = safe(item.path(field).asText());
                    if (!value.isBlank()) {
                        parts.add(value);
                    }
                }
                if (!parts.isEmpty()) {
                    values.add(String.join(" - ", parts));
                }
            }
            return values;
        } catch (IOException ex) {
            return List.of();
        }
    }

    private Map<String, Map<String, Object>> indexCandidatesBy(List<Map<String, Object>> candidates, String key) {
        Map<String, Map<String, Object>> index = new HashMap<>();
        for (Map<String, Object> candidate : candidates) {
            Object rawValue = candidate.get(key);
            String value = rawValue == null ? "" : safe(String.valueOf(rawValue));
            if (!value.isBlank()) {
                index.put(value.toLowerCase(), candidate);
            }
        }
        return index;
    }

    private void hydrateCandidateIdentity(
            AssistantCandidateSuggestionResponse suggestion,
            Map<String, Map<String, Object>> candidatesByEmail,
            Map<String, Map<String, Object>> candidatesByName
    ) {
        if (suggestion.getCandidateId() != null && suggestion.getCandidateId() > 0) {
            return;
        }

        Map<String, Object> sourceCandidate = null;
        String email = safe(suggestion.getEmail()).toLowerCase();
        String name = safe(suggestion.getName()).toLowerCase();

        if (!email.isBlank()) {
            sourceCandidate = candidatesByEmail.get(email);
        }

        if (sourceCandidate == null && !name.isBlank()) {
            sourceCandidate = candidatesByName.get(name);
        }

        if (sourceCandidate == null) {
            return;
        }

        Object candidateId = sourceCandidate.get("candidateId");
        if (candidateId instanceof Number numberValue) {
            suggestion.setCandidateId(numberValue.longValue());
        }

        if (safe(suggestion.getEmail()).isBlank()) {
            Object rawEmail = sourceCandidate.get("email");
            suggestion.setEmail(rawEmail == null ? "" : safe(String.valueOf(rawEmail)));
        }

        if (safe(suggestion.getName()).isBlank()) {
            Object rawName = sourceCandidate.get("name");
            suggestion.setName(rawName == null ? "" : safe(String.valueOf(rawName)));
        }
    }

    private List<String> defaultCollection(List<String> values) {
        if (values == null) {
            return List.of();
        }
        return values.stream().map(this::safe).filter(value -> !value.isBlank()).toList();
    }

    private AssistantChatResponse buildChatResponse(JsonNode response, String source) {
        AssistantChatResponse result = new AssistantChatResponse();
        String content = readText(response, "response", readText(response, "content", ""));
        result.setMessage(readText(response, "message", "Reponse de l'assistant prete."));
        result.setContent(content);
        result.setResponse(content);
        result.setSuggestions(readStringList(response.get("suggestions")));
        result.setSource(source);
        result.setCreatedAt(OffsetDateTime.now().toString());
        return result;
    }

    private AssistantChatResponse buildFallbackChatResponse(String message, String content, List<String> suggestions, String source) {
        AssistantChatResponse result = new AssistantChatResponse();
        result.setMessage(message);
        result.setContent(content);
        result.setResponse(content);
        result.setSuggestions(suggestions);
        result.setSource(source);
        result.setCreatedAt(OffsetDateTime.now().toString());
        return result;
    }

    private String buildCandidateFallback(String message) {
        return "Voici une aide immediate sur votre demande : "
                + message
                + ". Commencez par renforcer votre titre cible, vos competences principales et vos experiences avec des resultats concrets. "
                + "Si votre objectif est un entretien, preparez 3 exemples de projets, 3 competences fortes et 1 axe d'amelioration assume.";
    }

    private String buildRecruiterFallback(String message) {
        return "Voici une premiere reponse exploitable sur votre demande : "
                + message
                + ". Structurez votre besoin avec un titre clair, 5 a 8 competences indispensables, le niveau d'experience attendu, "
                + "puis listez les criteres obligatoires et les criteres souhaites pour obtenir des sorties IA plus pertinentes.";
    }

    private String normalizeContextType(String contextType) {
        String value = safe(contextType).toUpperCase();
        if (value.isBlank()) {
            return "GENERAL";
        }
        return switch (value) {
            case "GENERAL", "CANDIDATE_PROFILE", "JOB_OFFER", "APPLICATION", "INTERVIEW", "AI_TEST" -> value;
            default -> "GENERAL";
        };
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

    private String readText(JsonNode node, String field, String fallback) {
        if (node == null) {
            return fallback;
        }

        String value = safe(node.path(field).asText());
        return value.isBlank() ? fallback : value;
    }

    private List<String> readStringList(JsonNode node) {
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

    private String nonEmpty(String primary, String fallback) {
        String value = safe(primary);
        return value.isBlank() ? safe(fallback) : value;
    }

    private String safe(String value) {
        return value == null ? "" : value.trim();
    }
}
