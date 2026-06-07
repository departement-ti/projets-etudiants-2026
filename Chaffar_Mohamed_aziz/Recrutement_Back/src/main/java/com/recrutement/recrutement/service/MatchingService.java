package com.recrutement.recrutement.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.recrutement.recrutement.dto.CandidateProfileRequest;
import com.recrutement.recrutement.dto.OffreCompetenceRequest;
import com.recrutement.recrutement.dto.SkillMatchResponse;
import com.recrutement.recrutement.entities.Candidate;
import com.recrutement.recrutement.entities.Offre;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;

@Service
public class MatchingService {
    private final ObjectMapper objectMapper;

    public MatchingService(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public MatchResult evaluate(Candidate candidate, Offre offre) {
        List<CandidateProfileRequest.CandidateSkillRequest> candidateSkills = readCandidateSkills(candidate == null ? null : candidate.getSkillsJson());
        List<OffreCompetenceRequest> offerSkills = readOfferSkills(offre == null ? null : offre.getCompetencesJson());

        if (offerSkills.isEmpty()) {
            return new MatchResult(100d, new ArrayList<>(), new ArrayList<>(), new ArrayList<>());
        }

        Set<String> candidateKeys = buildCandidateSkillKeys(candidateSkills);
        double totalWeight = 0d;
        double matchedWeight = 0d;
        List<String> matchingSkills = new ArrayList<>();
        List<String> missingSkills = new ArrayList<>();
        List<SkillMatchResponse> skills = new ArrayList<>();

        for (OffreCompetenceRequest offerSkill : offerSkills) {
            String skillName = cleanedSkillName(offerSkill.getNom(), "Competence");
            int weight = normalizeWeight(offerSkill.getPonderation());
            boolean matched = isMatched(offerSkill, candidateKeys);

            totalWeight += weight;
            if (matched) {
                matchedWeight += weight;
                matchingSkills.add(skillName);
            } else {
                missingSkills.add(skillName);
            }

            SkillMatchResponse detail = new SkillMatchResponse();
            detail.setNom(skillName);
            detail.setMatched(matched);
            detail.setType(defaultText(offerSkill.getType(), "OBLIGATOIRE"));
            detail.setPonderation(weight);
            skills.add(detail);
        }

        double score = totalWeight == 0d ? 100d : roundScore((matchedWeight / totalWeight) * 100d);
        return new MatchResult(
                score,
                deduplicate(matchingSkills),
                deduplicate(missingSkills),
                skills
        );
    }

    private List<CandidateProfileRequest.CandidateSkillRequest> readCandidateSkills(String skillsJson) {
        if (skillsJson == null || skillsJson.isBlank()) {
            return new ArrayList<>();
        }

        try {
            return objectMapper.readValue(skillsJson, new TypeReference<List<CandidateProfileRequest.CandidateSkillRequest>>() {
            });
        } catch (JsonProcessingException ex) {
            return new ArrayList<>();
        }
    }

    private List<OffreCompetenceRequest> readOfferSkills(String skillsJson) {
        if (skillsJson == null || skillsJson.isBlank()) {
            return new ArrayList<>();
        }

        try {
            return objectMapper.readValue(skillsJson, new TypeReference<List<OffreCompetenceRequest>>() {
            });
        } catch (JsonProcessingException ex) {
            return new ArrayList<>();
        }
    }

    private Set<String> buildCandidateSkillKeys(List<CandidateProfileRequest.CandidateSkillRequest> candidateSkills) {
        return candidateSkills.stream()
                .flatMap(skill -> buildKeys(skill.getCompetenceId(), skill.getTitle()).stream())
                .collect(Collectors.toSet());
    }

    private boolean isMatched(OffreCompetenceRequest offerSkill, Set<String> candidateKeys) {
        for (String key : buildKeys(offerSkill.getCompetenceId(), offerSkill.getNom())) {
            if (candidateKeys.contains(key)) {
                return true;
            }
        }
        return false;
    }

    private List<String> buildKeys(Long competenceId, String label) {
        List<String> keys = new ArrayList<>();
        if (competenceId != null) {
            keys.add("ID:" + competenceId);
        }

        String normalizedLabel = normalize(label);
        if (!normalizedLabel.isEmpty()) {
            keys.add("NAME:" + normalizedLabel);
        }
        return keys;
    }

    private int normalizeWeight(Integer value) {
        if (value == null || value <= 0) {
            return 50;
        }
        return value;
    }

    private String cleanedSkillName(String value, String fallback) {
        String normalized = value == null ? "" : value.trim();
        return normalized.isEmpty() ? fallback : normalized;
    }

    private String defaultText(String value, String fallback) {
        String normalized = value == null ? "" : value.trim();
        return normalized.isEmpty() ? fallback : normalized;
    }

    private double roundScore(double value) {
        return Math.round(value * 10d) / 10d;
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
    }

    private List<String> deduplicate(List<String> values) {
        return new ArrayList<>(new LinkedHashSet<>(values));
    }

    public static class MatchResult {
        private final double score;
        private final List<String> matchingSkills;
        private final List<String> missingSkills;
        private final List<SkillMatchResponse> skills;

        public MatchResult(
                double score,
                List<String> matchingSkills,
                List<String> missingSkills,
                List<SkillMatchResponse> skills
        ) {
            this.score = score;
            this.matchingSkills = matchingSkills;
            this.missingSkills = missingSkills;
            this.skills = skills;
        }

        public double getScore() {
            return score;
        }

        public List<String> getMatchingSkills() {
            return matchingSkills;
        }

        public List<String> getMissingSkills() {
            return missingSkills;
        }

        public List<SkillMatchResponse> getSkills() {
            return skills;
        }
    }
}
