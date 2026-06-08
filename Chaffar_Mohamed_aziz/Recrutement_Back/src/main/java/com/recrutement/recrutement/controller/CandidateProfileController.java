package com.recrutement.recrutement.controller;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.recrutement.recrutement.dto.CandidateProfileRequest;
import com.recrutement.recrutement.dto.CandidateProfileAutofillResponse;
import com.recrutement.recrutement.dto.CandidateProfileResponse;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.service.CandidateProfileService;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.security.core.Authentication;

@RestController
@RequestMapping("/api/candidate/profile")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class CandidateProfileController {
    private static final Logger log = LoggerFactory.getLogger(CandidateProfileController.class);

    private final CandidateProfileService candidateProfileService;
    private final ObjectMapper objectMapper;

    @GetMapping
    public ResponseEntity<CandidateProfileResponse> getCurrentProfile(Authentication authentication) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(candidateProfileService.getCurrentProfile(currentUser));
    }

    @PutMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<CandidateProfileResponse> saveCurrentProfile(
            Authentication authentication,
            @RequestPart("profile") MultipartFile profilePayload,
            @RequestPart(value = "profilePhoto", required = false) MultipartFile profilePhoto,
            @RequestPart(value = "coverPhoto", required = false) MultipartFile coverPhoto,
            @RequestPart(value = "cvFile", required = false) MultipartFile cvFile
    ) {
        User currentUser = (User) authentication.getPrincipal();
        CandidateProfileRequest request = readProfilePayload(profilePayload);
        return ResponseEntity.ok(
                candidateProfileService.saveCurrentProfile(currentUser, request, profilePhoto, coverPhoto, cvFile)
        );
    }

    @PostMapping(path = "/autofill-cv", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<CandidateProfileAutofillResponse> autofillFromCv(
            Authentication authentication,
            @RequestPart("cvFile") MultipartFile cvFile
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(candidateProfileService.extractProfileFromCv(currentUser, cvFile));
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Map<String, String>> handleProfileRuntimeException(RuntimeException ex) {
        return ResponseEntity.badRequest().body(Map.of(
                "message",
                ex.getMessage() == null || ex.getMessage().isBlank()
                        ? "Enregistrement du profil candidat impossible."
                        : ex.getMessage()
        ));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleProfileException(Exception ex) {
        log.error("Erreur technique lors de l'enregistrement du profil candidat", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                "message",
                "Une erreur technique est survenue lors de l'enregistrement du profil candidat."
        ));
    }

    private CandidateProfileRequest readProfilePayload(MultipartFile profilePayload) {
        if (profilePayload == null || profilePayload.isEmpty()) {
            throw new RuntimeException("Les donnees du profil candidat sont manquantes.");
        }

        try {
            String json = new String(profilePayload.getBytes(), StandardCharsets.UTF_8)
                    .replace("\uFEFF", "")
                    .trim();
            return objectMapper.readValue(json, CandidateProfileRequest.class);
        } catch (JsonProcessingException ex) {
            log.warn("Payload JSON invalide pour le profil candidat: {}", ex.getOriginalMessage());
            throw new RuntimeException("Le format des donnees du profil candidat est invalide.");
        } catch (IOException ex) {
            throw new RuntimeException("Lecture des donnees du profil candidat impossible.");
        }
    }
}
