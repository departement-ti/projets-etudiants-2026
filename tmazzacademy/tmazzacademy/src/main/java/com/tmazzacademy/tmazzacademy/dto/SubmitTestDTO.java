package com.tmazzacademy.tmazzacademy.dto;

import java.util.Map;

public class SubmitTestDTO {

    // questionId -> answer
    private Map<Long, String> answers;

    public SubmitTestDTO() {}

    public Map<Long, String> getAnswers() {
        return answers;
    }

    public void setAnswers(Map<Long, String> answers) {
        this.answers = answers;
    }
}