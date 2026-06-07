package com.recrutement.recrutement.entities;


import jakarta.persistence.*;
import lombok.*;

import java.util.Date;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CV {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Temporal(TemporalType.DATE)
    private Date dateImport;

    private String nomFichier;
    private String taille;
    private String urlFichier;
    private String cloudinaryPublicId;

    @ManyToOne
    @JoinColumn(name = "candidate_id")
    private Candidate candidate;
}
