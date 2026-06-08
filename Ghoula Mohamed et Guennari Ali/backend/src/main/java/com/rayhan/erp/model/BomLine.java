package com.rayhan.erp.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

/**
 * Ligne de nomenclature (BOM — Bill of Materials).
 * Définit quelle matière première (ou PSF) est nécessaire pour fabriquer un produit fini.
 * Ex : Pour 1000 Sacs Bertel (PF), il faut 15 kg de HDPE (MP) + 0.5 kg de colorant.
 */
@Entity
@Table(name = "bom_lines", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"produit_fini_id", "composant_id"})
})
@Getter
@Setter
@NoArgsConstructor
public class BomLine {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "produit_fini_id")
    private Article produitFini; // doit être de type PF ou PSF

    @ManyToOne(optional = false)
    @JoinColumn(name = "composant_id")
    private Article composant; // doit être de type MP ou PSF

    @Column(nullable = false, precision = 15, scale = 6)
    private BigDecimal quantiteParUnite; // quantité de composant par unité de produit fini

    @Column(length = 20)
    private String uniteMesure; // kg, g, L, unité
}
