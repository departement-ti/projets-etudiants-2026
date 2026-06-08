package com.recrutement.recrutement.controller;

import com.recrutement.recrutement.dto.AiTestResponse;
import com.recrutement.recrutement.dto.AiTestQuestionAnswerRequest;
import com.recrutement.recrutement.dto.AiTestSecurityEventRequest;
import com.recrutement.recrutement.dto.SubmitAiTestRequest;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.service.AiTestService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/candidate")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class CandidateAiTestController {
    private final AiTestService aiTestService;

    @GetMapping("/ai-tests")
    public ResponseEntity<List<AiTestResponse>> getCandidateAiTests(Authentication authentication) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.getCandidateAiTests(currentUser));
    }

    @GetMapping("/applications/{applicationId}/ai-test")
    public ResponseEntity<AiTestResponse> getCandidateAiTestByApplication(
            Authentication authentication,
            @PathVariable Long applicationId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.getCandidateAiTestByApplication(currentUser, applicationId));
    }

    @GetMapping("/ai-tests/{testId}")
    public ResponseEntity<AiTestResponse> getCandidateAiTest(
            Authentication authentication,
            @PathVariable Long testId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.getCandidateAiTest(currentUser, testId));
    }

    @PostMapping("/ai-tests/{testId}/start")
    public ResponseEntity<AiTestResponse> startCandidateAiTest(
            Authentication authentication,
            @PathVariable Long testId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.startCandidateAiTest(currentUser, testId));
    }

    @GetMapping("/ai-test-results/{resultId}/current-question")
    public ResponseEntity<AiTestResponse> getCurrentQuestion(
            Authentication authentication,
            @PathVariable Long resultId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.getCurrentQuestion(currentUser, resultId));
    }

    @PostMapping("/ai-test-results/{resultId}/answer")
    public ResponseEntity<AiTestResponse> answerCurrentQuestion(
            Authentication authentication,
            @PathVariable Long resultId,
            @RequestBody(required = false) AiTestQuestionAnswerRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.answerCurrentQuestion(currentUser, resultId, request));
    }

    @PostMapping("/ai-test-results/{resultId}/next")
    public ResponseEntity<AiTestResponse> moveToNextQuestion(
            Authentication authentication,
            @PathVariable Long resultId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.moveToNextQuestion(currentUser, resultId));
    }

    @PostMapping("/ai-test-results/{resultId}/submit")
    public ResponseEntity<AiTestResponse> submitCandidateAiTestResult(
            Authentication authentication,
            @PathVariable Long resultId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.submitCandidateAiTestResult(currentUser, resultId));
    }

    @PostMapping("/ai-tests/{testId}/submit")
    public ResponseEntity<AiTestResponse> submitCandidateAiTest(
            Authentication authentication,
            @PathVariable Long testId,
            @RequestBody SubmitAiTestRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.submitCandidateAiTest(currentUser, testId, request));
    }

    @PostMapping("/ai-tests/{testId}/security-event")
    public ResponseEntity<AiTestResponse> registerSecurityEvent(
            Authentication authentication,
            @PathVariable Long testId,
            @RequestBody AiTestSecurityEventRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.registerSecurityEvent(currentUser, testId, request));
    }
}
