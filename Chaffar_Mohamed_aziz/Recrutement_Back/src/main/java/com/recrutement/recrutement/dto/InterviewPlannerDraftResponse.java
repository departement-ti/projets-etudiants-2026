package com.recrutement.recrutement.dto;

import java.util.ArrayList;
import java.util.List;

public class InterviewPlannerDraftResponse {
    private Long applicationId;
    private String candidateName;
    private String offerTitle;
    private Double aiTestScore;
    private String aiRecommendation;
    private String defaultInvitationMessage;
    private String suggestedInterviewType;
    private List<String> suggestedQuestions = new ArrayList<>();

    public Long getApplicationId() {
        return applicationId;
    }

    public void setApplicationId(Long applicationId) {
        this.applicationId = applicationId;
    }

    public String getCandidateName() {
        return candidateName;
    }

    public void setCandidateName(String candidateName) {
        this.candidateName = candidateName;
    }

    public String getOfferTitle() {
        return offerTitle;
    }

    public void setOfferTitle(String offerTitle) {
        this.offerTitle = offerTitle;
    }

    public Double getAiTestScore() {
        return aiTestScore;
    }

    public void setAiTestScore(Double aiTestScore) {
        this.aiTestScore = aiTestScore;
    }

    public String getAiRecommendation() {
        return aiRecommendation;
    }

    public void setAiRecommendation(String aiRecommendation) {
        this.aiRecommendation = aiRecommendation;
    }

    public String getDefaultInvitationMessage() {
        return defaultInvitationMessage;
    }

    public void setDefaultInvitationMessage(String defaultInvitationMessage) {
        this.defaultInvitationMessage = defaultInvitationMessage;
    }

    public String getSuggestedInterviewType() {
        return suggestedInterviewType;
    }

    public void setSuggestedInterviewType(String suggestedInterviewType) {
        this.suggestedInterviewType = suggestedInterviewType;
    }

    public List<String> getSuggestedQuestions() {
        return suggestedQuestions;
    }

    public void setSuggestedQuestions(List<String> suggestedQuestions) {
        this.suggestedQuestions = suggestedQuestions;
    }
}
