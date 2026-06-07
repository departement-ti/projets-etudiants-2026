package com.recrutement.recrutement.entities;
import jakarta.persistence.Entity;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrimaryKeyJoinColumn;
import jakarta.persistence.Table;

@Entity
@Table(name="recruiters")
@PrimaryKeyJoinColumn(name="user_id")
public class Recruiter extends User {
    private String fonction;
    private String poste;
    private String departement;

    @ManyToOne
    @JoinColumn(name = "entreprise_id")
    private Entreprise entreprise;

    public Recruiter() {
        super();
    }

    public Recruiter(String email, String nom, String password, Role role, Boolean statutCompte,
                     String fonction, String poste, String departement) {
        super();
        setEmail(email);
        setPassword(password);
        setNom(nom);
        setRole(role);
        setStatutCompte(statutCompte);
        this.fonction = fonction;
        this.poste = poste;
        this.departement = departement;
    }

    // Getters and Setters
    public String getFonction() {
        return fonction;
    }

    public void setFonction(String fonction) {
        this.fonction = fonction;
    }

    public String getPoste() {
        return poste;
    }

    public void setPoste(String poste) {
        this.poste = poste;
    }

    public String getDepartement() {
        return departement;
    }

    public void setDepartement(String departement) {
        this.departement = departement;
    }

    public Entreprise getEntreprise() {
        return entreprise;
    }

    public void setEntreprise(Entreprise entreprise) {
        this.entreprise = entreprise;
    }
}