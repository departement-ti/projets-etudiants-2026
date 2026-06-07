package com.recrutement.recrutement.dto;

import com.recrutement.recrutement.entities.Role;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoginResponse {
    private Long id;
    private String email;
    private String username;
    private Role role;
    private String message;
    private String token;
}
