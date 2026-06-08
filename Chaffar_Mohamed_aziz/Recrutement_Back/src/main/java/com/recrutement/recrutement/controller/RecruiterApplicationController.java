package com.recrutement.recrutement.controller;

import com.recrutement.recrutement.dto.AiTestResponse;
import com.recrutement.recrutement.dto.CreateAiTestRequest;
import com.recrutement.recrutement.dto.InterviewPlannerDraftResponse;
import com.recrutement.recrutement.dto.InterviewResponse;
import com.recrutement.recrutement.dto.MessageResponse;
import com.recrutement.recrutement.dto.ApplicationResponse;
import com.recrutement.recrutement.dto.RejectAfterAiTestRequest;
import com.recrutement.recrutement.dto.ScheduleInterviewRequest;
import com.recrutement.recrutement.dto.UpdateApplicationStatusRequest;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.service.AiTestService;
import com.recrutement.recrutement.service.ApplicationService;
import com.recrutement.recrutement.service.InterviewService;
import java.nio.charset.StandardCharsets;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/recruiter/candidatures")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class RecruiterApplicationController {
    private final ApplicationService applicationService;
    private final AiTestService aiTestService;
    private final InterviewService interviewService;

    @GetMapping
    public ResponseEntity<List<ApplicationResponse>> getRecruiterApplications(
            Authentication authentication,
            @RequestParam(required = false) Long offerId,
            @RequestParam(required = false) Double minScore
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(applicationService.getRecruiterApplications(currentUser, offerId, minScore));
    }

    @GetMapping("/{applicationId}")
    public ResponseEntity<ApplicationResponse> getRecruiterApplicationById(
            Authentication authentication,
            @PathVariable Long applicationId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(applicationService.getRecruiterApplicationById(currentUser, applicationId));
    }

    @GetMapping("/{applicationId}/cv")
    public ResponseEntity<ByteArrayResource> downloadRecruiterCandidateCv(
            Authentication authentication,
            @PathVariable Long applicationId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        ApplicationService.CvDownloadPayload payload = applicationService.getRecruiterCandidateCv(currentUser, applicationId);

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(payload.contentType()))
                .contentLength(payload.bytes().length)
                .header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment()
                                .filename(payload.fileName(), StandardCharsets.UTF_8)
                                .build()
                                .toString()
                )
                .body(new ByteArrayResource(payload.bytes()));
    }

    @GetMapping("/{applicationId}/interview-draft")
    public ResponseEntity<InterviewPlannerDraftResponse> getInterviewPlannerDraft(
            Authentication authentication,
            @PathVariable Long applicationId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(interviewService.getPlannerDraft(currentUser, applicationId));
    }

    @PutMapping("/{applicationId}/status")
    public ResponseEntity<ApplicationResponse> updateRecruiterApplicationStatus(
            Authentication authentication,
            @PathVariable Long applicationId,
            @RequestBody UpdateApplicationStatusRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(applicationService.updateRecruiterApplicationStatus(currentUser, applicationId, request.getStatus()));
    }

    @PostMapping("/{applicationId}/interview")
    public ResponseEntity<InterviewResponse> scheduleInterview(
            Authentication authentication,
            @PathVariable Long applicationId,
            @RequestBody ScheduleInterviewRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(interviewService.scheduleInterview(currentUser, applicationId, request));
    }

    @PostMapping("/{applicationId}/ai-test")
    public ResponseEntity<AiTestResponse> createAiTestFromApplicationRoute(
            Authentication authentication,
            @PathVariable Long applicationId,
            @RequestBody(required = false) CreateAiTestRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        Double threshold = request == null ? null : request.getThreshold();
        Integer durationMinutes = request == null ? null : request.getDurationMinutes();
        return ResponseEntity.ok(aiTestService.createRecruiterAiTest(currentUser, applicationId, threshold, durationMinutes));
    }

    @PostMapping("/{applicationId}/reject-after-ai-test")
    public ResponseEntity<MessageResponse> rejectAfterAiTestFromApplicationRoute(
            Authentication authentication,
            @PathVariable Long applicationId,
            @RequestBody(required = false) RejectAfterAiTestRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(aiTestService.rejectAfterAiTest(currentUser, applicationId, request));
    }
}
