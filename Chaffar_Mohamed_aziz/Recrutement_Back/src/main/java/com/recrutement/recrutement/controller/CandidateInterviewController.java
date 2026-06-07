package com.recrutement.recrutement.controller;

import com.recrutement.recrutement.dto.InterviewResponse;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.service.InterviewService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/candidate/interviews")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class CandidateInterviewController {
    private final InterviewService interviewService;

    @GetMapping
    public ResponseEntity<List<InterviewResponse>> getCandidateInterviews(Authentication authentication) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(interviewService.getCandidateInterviews(currentUser));
    }
}
