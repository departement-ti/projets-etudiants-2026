package com.recrutement.recrutement.controller;

import com.recrutement.recrutement.dto.RecruiterCompanyProfileRequest;
import com.recrutement.recrutement.dto.RecruiterCompanyProfileResponse;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.service.RecruiterCompanyProfileService;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/recruiter/company-profile")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class RecruiterCompanyProfileController {
    private final RecruiterCompanyProfileService recruiterCompanyProfileService;

    @GetMapping
    public ResponseEntity<RecruiterCompanyProfileResponse> getCurrentCompanyProfile(Authentication authentication) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(recruiterCompanyProfileService.getCurrentCompanyProfile(currentUser));
    }

    @PutMapping
    public ResponseEntity<RecruiterCompanyProfileResponse> saveCurrentCompanyProfile(
            Authentication authentication,
            @RequestBody RecruiterCompanyProfileRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(recruiterCompanyProfileService.saveCurrentCompanyProfile(currentUser, request));
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Map<String, String>> handleRuntimeException(RuntimeException ex) {
        return ResponseEntity.badRequest().body(Map.of(
                "message",
                ex.getMessage() == null || ex.getMessage().isBlank()
                        ? "Enregistrement des informations entreprise impossible."
                        : ex.getMessage()
        ));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleException(Exception ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                "message",
                "Une erreur technique est survenue lors de la mise a jour de l'entreprise."
        ));
    }
}
