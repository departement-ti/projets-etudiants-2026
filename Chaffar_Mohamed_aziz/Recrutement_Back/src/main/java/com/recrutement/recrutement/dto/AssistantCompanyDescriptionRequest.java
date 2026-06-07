package com.recrutement.recrutement.dto;

public class AssistantCompanyDescriptionRequest {
    private String nomEntreprise;
    private String secteur;
    private String adresse;
    private String email;
    private String abonnementActif;
    private String siteWeb;
    private String currentDescription;

    public String getNomEntreprise() {
        return nomEntreprise;
    }

    public void setNomEntreprise(String nomEntreprise) {
        this.nomEntreprise = nomEntreprise;
    }

    public String getSecteur() {
        return secteur;
    }

    public void setSecteur(String secteur) {
        this.secteur = secteur;
    }

    public String getAdresse() {
        return adresse;
    }

    public void setAdresse(String adresse) {
        this.adresse = adresse;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getAbonnementActif() {
        return abonnementActif;
    }

    public void setAbonnementActif(String abonnementActif) {
        this.abonnementActif = abonnementActif;
    }

    public String getSiteWeb() {
        return siteWeb;
    }

    public void setSiteWeb(String siteWeb) {
        this.siteWeb = siteWeb;
    }

    public String getCurrentDescription() {
        return currentDescription;
    }

    public void setCurrentDescription(String currentDescription) {
        this.currentDescription = currentDescription;
    }
}
