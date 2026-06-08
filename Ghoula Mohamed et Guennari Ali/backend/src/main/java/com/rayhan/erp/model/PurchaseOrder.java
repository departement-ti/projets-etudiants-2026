package com.rayhan.erp.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "purchase_orders")
@Getter
@Setter
@NoArgsConstructor
public class PurchaseOrder {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false, length = 30)
    private String reference; // ex: BC-2024-001

    @ManyToOne(optional = false)
    @JoinColumn(name = "fournisseur_id")
    private Fournisseur fournisseur;

    @Column(nullable = false)
    private LocalDate dateCommande = LocalDate.now();

    private LocalDate dateLivraisonPrevue;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private StatutCommande statut = StatutCommande.BROUILLON;

    @Column(precision = 15, scale = 3)
    private BigDecimal totalHT = BigDecimal.ZERO;

    @Column(precision = 15, scale = 3)
    private BigDecimal totalTVA = BigDecimal.ZERO;

    @Column(precision = 15, scale = 3)
    private BigDecimal totalTTC = BigDecimal.ZERO;

    @Column(length = 500)
    private String notes;

    @OneToMany(mappedBy = "purchaseOrder", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<PurchaseOrderLine> lignes = new ArrayList<>();

    @ManyToOne
    @JoinColumn(name = "created_by")
    private User creePar;

    public enum StatutCommande {
        BROUILLON, CONFIRMEE, PARTIELLEMENT_RECUE, COMPLETEMENT_RECUE, ANNULEE
    }
}
