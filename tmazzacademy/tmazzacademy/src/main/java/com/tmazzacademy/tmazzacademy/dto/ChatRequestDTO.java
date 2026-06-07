package com.tmazzacademy.tmazzacademy.dto;

public class ChatRequestDTO {

    private String message;
    private String role;

    public ChatRequestDTO() {}

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }
}