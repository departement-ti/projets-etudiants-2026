package com.recrutement.recrutement.service;

import com.recrutement.recrutement.dto.CompetenceRequest;
import com.recrutement.recrutement.dto.CompetenceResponse;
import com.recrutement.recrutement.entities.Competence;
import com.recrutement.recrutement.repositories.CompetenceRepository;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.stream.Collectors;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.stereotype.Service;

@Service
public class CompetenceService {
    public static final List<String> COMPETENCE_CATEGORIES = List.of(
            "Développement Frontend",
            "Développement Backend",
            "Développement Mobile",
            "Full Stack",
            "Langage de programmation",
            "Base de données",
            "DevOps",
            "Cloud",
            "Cybersécurité",
            "Intelligence Artificielle",
            "Data Science",
            "Data Engineering",
            "Réseaux",
            "Systèmes embarqués",
            "QA / Test",
            "UI/UX Design",
            "Gestion de projet",
            "Business / Analyse",
            "Marketing digital",
            "Vente / Commercial",
            "Communication",
            "Finance / Comptabilité",
            "Ressources humaines",
            "Bureautique",
            "Langues",
            "Soft Skills"
    );

    private static final String DEFAULT_COMPETENCE_CATEGORY = "Langage de programmation";
    private final CompetenceRepository competenceRepository;

    public CompetenceService(CompetenceRepository competenceRepository) {
        this.competenceRepository = competenceRepository;
    }

    public List<CompetenceResponse> getCompetences(String query, String type) {
        String normalizedQuery = normalize(query);
        String normalizedType = normalizeCompetenceType(type);

        List<Competence> items;
        if (!normalizedQuery.isEmpty()) {
            items = competenceRepository.findByNomContainingIgnoreCaseOrderByTypeAscNomAsc(normalizedQuery);
        } else {
            items = competenceRepository.findAllByOrderByTypeAscNomAsc();
        }

        return items.stream()
                .map(this::toResponse)
                .filter(item -> normalizedType.isEmpty() || item.getType().equalsIgnoreCase(normalizedType))
                .sorted(Comparator.comparing(CompetenceResponse::getType, String.CASE_INSENSITIVE_ORDER)
                        .thenComparing(CompetenceResponse::getNom, String.CASE_INSENSITIVE_ORDER))
                .collect(Collectors.toList());
    }

    public CompetenceResponse createCompetence(CompetenceRequest request) {
        String nom = normalizeCompetenceName(normalizeRequired(request.getNom(), "Le nom de la competence est obligatoire."));
        String type = requireCompetenceType(request.getType());

        if (findByNormalizedName(nom).isPresent()) {
            throw new RuntimeException("Une competence avec ce nom existe deja.");
        }

        Competence competence = Competence.builder()
                .nom(nom)
                .type(type)
                .description(normalize(request.getDescription()))
                .build();

        return toResponse(competenceRepository.save(competence));
    }

    public CompetenceResponse updateCompetence(Long id, CompetenceRequest request) {
        Competence competence = competenceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Competence introuvable."));

        String nom = normalizeCompetenceName(normalizeRequired(request.getNom(), "Le nom de la competence est obligatoire."));
        String type = requireCompetenceType(request.getType());

        Optional<Competence> existing = findByNormalizedName(nom);
        if (existing.isPresent() && !existing.get().getId().equals(id)) {
            throw new RuntimeException("Une competence avec ce nom existe deja.");
        }

        competence.setNom(nom);
        competence.setType(type);
        competence.setDescription(normalize(request.getDescription()));

        return toResponse(competenceRepository.save(competence));
    }

    public void deleteCompetence(Long id) {
        Competence competence = competenceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Competence introuvable."));

        competenceRepository.delete(competence);
    }

    public Competence resolveOrCreateCompetence(String rawName) {
        String normalizedName = normalizeCompetenceName(normalizeRequired(rawName, "Le nom de la competence est obligatoire."));

        return findByNormalizedName(normalizedName).orElseGet(() -> competenceRepository.save(
                Competence.builder()
                        .nom(normalizedName)
                        .type(inferCompetenceType(normalizedName))
                        .description("")
                        .build()
        ));
    }

    public Optional<Competence> findByNormalizedName(String rawName) {
        String normalized = normalizeToken(rawName);
        if (normalized.isEmpty()) {
            return Optional.empty();
        }

        return competenceRepository.findAllByOrderByTypeAscNomAsc().stream()
                .filter(item -> normalizeToken(item.getNom()).equals(normalized))
                .findFirst();
    }

    public Optional<Competence> findById(Long id) {
        return id == null ? Optional.empty() : competenceRepository.findById(id);
    }

    private CompetenceResponse toResponse(Competence competence) {
        String normalizedName = normalizeCompetenceName(competence.getNom());
        String normalizedType = normalizeCompetenceType(competence.getType());
        if (normalizedType.isBlank() || !isKnownCompetenceCategory(normalizedType)) {
            normalizedType = inferCompetenceType(normalizedName);
        }

        CompetenceResponse response = new CompetenceResponse();
        response.setId(competence.getId());
        response.setNom(normalizedName);
        response.setType(normalizedType);
        response.setDescription(competence.getDescription());
        return response;
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim();
    }

    private String normalizeRequired(String value, String errorMessage) {
        String normalized = normalize(value);
        if (normalized.isEmpty()) {
            throw new RuntimeException(errorMessage);
        }
        return normalized;
    }

    private String normalizeCompetenceName(String value) {
        String compact = normalize(value)
                .replaceAll("[_]+", " ")
                .replaceAll("\\s+", " ")
                .trim();
        if (compact.isEmpty()) {
            return compact;
        }

        return switch (normalizeToken(compact)) {
            case "javascript" -> "JavaScript";
            case "typescript" -> "TypeScript";
            case "nodejs", "node.js" -> "Node.js";
            case "nestjs" -> "NestJS";
            case "nextjs" -> "Next.js";
            case "reactjs", "react.js", "react" -> "React";
            case "vuejs", "vue.js", "vue" -> "Vue.js";
            case "angularjs", "angular" -> "Angular";
            case "springboot", "spring boot" -> "Spring Boot";
            case "postgresql", "postgres" -> "PostgreSQL";
            case "mysql" -> "MySQL";
            case "mongodb", "mongo" -> "MongoDB";
            case "sqlserver", "mssql" -> "SQL Server";
            case "aws" -> "AWS";
            case "gcp" -> "GCP";
            case "azure" -> "Azure";
            case "docker" -> "Docker";
            case "kubernetes", "k8s" -> "Kubernetes";
            case "git" -> "Git";
            case "github" -> "GitHub";
            case "gitlab" -> "GitLab";
            case "ci/cd", "cicd" -> "CI/CD";
            case "restapi", "rest api" -> "REST API";
            case "graphql" -> "GraphQL";
            case "html" -> "HTML";
            case "css" -> "CSS";
            case "scss", "sass" -> "SCSS";
            case "tailwindcss", "tailwind" -> "Tailwind CSS";
            case "bootstrap" -> "Bootstrap";
            case "ui/ux", "ux/ui" -> "UI/UX";
            case "figma" -> "Figma";
            case "powerbi", "power bi" -> "Power BI";
            case "machinelearning", "machine learning" -> "Machine Learning";
            case "deeplearning", "deep learning" -> "Deep Learning";
            case "artificialintelligence", "artificial intelligence" -> "Artificial Intelligence";
            case "openai" -> "OpenAI";
            default -> compact;
        };
    }

    public String normalizeCompetenceType(String rawType) {
        String cleaned = normalize(rawType);
        if (cleaned.isEmpty()) {
            return "";
        }

        String token = normalizeToken(cleaned);
        for (String category : COMPETENCE_CATEGORIES) {
            if (normalizeToken(category).equals(token)) {
                return category;
            }
        }

        return switch (token) {
            case "frontend", "developpementfrontend", "developpementwebfrontend", "front" -> "Développement Frontend";
            case "backend", "developpementbackend", "api", "serveur", "back" -> "Développement Backend";
            case "mobile", "developpementmobile", "android", "ios", "flutter", "reactnative" -> "Développement Mobile";
            case "fullstack", "full-stack", "developpementfullstack" -> "Full Stack";
            case "langagedeprogrammation", "langagesdeprogrammation", "programmation", "language", "languages" -> "Langage de programmation";
            case "basededonnees", "database", "databases", "bdd", "sql" -> "Base de données";
            case "devops", "ci", "cicd" -> "DevOps";
            case "cloud" -> "Cloud";
            case "cybersecurite", "securite", "security" -> "Cybersécurité";
            case "ia", "ai", "intelligenceartificielle", "machinelearning", "deeplearning", "llm", "genai" -> "Intelligence Artificielle";
            case "datascience", "science", "scienceofdata" -> "Data Science";
            case "dataengineering", "engineeringdata", "etl" -> "Data Engineering";
            case "reseaux", "reseau", "network", "networking" -> "Réseaux";
            case "systemesembarques", "embarque", "embedded" -> "Systèmes embarqués";
            case "qatest", "qa", "test", "tests", "testing", "qualityassurance" -> "QA / Test";
            case "uiuxdesign", "uiux", "uxui", "design", "productdesign" -> "UI/UX Design";
            case "gestiondeprojet", "projectmanagement", "agile", "scrum", "management" -> "Gestion de projet";
            case "businessanalyse", "business", "analyse", "analysis", "businessanalysis" -> "Business / Analyse";
            case "marketingdigital", "marketing", "seo", "sea", "growth" -> "Marketing digital";
            case "ventecommercial", "vente", "commercial", "sales" -> "Vente / Commercial";
            case "communication" -> "Communication";
            case "financecomptabilite", "finance", "comptabilite", "accounting" -> "Finance / Comptabilité";
            case "ressourceshumaines", "rh", "hr", "humanresources" -> "Ressources humaines";
            case "bureautique", "office", "officeautomation" -> "Bureautique";
            case "langues", "langue", "languageskills" -> "Langues";
            case "softskills", "softskill", "soft", "competencescomportementales", "savoirfaire", "savoiretre" -> "Soft Skills";
            default -> cleaned;
        };
    }

    private String requireCompetenceType(String rawType) {
        String normalizedType = normalizeCompetenceType(normalizeRequired(rawType, "La categorie de la competence est obligatoire."));
        if (!isKnownCompetenceCategory(normalizedType)) {
            throw new RuntimeException("Categorie de competence invalide.");
        }
        return normalizedType;
    }

    private boolean isKnownCompetenceCategory(String value) {
        String token = normalizeToken(value);
        return COMPETENCE_CATEGORIES.stream()
                .map(this::normalizeToken)
                .anyMatch(token::equals);
    }

    @Transactional
    public void synchronizeStoredCategories() {
        List<Competence> competences = new ArrayList<>(competenceRepository.findAll());
        boolean hasChanges = false;

        for (Competence competence : competences) {
            String normalizedName = normalizeCompetenceName(competence.getNom());
            String normalizedType = normalizeCompetenceType(competence.getType());
            String resolvedType = normalizedType.isBlank() ? inferCompetenceType(normalizedName) : normalizedType;

            if (!normalizedName.equals(competence.getNom())) {
                competence.setNom(normalizedName);
                hasChanges = true;
            }

            if (!resolvedType.equals(competence.getType())) {
                competence.setType(resolvedType);
                hasChanges = true;
            }
        }

        if (hasChanges) {
            competenceRepository.saveAll(competences);
        }
    }

    private String inferCompetenceType(String competenceName) {
        String normalized = normalizeToken(competenceName);
        if (normalized.matches(".*(angular|react|vue|html|css|scss|sass|bootstrap|tailwind|figma|uiux|uxui|frontend|webflow).*")) {
            return "Développement Frontend";
        }
        if (normalized.matches(".*(android|ios|swift|kotlin|flutter|reactnative|xamarin|mobile).*")) {
            return "Développement Mobile";
        }
        if (normalized.matches(".*(fullstack|mern|mean|jamstack).*")) {
            return "Full Stack";
        }
        if (normalized.matches(".*(java|spring|node|nestjs|express|php|laravel|symfony|dotnet|csharp|api|graphql|django|flask|backend|microservice).*")) {
            return "Développement Backend";
        }
        if (normalized.matches(".*(javascript|typescript|python|java|kotlin|swift|php|csharp|cplusplus|cpp|c|ruby|go|rust).*")) {
            return "Langage de programmation";
        }
        if (normalized.matches(".*(sql|postgres|mysql|oracle|mongodb|mongo|redis|database|sqlite|cassandra|elasticsearch).*")) {
            return "Base de données";
        }
        if (normalized.matches(".*(devops|ci|cicd|jenkins|gitlabci|githubactions|terraform|ansible).*")) {
            return "DevOps";
        }
        if (normalized.matches(".*(aws|azure|gcp|docker|kubernetes|cloud|serverless).*")) {
            return "Cloud";
        }
        if (normalized.matches(".*(cyber|security|pentest|soc|siem|cryptography|forensic).*")) {
            return "Cybersécurité";
        }
        if (normalized.matches(".*(groq|openai|machinelearning|deeplearning|artificialintelligence|llm|genai|nlp|computervision|ai).*")) {
            return "Intelligence Artificielle";
        }
        if (normalized.matches(".*(datascience|statistics|statistique|powerbi|tableau|bi|visualization|analysepredictive).*")) {
            return "Data Science";
        }
        if (normalized.matches(".*(dataengineering|etl|elt|spark|hadoop|airflow|bigquery|warehouse).*")) {
            return "Data Engineering";
        }
        if (normalized.matches(".*(reseau|reseaux|network|routing|switching|ccna|tcpip).*")) {
            return "Réseaux";
        }
        if (normalized.matches(".*(embarque|embedded|iot|arduino|raspberry|microcontroller|firmware).*")) {
            return "Systèmes embarqués";
        }
        if (normalized.matches(".*(qa|test|testing|selenium|cypress|qualityassurance|postman).*")) {
            return "QA / Test";
        }
        if (normalized.matches(".*(uiux|uxui|design|figma|adobexd|wireframe|prototype).*")) {
            return "UI/UX Design";
        }
        if (normalized.matches(".*(gestiondeprojet|projectmanagement|agile|scrum|kanban|pmp|management).*")) {
            return "Gestion de projet";
        }
        if (normalized.matches(".*(business|analyse|analysis|amoa|productowner|productmanager|crm).*")) {
            return "Business / Analyse";
        }
        if (normalized.matches(".*(marketing|seo|sea|growth|content|socialmedia|ads).*")) {
            return "Marketing digital";
        }
        if (normalized.matches(".*(vente|commercial|sales|prospection|negociation).*")) {
            return "Vente / Commercial";
        }
        if (normalized.matches(".*(communication|copywriting|presentation|redaction).*")) {
            return "Communication";
        }
        if (normalized.matches(".*(finance|comptabilite|accounting|excel|audit|controlling).*")) {
            return "Finance / Comptabilité";
        }
        if (normalized.matches(".*(ressourceshumaines|rh|hr|recrutement|paie).*")) {
            return "Ressources humaines";
        }
        if (normalized.matches(".*(word|excel|powerpoint|office|bureautique).*")) {
            return "Bureautique";
        }
        if (normalized.matches(".*(anglais|francais|espagnol|allemand|italien|arabe|langue|ielts|toeic).*")) {
            return "Langues";
        }
        if (normalized.matches(".*(leadership|teamwork|collaboration|problemsolving|organisation|adaptabilite|creativite|softskill).*")) {
            return "Soft Skills";
        }
        return DEFAULT_COMPETENCE_CATEGORY;
    }

    private String normalizeToken(String value) {
        String ascii = Normalizer.normalize(normalize(value), Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "");
        return ascii.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9+/#.]","");
    }
}
