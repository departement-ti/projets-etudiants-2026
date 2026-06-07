package com.recrutement.recrutement.controller;

import com.recrutement.recrutement.dto.AiTestResponse;
import com.recrutement.recrutement.dto.AiTestQuestionUpdateRequest;
import com.recrutement.recrutement.dto.CreateAiTestRequest;
import com.recrutement.recrutement.dto.MessageResponse;
import com.recrutement.recrutement.dto.RejectAfterAiTestRequest;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.service.AiTestService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/recruiter")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class RecruiterAiTestController {
    private final AiTestService aiTestService;

    @PostMapping("/applications/{applicationId}/ai-test")
    public ResponseEntity<AiTestResponse> createAiTest(
            Authentication authentication,
            @PathVariable Long applicationId,
            @RequestBody(required = false) CreateAiTestRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        Double threshold = request == null ? null : request.getThreshold();
        Integer durationMinutes = request == null ? null : request.getDurationMinutes();
        return ResponseEntity.ok(aiTestService.createRecruiterAiTest(currentUser, applicationId, threshold, durationMinutes));
    }

    @PostMapping("/offers/{offerId}/ai-test")
    public ResponseEntity<AiTestResponse> configureOfferAiTest(
            Authentication authentication,
            @PathVariable Long offerId,
            @RequestBody(required = false) CreateAiTestRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.configureOfferAiTest(currentUser, offerId, request));
    }

    @PostMapping("/offers/{offerId}/ai-test/generate")
    public ResponseEntity<AiTestResponse> generateOfferAiTest(
            Authentication authentication,
            @PathVariable Long offerId,
            @RequestBody(required = false) CreateAiTestRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.generateOfferAiTest(currentUser, offerId, request));
    }

    @GetMapping("/offers/{offerId}/ai-test")
    public ResponseEntity<AiTestResponse> getOfferAiTest(
            Authentication authentication,
            @PathVariable Long offerId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.getRecruiterOfferAiTest(currentUser, offerId));
    }

    @PutMapping("/ai-tests/{testId}")
    public ResponseEntity<AiTestResponse> updateAiTest(
            Authentication authentication,
            @PathVariable Long testId,
            @RequestBody CreateAiTestRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.updateRecruiterAiTest(currentUser, testId, request));
    }

    @PutMapping("/ai-tests/questions/{questionId}")
    public ResponseEntity<AiTestResponse> updateAiQuestion(
            Authentication authentication,
            @PathVariable Long questionId,
            @RequestBody AiTestQuestionUpdateRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.updateRecruiterAiQuestion(currentUser, questionId, request));
    }

    @PostMapping("/ai-tests/questions/{questionId}/regenerate")
    public ResponseEntity<AiTestResponse> regenerateAiQuestion(
            Authentication authentication,
            @PathVariable Long questionId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.regenerateRecruiterAiQuestion(currentUser, questionId));
    }

    @DeleteMapping("/ai-tests/questions/{questionId}")
    public ResponseEntity<MessageResponse> deleteAiQuestion(
            Authentication authentication,
            @PathVariable Long questionId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.deleteRecruiterAiQuestion(currentUser, questionId));
    }

    @PostMapping("/ai-tests/{testId}/validate")
    public ResponseEntity<AiTestResponse> validateAiTest(
            Authentication authentication,
            @PathVariable Long testId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.validateRecruiterAiTest(currentUser, testId));
    }

    @GetMapping("/ai-tests/{testId}/result")
    public ResponseEntity<AiTestResponse> getAiTestResult(
            Authentication authentication,
            @PathVariable Long testId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.getRecruiterAiTestResult(currentUser, testId));
    }

    @PostMapping("/applications/{applicationId}/reject-after-ai-test")
    public ResponseEntity<MessageResponse> rejectAfterAiTest(
            Authentication authentication,
            @PathVariable Long applicationId,
            @RequestBody(required = false) RejectAfterAiTestRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.rejectAfterAiTest(currentUser, applicationId, request));
    }

    @PostMapping("/ai-tests/{testId}/reopen")
    public ResponseEntity<AiTestResponse> reopenAiTest(
            Authentication authentication,
            @PathVariable Long testId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.reopenRecruiterAiTest(currentUser, testId));
    }
}
