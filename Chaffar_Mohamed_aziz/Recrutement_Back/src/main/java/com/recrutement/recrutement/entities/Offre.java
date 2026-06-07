package com.recrutement.recrutement.entities;


import jakarta.persistence.*;
import lombok.*;

import java.util.Date;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Offre {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(columnDefinition = "TEXT")
    private String titre;

    @Temporal(TemporalType.DATE)
    private Date date;

    @Temporal(TemporalType.DATE)
    private Date dateExpiration;

    @Column(columnDefinition = "TEXT")
    private String categorie;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(columnDefinition = "TEXT")
    private String localisation;
    private double salaire;
    @Column(length = 32)
    private String devise;
    private Integer nombrePostes;

    @Column(columnDefinition = "TEXT")
    private String experienceRequise;

    @Column(columnDefinition = "TEXT")
    private String typeContrat;

    @Column(length = 64)
    private String statut;

    @Column(columnDefinition = "TEXT")
    private String competencesJson;

    @ManyToOne
    @JoinColumn(name = "recruiter_id")
    private Recruiter recruiter;
}
