package com.recrutement.recrutement.dto;

public class SkillMatchResponse {
    private String nom;
    private boolean matched;
    private String type;
    private Integer ponderation;

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    public boolean isMatched() {
        return matched;
    }

    public void setMatched(boolean matched) {
        this.matched = matched;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public Integer getPonderation() {
        return ponderation;
    }

    public void setPonderation(Integer ponderation) {
        this.ponderation = ponderation;
    }
}
