package com.tmazzacademy.tmazzacademy.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import com.tmazzacademy.tmazzacademy.dto.LoginRequest;
import com.tmazzacademy.tmazzacademy.dto.RegisterRequestDTO;
import com.tmazzacademy.tmazzacademy.model.Admin;
import com.tmazzacademy.tmazzacademy.model.Instructor;
import com.tmazzacademy.tmazzacademy.model.Role;
import com.tmazzacademy.tmazzacademy.model.Student;
import com.tmazzacademy.tmazzacademy.model.User;
import com.tmazzacademy.tmazzacademy.repository.RoleRepository;
import com.tmazzacademy.tmazzacademy.repository.UserRepository;
import com.tmazzacademy.tmazzacademy.security.JwtUtil;

@RestController
@RequestMapping("/auth")
@CrossOrigin(origins = "http://localhost:4200")
public class AuthController {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public AuthController(
            UserRepository userRepository,
            RoleRepository roleRepository,
            PasswordEncoder passwordEncoder,
            JwtUtil jwtUtil
    ) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
    }

    @PostMapping("/register")
    public String register(@RequestBody RegisterRequestDTO dto) {

        Role role = roleRepository.findByName(dto.getRole())
                .orElseThrow(() ->
                        new RuntimeException("Role not found: " + dto.getRole()));

        User user;

        if (dto.getRole().equals("ADMIN")) {

            user = new Admin();

        } else if (dto.getRole().equals("INSTRUCTOR")) {

            Instructor instructor = new Instructor();
            instructor.setSpeciality(dto.getSpeciality());

            user = instructor;

        } else {

            user = new Student();
        }

        user.setName(dto.getName());
        user.setLastname(dto.getLastname());
        user.setEmail(dto.getEmail());
        user.setTel(dto.getTel());

        user.setPassword(
                passwordEncoder.encode(dto.getPassword())
        );

        user.setRole(role);

        userRepository.save(user);

        return "User registered successfully";
    }

    @PostMapping("/login")
    public Map<String, String> login(
            @RequestBody LoginRequest request
    ) throws Exception {

        User user = userRepository.findByEmail(
                request.getEmail()
        );

        if (
                user == null ||
                !passwordEncoder.matches(
                        request.getPassword(),
                        user.getPassword()
                )
        ) {
            throw new Exception("Invalid credentials");
        }

        // CHECK ACTIVE
        if (!user.isActive()) {
            throw new Exception("Account is disabled");
        }

        String token = jwtUtil.generateToken(
                user.getEmail()
        );

        Map<String, String> response = new HashMap<>();

        response.put("token", token);

        response.put(
                "role",
                user.getRole().getName()
        );

        response.put(
                "userId",
                user.getId().toString()
        );

        return response;
    }
}