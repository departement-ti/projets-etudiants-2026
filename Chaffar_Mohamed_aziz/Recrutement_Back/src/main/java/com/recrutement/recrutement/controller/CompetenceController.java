package com.recrutement.recrutement.controller;

import com.recrutement.recrutement.dto.CompetenceResponse;
import com.recrutement.recrutement.service.CompetenceService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/competences")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class CompetenceController {
    private final CompetenceService competenceService;

    @GetMapping
    public ResponseEntity<List<CompetenceResponse>> getCompetences(
            @RequestParam(required = false) String query,
            @RequestParam(required = false) String type
    ) {
        return ResponseEntity.ok(competenceService.getCompetences(query, type));
    }
}
