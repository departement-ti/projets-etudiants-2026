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
@Table(name = "sales_orders")
@Getter
@Setter
@NoArgsConstructor
public class SalesOrder {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false, length = 30)
    private String reference; // ex: CC-2024-001

    @ManyToOne(optional = false)
    @JoinColumn(name = "client_id")
    private Client client;

    @Column(nullable = false)
    private LocalDate dateCommande = LocalDate.now();

    private LocalDate dateLivraisonSouhaitee;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 25)
    private StatutCommande statut = StatutCommande.EN_ATTENTE;

    @Column(precision = 15, scale = 3)
    private BigDecimal totalHT = BigDecimal.ZERO;

    @Column(precision = 15, scale = 3)
    private BigDecimal totalTVA = BigDecimal.ZERO;

    @Column(precision = 15, scale = 3)
    private BigDecimal totalTTC = BigDecimal.ZERO;

    @Column(length = 500)
    private String notes;

    @OneToMany(mappedBy = "salesOrder", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<SalesOrderLine> lignes = new ArrayList<>();

    @ManyToOne
    @JoinColumn(name = "created_by")
    private User creePar;

    public enum StatutCommande {
        EN_ATTENTE, CONFIRMEE, EN_PREPARATION, PARTIELLEMENT_LIVREE, COMPLETEMENT_LIVREE, ANNULEE
    }
}
