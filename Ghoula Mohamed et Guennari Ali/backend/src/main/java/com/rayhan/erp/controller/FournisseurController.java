package com.rayhan.erp.controller;

import com.rayhan.erp.model.Fournisseur;
import com.rayhan.erp.service.FournisseurService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/fournisseurs")
public class FournisseurController {

    @Autowired
    private FournisseurService fournisseurService;

    @GetMapping
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_ACHAT')")
    public List<Fournisseur> getAllFournisseurs() {
        return fournisseurService.getAllFournisseurs();
    }

    @GetMapping("/search")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_ACHAT')")
    public List<Fournisseur> searchFournisseurs(@RequestParam String q) {
        return fournisseurService.searchFournisseurs(q);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_ACHAT')")
    public ResponseEntity<Fournisseur> getFournisseurById(@PathVariable Long id) {
        Fournisseur fournisseur = fournisseurService.getFournisseurById(id);
        return fournisseur != null ? ResponseEntity.ok(fournisseur) : ResponseEntity.notFound().build();
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_ACHAT')")
    public Fournisseur createFournisseur(@Valid @RequestBody Fournisseur fournisseur) {
        return fournisseurService.createFournisseur(fournisseur);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_ACHAT')")
    public ResponseEntity<Void> deleteFournisseur(@PathVariable Long id) {
        boolean deleted = fournisseurService.deleteFournisseur(id);
        return deleted ? ResponseEntity.noContent().build() : ResponseEntity.notFound().build();
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_ACHAT')")
    public ResponseEntity<Fournisseur> updateFournisseur(@PathVariable Long id,
                                                          @Valid @RequestBody Fournisseur details) {
        Fournisseur updated = fournisseurService.updateFournisseur(id, details);
        return updated != null ? ResponseEntity.ok(updated) : ResponseEntity.notFound().build();
    }
}
