package com.tmazzacademy.tmazzacademy.dto;

public class TestStatusDTO {

    private boolean canStart;
    private String message;
    private long secondsLeft;
    private long attemptsLeft;

    public TestStatusDTO() {}

    public TestStatusDTO(
            boolean canStart,
            String message,
            long secondsLeft,
            long attemptsLeft
    ) {
        this.canStart = canStart;
        this.message = message;
        this.secondsLeft = secondsLeft;
        this.attemptsLeft = attemptsLeft;
    }

    public boolean isCanStart() {
        return canStart;
    }

    public void setCanStart(boolean canStart) {
        this.canStart = canStart;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public long getSecondsLeft() {
        return secondsLeft;
    }

    public void setSecondsLeft(long secondsLeft) {
        this.secondsLeft = secondsLeft;
    }

    public long getAttemptsLeft() {
        return attemptsLeft;
    }

    public void setAttemptsLeft(long attemptsLeft) {
        this.attemptsLeft = attemptsLeft;
    }
}