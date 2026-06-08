package com.recrutement.recrutement.dto;

import java.util.ArrayList;
import java.util.List;

public class SubmitAiTestRequest {
    private List<AiAnswerSubmissionRequest> answers = new ArrayList<>();
    private Boolean autoSubmit;
    private String submitReason;

    public List<AiAnswerSubmissionRequest> getAnswers() {
        return answers;
    }

    public void setAnswers(List<AiAnswerSubmissionRequest> answers) {
        this.answers = answers;
    }

    public Boolean getAutoSubmit() {
        return autoSubmit;
    }

    public void setAutoSubmit(Boolean autoSubmit) {
        this.autoSubmit = autoSubmit;
    }

    public String getSubmitReason() {
        return submitReason;
    }

    public void setSubmitReason(String submitReason) {
        this.submitReason = submitReason;
    }
}
