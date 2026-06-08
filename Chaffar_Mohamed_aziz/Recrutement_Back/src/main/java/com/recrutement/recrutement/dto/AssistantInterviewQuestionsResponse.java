package com.recrutement.recrutement.dto;

import java.util.ArrayList;
import java.util.List;

public class AssistantInterviewQuestionsResponse {
    private String message;
    private String intro;
    private List<String> questions = new ArrayList<>();

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getIntro() {
        return intro;
    }

    public void setIntro(String intro) {
        this.intro = intro;
    }

    public List<String> getQuestions() {
        return questions;
    }

    public void setQuestions(List<String> questions) {
        this.questions = questions == null ? new ArrayList<>() : questions;
    }
}
