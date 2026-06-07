package com.recrutement.recrutement.dto;

import java.util.Date;

public class NotificationResponse {
    private Long id;
    private String message;
    private Date dateEnvoi;
    private boolean lue;

    public NotificationResponse() {
    }

    public NotificationResponse(Long id, String message, Date dateEnvoi, boolean lue) {
        this.id = id;
        this.message = message;
        this.dateEnvoi = dateEnvoi;
        this.lue = lue;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public Date getDateEnvoi() {
        return dateEnvoi;
    }

    public void setDateEnvoi(Date dateEnvoi) {
        this.dateEnvoi = dateEnvoi;
    }

    public boolean isLue() {
        return lue;
    }

    public void setLue(boolean lue) {
        this.lue = lue;
    }
}
