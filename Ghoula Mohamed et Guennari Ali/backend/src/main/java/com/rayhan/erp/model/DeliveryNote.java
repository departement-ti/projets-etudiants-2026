package com.rayhan.erp.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "delivery_notes")
@Getter
@Setter
@NoArgsConstructor
public class DeliveryNote {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false, length = 30)
    private String reference; // ex: BL-2024-001

    @ManyToOne(optional = false)
    @JoinColumn(name = "sales_order_id")
    private SalesOrder salesOrder;

    @Column(nullable = false)
    private LocalDate dateLivraison = LocalDate.now();

    @Column(length = 200)
    private String adresseLivraison;

    @Column(length = 200)
    private String notes;

    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private StatutLivraison statut = StatutLivraison.LIVRE;

    @OneToMany(mappedBy = "deliveryNote", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<DeliveryNoteLine> lignes = new ArrayList<>();

    @ManyToOne
    @JoinColumn(name = "created_by")
    private User creePar;

    public enum StatutLivraison {
        EN_PREPARATION, LIVRE, RETOURNE_PARTIEL
    }
}
