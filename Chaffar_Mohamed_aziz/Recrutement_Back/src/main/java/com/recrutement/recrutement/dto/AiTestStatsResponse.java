package com.recrutement.recrutement.dto;

public class AiTestStatsResponse {
    private long totalTests;
    private long completedTests;
    private long passedTests;
    private long failedTests;
    private long expiredTests;
    private long cheatingSuspicions;
    private double averageScore;
    private double successRate;

    public long getTotalTests() { return totalTests; }
    public void setTotalTests(long totalTests) { this.totalTests = totalTests; }
    public long getCompletedTests() { return completedTests; }
    public void setCompletedTests(long completedTests) { this.completedTests = completedTests; }
    public long getPassedTests() { return passedTests; }
    public void setPassedTests(long passedTests) { this.passedTests = passedTests; }
    public long getFailedTests() { return failedTests; }
    public void setFailedTests(long failedTests) { this.failedTests = failedTests; }
    public long getExpiredTests() { return expiredTests; }
    public void setExpiredTests(long expiredTests) { this.expiredTests = expiredTests; }
    public long getCheatingSuspicions() { return cheatingSuspicions; }
    public void setCheatingSuspicions(long cheatingSuspicions) { this.cheatingSuspicions = cheatingSuspicions; }
    public double getAverageScore() { return averageScore; }
    public void setAverageScore(double averageScore) { this.averageScore = averageScore; }
    public double getSuccessRate() { return successRate; }
    public void setSuccessRate(double successRate) { this.successRate = successRate; }
}
