package com.rayhan.erp.controller;

import com.rayhan.erp.dto.request.StaffRequest;
import com.rayhan.erp.dto.response.MessageResponse;
import com.rayhan.erp.dto.response.UserResponse;
import com.rayhan.erp.service.UserService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    @PreAuthorize("hasRole('ROLE_PDG')")
    public ResponseEntity<List<UserResponse>> listStaff() {
        return ResponseEntity.ok(userService.getAllStaff());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ROLE_PDG')")
    public ResponseEntity<UserResponse> getById(@PathVariable Long id) {
        return ResponseEntity.ok(userService.getById(id));
    }

    @PostMapping
    @PreAuthorize("hasRole('ROLE_PDG')")
    public ResponseEntity<?> createStaff(@Valid @RequestBody StaffRequest request) {
        try {
            UserResponse created = userService.create(request);
            return ResponseEntity.ok(created);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ROLE_PDG')")
    public ResponseEntity<?> updateStaff(@PathVariable Long id,
                                          @Valid @RequestBody StaffRequest request) {
        try {
            UserResponse updated = userService.update(id, request);
            return ResponseEntity.ok(updated);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }

    @PutMapping("/{id}/password")
    @PreAuthorize("hasRole('ROLE_PDG')")
    public ResponseEntity<?> resetPassword(@PathVariable Long id,
                                            @RequestBody StaffRequest request) {
        if (request.getPassword() == null || request.getPassword().isBlank()) {
            return ResponseEntity.badRequest()
                .body(new MessageResponse("Le mot de passe ne peut pas être vide."));
        }
        try {
            userService.setPassword(id, request.getPassword());
            return ResponseEntity.ok(new MessageResponse("Mot de passe réinitialisé avec succès."));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ROLE_PDG')")
    public ResponseEntity<?> disableStaff(@PathVariable Long id) {
        try {
            userService.disable(id);
            return ResponseEntity.ok(new MessageResponse("Utilisateur désactivé."));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }

    @PutMapping("/{id}/enable")
    @PreAuthorize("hasRole('ROLE_PDG')")
    public ResponseEntity<?> enableStaff(@PathVariable Long id) {
        try {
            userService.enable(id);
            return ResponseEntity.ok(new MessageResponse("Utilisateur activé."));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }
}
