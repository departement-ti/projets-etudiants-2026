package com.recrutement.recrutement.dto;

import java.util.ArrayList;
import java.util.List;

public class CandidateProfileAutofillResponse {
    private String message = "";
    private String fullName = "";
    private String profession = "";
    private String email = "";
    private String phone = "";
    private String jobTitle = "";
    private String address = "";
    private String description = "";
    private List<CandidateProfileRequest.CandidateExperienceRequest> experiences = new ArrayList<>();
    private List<CandidateProfileRequest.CandidateEducationRequest> education = new ArrayList<>();
    private List<CandidateProfileRequest.CandidateSkillRequest> skills = new ArrayList<>();

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getProfession() {
        return profession;
    }

    public void setProfession(String profession) {
        this.profession = profession;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getJobTitle() {
        return jobTitle;
    }

    public void setJobTitle(String jobTitle) {
        this.jobTitle = jobTitle;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public List<CandidateProfileRequest.CandidateExperienceRequest> getExperiences() {
        return experiences;
    }

    public void setExperiences(List<CandidateProfileRequest.CandidateExperienceRequest> experiences) {
        this.experiences = experiences == null ? new ArrayList<>() : experiences;
    }

    public List<CandidateProfileRequest.CandidateEducationRequest> getEducation() {
        return education;
    }

    public void setEducation(List<CandidateProfileRequest.CandidateEducationRequest> education) {
        this.education = education == null ? new ArrayList<>() : education;
    }

    public List<CandidateProfileRequest.CandidateSkillRequest> getSkills() {
        return skills;
    }

    public void setSkills(List<CandidateProfileRequest.CandidateSkillRequest> skills) {
        this.skills = skills == null ? new ArrayList<>() : skills;
    }
}
