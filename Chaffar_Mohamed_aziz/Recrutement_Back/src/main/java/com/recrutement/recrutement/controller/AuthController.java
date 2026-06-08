package com.recrutement.recrutement.controller;
import com.recrutement.recrutement.dto.*;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@CrossOrigin(origins ="*")
public class AuthController {
    private final AuthService authService;

    @PostMapping("/register/candidate")
    public ResponseEntity<RegisterResponse> registerCandidate(@RequestBody CandidateRegisterRequest request) {
        RegisterResponse response = authService.registerCandidate(request);
        if (response.isSuccess()) {
            return ResponseEntity.ok(response);
        }
        return ResponseEntity.badRequest().body(response);
    }

    @PostMapping("/register/recruiter")
    public ResponseEntity<RegisterResponse> registerRecruiter(
            @RequestBody RecruiterRegisterRequest request) {

        RegisterResponse response = authService.registerRecruiter(request);
        if (response.isSuccess()) {
            return ResponseEntity.ok(response);
        }
        return ResponseEntity.badRequest().body(response);
    }

    @PostMapping("/register/admin")
    public ResponseEntity<RegisterResponse> registerAdmin(
            @RequestBody AdminRegisterRequest request) {

        RegisterResponse response = authService.registerAdmin(request);
        if (response.isSuccess()) {
            return ResponseEntity.ok(response);
        }
        return ResponseEntity.badRequest().body(response);
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<MessageResponse> forgotPassword(@RequestBody ForgotPasswordRequest request) {
        return ResponseEntity.ok(authService.forgotPassword(request));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<MessageResponse> resetPassword(@RequestBody ResetPasswordRequest request) {
        MessageResponse response = authService.resetPassword(request);
        if (response.isSuccess()) {
            return ResponseEntity.ok(response);
        }
        return ResponseEntity.badRequest().body(response);
    }

    @PostMapping("/change-password")
    public ResponseEntity<MessageResponse> changePassword(Authentication authentication, @RequestBody ChangePasswordRequest request) {
        User currentUser = (User) authentication.getPrincipal();
        MessageResponse response = authService.changePassword(currentUser, request);
        if (response.isSuccess()) {
            return ResponseEntity.ok(response);
        }
        return ResponseEntity.badRequest().body(response);
    }

    @GetMapping("/verified-email")
    public ResponseEntity<String> activateAccount(@RequestParam String token) {
        try {
            String result = authService.activateAccount(token);
            return ResponseEntity.ok(result);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    @PostMapping("/admin/approve-recruiter/{id}")
    public ResponseEntity<RegisterResponse> approveRecruiter(@PathVariable Long id) {
        RegisterResponse response = authService.approveRecruiter(id);
        if (response.isSuccess()) {
            return ResponseEntity.ok(response);
        }
        return ResponseEntity.badRequest().body(response);
    }

}
