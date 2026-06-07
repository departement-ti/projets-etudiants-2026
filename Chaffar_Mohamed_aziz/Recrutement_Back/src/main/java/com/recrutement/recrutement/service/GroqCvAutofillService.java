package com.recrutement.recrutement.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.recrutement.recrutement.dto.CandidateProfileAutofillResponse;
import com.recrutement.recrutement.dto.CandidateProfileRequest;
import com.recrutement.recrutement.entities.Competence;
import com.recrutement.recrutement.repositories.CompetenceRepository;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.apache.poi.hwpf.extractor.WordExtractor;
import org.apache.poi.xwpf.extractor.XWPFWordExtractor;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class GroqCvAutofillService {
    private static final Logger log = LoggerFactory.getLogger(GroqCvAutofillService.class);
    private static final int MAX_CV_TEXT_LENGTH = 50000;

    private final ObjectMapper objectMapper;
    private final CompetenceRepository competenceRepository;
    private final PythonGroqAgentService pythonGroqAgentService;

    public GroqCvAutofillService(
            ObjectMapper objectMapper,
            CompetenceRepository competenceRepository,
            PythonGroqAgentService pythonGroqAgentService
    ) {
        this.objectMapper = objectMapper;
        this.competenceRepository = competenceRepository;
        this.pythonGroqAgentService = pythonGroqAgentService;
    }

    public CandidateProfileAutofillResponse extractFromCv(MultipartFile cvFile) {
        if (cvFile == null || cvFile.isEmpty()) {
            throw new RuntimeException("Veuillez televerser un CV valide avant de lancer l'auto-remplissage.");
        }

        List<Competence> referential = competenceRepository.findAllByOrderByTypeAscNomAsc();
        String extractedText = limitCvText(extractTextFromCv(cvFile));
        if (clean(extractedText).isBlank()) {
            throw new RuntimeException("Le texte du CV est vide ou illisible. Utilisez un PDF, DOC, DOCX ou TXT plus exploitable.");
        }

        JsonNode rawResponse = pythonGroqAgentService.invoke("cv_autofill", Map.of(
                "fileName", clean(cvFile.getOriginalFilename()),
                "cvText", extractedText,
                "referentialSkills", referential.stream().limit(200).map(Competence::getNom).toList()
        ));

        CandidateProfileAutofillResponse response = toAutofillResponse(rawResponse);
        response.setMessage(
                readText(rawResponse, "message", "Le CV a ete analyse par Groq et le profil a ete pre-rempli.")
        );

        log.info("CV Autofill: analyse Groq reussie pour le fichier {}", clean(cvFile.getOriginalFilename()));
        return normalizeResponse(response, referential);
    }

    private CandidateProfileAutofillResponse toAutofillResponse(JsonNode response) {
        if (!response.isObject()) {
            throw new RuntimeException("La reponse Groq recue pour l'auto-remplissage est invalide.");
        }

        ObjectNode sanitized = ((ObjectNode) response).deepCopy();
        sanitized.remove(List.of("success"));

        try {
            return objectMapper.treeToValue(sanitized, CandidateProfileAutofillResponse.class);
        } catch (JsonProcessingException ex) {
            throw new RuntimeException("Le resultat recu depuis Groq est invalide pour l'auto-remplissage du profil.");
        }
    }

    private CandidateProfileAutofillResponse normalizeResponse(
            CandidateProfileAutofillResponse response,
            List<Competence> referential
    ) {
        CandidateProfileAutofillResponse normalized = response == null ? new CandidateProfileAutofillResponse() : response;

        normalized.setFullName(clean(normalized.getFullName()));
        normalized.setProfession(clean(normalized.getProfession()));
        normalized.setEmail(clean(normalized.getEmail()).toLowerCase(Locale.ROOT));
        normalized.setPhone(clean(normalized.getPhone()));
        normalized.setJobTitle(clean(normalized.getJobTitle()));
        normalized.setAddress(clean(normalized.getAddress()));
        normalized.setDescription(clean(normalized.getDescription()));

        List<CandidateProfileRequest.CandidateExperienceRequest> experiences =
                normalized.getExperiences() == null ? new ArrayList<>() : normalized.getExperiences();
        List<CandidateProfileRequest.CandidateEducationRequest> education =
                normalized.getEducation() == null ? new ArrayList<>() : normalized.getEducation();
        List<CandidateProfileRequest.CandidateSkillRequest> skills =
                normalized.getSkills() == null ? new ArrayList<>() : normalized.getSkills();

        normalized.setExperiences(
                experiences.stream()
                        .filter(Objects::nonNull)
                        .map(this::normalizeExperience)
                        .filter(this::hasExperienceContent)
                        .toList()
        );

        normalized.setEducation(
                education.stream()
                        .filter(Objects::nonNull)
                        .map(this::normalizeEducation)
                        .filter(this::hasEducationContent)
                        .toList()
        );

        normalized.setSkills(
                skills.stream()
                        .filter(Objects::nonNull)
                        .map(skill -> normalizeSkill(skill, referential))
                        .filter(this::hasSkillContent)
                        .toList()
        );

        return normalized;
    }

    private CandidateProfileRequest.CandidateExperienceRequest normalizeExperience(
            CandidateProfileRequest.CandidateExperienceRequest experience
    ) {
        CandidateProfileRequest.CandidateExperienceRequest normalized = new CandidateProfileRequest.CandidateExperienceRequest();
        normalized.setTitle(clean(experience.getTitle()));
        normalized.setCompany(clean(experience.getCompany()));
        normalized.setLocation(clean(experience.getLocation()));
        normalized.setPeriod(clean(experience.getPeriod()));
        normalized.setDescription(clean(experience.getDescription()));
        return normalized;
    }

    private CandidateProfileRequest.CandidateEducationRequest normalizeEducation(
            CandidateProfileRequest.CandidateEducationRequest education
    ) {
        CandidateProfileRequest.CandidateEducationRequest normalized = new CandidateProfileRequest.CandidateEducationRequest();
        normalized.setTitle(clean(education.getTitle()));
        normalized.setDegree(clean(education.getDegree()));
        normalized.setInstitute(clean(education.getInstitute()));
        normalized.setYear(clean(education.getYear()));
        return normalized;
    }

    private CandidateProfileRequest.CandidateSkillRequest normalizeSkill(
            CandidateProfileRequest.CandidateSkillRequest skill,
            List<Competence> referential
    ) {
        CandidateProfileRequest.CandidateSkillRequest normalized = new CandidateProfileRequest.CandidateSkillRequest();
        String normalizedTitle = clean(skill.getTitle());

        normalized.setTitle(normalizedTitle);
        normalized.setCompetenceId(resolveCompetenceId(normalizedTitle, referential));
        normalized.setLevel(normalizeLevel(skill.getLevel()));
        normalized.setYearsExperience(normalizeYearsExperience(skill.getYearsExperience()));
        normalized.setPercentage(clampPercentage(skill.getPercentage()));
        return normalized;
    }

    private Long resolveCompetenceId(String skillTitle, List<Competence> referential) {
        if (skillTitle.isBlank()) {
            return null;
        }

        String normalizedTitle = normalizeToken(skillTitle);
        for (Competence competence : referential) {
            if (normalizeToken(competence.getNom()).equals(normalizedTitle)) {
                return competence.getId();
            }
        }

        return referential.stream()
                .sorted(Comparator.comparingInt(item -> levenshteinDistance(normalizedTitle, normalizeToken(item.getNom()))))
                .filter(item -> levenshteinDistance(normalizedTitle, normalizeToken(item.getNom())) <= 2)
                .map(Competence::getId)
                .findFirst()
                .orElse(null);
    }

    private String normalizeLevel(String value) {
        String normalized = normalizeToken(value);
        return switch (normalized) {
            case "expert" -> "Expert";
            case "avance", "advanced", "senior" -> "Avance";
            case "debutant", "junior", "beginner" -> "Debutant";
            default -> "Intermediaire";
        };
    }

    private String normalizeYearsExperience(String value) {
        String cleaned = clean(value);
        return cleaned.isBlank() ? "1 an" : cleaned;
    }

    private Integer clampPercentage(Integer percentage) {
        if (percentage == null) {
            return 70;
        }
        return Math.max(0, Math.min(100, percentage));
    }

    private boolean hasExperienceContent(CandidateProfileRequest.CandidateExperienceRequest experience) {
        return !(experience.getTitle().isBlank()
                && experience.getCompany().isBlank()
                && experience.getLocation().isBlank()
                && experience.getPeriod().isBlank()
                && experience.getDescription().isBlank());
    }

    private boolean hasEducationContent(CandidateProfileRequest.CandidateEducationRequest education) {
        return !(education.getTitle().isBlank()
                && education.getDegree().isBlank()
                && education.getInstitute().isBlank()
                && education.getYear().isBlank());
    }

    private boolean hasSkillContent(CandidateProfileRequest.CandidateSkillRequest skill) {
        return !skill.getTitle().isBlank() || skill.getCompetenceId() != null;
    }

    private String extractTextFromCv(MultipartFile cvFile) {
        String fileName = clean(cvFile.getOriginalFilename()).toLowerCase(Locale.ROOT);

        try {
            if (fileName.endsWith(".docx")) {
                return extractDocxText(cvFile);
            }
            if (fileName.endsWith(".txt")) {
                return new String(cvFile.getBytes(), StandardCharsets.UTF_8);
            }
            if (fileName.endsWith(".pdf")) {
                return extractPdfText(cvFile);
            }
            if (fileName.endsWith(".doc")) {
                return extractDocText(cvFile);
            }
            return extractPrintableText(cvFile.getBytes());
        } catch (IOException ex) {
            throw new RuntimeException("Lecture du CV impossible pour l'auto-remplissage.");
        }
    }

    private String extractDocxText(MultipartFile cvFile) throws IOException {
        try (InputStream inputStream = cvFile.getInputStream();
             XWPFDocument document = new XWPFDocument(inputStream);
             XWPFWordExtractor extractor = new XWPFWordExtractor(document)) {
            String extracted = extractor.getText();
            if (!clean(extracted).isBlank()) {
                return extracted;
            }
        } catch (Exception ignored) {
            // Fallback to zip parsing below.
        }

        StringBuilder text = new StringBuilder();
        try (InputStream inputStream = cvFile.getInputStream();
             ZipInputStream zipInputStream = new ZipInputStream(inputStream, StandardCharsets.UTF_8)) {
            ZipEntry entry;
            while ((entry = zipInputStream.getNextEntry()) != null) {
                if (!"word/document.xml".equals(entry.getName())) {
                    continue;
                }
                String xml = new String(zipInputStream.readAllBytes(), StandardCharsets.UTF_8);
                xml = xml.replaceAll("</w:p>", "\n");
                xml = xml.replaceAll("<[^>]+>", " ");
                xml = xml.replaceAll("&amp;", "&");
                xml = xml.replaceAll("&lt;", "<");
                xml = xml.replaceAll("&gt;", ">");
                text.append(xml);
            }
        }

        return text.toString();
    }

    private String extractDocText(MultipartFile cvFile) throws IOException {
        try (InputStream inputStream = cvFile.getInputStream();
             WordExtractor extractor = new WordExtractor(inputStream)) {
            String extracted = extractor.getText();
            if (!clean(extracted).isBlank()) {
                return extracted;
            }
        } catch (Exception ignored) {
            // Fallback to printable extraction below.
        }
        return extractPrintableText(cvFile.getBytes());
    }

    private String extractPdfText(MultipartFile cvFile) throws IOException {
        try (PDDocument document = Loader.loadPDF(cvFile.getBytes())) {
            PDFTextStripper stripper = new PDFTextStripper();
            String extracted = stripper.getText(document);
            if (!clean(extracted).isBlank()) {
                return extracted;
            }
        } catch (Exception ignored) {
            // Fallback to lightweight extraction below.
        }

        String raw = new String(cvFile.getBytes(), StandardCharsets.ISO_8859_1);
        StringBuilder extracted = new StringBuilder();
        Matcher matcher = Pattern.compile("\\(([^\\)]{2,})\\)").matcher(raw);
        while (matcher.find()) {
            extracted.append(matcher.group(1)).append('\n');
        }

        String text = extracted.toString().trim();
        if (!text.isBlank()) {
            return text;
        }

        return extractPrintableText(cvFile.getBytes());
    }

    private String extractPrintableText(byte[] bytes) {
        String raw = new String(bytes, StandardCharsets.ISO_8859_1);
        return raw.replaceAll("[^\\p{L}\\p{N}@._+\\-\\n\\r:/ ]", " ")
                .replaceAll("[ ]{2,}", " ")
                .replaceAll("(\\r?\\n){3,}", "\n\n");
    }

    private String limitCvText(String text) {
        String cleaned = clean(text);
        if (cleaned.length() <= MAX_CV_TEXT_LENGTH) {
            return cleaned;
        }
        return cleaned.substring(0, MAX_CV_TEXT_LENGTH) + "\n\n[Texte tronque pour l'analyse IA]";
    }

    private String readText(JsonNode node, String field, String fallback) {
        if (node == null) {
            return fallback;
        }

        String value = clean(node.path(field).asText());
        return value.isBlank() ? fallback : value;
    }

    private String clean(String value) {
        return value == null ? "" : value.trim();
    }

    private String normalizeToken(String value) {
        String ascii = Normalizer.normalize(clean(value), Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "");
        return ascii
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9]+", "");
    }

    private int levenshteinDistance(String left, String right) {
        if (left.equals(right)) {
            return 0;
        }
        if (left.isBlank()) {
            return right.length();
        }
        if (right.isBlank()) {
            return left.length();
        }

        int[] costs = new int[right.length() + 1];
        for (int j = 0; j < costs.length; j++) {
            costs[j] = j;
        }

        for (int i = 1; i <= left.length(); i++) {
            costs[0] = i;
            int northwest = i - 1;
            for (int j = 1; j <= right.length(); j++) {
                int insert = costs[j] + 1;
                int delete = costs[j - 1] + 1;
                int replace = northwest + (left.charAt(i - 1) == right.charAt(j - 1) ? 0 : 1);
                northwest = costs[j];
                costs[j] = Math.min(Math.min(insert, delete), replace);
            }
        }

        return costs[right.length()];
    }
}
