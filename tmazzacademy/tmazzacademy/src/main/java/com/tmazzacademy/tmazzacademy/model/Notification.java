package com.tmazzacademy.tmazzacademy.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

    @Column(length = 3000)
    private String message;

    private boolean readed = false;

    private String targetRole;

    private Long userId;

    private LocalDateTime createdAt = LocalDateTime.now();

    public Notification() {}

    public Long getId() {
        return id;
    }

    public String getTitle() {
        return title;
    }

    public String getMessage() {
        return message;
    }

    public boolean isReaded() {
        return readed;
    }

    public String getTargetRole() {
        return targetRole;
    }

    public Long getUserId() {
        return userId;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public void setReaded(boolean readed) {
        this.readed = readed;
    }

    public void setTargetRole(String targetRole) {
        this.targetRole = targetRole;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}