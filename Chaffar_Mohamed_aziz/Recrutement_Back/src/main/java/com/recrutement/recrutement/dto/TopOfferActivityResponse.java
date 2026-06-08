package com.recrutement.recrutement.dto;

public class TopOfferActivityResponse {
    private Long offerId;
    private String title;
    private long applicationsCount;

    public TopOfferActivityResponse() {
    }

    public TopOfferActivityResponse(Long offerId, String title, long applicationsCount) {
        this.offerId = offerId;
        this.title = title;
        this.applicationsCount = applicationsCount;
    }

    public Long getOfferId() { return offerId; }
    public void setOfferId(Long offerId) { this.offerId = offerId; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public long getApplicationsCount() { return applicationsCount; }
    public void setApplicationsCount(long applicationsCount) { this.applicationsCount = applicationsCount; }
}
