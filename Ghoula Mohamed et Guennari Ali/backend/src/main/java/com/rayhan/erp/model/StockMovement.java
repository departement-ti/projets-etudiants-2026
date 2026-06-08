package com.rayhan.erp.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "stock_movements")
@Getter
@Setter
@NoArgsConstructor
public class StockMovement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "article_id")
    private Article article;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private TypeMouvement type; // IN = entrée, OUT = sortie

    @Column(nullable = false, precision = 15, scale = 3)
    private BigDecimal quantite;

    @Column(precision = 15, scale = 3)
    private BigDecimal stockAvant;

    @Column(precision = 15, scale = 3)
    private BigDecimal stockApres;

    @Column(length = 50)
    private String sourceDocument; // BON_RECEPTION, BON_LIVRAISON, OF, AJUSTEMENT

    @Column(length = 30)
    private String referenceDocument; // ex: BR-2024-001

    @Column(length = 200)
    private String motif;

    @Column(nullable = false)
    private LocalDateTime dateHeure = LocalDateTime.now();

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User creePar;

    public enum TypeMouvement {
        IN,  // Entrée stock
        OUT  // Sortie stock
    }
}
