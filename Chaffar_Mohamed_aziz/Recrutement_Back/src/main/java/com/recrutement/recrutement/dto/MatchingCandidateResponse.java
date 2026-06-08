package com.recrutement.recrutement.dto;

import java.util.ArrayList;
import java.util.List;

public class MatchingCandidateResponse {
    private Long candidateId;
    private String fullName;
    private String email;
    private String profileTitle;
    private String location;
    private Integer experience;
    private Double matchingScore;
    private List<String> compatibleSkills = new ArrayList<>();
    private List<String> missingSkills = new ArrayList<>();
    private Boolean hasApplied;
    private Boolean alreadyInvited;

    public Long getCandidateId() {
        return candidateId;
    }

    public void setCandidateId(Long candidateId) {
        this.candidateId = candidateId;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getProfileTitle() {
        return profileTitle;
    }

    public void setProfileTitle(String profileTitle) {
        this.profileTitle = profileTitle;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public Integer getExperience() {
        return experience;
    }

    public void setExperience(Integer experience) {
        this.experience = experience;
    }

    public Double getMatchingScore() {
        return matchingScore;
    }

    public void setMatchingScore(Double matchingScore) {
        this.matchingScore = matchingScore;
    }

    public List<String> getCompatibleSkills() {
        return compatibleSkills;
    }

    public void setCompatibleSkills(List<String> compatibleSkills) {
        this.compatibleSkills = compatibleSkills;
    }

    public List<String> getMissingSkills() {
        return missingSkills;
    }

    public void setMissingSkills(List<String> missingSkills) {
        this.missingSkills = missingSkills;
    }

    public Boolean getHasApplied() {
        return hasApplied;
    }

    public void setHasApplied(Boolean hasApplied) {
        this.hasApplied = hasApplied;
    }

    public Boolean getAlreadyInvited() {
        return alreadyInvited;
    }

    public void setAlreadyInvited(Boolean alreadyInvited) {
        this.alreadyInvited = alreadyInvited;
    }
}
