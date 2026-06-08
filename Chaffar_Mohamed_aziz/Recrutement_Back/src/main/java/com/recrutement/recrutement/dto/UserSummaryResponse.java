package com.recrutement.recrutement.dto;

import com.recrutement.recrutement.entities.Role;

public class UserSummaryResponse {
    private Long id;
    private String nom;
    private String email;
    private Role role;
    private Boolean statutCompte;
    private String approvalStatus;

    public UserSummaryResponse() {
    }

    public UserSummaryResponse(Long id, String nom, String email, Role role) {
        this.id = id;
        this.nom = nom;
        this.email = email;
        this.role = role;
    }

    public UserSummaryResponse(Long id, String nom, String email, Role role, Boolean statutCompte, String approvalStatus) {
        this.id = id;
        this.nom = nom;
        this.email = email;
        this.role = role;
        this.statutCompte = statutCompte;
        this.approvalStatus = approvalStatus;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public Role getRole() {
        return role;
    }

    public void setRole(Role role) {
        this.role = role;
    }

    public Boolean getStatutCompte() {
        return statutCompte;
    }

    public void setStatutCompte(Boolean statutCompte) {
        this.statutCompte = statutCompte;
    }

    public String getApprovalStatus() {
        return approvalStatus;
    }

    public void setApprovalStatus(String approvalStatus) {
        this.approvalStatus = approvalStatus;
    }
}
