package com.recrutement.recrutement.dto;

public class CreateAiTestRequest {
    private Boolean enabled;
    private String title;
    private String description;
    private Integer numberOfQuestions;
    private Double threshold;
    private Integer durationMinutes;
    private String difficulty;
    private Boolean allowPreviousQuestion;
    private java.util.List<String> evaluationSkills;

    public Boolean getEnabled() {
        return enabled;
    }

    public void setEnabled(Boolean enabled) {
        this.enabled = enabled;
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

    public Integer getNumberOfQuestions() {
        return numberOfQuestions;
    }

    public void setNumberOfQuestions(Integer numberOfQuestions) {
        this.numberOfQuestions = numberOfQuestions;
    }

    public Double getThreshold() {
        return threshold;
    }

    public void setThreshold(Double threshold) {
        this.threshold = threshold;
    }

    public Integer getDurationMinutes() {
        return durationMinutes;
    }

    public void setDurationMinutes(Integer durationMinutes) {
        this.durationMinutes = durationMinutes;
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

    public java.util.List<String> getEvaluationSkills() {
        return evaluationSkills;
    }

    public void setEvaluationSkills(java.util.List<String> evaluationSkills) {
        this.evaluationSkills = evaluationSkills;
    }
}
