package com.recrutement.recrutement.controller;

import com.recrutement.recrutement.dto.CandidateProfileResponse;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.service.ApplicationService;
import com.recrutement.recrutement.service.CandidateProfileService;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/recruiter/candidates")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class RecruiterCandidateController {
    private static final Logger log = LoggerFactory.getLogger(RecruiterCandidateController.class);

    private final CandidateProfileService candidateProfileService;
    private final ApplicationService applicationService;

    @GetMapping("/{candidateId}/profile")
    public ResponseEntity<CandidateProfileResponse> getCandidateProfile(
            Authentication authentication,
            @PathVariable Long candidateId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(candidateProfileService.getProfileForRecruiter(currentUser, candidateId));
    }

    @GetMapping("/{candidateId}/cv")
    public ResponseEntity<ByteArrayResource> downloadCandidateCv(
            Authentication authentication,
            @PathVariable Long candidateId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        ApplicationService.CvDownloadPayload payload =
                applicationService.getRecruiterCandidateCvByCandidateId(currentUser, candidateId);

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(payload.contentType()))
                .contentLength(payload.bytes().length)
                .header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment()
                                .filename(payload.fileName())
                                .build()
                                .toString()
                )
                .body(new ByteArrayResource(payload.bytes()));
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Map<String, String>> handleRuntimeException(RuntimeException ex) {
        return ResponseEntity.badRequest().body(Map.of(
                "message",
                ex.getMessage() == null || ex.getMessage().isBlank()
                        ? "Chargement du profil candidat impossible."
                        : ex.getMessage()
        ));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleException(Exception ex) {
        log.error("Erreur technique lors du chargement du profil candidat recruteur", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                "message",
                "Une erreur technique est survenue lors du chargement du profil candidat."
        ));
    }
}
