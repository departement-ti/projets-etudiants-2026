package com.recrutement.recrutement.entities;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.PrimaryKeyJoinColumn;
import jakarta.persistence.Table;
import java.time.LocalDate;

@Entity
@Table(name = "candidates")
@PrimaryKeyJoinColumn(name = "user_id")
public class Candidate extends User {

    private String profession;
    private LocalDate dateNaissance;
    private String numTelephone;
    private String posteRecherche;
    private String localisation;
    private String adresse;
    private String genre;
    @Column(columnDefinition = "TEXT")
    private String description;
    private int experience;
    private String photoProfilNom;
    private String photoProfilUrl;
    private String photoProfilPublicId;
    private String photoCouvertureNom;
    private String photoCouvertureUrl;
    private String photoCouverturePublicId;
    private String facebookUrl;
    private String instagramUrl;
    private String linkedinUrl;
    private String githubUrl;
    @Column(columnDefinition = "TEXT")
    private String experiencesJson;
    @Column(columnDefinition = "TEXT")
    private String educationJson;
    @Column(columnDefinition = "TEXT")
    private String skillsJson;

    public Candidate() {
        super();
    }

    public Candidate(String numTelephone, String posteRecherche, String localisation, int experience) {
        super();
        this.numTelephone = numTelephone;
        this.posteRecherche = posteRecherche;
        this.localisation = localisation;
        this.experience = experience;
    }

    // Getters and Setters
    public String getNumTelephone() {
        return numTelephone;
    }

    public void setNumTelephone(String numTelephone) {
        this.numTelephone = numTelephone;
    }

    public String getPosteRecherche() {
        return posteRecherche;
    }

    public void setPosteRecherche(String posteRecherche) {
        this.posteRecherche = posteRecherche;
    }

    public String getLocalisation() {
        return localisation;
    }

    public void setLocalisation(String localisation) {
        this.localisation = localisation;
    }

    public int getExperience() {
        return experience;
    }

    public void setExperience(int experience) {
        this.experience = experience;
    }

    public String getProfession() {
        return profession;
    }

    public void setProfession(String profession) {
        this.profession = profession;
    }

    public LocalDate getDateNaissance() {
        return dateNaissance;
    }

    public void setDateNaissance(LocalDate dateNaissance) {
        this.dateNaissance = dateNaissance;
    }

    public String getAdresse() {
        return adresse;
    }

    public void setAdresse(String adresse) {
        this.adresse = adresse;
    }

    public String getGenre() {
        return genre;
    }

    public void setGenre(String genre) {
        this.genre = genre;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getPhotoProfilNom() {
        return photoProfilNom;
    }

    public void setPhotoProfilNom(String photoProfilNom) {
        this.photoProfilNom = photoProfilNom;
    }

    public String getPhotoProfilUrl() {
        return photoProfilUrl;
    }

    public void setPhotoProfilUrl(String photoProfilUrl) {
        this.photoProfilUrl = photoProfilUrl;
    }

    public String getPhotoProfilPublicId() {
        return photoProfilPublicId;
    }

    public void setPhotoProfilPublicId(String photoProfilPublicId) {
        this.photoProfilPublicId = photoProfilPublicId;
    }

    public String getPhotoCouvertureNom() {
        return photoCouvertureNom;
    }

    public void setPhotoCouvertureNom(String photoCouvertureNom) {
        this.photoCouvertureNom = photoCouvertureNom;
    }

    public String getPhotoCouvertureUrl() {
        return photoCouvertureUrl;
    }

    public void setPhotoCouvertureUrl(String photoCouvertureUrl) {
        this.photoCouvertureUrl = photoCouvertureUrl;
    }

    public String getPhotoCouverturePublicId() {
        return photoCouverturePublicId;
    }

    public void setPhotoCouverturePublicId(String photoCouverturePublicId) {
        this.photoCouverturePublicId = photoCouverturePublicId;
    }

    public String getFacebookUrl() {
        return facebookUrl;
    }

    public void setFacebookUrl(String facebookUrl) {
        this.facebookUrl = facebookUrl;
    }

    public String getInstagramUrl() {
        return instagramUrl;
    }

    public void setInstagramUrl(String instagramUrl) {
        this.instagramUrl = instagramUrl;
    }

    public String getLinkedinUrl() {
        return linkedinUrl;
    }

    public void setLinkedinUrl(String linkedinUrl) {
        this.linkedinUrl = linkedinUrl;
    }

    public String getGithubUrl() {
        return githubUrl;
    }

    public void setGithubUrl(String githubUrl) {
        this.githubUrl = githubUrl;
    }

    public String getExperiencesJson() {
        return experiencesJson;
    }

    public void setExperiencesJson(String experiencesJson) {
        this.experiencesJson = experiencesJson;
    }

    public String getEducationJson() {
        return educationJson;
    }

    public void setEducationJson(String educationJson) {
        this.educationJson = educationJson;
    }

    public String getSkillsJson() {
        return skillsJson;
    }

    public void setSkillsJson(String skillsJson) {
        this.skillsJson = skillsJson;
    }
}
