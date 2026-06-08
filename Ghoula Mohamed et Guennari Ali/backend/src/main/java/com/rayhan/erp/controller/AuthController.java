package com.rayhan.erp.controller;

import com.rayhan.erp.dto.request.LoginRequest;
import com.rayhan.erp.dto.request.SignupRequest;
import com.rayhan.erp.dto.response.JwtResponse;
import com.rayhan.erp.dto.response.MessageResponse;
import com.rayhan.erp.model.Client;
import com.rayhan.erp.model.ERole;
import com.rayhan.erp.model.Role;
import com.rayhan.erp.model.User;
import com.rayhan.erp.repository.ClientRepository;
import com.rayhan.erp.repository.RoleRepository;
import com.rayhan.erp.repository.UserRepository;
import com.rayhan.erp.security.jwt.JwtUtils;
import com.rayhan.erp.security.services.UserDetailsImpl;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired AuthenticationManager authenticationManager;
    @Autowired UserRepository userRepository;
    @Autowired RoleRepository roleRepository;
    @Autowired PasswordEncoder encoder;
    @Autowired JwtUtils jwtUtils;
    @Autowired ClientRepository clientRepository;

    /**
     * POST /api/auth/signin
     * Connexion d'un utilisateur — retourne un token JWT
     */
    @PostMapping("/signin")
    public ResponseEntity<?> authenticateUser(@Valid @RequestBody LoginRequest loginRequest) {
        Authentication authentication = authenticationManager.authenticate(
            new UsernamePasswordAuthenticationToken(loginRequest.getUsername(), loginRequest.getPassword()));

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String jwt = jwtUtils.generateJwtToken(authentication);

        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
        List<String> roles = userDetails.getAuthorities().stream()
            .map(item -> item.getAuthority())
            .collect(Collectors.toList());

        return ResponseEntity.ok(new JwtResponse(jwt,
            userDetails.getId(),
            userDetails.getUsername(),
            userDetails.getEmail(),
            userDetails.getFirstName(),
            userDetails.getLastName(),
            roles));
    }

    /**
     * POST /api/auth/signup
     * Inscription publique — crée un compte client avec le rôle ROLE_CLIENT
     */
    @PostMapping("/signup")
    public ResponseEntity<?> registerUser(@Valid @RequestBody SignupRequest signUpRequest) {
        if (userRepository.existsByUsername(signUpRequest.getUsername())) {
            return ResponseEntity.badRequest()
                .body(new MessageResponse("Erreur : Ce nom d'utilisateur est déjà pris."));
        }
        if (userRepository.existsByEmail(signUpRequest.getEmail())) {
            return ResponseEntity.badRequest()
                .body(new MessageResponse("Erreur : Cet email est déjà utilisé."));
        }

        Client client = new Client(
            signUpRequest.getFirstName() + " " + signUpRequest.getLastName(),
            null,
            null
        );
        client.setEmail(signUpRequest.getEmail());
        client = clientRepository.save(client);

        User user = new User(
            signUpRequest.getUsername(),
            signUpRequest.getEmail(),
            encoder.encode(signUpRequest.getPassword()),
            signUpRequest.getFirstName(),
            signUpRequest.getLastName());

        Role clientRole = roleRepository.findByName(ERole.ROLE_CLIENT)
            .orElseThrow(() -> new RuntimeException("Rôle ROLE_CLIENT introuvable en base."));
        user.setRoles(Set.of(clientRole));
        user.setClient(client);
        userRepository.save(user);

        Authentication authentication = authenticationManager.authenticate(
            new UsernamePasswordAuthenticationToken(
                signUpRequest.getUsername(), signUpRequest.getPassword()));

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String jwt = jwtUtils.generateJwtToken(authentication);

        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
        List<String> roles = userDetails.getAuthorities().stream()
            .map(item -> item.getAuthority())
            .collect(Collectors.toList());

        return ResponseEntity.ok(new JwtResponse(jwt,
            userDetails.getId(),
            userDetails.getUsername(),
            userDetails.getEmail(),
            userDetails.getFirstName(),
            userDetails.getLastName(),
            roles));
    }
}
