package com.recrutement.recrutement.controller;

import com.recrutement.recrutement.dto.OffreRequest;
import com.recrutement.recrutement.dto.OffreResponse;
import com.recrutement.recrutement.dto.MatchingCandidateResponse;
import com.recrutement.recrutement.dto.MessageResponse;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.service.OfferService;
import java.util.Map;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping({"/api/recruiter/offres", "/api/recruiter/offers"})
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class RecruiterOfferController {
    private final OfferService offerService;

    @GetMapping
    public ResponseEntity<List<OffreResponse>> getMyOffers(Authentication authentication) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(offerService.getRecruiterOffers(currentUser));
    }

    @GetMapping("/{id}/matching-candidates")
    public ResponseEntity<List<MatchingCandidateResponse>> getMatchingCandidates(
            Authentication authentication,
            @PathVariable Long id,
            @RequestParam(name = "minScore", required = false) Double minScore
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(offerService.getMatchingCandidates(currentUser, id, minScore));
    }

    @PostMapping("/{offerId}/invite-candidate/{candidateId}")
    public ResponseEntity<MessageResponse> inviteCandidate(
            Authentication authentication,
            @PathVariable Long offerId,
            @PathVariable Long candidateId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(offerService.inviteCandidateToOffer(currentUser, offerId, candidateId));
    }

    @PostMapping
    public ResponseEntity<OffreResponse> createOffer(
            Authentication authentication,
            @RequestBody OffreRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(offerService.createOffer(currentUser, request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<OffreResponse> updateOffer(
            Authentication authentication,
            @PathVariable Long id,
            @RequestBody OffreRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(offerService.updateOffer(currentUser, id, request));
    }

    @PatchMapping("/{id}/archive")
    public ResponseEntity<OffreResponse> archiveOffer(
            Authentication authentication,
            @PathVariable Long id
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(offerService.archiveOffer(currentUser, id));
    }

    @PatchMapping("/{id}/unarchive")
    public ResponseEntity<OffreResponse> unarchiveOffer(
            Authentication authentication,
            @PathVariable Long id
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(offerService.unarchiveOffer(currentUser, id));
    }

    @PatchMapping("/{id}/publish")
    public ResponseEntity<OffreResponse> publishOffer(
            Authentication authentication,
            @PathVariable Long id
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(offerService.publishOffer(currentUser, id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<MessageResponse> deleteOffer(
            Authentication authentication,
            @PathVariable Long id
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(new MessageResponse(true, offerService.deleteOffer(currentUser, id)));
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Map<String, String>> handleRecruiterOfferRuntimeException(RuntimeException ex) {
        return ResponseEntity.badRequest().body(Map.of(
                "message",
                ex.getMessage() == null || ex.getMessage().isBlank()
                        ? "Gestion de l'offre impossible."
                        : ex.getMessage()
        ));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleRecruiterOfferException(Exception ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                "message",
                "Une erreur technique est survenue lors de la gestion de l'offre."
        ));
    }
}
