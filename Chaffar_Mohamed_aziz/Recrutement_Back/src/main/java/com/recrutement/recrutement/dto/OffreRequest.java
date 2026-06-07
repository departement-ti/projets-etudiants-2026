package com.recrutement.recrutement.dto;

import java.util.List;

public class OffreRequest {
    private String titre;
    private String categorie;
    private String description;
    private String localisation;
    private Double salaire;
    private String devise;
    private Integer nombrePostes;
    private String experienceRequise;
    private String typeContrat;
    private String statut;
    private String dateExpiration;
    private List<OffreCompetenceRequest> competences;

    public String getTitre() {
        return titre;
    }

    public void setTitre(String titre) {
        this.titre = titre;
    }

    public String getCategorie() {
        return categorie;
    }

    public void setCategorie(String categorie) {
        this.categorie = categorie;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getLocalisation() {
        return localisation;
    }

    public void setLocalisation(String localisation) {
        this.localisation = localisation;
    }

    public Double getSalaire() {
        return salaire;
    }

    public void setSalaire(Double salaire) {
        this.salaire = salaire;
    }

    public String getDevise() {
        return devise;
    }

    public void setDevise(String devise) {
        this.devise = devise;
    }

    public Integer getNombrePostes() {
        return nombrePostes;
    }

    public void setNombrePostes(Integer nombrePostes) {
        this.nombrePostes = nombrePostes;
    }

    public String getExperienceRequise() {
        return experienceRequise;
    }

    public void setExperienceRequise(String experienceRequise) {
        this.experienceRequise = experienceRequise;
    }

    public String getTypeContrat() {
        return typeContrat;
    }

    public void setTypeContrat(String typeContrat) {
        this.typeContrat = typeContrat;
    }

    public String getStatut() {
        return statut;
    }

    public void setStatut(String statut) {
        this.statut = statut;
    }

    public String getDateExpiration() {
        return dateExpiration;
    }

    public void setDateExpiration(String dateExpiration) {
        this.dateExpiration = dateExpiration;
    }

    public List<OffreCompetenceRequest> getCompetences() {
        return competences;
    }

    public void setCompetences(List<OffreCompetenceRequest> competences) {
        this.competences = competences;
    }
}
