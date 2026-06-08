package com.rayhan.erp.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "production_orders")
@Getter
@Setter
@NoArgsConstructor
public class ProductionOrder {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false, length = 30)
    private String reference; // ex: OF-2024-001

    @ManyToOne(optional = false)
    @JoinColumn(name = "produit_fini_id")
    private Article produitFini;

    @Column(nullable = false, precision = 15, scale = 3)
    private BigDecimal quantitePlanifiee;

    @Column(precision = 15, scale = 3)
    private BigDecimal quantiteRealisee = BigDecimal.ZERO;

    @Column(nullable = false)
    private LocalDate datePlanifiee;

    private LocalDateTime dateLancement;
    private LocalDateTime dateTerminaison;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private StatutOF statut = StatutOF.PLANIFIE;

    @Column(length = 500)
    private String notes;

    @ManyToOne
    @JoinColumn(name = "created_by")
    private User creePar;

    public enum StatutOF {
        PLANIFIE, LANCE, EN_COURS, TERMINE, ANNULE
    }
}
