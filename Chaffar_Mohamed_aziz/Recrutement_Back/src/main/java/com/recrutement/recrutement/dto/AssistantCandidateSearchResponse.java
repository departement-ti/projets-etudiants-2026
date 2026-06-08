package com.recrutement.recrutement.dto;

import java.util.ArrayList;
import java.util.List;

public class AssistantCandidateSearchResponse {
    private String message;
    private List<AssistantCandidateSuggestionResponse> suggestions = new ArrayList<>();

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public List<AssistantCandidateSuggestionResponse> getSuggestions() {
        return suggestions;
    }

    public void setSuggestions(List<AssistantCandidateSuggestionResponse> suggestions) {
        this.suggestions = suggestions == null ? new ArrayList<>() : suggestions;
    }
}
