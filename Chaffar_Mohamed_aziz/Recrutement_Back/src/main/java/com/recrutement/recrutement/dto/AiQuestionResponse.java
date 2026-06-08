package com.recrutement.recrutement.dto;

import java.util.ArrayList;
import java.util.List;

public class AiQuestionResponse {
    private Long id;
    private String questionText;
    private String questionType;
    private List<String> options = new ArrayList<>();
    private String correctAnswer;
    private String expectedAnswer;
    private Double points;
    private Integer orderIndex;
    private Integer timeLimitSeconds;
    private Boolean acceptedByRecruiter;
    private String candidateAnswer;
    private Boolean correct;
    private Double pointsObtained;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getQuestionText() {
        return questionText;
    }

    public void setQuestionText(String questionText) {
        this.questionText = questionText;
    }

    public String getQuestionType() {
        return questionType;
    }

    public void setQuestionType(String questionType) {
        this.questionType = questionType;
    }

    public List<String> getOptions() {
        return options;
    }

    public void setOptions(List<String> options) {
        this.options = options;
    }

    public String getCorrectAnswer() {
        return correctAnswer;
    }

    public void setCorrectAnswer(String correctAnswer) {
        this.correctAnswer = correctAnswer;
    }

    public String getExpectedAnswer() {
        return expectedAnswer;
    }

    public void setExpectedAnswer(String expectedAnswer) {
        this.expectedAnswer = expectedAnswer;
    }

    public Double getPoints() {
        return points;
    }

    public void setPoints(Double points) {
        this.points = points;
    }

    public Integer getOrderIndex() {
        return orderIndex;
    }

    public void setOrderIndex(Integer orderIndex) {
        this.orderIndex = orderIndex;
    }

    public Integer getTimeLimitSeconds() {
        return timeLimitSeconds;
    }

    public void setTimeLimitSeconds(Integer timeLimitSeconds) {
        this.timeLimitSeconds = timeLimitSeconds;
    }

    public Boolean getAcceptedByRecruiter() {
        return acceptedByRecruiter;
    }

    public void setAcceptedByRecruiter(Boolean acceptedByRecruiter) {
        this.acceptedByRecruiter = acceptedByRecruiter;
    }

    public String getCandidateAnswer() {
        return candidateAnswer;
    }

    public void setCandidateAnswer(String candidateAnswer) {
        this.candidateAnswer = candidateAnswer;
    }

    public Boolean getCorrect() {
        return correct;
    }

    public void setCorrect(Boolean correct) {
        this.correct = correct;
    }

    public Double getPointsObtained() {
        return pointsObtained;
    }

    public void setPointsObtained(Double pointsObtained) {
        this.pointsObtained = pointsObtained;
    }
}
