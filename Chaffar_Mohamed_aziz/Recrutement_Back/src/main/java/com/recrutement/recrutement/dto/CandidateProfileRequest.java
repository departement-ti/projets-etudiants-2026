package com.recrutement.recrutement.dto;

import java.util.List;

public class CandidateProfileRequest {
    private String fullName;
    private String profession;
    private String email;
    private String birthDate;
    private String phone;
    private String jobTitle;
    private String address;
    private String gender;
    private String description;
    private List<CandidateExperienceRequest> experiences;
    private List<CandidateEducationRequest> education;
    private List<CandidateSkillRequest> skills;
    private CandidateSocialLinksRequest socialLinks;

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

    public String getBirthDate() {
        return birthDate;
    }

    public void setBirthDate(String birthDate) {
        this.birthDate = birthDate;
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

    public String getGender() {
        return gender;
    }

    public void setGender(String gender) {
        this.gender = gender;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public List<CandidateExperienceRequest> getExperiences() {
        return experiences;
    }

    public void setExperiences(List<CandidateExperienceRequest> experiences) {
        this.experiences = experiences;
    }

    public List<CandidateEducationRequest> getEducation() {
        return education;
    }

    public void setEducation(List<CandidateEducationRequest> education) {
        this.education = education;
    }

    public List<CandidateSkillRequest> getSkills() {
        return skills;
    }

    public void setSkills(List<CandidateSkillRequest> skills) {
        this.skills = skills;
    }

    public CandidateSocialLinksRequest getSocialLinks() {
        return socialLinks;
    }

    public void setSocialLinks(CandidateSocialLinksRequest socialLinks) {
        this.socialLinks = socialLinks;
    }

    public static class CandidateExperienceRequest {
        private String title;
        private String company;
        private String location;
        private String period;
        private String description;

        public String getTitle() {
            return title;
        }

        public void setTitle(String title) {
            this.title = title;
        }

        public String getCompany() {
            return company;
        }

        public void setCompany(String company) {
            this.company = company;
        }

        public String getLocation() {
            return location;
        }

        public void setLocation(String location) {
            this.location = location;
        }

        public String getPeriod() {
            return period;
        }

        public void setPeriod(String period) {
            this.period = period;
        }

        public String getDescription() {
            return description;
        }

        public void setDescription(String description) {
            this.description = description;
        }
    }

    public static class CandidateEducationRequest {
        private String title;
        private String degree;
        private String institute;
        private String year;

        public String getTitle() {
            return title;
        }

        public void setTitle(String title) {
            this.title = title;
        }

        public String getDegree() {
            return degree;
        }

        public void setDegree(String degree) {
            this.degree = degree;
        }

        public String getInstitute() {
            return institute;
        }

        public void setInstitute(String institute) {
            this.institute = institute;
        }

        public String getYear() {
            return year;
        }

        public void setYear(String year) {
            this.year = year;
        }
    }

    public static class CandidateSkillRequest {
        private Long competenceId;
        private String title;
        private String level;
        private String yearsExperience;
        private Integer percentage;

        public Long getCompetenceId() {
            return competenceId;
        }

        public void setCompetenceId(Long competenceId) {
            this.competenceId = competenceId;
        }

        public String getTitle() {
            return title;
        }

        public void setTitle(String title) {
            this.title = title;
        }

        public String getLevel() {
            return level;
        }

        public void setLevel(String level) {
            this.level = level;
        }

        public String getYearsExperience() {
            return yearsExperience;
        }

        public void setYearsExperience(String yearsExperience) {
            this.yearsExperience = yearsExperience;
        }

        public Integer getPercentage() {
            return percentage;
        }

        public void setPercentage(Integer percentage) {
            this.percentage = percentage;
        }
    }

    public static class CandidateSocialLinksRequest {
        private String facebook;
        private String instagram;
        private String linkedin;
        private String github;

        public String getFacebook() {
            return facebook;
        }

        public void setFacebook(String facebook) {
            this.facebook = facebook;
        }

        public String getInstagram() {
            return instagram;
        }

        public void setInstagram(String instagram) {
            this.instagram = instagram;
        }

        public String getLinkedin() {
            return linkedin;
        }

        public void setLinkedin(String linkedin) {
            this.linkedin = linkedin;
        }

        public String getGithub() {
            return github;
        }

        public void setGithub(String github) {
            this.github = github;
        }
    }
}
