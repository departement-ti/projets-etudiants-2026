package com.rayhan.erp.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Entity
@Table(name = "articles")
@Getter
@Setter
@NoArgsConstructor
public class Article {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false, length = 30)
    private String reference;

    @Column(nullable = false, length = 150)
    private String designation;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private TypeArticle type; // MP, PF, PSF

    @Column(length = 20)
    private String uniteMesure; // kg, unité, rouleau, m

    @Column(precision = 15, scale = 3)
    private BigDecimal prixUnitaire = BigDecimal.ZERO;

    @Column(precision = 15, scale = 3)
    private BigDecimal stockActuel = BigDecimal.ZERO;

    @Column(precision = 15, scale = 3)
    private BigDecimal stockMinimum = BigDecimal.ZERO;

    private boolean actif = true;

    @Column(length = 100)
    private String assetImage;

    public enum TypeArticle {
        MP,   // Matière Première (HDPE, LDPE, colorants)
        PSF,  // Produit Semi-Fini (film tubulaire)
        PF    // Produit Fini (sacs, film rétractable)
    }
}
