package com.recrutement.recrutement.controller;

import com.recrutement.recrutement.dto.ConfirmInterviewAbsenceRequest;
import com.recrutement.recrutement.dto.InterviewResponse;
import com.recrutement.recrutement.dto.MessageResponse;
import com.recrutement.recrutement.dto.RescheduleInterviewRequest;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.service.InterviewService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/recruiter/interviews")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class RecruiterInterviewController {
    private final InterviewService interviewService;

    @PutMapping("/{interviewId}/present")
    public ResponseEntity<InterviewResponse> markPresent(
            Authentication authentication,
            @PathVariable Long interviewId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(interviewService.markCandidatePresent(currentUser, interviewId));
    }

    @PutMapping("/{interviewId}/confirm-absence")
    public ResponseEntity<MessageResponse> confirmAbsence(
            Authentication authentication,
            @PathVariable Long interviewId,
            @RequestBody(required = false) ConfirmInterviewAbsenceRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(interviewService.confirmAbsence(currentUser, interviewId, request));
    }

    @PutMapping("/{interviewId}/reschedule")
    public ResponseEntity<InterviewResponse> rescheduleInterview(
            Authentication authentication,
            @PathVariable Long interviewId,
            @RequestBody RescheduleInterviewRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(interviewService.rescheduleInterview(currentUser, interviewId, request));
    }
}
