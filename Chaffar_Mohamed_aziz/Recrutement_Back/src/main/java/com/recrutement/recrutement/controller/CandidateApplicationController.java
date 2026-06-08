package com.recrutement.recrutement.controller;

import com.recrutement.recrutement.dto.ApplicationResponse;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.service.ApplicationService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/candidate")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class CandidateApplicationController {
    private final ApplicationService applicationService;

    @GetMapping("/candidatures")
    public ResponseEntity<List<ApplicationResponse>> getMyApplications(Authentication authentication) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(applicationService.getCandidateApplications(currentUser));
    }

    @PostMapping("/offres/{offerId}/apply")
    public ResponseEntity<ApplicationResponse> applyToOffer(
            Authentication authentication,
            @PathVariable Long offerId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(applicationService.applyToOffer(currentUser, offerId));
    }
}
