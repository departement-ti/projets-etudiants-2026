package com.recrutement.recrutement.dto;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RecruiterRegisterRequest {
    private String email;
    private String username;
    private String password;
    private String fonction;
    private String poste;
    private String departement;
    private Long identreprise;
}
