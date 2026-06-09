package com.tmazzacademy.tmazzacademy.model;

import jakarta.persistence.*;

@Entity
public class Cours {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String titre;

    @Column(length = 2000)
    private String description;

    private String videoPath;

    private String pdfPath;

    private boolean active = true;

    @ManyToOne
    @JoinColumn(name = "instructor_id")
    private Instructor instructor;

    private double rating = 0;

    private int ratingCount = 0;

    public Cours() {}

    public Cours(
            String titre,
            String description,
            String videoPath,
            String pdfPath,
            Instructor instructor
    ) {
        this.titre = titre;
        this.description = description;
        this.videoPath = videoPath;
        this.pdfPath = pdfPath;
        this.instructor = instructor;
        this.active = true;
    }

    public Long getId() {
        return id;
    }

    public String getTitre() {
        return titre;
    }

    public void setTitre(String titre) {
        this.titre = titre;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getVideoPath() {
        return videoPath;
    }

    public void setVideoPath(String videoPath) {
        this.videoPath = videoPath;
    }

    public String getPdfPath() {
        return pdfPath;
    }

    public void setPdfPath(String pdfPath) {
        this.pdfPath = pdfPath;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public Instructor getInstructor() {
        return instructor;
    }

    public void setInstructor(Instructor instructor) {
        this.instructor = instructor;
    }

    public double getRating() {
        return rating;
    }

    public void setRating(double rating) {
        this.rating = rating;
    }

    public int getRatingCount() {
        return ratingCount;
    }

    public void setRatingCount(int ratingCount) {
        this.ratingCount = ratingCount;
    }
}