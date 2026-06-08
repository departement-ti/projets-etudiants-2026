package com.recrutement.recrutement.controller;

import com.recrutement.recrutement.dto.OffreResponse;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.service.OfferService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/offres")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class OfferController {
    private final OfferService offerService;

    @GetMapping
    public ResponseEntity<List<OffreResponse>> getAllOffers(Authentication authentication) {
        User currentUser = authentication != null && authentication.getPrincipal() instanceof User
                ? (User) authentication.getPrincipal()
                : null;
        return ResponseEntity.ok(offerService.getAllOffers(currentUser));
    }

    @GetMapping("/{id}")
    public ResponseEntity<OffreResponse> getOfferById(@PathVariable Long id, Authentication authentication) {
        User currentUser = authentication != null && authentication.getPrincipal() instanceof User
                ? (User) authentication.getPrincipal()
                : null;
        return ResponseEntity.ok(offerService.getOfferById(id, currentUser));
    }
}
