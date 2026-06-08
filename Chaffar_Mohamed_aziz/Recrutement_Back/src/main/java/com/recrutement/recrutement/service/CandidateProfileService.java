package com.recrutement.recrutement.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.recrutement.recrutement.dto.CandidateProfileAutofillResponse;
import com.recrutement.recrutement.dto.CandidateProfileRequest;
import com.recrutement.recrutement.dto.CandidateProfileResponse;
import com.recrutement.recrutement.entities.CV;
import com.recrutement.recrutement.entities.Candidate;
import com.recrutement.recrutement.entities.Competence;
import com.recrutement.recrutement.entities.Role;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.repositories.CVRepository;
import com.recrutement.recrutement.repositories.CandidateRepository;
import com.recrutement.recrutement.repositories.UserRepository;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.text.Normalizer;
import java.util.Base64;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.ArrayList;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class CandidateProfileService {
    private final CandidateRepository candidateRepository;
    private final CVRepository cvRepository;
    private final UserRepository userRepository;
    private final ObjectMapper objectMapper;
    private final CloudinaryStorageService cloudinaryStorageService;
    private final GroqCvAutofillService groqCvAutofillService;
    private final CompetenceService competenceService;

    public CandidateProfileService(
            CandidateRepository candidateRepository,
            CVRepository cvRepository,
            UserRepository userRepository,
            ObjectMapper objectMapper,
            CloudinaryStorageService cloudinaryStorageService,
            GroqCvAutofillService groqCvAutofillService,
            CompetenceService competenceService
    ) {
        this.candidateRepository = candidateRepository;
        this.cvRepository = cvRepository;
        this.userRepository = userRepository;
        this.objectMapper = objectMapper;
        this.cloudinaryStorageService = cloudinaryStorageService;
        this.groqCvAutofillService = groqCvAutofillService;
        this.competenceService = competenceService;
    }

    public CandidateProfileResponse getCurrentProfile(User user) {
        Candidate candidate = getCurrentCandidate(user);
        return buildResponse(candidate);
    }

    public CandidateProfileResponse getProfileForRecruiter(User user, Long candidateId) {
        if (user == null || user.getRole() != Role.RECRUITER) {
            throw new RuntimeException("Cette consultation est reservee aux recruteurs.");
        }

        if (candidateId == null) {
            throw new RuntimeException("Identifiant candidat manquant.");
        }

        Candidate candidate = candidateRepository.findById(candidateId)
                .orElseThrow(() -> new RuntimeException("Profil candidat introuvable."));

        return buildResponse(candidate);
    }

    public CandidateProfileAutofillResponse extractProfileFromCv(User user, MultipartFile cvFile) {
        getCurrentCandidate(user);
        CandidateProfileAutofillResponse response = groqCvAutofillService.extractFromCv(cvFile);
        response.setSkills(synchronizeSkillsWithLibrary(response.getSkills()));
        return response;
    }

    public CandidateProfileResponse saveCurrentProfile(
            User user,
            CandidateProfileRequest request,
            MultipartFile profilePhoto,
            MultipartFile coverPhoto,
            MultipartFile cvFile
    ) {
        Candidate candidate = getCurrentCandidate(user);

        if (request != null) {
            candidate.setNom(nonEmpty(request.getFullName(), candidate.getNom()));
            candidate.setEmail(resolveEmail(candidate, request.getEmail()));
            candidate.setProfession(clean(request.getProfession()));
            candidate.setDateNaissance(parseDate(request.getBirthDate()));
            candidate.setNumTelephone(clean(request.getPhone()));
            candidate.setPosteRecherche(clean(request.getJobTitle()));
            candidate.setLocalisation(clean(request.getAddress()));
            candidate.setAdresse(clean(request.getAddress()));
            candidate.setGenre(clean(request.getGender()));
            candidate.setDescription(clean(request.getDescription()));

            if (request.getSocialLinks() != null) {
                candidate.setFacebookUrl(clean(request.getSocialLinks().getFacebook()));
                candidate.setInstagramUrl(clean(request.getSocialLinks().getInstagram()));
                candidate.setLinkedinUrl(clean(request.getSocialLinks().getLinkedin()));
                candidate.setGithubUrl(clean(request.getSocialLinks().getGithub()));
            }

            candidate.setExperiencesJson(writeExperiencesJson(request.getExperiences()));
            candidate.setEducationJson(writeEducationJson(request.getEducation()));
            candidate.setSkillsJson(writeSkillsJson(synchronizeSkillsWithLibrary(request.getSkills())));
        }

        if (hasFile(profilePhoto)) {
            StoredAsset asset = storeImageAsset(candidate, profilePhoto, "profil", candidate.getPhotoProfilPublicId());
            candidate.setPhotoProfilNom(asset.fileName());
            candidate.setPhotoProfilUrl(asset.url());
            candidate.setPhotoProfilPublicId(asset.publicId());
        }

        if (hasFile(coverPhoto)) {
            StoredAsset asset = storeImageAsset(candidate, coverPhoto, "couverture", candidate.getPhotoCouverturePublicId());
            candidate.setPhotoCouvertureNom(asset.fileName());
            candidate.setPhotoCouvertureUrl(asset.url());
            candidate.setPhotoCouverturePublicId(asset.publicId());
        }

        Candidate savedCandidate = candidateRepository.save(candidate);

        if (hasFile(cvFile)) {
            CV existingCv = cvRepository.findTopByCandidateOrderByDateImportDesc(savedCandidate).orElse(new CV());
            StoredAsset asset = storeDocumentAsset(savedCandidate, cvFile, "cv", existingCv.getCloudinaryPublicId());

            existingCv.setCandidate(savedCandidate);
            existingCv.setDateImport(new Date());
            existingCv.setNomFichier(asset.fileName());
            existingCv.setTaille(formatFileSize(cvFile.getSize()));
            existingCv.setUrlFichier(asset.url());
            existingCv.setCloudinaryPublicId(asset.publicId());
            cvRepository.save(existingCv);
        }

        return buildResponse(savedCandidate);
    }

    private Candidate getCurrentCandidate(User user) {
        Candidate candidate = user.getId() == null
                ? null
                : candidateRepository.findById(user.getId()).orElse(null);

        if (candidate == null && user.getEmail() != null) {
            candidate = candidateRepository.findByEmail(user.getEmail());
        }

        if (candidate == null) {
            candidate = createMissingCandidateProfile(user);
        }

        if (candidate == null) {
            throw new RuntimeException("Profil candidat introuvable.");
        }
        return candidate;
    }

    private CandidateProfileResponse buildResponse(Candidate candidate) {
        CandidateProfileResponse response = new CandidateProfileResponse();
        response.setId(candidate.getId());
        response.setFullName(candidate.getNom());
        response.setProfession(candidate.getProfession());
        response.setEmail(candidate.getEmail());
        response.setBirthDate(candidate.getDateNaissance() == null ? "" : candidate.getDateNaissance().toString());
        response.setPhone(candidate.getNumTelephone());
        response.setJobTitle(candidate.getPosteRecherche());
        response.setAddress(candidate.getAdresse());
        response.setGender(candidate.getGenre());
        response.setDescription(candidate.getDescription());
        response.setExperienceJson(defaultJson(candidate.getExperiencesJson(), "[]"));
        response.setEducationJson(defaultJson(candidate.getEducationJson(), "[]"));
        response.setSkillsJson(defaultJson(candidate.getSkillsJson(), "[]"));
        response.setFacebook(candidate.getFacebookUrl());
        response.setInstagram(candidate.getInstagramUrl());
        response.setLinkedin(candidate.getLinkedinUrl());
        response.setGithub(candidate.getGithubUrl());
        response.setProfilePhotoName(candidate.getPhotoProfilNom());
        response.setProfilePhotoUrl(firstNonBlank(
                candidate.getPhotoProfilUrl(),
                buildImageDataUrl(candidate.getId(), candidate.getPhotoProfilNom())
        ));
        response.setCoverPhotoName(candidate.getPhotoCouvertureNom());
        response.setCoverPhotoUrl(firstNonBlank(
                candidate.getPhotoCouvertureUrl(),
                buildImageDataUrl(candidate.getId(), candidate.getPhotoCouvertureNom())
        ));

        cvRepository.findTopByCandidateOrderByDateImportDesc(candidate).ifPresent(cv -> {
            response.setCvFileName(cv.getNomFichier());
            response.setCvFileSize(cv.getTaille());
            response.setCvFileUrl(cv.getUrlFichier());
        });

        return response;
    }

    private boolean hasFile(MultipartFile file) {
        return file != null && !file.isEmpty();
    }

    private StoredAsset storeImageAsset(
            Candidate candidate,
            MultipartFile file,
            String prefix,
            String previousPublicId
    ) {
        try {
            CloudinaryStorageService.UploadedAsset uploadedAsset =
                    cloudinaryStorageService.uploadCandidateImage(candidate.getId(), file, prefix);
            cloudinaryStorageService.deleteQuietly(previousPublicId, "image");
            return new StoredAsset(
                    uploadedAsset.getOriginalFileName(),
                    uploadedAsset.getSecureUrl(),
                    uploadedAsset.getPublicId()
            );
        } catch (RuntimeException ex) {
            String storedName = storeFileLocally(candidate.getId(), file, prefix);
            return new StoredAsset(storedName, "", "");
        }
    }

    private StoredAsset storeDocumentAsset(
            Candidate candidate,
            MultipartFile file,
            String prefix,
            String previousPublicId
    ) {
        try {
            CloudinaryStorageService.UploadedAsset uploadedAsset =
                    cloudinaryStorageService.uploadCandidateDocument(candidate.getId(), file, prefix);
            cloudinaryStorageService.deleteQuietly(previousPublicId, "raw");
            return new StoredAsset(
                    uploadedAsset.getOriginalFileName(),
                    uploadedAsset.getSecureUrl(),
                    uploadedAsset.getPublicId()
            );
        } catch (RuntimeException ex) {
            String storedName = storeFileLocally(candidate.getId(), file, prefix);
            return new StoredAsset(storedName, "", "");
        }
    }

    private String storeFileLocally(Long candidateId, MultipartFile file, String prefix) {
        try {
            Path uploadDir = Paths.get("uploads", "candidates", String.valueOf(candidateId));
            Files.createDirectories(uploadDir);
            String originalName = file.getOriginalFilename() == null ? "fichier" : file.getOriginalFilename();
            String safeName = originalName.replaceAll("[^a-zA-Z0-9._-]", "_");
            String storedName = prefix + "_" + System.currentTimeMillis() + "_" + safeName;
            Path targetPath = uploadDir.resolve(storedName);

            try (InputStream inputStream = file.getInputStream()) {
                Files.copy(inputStream, targetPath, StandardCopyOption.REPLACE_EXISTING);
            }

            return storedName;
        } catch (IOException ex) {
            throw new RuntimeException("Impossible d'enregistrer le fichier " + file.getOriginalFilename() + ".");
        }
    }

    private String writeExperiencesJson(List<CandidateProfileRequest.CandidateExperienceRequest> experiences) {
        if (experiences == null || experiences.isEmpty()) {
            return "[]";
        }

        try {
            return objectMapper.writeValueAsString(experiences);
        } catch (JsonProcessingException ex) {
            throw new RuntimeException("Impossible d'enregistrer les experiences du candidat.");
        }
    }

    private String writeEducationJson(List<CandidateProfileRequest.CandidateEducationRequest> education) {
        if (education == null || education.isEmpty()) {
            return "[]";
        }

        try {
            return objectMapper.writeValueAsString(education);
        } catch (JsonProcessingException ex) {
            throw new RuntimeException("Impossible d'enregistrer la formation du candidat.");
        }
    }

    private String writeSkillsJson(List<CandidateProfileRequest.CandidateSkillRequest> skills) {
        if (skills == null || skills.isEmpty()) {
            return "[]";
        }

        try {
            return objectMapper.writeValueAsString(skills);
        } catch (JsonProcessingException ex) {
            throw new RuntimeException("Impossible d'enregistrer les competences du candidat.");
        }
    }

    private List<CandidateProfileRequest.CandidateSkillRequest> synchronizeSkillsWithLibrary(
            List<CandidateProfileRequest.CandidateSkillRequest> skills
    ) {
        if (skills == null || skills.isEmpty()) {
            return new ArrayList<>();
        }

        Map<String, CandidateProfileRequest.CandidateSkillRequest> uniqueSkills = new LinkedHashMap<>();
        for (CandidateProfileRequest.CandidateSkillRequest skill : skills) {
            if (skill == null) {
                continue;
            }

            CandidateProfileRequest.CandidateSkillRequest normalized = normalizeSkill(skill);
            if (!hasSkillContent(normalized)) {
                continue;
            }

            Competence competence = resolveCompetence(normalized);
            if (competence != null) {
                normalized.setCompetenceId(competence.getId());
                normalized.setTitle(competence.getNom());
            }

            String uniqueKey = competence != null
                    ? "id:" + competence.getId()
                    : "title:" + normalizeToken(normalized.getTitle());

            if (uniqueKey.endsWith(":")) {
                continue;
            }

            if (uniqueSkills.containsKey(uniqueKey)) {
                mergeSkill(uniqueSkills.get(uniqueKey), normalized);
                continue;
            }

            uniqueSkills.put(uniqueKey, normalized);
        }

        return new ArrayList<>(uniqueSkills.values());
    }

    private CandidateProfileRequest.CandidateSkillRequest normalizeSkill(
            CandidateProfileRequest.CandidateSkillRequest skill
    ) {
        CandidateProfileRequest.CandidateSkillRequest normalized = new CandidateProfileRequest.CandidateSkillRequest();
        normalized.setCompetenceId(skill.getCompetenceId());
        normalized.setTitle(normalizeDisplaySkillName(skill.getTitle()));
        normalized.setLevel(normalizeSkillLevel(skill.getLevel()));
        normalized.setYearsExperience(normalizeYearsExperience(skill.getYearsExperience()));
        normalized.setPercentage(normalizePercentage(skill.getPercentage()));
        return normalized;
    }

    private Competence resolveCompetence(CandidateProfileRequest.CandidateSkillRequest skill) {
        if (skill.getCompetenceId() != null) {
            Optional<Competence> competenceById = competenceService.findById(skill.getCompetenceId());
            if (competenceById.isPresent()) {
                return competenceById.get();
            }
        }

        Optional<Competence> direct = competenceService.findByNormalizedName(skill.getTitle());
        if (direct.isPresent()) {
            return direct.get();
        }

        if (clean(skill.getTitle()).isBlank()) {
            return null;
        }

        return competenceService.resolveOrCreateCompetence(skill.getTitle());
    }

    private void mergeSkill(
            CandidateProfileRequest.CandidateSkillRequest target,
            CandidateProfileRequest.CandidateSkillRequest source
    ) {
        if (target.getCompetenceId() == null && source.getCompetenceId() != null) {
            target.setCompetenceId(source.getCompetenceId());
        }

        if (clean(target.getTitle()).isBlank()) {
            target.setTitle(source.getTitle());
        }

        if (skillLevelRank(source.getLevel()) > skillLevelRank(target.getLevel())) {
            target.setLevel(source.getLevel());
        }

        if (clean(target.getYearsExperience()).isBlank()) {
            target.setYearsExperience(source.getYearsExperience());
        }

        target.setPercentage(Math.max(
                normalizePercentage(target.getPercentage()),
                normalizePercentage(source.getPercentage())
        ));
    }

    private boolean hasSkillContent(CandidateProfileRequest.CandidateSkillRequest skill) {
        return skill.getCompetenceId() != null || !clean(skill.getTitle()).isBlank();
    }

    private String normalizeDisplaySkillName(String value) {
        String compact = clean(value)
                .replaceAll("[_]+", " ")
                .replaceAll("\\s+", " ")
                .trim();

        if (compact.isBlank()) {
            return "";
        }

        return switch (normalizeToken(compact)) {
            case "javascript" -> "JavaScript";
            case "typescript" -> "TypeScript";
            case "nodejs", "node.js" -> "Node.js";
            case "nextjs", "next.js" -> "Next.js";
            case "nestjs" -> "NestJS";
            case "springboot" -> "Spring Boot";
            case "postgresql", "postgres" -> "PostgreSQL";
            case "mysql" -> "MySQL";
            case "mongodb", "mongo" -> "MongoDB";
            case "sqlserver", "mssql" -> "SQL Server";
            case "powerbi", "power bi" -> "Power BI";
            case "uiux", "uxui" -> "UI/UX";
            default -> compact;
        };
    }

    private String normalizeSkillLevel(String value) {
        return switch (normalizeToken(value)) {
            case "expert" -> "Expert";
            case "avance", "advanced", "senior" -> "Avance";
            case "debutant", "beginner", "junior" -> "Debutant";
            default -> "Intermediaire";
        };
    }

    private int skillLevelRank(String value) {
        return switch (normalizeSkillLevel(value)) {
            case "Expert" -> 4;
            case "Avance" -> 3;
            case "Intermediaire" -> 2;
            default -> 1;
        };
    }

    private String normalizeYearsExperience(String value) {
        String cleaned = clean(value);
        return cleaned.isBlank() ? "1 an" : cleaned;
    }

    private Integer normalizePercentage(Integer value) {
        if (value == null) {
            return 70;
        }
        return Math.max(0, Math.min(100, value));
    }

    private String clean(String value) {
        return value == null ? "" : value.trim();
    }

    private String nonEmpty(String value, String fallback) {
        String cleaned = clean(value);
        return cleaned.isEmpty() ? fallback : cleaned;
    }

    private String resolveEmail(Candidate candidate, String value) {
        String cleaned = clean(value).toLowerCase();
        if (cleaned.isEmpty()) {
            return candidate.getEmail();
        }

        if (candidate.getEmail() != null && candidate.getEmail().equalsIgnoreCase(cleaned)) {
            return candidate.getEmail();
        }

        Optional<User> existingUser = userRepository.findByEmail(cleaned);
        if (existingUser.isPresent() && !existingUser.get().getId().equals(candidate.getId())) {
            throw new RuntimeException("Cette adresse e-mail est deja utilisee.");
        }

        return cleaned;
    }

    private LocalDate parseDate(String value) {
        String cleaned = clean(value);
        if (cleaned.isEmpty()) {
            return null;
        }
        try {
            return LocalDate.parse(cleaned);
        } catch (DateTimeParseException ex) {
            throw new RuntimeException("La date de naissance est invalide.");
        }
    }

    private String defaultJson(String value, String fallback) {
        return (value == null || value.isBlank()) ? fallback : value;
    }

    private String formatFileSize(long sizeInBytes) {
        if (sizeInBytes < 1024) {
            return sizeInBytes + " o";
        }
        if (sizeInBytes < 1024 * 1024) {
            return (sizeInBytes / 1024) + " Ko";
        }
        return String.format("%.1f Mo", sizeInBytes / (1024d * 1024d));
    }

    private String buildImageDataUrl(Long candidateId, String fileName) {
        if (candidateId == null || fileName == null || fileName.isBlank()) {
            return "";
        }

        Path filePath = Paths.get("uploads", "candidates", String.valueOf(candidateId), fileName);
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
        String lowerCaseName = fileName.toLowerCase();
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

    private Candidate createMissingCandidateProfile(User authenticatedUser) {
        Long userId = authenticatedUser.getId();
        String userEmail = authenticatedUser.getEmail();

        User persistedUser = null;
        if (userId != null) {
            persistedUser = userRepository.findById(userId).orElse(null);
        }

        if (persistedUser == null && userEmail != null && !userEmail.isBlank()) {
            persistedUser = userRepository.findByEmail(userEmail).orElse(null);
        }

        if (persistedUser == null) {
            return null;
        }

        if (persistedUser.getRole() != Role.CANDIDATE) {
            throw new RuntimeException("Seuls les comptes candidats peuvent enregistrer ce profil.");
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

    private String firstNonBlank(String primary, String fallback) {
        return primary != null && !primary.isBlank() ? primary : fallback;
    }

    private String normalizeToken(String value) {
        String ascii = Normalizer.normalize(clean(value), Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "");
        return ascii.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9+/#.]", "");
    }

    private record StoredAsset(String fileName, String url, String publicId) {
    }
}
