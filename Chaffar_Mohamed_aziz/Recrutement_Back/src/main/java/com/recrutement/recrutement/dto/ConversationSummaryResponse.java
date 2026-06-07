package com.recrutement.recrutement.dto;

public class ConversationSummaryResponse {
    private Long applicationId;
    private Long offerId;
    private String offerTitle;
    private String companyName;
    private String counterpartName;
    private String counterpartEmail;
    private String counterpartRole;
    private String status;
    private double score;
    private String lastMessage;
    private String lastMessageAt;
    private long unreadCount;

    public Long getApplicationId() {
        return applicationId;
    }

    public void setApplicationId(Long applicationId) {
        this.applicationId = applicationId;
    }

    public Long getOfferId() {
        return offerId;
    }

    public void setOfferId(Long offerId) {
        this.offerId = offerId;
    }

    public String getOfferTitle() {
        return offerTitle;
    }

    public void setOfferTitle(String offerTitle) {
        this.offerTitle = offerTitle;
    }

    public String getCompanyName() {
        return companyName;
    }

    public void setCompanyName(String companyName) {
        this.companyName = companyName;
    }

    public String getCounterpartName() {
        return counterpartName;
    }

    public void setCounterpartName(String counterpartName) {
        this.counterpartName = counterpartName;
    }

    public String getCounterpartEmail() {
        return counterpartEmail;
    }

    public void setCounterpartEmail(String counterpartEmail) {
        this.counterpartEmail = counterpartEmail;
    }

    public String getCounterpartRole() {
        return counterpartRole;
    }

    public void setCounterpartRole(String counterpartRole) {
        this.counterpartRole = counterpartRole;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public double getScore() {
        return score;
    }

    public void setScore(double score) {
        this.score = score;
    }

    public String getLastMessage() {
        return lastMessage;
    }

    public void setLastMessage(String lastMessage) {
        this.lastMessage = lastMessage;
    }

    public String getLastMessageAt() {
        return lastMessageAt;
    }

    public void setLastMessageAt(String lastMessageAt) {
        this.lastMessageAt = lastMessageAt;
    }

    public long getUnreadCount() {
        return unreadCount;
    }

    public void setUnreadCount(long unreadCount) {
        this.unreadCount = unreadCount;
    }
}
