package com.recrutement.recrutement.dto;

import com.recrutement.recrutement.entities.Role;
import lombok.Data;

@Data
public class CandidateRegisterRequest {
    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public Role getRole() {
        return role;
    }

    public void setRole(Role role) {
        this.role = role;
    }

    private String email;
    private String password;
    private String username;
    private String phoneNumber;
    private Role role;
    public CandidateRegisterRequest() {

    }
    public CandidateRegisterRequest(String email, String password, String username, String phoneNumber, Role role) {
        this.email = email;
        this.password = password;
        this.username = username;
        this.phoneNumber = phoneNumber;
        this.role = role;
    }
}
