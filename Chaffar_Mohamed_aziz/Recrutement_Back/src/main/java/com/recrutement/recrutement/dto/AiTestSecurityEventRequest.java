package com.recrutement.recrutement.dto;

public class AiTestSecurityEventRequest {
    private String eventType;
    private String description;

    public String getEventType() {
        return eventType;
    }

    public void setEventType(String eventType) {
        this.eventType = eventType;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }
}
