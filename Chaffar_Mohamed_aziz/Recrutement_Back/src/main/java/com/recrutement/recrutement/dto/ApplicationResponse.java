package com.recrutement.recrutement.dto;

import java.util.ArrayList;
import java.util.List;

public class ApplicationResponse {
    private Long id;
    private Long offerId;
    private String offerTitle;
    private String companyName;
    private String offerLocation;
    private String contractType;
    private String appliedAt;
    private String status;
    private double score;
    private Long candidateId;
    private String candidateName;
    private String candidateEmail;
    private String candidateJobTitle;
    private String candidateLocation;
    private Integer candidateExperience;
    private String candidateSummary;
    private String candidateCvFileName;
    private String candidateCvFileUrl;
    private String candidateProfilePhotoUrl;
    private String candidateCoverPhotoUrl;
    private String candidateLinkedinUrl;
    private String candidateGithubUrl;
    private String candidateFacebookUrl;
    private String candidateInstagramUrl;
    private Long aiTestId;
    private Boolean hasAiTest;
    private Boolean aiTestAvailable;
    private Boolean canPassAiTest;
    private String aiTestStatus;
    private Double aiTestThreshold;
    private Double aiTestScore;
    private String aiTestRecommendation;
    private Integer aiTestDurationMinutes;
    private String aiTestStartedAt;
    private String aiTestExpiresAt;
    private String aiTestSubmittedAt;
    private String aiTestCompletedAt;
    private String aiTestClosedReason;
    private Boolean aiTestCheatingSuspicion;
    private Integer aiTestTabSwitchCount;
    private Integer aiTestWarningCount;
    private Long interviewId;
    private String interviewStatus;
    private String interviewDateTime;
    private Integer interviewDurationMinutes;
    private String interviewType;
    private String interviewMode;
    private String interviewMeetingLink;
    private String interviewLocation;
    private Boolean interviewReminder24hSent;
    private Boolean interviewReminder1hSent;
    private String interviewAttendanceStatus;
    private List<String> matchingSkills = new ArrayList<>();
    private List<String> missingSkills = new ArrayList<>();
    private List<SkillMatchResponse> skills = new ArrayList<>();

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getOfferId() {
        return offerId;
    }

    public void setOfferId(Long offerId) {
        this.offerId = offerId;
    }

    public String getOfferTitle() {
        return offerTitle;
    }

    public void setOfferTitle(String offerTitle) {
        this.offerTitle = offerTitle;
    }

    public String getCompanyName() {
        return companyName;
    }

    public void setCompanyName(String companyName) {
        this.companyName = companyName;
    }

    public String getOfferLocation() {
        return offerLocation;
    }

    public void setOfferLocation(String offerLocation) {
        this.offerLocation = offerLocation;
    }

    public String getContractType() {
        return contractType;
    }

    public void setContractType(String contractType) {
        this.contractType = contractType;
    }

    public String getAppliedAt() {
        return appliedAt;
    }

    public void setAppliedAt(String appliedAt) {
        this.appliedAt = appliedAt;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public double getScore() {
        return score;
    }

    public void setScore(double score) {
        this.score = score;
    }

    public Long getCandidateId() {
        return candidateId;
    }

    public void setCandidateId(Long candidateId) {
        this.candidateId = candidateId;
    }

    public String getCandidateName() {
        return candidateName;
    }

    public void setCandidateName(String candidateName) {
        this.candidateName = candidateName;
    }

    public String getCandidateEmail() {
        return candidateEmail;
    }

    public void setCandidateEmail(String candidateEmail) {
        this.candidateEmail = candidateEmail;
    }

    public String getCandidateJobTitle() {
        return candidateJobTitle;
    }

    public void setCandidateJobTitle(String candidateJobTitle) {
        this.candidateJobTitle = candidateJobTitle;
    }

    public String getCandidateLocation() {
        return candidateLocation;
    }

    public void setCandidateLocation(String candidateLocation) {
        this.candidateLocation = candidateLocation;
    }

    public Integer getCandidateExperience() {
        return candidateExperience;
    }

    public void setCandidateExperience(Integer candidateExperience) {
        this.candidateExperience = candidateExperience;
    }

    public String getCandidateSummary() {
        return candidateSummary;
    }

    public void setCandidateSummary(String candidateSummary) {
        this.candidateSummary = candidateSummary;
    }

    public String getCandidateCvFileName() {
        return candidateCvFileName;
    }

    public void setCandidateCvFileName(String candidateCvFileName) {
        this.candidateCvFileName = candidateCvFileName;
    }

    public String getCandidateCvFileUrl() {
        return candidateCvFileUrl;
    }

    public void setCandidateCvFileUrl(String candidateCvFileUrl) {
        this.candidateCvFileUrl = candidateCvFileUrl;
    }

    public String getCandidateProfilePhotoUrl() {
        return candidateProfilePhotoUrl;
    }

    public void setCandidateProfilePhotoUrl(String candidateProfilePhotoUrl) {
        this.candidateProfilePhotoUrl = candidateProfilePhotoUrl;
    }

    public String getCandidateCoverPhotoUrl() {
        return candidateCoverPhotoUrl;
    }

    public void setCandidateCoverPhotoUrl(String candidateCoverPhotoUrl) {
        this.candidateCoverPhotoUrl = candidateCoverPhotoUrl;
    }

    public String getCandidateLinkedinUrl() {
        return candidateLinkedinUrl;
    }

    public void setCandidateLinkedinUrl(String candidateLinkedinUrl) {
        this.candidateLinkedinUrl = candidateLinkedinUrl;
    }

    public String getCandidateGithubUrl() {
        return candidateGithubUrl;
    }

    public void setCandidateGithubUrl(String candidateGithubUrl) {
        this.candidateGithubUrl = candidateGithubUrl;
    }

    public String getCandidateFacebookUrl() {
        return candidateFacebookUrl;
    }

    public void setCandidateFacebookUrl(String candidateFacebookUrl) {
        this.candidateFacebookUrl = candidateFacebookUrl;
    }

    public String getCandidateInstagramUrl() {
        return candidateInstagramUrl;
    }

    public void setCandidateInstagramUrl(String candidateInstagramUrl) {
        this.candidateInstagramUrl = candidateInstagramUrl;
    }

    public Long getAiTestId() {
        return aiTestId;
    }

    public void setAiTestId(Long aiTestId) {
        this.aiTestId = aiTestId;
    }

    public Boolean getHasAiTest() {
        return hasAiTest;
    }

    public void setHasAiTest(Boolean hasAiTest) {
        this.hasAiTest = hasAiTest;
    }

    public Boolean getAiTestAvailable() {
        return aiTestAvailable;
    }

    public void setAiTestAvailable(Boolean aiTestAvailable) {
        this.aiTestAvailable = aiTestAvailable;
    }

    public Boolean getCanPassAiTest() {
        return canPassAiTest;
    }

    public void setCanPassAiTest(Boolean canPassAiTest) {
        this.canPassAiTest = canPassAiTest;
    }

    public String getAiTestStatus() {
        return aiTestStatus;
    }

    public void setAiTestStatus(String aiTestStatus) {
        this.aiTestStatus = aiTestStatus;
    }

    public Double getAiTestThreshold() {
        return aiTestThreshold;
    }

    public void setAiTestThreshold(Double aiTestThreshold) {
        this.aiTestThreshold = aiTestThreshold;
    }

    public Double getAiTestScore() {
        return aiTestScore;
    }

    public void setAiTestScore(Double aiTestScore) {
        this.aiTestScore = aiTestScore;
    }

    public String getAiTestRecommendation() {
        return aiTestRecommendation;
    }

    public void setAiTestRecommendation(String aiTestRecommendation) {
        this.aiTestRecommendation = aiTestRecommendation;
    }

    public Integer getAiTestDurationMinutes() {
        return aiTestDurationMinutes;
    }

    public void setAiTestDurationMinutes(Integer aiTestDurationMinutes) {
        this.aiTestDurationMinutes = aiTestDurationMinutes;
    }

    public String getAiTestStartedAt() {
        return aiTestStartedAt;
    }

    public void setAiTestStartedAt(String aiTestStartedAt) {
        this.aiTestStartedAt = aiTestStartedAt;
    }

    public String getAiTestExpiresAt() {
        return aiTestExpiresAt;
    }

    public void setAiTestExpiresAt(String aiTestExpiresAt) {
        this.aiTestExpiresAt = aiTestExpiresAt;
    }

    public String getAiTestSubmittedAt() {
        return aiTestSubmittedAt;
    }

    public void setAiTestSubmittedAt(String aiTestSubmittedAt) {
        this.aiTestSubmittedAt = aiTestSubmittedAt;
    }

    public String getAiTestCompletedAt() {
        return aiTestCompletedAt;
    }

    public void setAiTestCompletedAt(String aiTestCompletedAt) {
        this.aiTestCompletedAt = aiTestCompletedAt;
    }

    public String getAiTestClosedReason() {
        return aiTestClosedReason;
    }

    public void setAiTestClosedReason(String aiTestClosedReason) {
        this.aiTestClosedReason = aiTestClosedReason;
    }

    public Boolean getAiTestCheatingSuspicion() {
        return aiTestCheatingSuspicion;
    }

    public void setAiTestCheatingSuspicion(Boolean aiTestCheatingSuspicion) {
        this.aiTestCheatingSuspicion = aiTestCheatingSuspicion;
    }

    public Integer getAiTestTabSwitchCount() {
        return aiTestTabSwitchCount;
    }

    public void setAiTestTabSwitchCount(Integer aiTestTabSwitchCount) {
        this.aiTestTabSwitchCount = aiTestTabSwitchCount;
    }

    public Integer getAiTestWarningCount() {
        return aiTestWarningCount;
    }

    public void setAiTestWarningCount(Integer aiTestWarningCount) {
        this.aiTestWarningCount = aiTestWarningCount;
    }

    public Long getInterviewId() {
        return interviewId;
    }

    public void setInterviewId(Long interviewId) {
        this.interviewId = interviewId;
    }

    public String getInterviewStatus() {
        return interviewStatus;
    }

    public void setInterviewStatus(String interviewStatus) {
        this.interviewStatus = interviewStatus;
    }

    public String getInterviewDateTime() {
        return interviewDateTime;
    }

    public void setInterviewDateTime(String interviewDateTime) {
        this.interviewDateTime = interviewDateTime;
    }

    public Integer getInterviewDurationMinutes() {
        return interviewDurationMinutes;
    }

    public void setInterviewDurationMinutes(Integer interviewDurationMinutes) {
        this.interviewDurationMinutes = interviewDurationMinutes;
    }

    public String getInterviewType() {
        return interviewType;
    }

    public void setInterviewType(String interviewType) {
        this.interviewType = interviewType;
    }

    public String getInterviewMode() {
        return interviewMode;
    }

    public void setInterviewMode(String interviewMode) {
        this.interviewMode = interviewMode;
    }

    public String getInterviewMeetingLink() {
        return interviewMeetingLink;
    }

    public void setInterviewMeetingLink(String interviewMeetingLink) {
        this.interviewMeetingLink = interviewMeetingLink;
    }

    public String getInterviewLocation() {
        return interviewLocation;
    }

    public void setInterviewLocation(String interviewLocation) {
        this.interviewLocation = interviewLocation;
    }

    public Boolean getInterviewReminder24hSent() {
        return interviewReminder24hSent;
    }

    public void setInterviewReminder24hSent(Boolean interviewReminder24hSent) {
        this.interviewReminder24hSent = interviewReminder24hSent;
    }

    public Boolean getInterviewReminder1hSent() {
        return interviewReminder1hSent;
    }

    public void setInterviewReminder1hSent(Boolean interviewReminder1hSent) {
        this.interviewReminder1hSent = interviewReminder1hSent;
    }

    public String getInterviewAttendanceStatus() {
        return interviewAttendanceStatus;
    }

    public void setInterviewAttendanceStatus(String interviewAttendanceStatus) {
        this.interviewAttendanceStatus = interviewAttendanceStatus;
    }

    public List<String> getMatchingSkills() {
        return matchingSkills;
    }

    public void setMatchingSkills(List<String> matchingSkills) {
        this.matchingSkills = matchingSkills;
    }

    public List<String> getMissingSkills() {
        return missingSkills;
    }

    public void setMissingSkills(List<String> missingSkills) {
        this.missingSkills = missingSkills;
    }

    public List<SkillMatchResponse> getSkills() {
        return skills;
    }

    public void setSkills(List<SkillMatchResponse> skills) {
        this.skills = skills;
    }
}
