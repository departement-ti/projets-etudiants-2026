package com.recrutement.recrutement.dto;

import java.util.ArrayList;
import java.util.List;

public class AiTestResponse {
    private Long id;
    private Long applicationId;
    private Long offerId;
    private Long candidateId;
    private Long recruiterId;
    private Long resultId;
    private String offerTitle;
    private String companyName;
    private String candidateName;
    private String title;
    private String description;
    private String status;
    private Double threshold;
    private Double passingScore;
    private Integer durationMinutes;
    private Integer totalDurationSeconds;
    private Integer numberOfQuestions;
    private Double score;
    private String recommendation;
    private String difficulty;
    private Boolean allowPreviousQuestion;
    private Integer currentQuestionIndex;
    private Integer totalQuestions;
    private String questionStartedAt;
    private String questionExpiresAt;
    private String createdAt;
    private String updatedAt;
    private String startedAt;
    private String expiresAt;
    private String submittedAt;
    private String completedAt;
    private Long timeRemainingSeconds;
    private String closedReason;
    private Boolean cheatingSuspicion;
    private Integer tabSwitchCount;
    private Integer warningCount;
    private String report;
    private List<String> strengths = new ArrayList<>();
    private List<String> weaknesses = new ArrayList<>();
    private String generatedReport;
    private String proposedRejectionEmail;
    private List<String> evaluationSkills = new ArrayList<>();
    private List<AiQuestionResponse> questions = new ArrayList<>();

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getApplicationId() {
        return applicationId;
    }

    public void setApplicationId(Long applicationId) {
        this.applicationId = applicationId;
    }

    public Long getOfferId() {
        return offerId;
    }

    public void setOfferId(Long offerId) {
        this.offerId = offerId;
    }

    public Long getCandidateId() {
        return candidateId;
    }

    public void setCandidateId(Long candidateId) {
        this.candidateId = candidateId;
    }

    public Long getRecruiterId() {
        return recruiterId;
    }

    public void setRecruiterId(Long recruiterId) {
        this.recruiterId = recruiterId;
    }

    public Long getResultId() {
        return resultId;
    }

    public void setResultId(Long resultId) {
        this.resultId = resultId;
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

    public String getCandidateName() {
        return candidateName;
    }

    public void setCandidateName(String candidateName) {
        this.candidateName = candidateName;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Double getThreshold() {
        return threshold;
    }

    public void setThreshold(Double threshold) {
        this.threshold = threshold;
    }

    public Double getPassingScore() {
        return passingScore;
    }

    public void setPassingScore(Double passingScore) {
        this.passingScore = passingScore;
    }

    public Double getScore() {
        return score;
    }

    public void setScore(Double score) {
        this.score = score;
    }

    public Integer getDurationMinutes() {
        return durationMinutes;
    }

    public void setDurationMinutes(Integer durationMinutes) {
        this.durationMinutes = durationMinutes;
    }

    public Integer getTotalDurationSeconds() {
        return totalDurationSeconds;
    }

    public void setTotalDurationSeconds(Integer totalDurationSeconds) {
        this.totalDurationSeconds = totalDurationSeconds;
    }

    public Integer getNumberOfQuestions() {
        return numberOfQuestions;
    }

    public void setNumberOfQuestions(Integer numberOfQuestions) {
        this.numberOfQuestions = numberOfQuestions;
    }

    public String getRecommendation() {
        return recommendation;
    }

    public void setRecommendation(String recommendation) {
        this.recommendation = recommendation;
    }

    public String getDifficulty() {
        return difficulty;
    }

    public void setDifficulty(String difficulty) {
        this.difficulty = difficulty;
    }

    public Boolean getAllowPreviousQuestion() {
        return allowPreviousQuestion;
    }

    public void setAllowPreviousQuestion(Boolean allowPreviousQuestion) {
        this.allowPreviousQuestion = allowPreviousQuestion;
    }

    public Integer getCurrentQuestionIndex() {
        return currentQuestionIndex;
    }

    public void setCurrentQuestionIndex(Integer currentQuestionIndex) {
        this.currentQuestionIndex = currentQuestionIndex;
    }

    public Integer getTotalQuestions() {
        return totalQuestions;
    }

    public void setTotalQuestions(Integer totalQuestions) {
        this.totalQuestions = totalQuestions;
    }

    public String getQuestionStartedAt() {
        return questionStartedAt;
    }

    public void setQuestionStartedAt(String questionStartedAt) {
        this.questionStartedAt = questionStartedAt;
    }

    public String getQuestionExpiresAt() {
        return questionExpiresAt;
    }

    public void setQuestionExpiresAt(String questionExpiresAt) {
        this.questionExpiresAt = questionExpiresAt;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }

    public String getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(String updatedAt) {
        this.updatedAt = updatedAt;
    }

    public String getStartedAt() {
        return startedAt;
    }

    public void setStartedAt(String startedAt) {
        this.startedAt = startedAt;
    }

    public String getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(String expiresAt) {
        this.expiresAt = expiresAt;
    }

    public String getSubmittedAt() {
        return submittedAt;
    }

    public void setSubmittedAt(String submittedAt) {
        this.submittedAt = submittedAt;
    }

    public String getCompletedAt() {
        return completedAt;
    }

    public void setCompletedAt(String completedAt) {
        this.completedAt = completedAt;
    }

    public Long getTimeRemainingSeconds() {
        return timeRemainingSeconds;
    }

    public void setTimeRemainingSeconds(Long timeRemainingSeconds) {
        this.timeRemainingSeconds = timeRemainingSeconds;
    }

    public String getClosedReason() {
        return closedReason;
    }

    public void setClosedReason(String closedReason) {
        this.closedReason = closedReason;
    }

    public Boolean getCheatingSuspicion() {
        return cheatingSuspicion;
    }

    public void setCheatingSuspicion(Boolean cheatingSuspicion) {
        this.cheatingSuspicion = cheatingSuspicion;
    }

    public Integer getTabSwitchCount() {
        return tabSwitchCount;
    }

    public void setTabSwitchCount(Integer tabSwitchCount) {
        this.tabSwitchCount = tabSwitchCount;
    }

    public Integer getWarningCount() {
        return warningCount;
    }

    public void setWarningCount(Integer warningCount) {
        this.warningCount = warningCount;
    }

    public String getReport() {
        return report;
    }

    public void setReport(String report) {
        this.report = report;
    }

    public List<String> getStrengths() {
        return strengths;
    }

    public void setStrengths(List<String> strengths) {
        this.strengths = strengths;
    }

    public List<String> getWeaknesses() {
        return weaknesses;
    }

    public void setWeaknesses(List<String> weaknesses) {
        this.weaknesses = weaknesses;
    }

    public String getGeneratedReport() {
        return generatedReport;
    }

    public void setGeneratedReport(String generatedReport) {
        this.generatedReport = generatedReport;
    }

    public String getProposedRejectionEmail() {
        return proposedRejectionEmail;
    }

    public void setProposedRejectionEmail(String proposedRejectionEmail) {
        this.proposedRejectionEmail = proposedRejectionEmail;
    }

    public List<String> getEvaluationSkills() {
        return evaluationSkills;
    }

    public void setEvaluationSkills(List<String> evaluationSkills) {
        this.evaluationSkills = evaluationSkills;
    }

    public List<AiQuestionResponse> getQuestions() {
        return questions;
    }

    public void setQuestions(List<AiQuestionResponse> questions) {
        this.questions = questions;
    }
}
