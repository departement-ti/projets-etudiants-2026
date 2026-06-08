package com.recrutement.recrutement.dto;

import java.util.ArrayList;
import java.util.List;

public class AssistantOfferDraftResponse {
    private String message;
    private String generatedDescription;
    private List<String> highlights = new ArrayList<>();
    private List<String> keywords = new ArrayList<>();

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getGeneratedDescription() {
        return generatedDescription;
    }

    public void setGeneratedDescription(String generatedDescription) {
        this.generatedDescription = generatedDescription;
    }

    public List<String> getHighlights() {
        return highlights;
    }

    public void setHighlights(List<String> highlights) {
        this.highlights = highlights == null ? new ArrayList<>() : highlights;
    }

    public List<String> getKeywords() {
        return keywords;
    }

    public void setKeywords(List<String> keywords) {
        this.keywords = keywords == null ? new ArrayList<>() : keywords;
    }
}
