package com.recrutement.recrutement.service;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class InterviewScheduler {
    private final InterviewService interviewService;

    public InterviewScheduler(InterviewService interviewService) {
        this.interviewService = interviewService;
    }

    @Scheduled(fixedDelay = 60000)
    public void processInterviewEvents() {
        interviewService.processScheduledInterviews();
    }
}
