package com.recrutement.recrutement.entities;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "entreprises")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Entreprise {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long idEntreprise ;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String nomEntreprise;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String secteur;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String adresse;

    @Column(nullable = false, unique = true, columnDefinition = "TEXT")
    private String email;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String abonnementActif;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    @Column(columnDefinition = "TEXT")
    private String siteWeb;
}
