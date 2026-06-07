package com.recrutement.recrutement.controller;

import com.recrutement.recrutement.dto.AssistantCandidateSearchRequest;
import com.recrutement.recrutement.dto.AssistantCandidateSearchResponse;
import com.recrutement.recrutement.dto.AssistantCompanyDescriptionRequest;
import com.recrutement.recrutement.dto.AssistantCompanyDescriptionResponse;
import com.recrutement.recrutement.dto.AssistantChatRequest;
import com.recrutement.recrutement.dto.AssistantChatResponse;
import com.recrutement.recrutement.dto.AssistantInterviewQuestionsRequest;
import com.recrutement.recrutement.dto.AssistantInterviewQuestionsResponse;
import com.recrutement.recrutement.dto.AssistantOfferDraftRequest;
import com.recrutement.recrutement.dto.AssistantOfferDraftResponse;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.service.AssistantAgentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/assistant")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AssistantController {
    private final AssistantAgentService assistantAgentService;

    @PostMapping("/recruiter/generate-offer")
    public ResponseEntity<AssistantOfferDraftResponse> generateOfferDraft(
            Authentication authentication,
            @RequestBody AssistantOfferDraftRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(assistantAgentService.generateOfferDraft(currentUser, request));
    }

    @PostMapping("/recruiter/interview-questions")
    public ResponseEntity<AssistantInterviewQuestionsResponse> suggestInterviewQuestions(
            Authentication authentication,
            @RequestBody AssistantInterviewQuestionsRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(assistantAgentService.suggestInterviewQuestions(currentUser, request));
    }

    @PostMapping("/recruiter/find-candidates")
    public ResponseEntity<AssistantCandidateSearchResponse> findCandidates(
            Authentication authentication,
            @RequestBody AssistantCandidateSearchRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(assistantAgentService.findCandidates(currentUser, request));
    }

    @PostMapping("/recruiter/company-description")
    public ResponseEntity<AssistantCompanyDescriptionResponse> generateCompanyDescription(
            Authentication authentication,
            @RequestBody AssistantCompanyDescriptionRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(assistantAgentService.generateCompanyDescription(currentUser, request));
    }

    @PostMapping("/candidate/coach")
    public ResponseEntity<AssistantChatResponse> coachCandidate(
            Authentication authentication,
            @RequestBody AssistantChatRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(assistantAgentService.coachCandidate(currentUser, request));
    }

    @PostMapping("/chat")
    public ResponseEntity<AssistantChatResponse> chat(
            Authentication authentication,
            @RequestBody AssistantChatRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(assistantAgentService.chat(currentUser, request));
    }
}
