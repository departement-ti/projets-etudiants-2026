package com.recrutement.recrutement.dto;

import java.util.ArrayList;
import java.util.List;

public class AssistantChatRequest {
    private String message;
    private String prompt;
    private String contextType;
    private Long targetId;
    private List<String> history = new ArrayList<>();

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getPrompt() {
        return prompt;
    }

    public void setPrompt(String prompt) {
        this.prompt = prompt;
    }

    public String getContextType() {
        return contextType;
    }

    public void setContextType(String contextType) {
        this.contextType = contextType;
    }

    public Long getTargetId() {
        return targetId;
    }

    public void setTargetId(Long targetId) {
        this.targetId = targetId;
    }

    public List<String> getHistory() {
        return history;
    }

    public void setHistory(List<String> history) {
        this.history = history == null ? new ArrayList<>() : history;
    }

    public String resolveMessage() {
        if (message != null && !message.trim().isEmpty()) {
            return message.trim();
        }
        return prompt == null ? "" : prompt.trim();
    }
}
