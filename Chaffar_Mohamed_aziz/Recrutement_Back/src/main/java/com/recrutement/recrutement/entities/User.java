package com.recrutement.recrutement.entities;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

@Entity
@Table(name = "users")
@Inheritance(strategy = InheritanceType.JOINED)
public class User implements UserDetails {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;
    @Column(nullable = false)
    private String nom;
    @Column(nullable = false)
    private String password;

    @Enumerated(EnumType.STRING)
    private Role role;

    private Boolean statutCompte;

    @Enumerated(EnumType.STRING)
    private AccountApprovalStatus approvalStatus;

    private Boolean emailVerified= false;
    @Column(unique = true)
    private String activationToken;
    @Column(unique = true)
    private String resetPasswordToken;
    private LocalDateTime resetPasswordTokenExpiresAt;
    private LocalDateTime createdAt;

    public User() {
    }

    public User(Long id, String email, String nom, String password, Role role, Boolean statutCompte) {
        this.id = id;
        this.email = email;
        this.nom = nom;
        this.password = password;
        this.role = role;
        this.statutCompte = statutCompte;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    @Override
    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
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

    public AccountApprovalStatus getApprovalStatus() {
        return approvalStatus;
    }

    public void setApprovalStatus(AccountApprovalStatus approvalStatus) {
        this.approvalStatus = approvalStatus;
    }

    public Boolean getEmailverified() {
        return emailVerified;
    }

    public void setEmailVerified(Boolean emailVerified) {
        this.emailVerified = emailVerified;
    }

    public String getActivationToken() {
        return activationToken;
    }

    public void setActivationToken(String activationToken) {
        this.activationToken = activationToken;
    }

    public String getResetPasswordToken() {
        return resetPasswordToken;
    }

    public void setResetPasswordToken(String resetPasswordToken) {
        this.resetPasswordToken = resetPasswordToken;
    }

    public LocalDateTime getResetPasswordTokenExpiresAt() {
        return resetPasswordTokenExpiresAt;
    }

    public void setResetPasswordTokenExpiresAt(LocalDateTime resetPasswordTokenExpiresAt) {
        this.resetPasswordTokenExpiresAt = resetPasswordTokenExpiresAt;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }


    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + role.name()));
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return statutCompte != null && statutCompte;
    }

    @Override
    public String getUsername() {
        return email;
    }
}
