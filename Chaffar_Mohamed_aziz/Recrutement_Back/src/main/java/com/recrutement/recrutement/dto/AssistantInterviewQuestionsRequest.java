package com.recrutement.recrutement.dto;

import java.util.ArrayList;
import java.util.List;

public class AssistantInterviewQuestionsRequest {
    private String offerTitle;
    private String jobDescription;
    private String seniority;
    private Integer count;
    private List<String> focusSkills = new ArrayList<>();

    public String getOfferTitle() {
        return offerTitle;
    }

    public void setOfferTitle(String offerTitle) {
        this.offerTitle = offerTitle;
    }

    public String getJobDescription() {
        return jobDescription;
    }

    public void setJobDescription(String jobDescription) {
        this.jobDescription = jobDescription;
    }

    public String getSeniority() {
        return seniority;
    }

    public void setSeniority(String seniority) {
        this.seniority = seniority;
    }

    public Integer getCount() {
        return count;
    }

    public void setCount(Integer count) {
        this.count = count;
    }

    public List<String> getFocusSkills() {
        return focusSkills;
    }

    public void setFocusSkills(List<String> focusSkills) {
        this.focusSkills = focusSkills == null ? new ArrayList<>() : focusSkills;
    }
}
