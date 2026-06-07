package com.recrutement.recrutement.controller;

import com.recrutement.recrutement.dto.CompetenceRequest;
import com.recrutement.recrutement.dto.CompetenceResponse;
import com.recrutement.recrutement.dto.MessageResponse;
import com.recrutement.recrutement.service.CompetenceService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/competences")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AdminCompetenceController {
    private final CompetenceService competenceService;

    @GetMapping
    public ResponseEntity<List<CompetenceResponse>> getCompetences(
            @RequestParam(required = false) String query,
            @RequestParam(required = false) String type
    ) {
        return ResponseEntity.ok(competenceService.getCompetences(query, type));
    }

    @PostMapping
    public ResponseEntity<CompetenceResponse> createCompetence(@RequestBody CompetenceRequest request) {
        return ResponseEntity.ok(competenceService.createCompetence(request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<CompetenceResponse> updateCompetence(
            @PathVariable Long id,
            @RequestBody CompetenceRequest request
    ) {
        return ResponseEntity.ok(competenceService.updateCompetence(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<MessageResponse> deleteCompetence(@PathVariable Long id) {
        competenceService.deleteCompetence(id);
        return ResponseEntity.ok(new MessageResponse(true, "Competence supprimee avec succes."));
    }
}
