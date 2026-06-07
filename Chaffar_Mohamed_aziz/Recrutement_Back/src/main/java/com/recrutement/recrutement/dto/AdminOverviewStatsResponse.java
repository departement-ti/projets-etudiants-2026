package com.recrutement.recrutement.dto;

import java.util.List;

public class AdminOverviewStatsResponse {
    private long totalUsers;
    private long totalCandidates;
    private long totalRecruiters;
    private long totalOffers;
    private long totalApplications;
    private long totalPlannedInterviews;
    private long totalRejectedApplications;
    private long totalRetainedCandidates;
    private long totalCompletedAiTests;
    private double aiTestSuccessRate;
    private double averageMatchingScore;
    private List<TopSkillResponse> topSkills;
    private List<TopOfferActivityResponse> topOffers;

    public long getTotalUsers() { return totalUsers; }
    public void setTotalUsers(long totalUsers) { this.totalUsers = totalUsers; }
    public long getTotalCandidates() { return totalCandidates; }
    public void setTotalCandidates(long totalCandidates) { this.totalCandidates = totalCandidates; }
    public long getTotalRecruiters() { return totalRecruiters; }
    public void setTotalRecruiters(long totalRecruiters) { this.totalRecruiters = totalRecruiters; }
    public long getTotalOffers() { return totalOffers; }
    public void setTotalOffers(long totalOffers) { this.totalOffers = totalOffers; }
    public long getTotalApplications() { return totalApplications; }
    public void setTotalApplications(long totalApplications) { this.totalApplications = totalApplications; }
    public long getTotalPlannedInterviews() { return totalPlannedInterviews; }
    public void setTotalPlannedInterviews(long totalPlannedInterviews) { this.totalPlannedInterviews = totalPlannedInterviews; }
    public long getTotalRejectedApplications() { return totalRejectedApplications; }
    public void setTotalRejectedApplications(long totalRejectedApplications) { this.totalRejectedApplications = totalRejectedApplications; }
    public long getTotalRetainedCandidates() { return totalRetainedCandidates; }
    public void setTotalRetainedCandidates(long totalRetainedCandidates) { this.totalRetainedCandidates = totalRetainedCandidates; }
    public long getTotalCompletedAiTests() { return totalCompletedAiTests; }
    public void setTotalCompletedAiTests(long totalCompletedAiTests) { this.totalCompletedAiTests = totalCompletedAiTests; }
    public double getAiTestSuccessRate() { return aiTestSuccessRate; }
    public void setAiTestSuccessRate(double aiTestSuccessRate) { this.aiTestSuccessRate = aiTestSuccessRate; }
    public double getAverageMatchingScore() { return averageMatchingScore; }
    public void setAverageMatchingScore(double averageMatchingScore) { this.averageMatchingScore = averageMatchingScore; }
    public List<TopSkillResponse> getTopSkills() { return topSkills; }
    public void setTopSkills(List<TopSkillResponse> topSkills) { this.topSkills = topSkills; }
    public List<TopOfferActivityResponse> getTopOffers() { return topOffers; }
    public void setTopOffers(List<TopOfferActivityResponse> topOffers) { this.topOffers = topOffers; }
}
