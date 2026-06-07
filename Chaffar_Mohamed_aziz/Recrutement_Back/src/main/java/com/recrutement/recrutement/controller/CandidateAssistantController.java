package com.recrutement.recrutement.controller;

import com.recrutement.recrutement.dto.CandidateTopMatchingOfferResponse;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.service.OfferService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/candidate/assistant")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class CandidateAssistantController {
    private final OfferService offerService;

    @GetMapping("/top-matching-offers")
    public ResponseEntity<List<CandidateTopMatchingOfferResponse>> getTopMatchingOffers(
            Authentication authentication,
            @RequestParam(required = false) Double minScore
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(offerService.getTopMatchingOffersForCandidate(currentUser, minScore));
    }
}
