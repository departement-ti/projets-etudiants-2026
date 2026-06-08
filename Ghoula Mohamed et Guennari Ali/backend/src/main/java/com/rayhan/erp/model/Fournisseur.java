package com.rayhan.erp.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "fournisseurs")
@PrimaryKeyJoinColumn(name = "tiers_id")
@Getter
@Setter
@NoArgsConstructor
public class Fournisseur extends Tiers {

    @Column(length = 100)
    private String pays = "Tunisie";

    @Column(length = 50)
    private String categorieProduit; // Matières plastiques, Emballages...

    private Integer delaiLivraison = 7; // jours

    @Column(length = 30)
    private String modePaiement; // Virement, Chèque, Espèces

    public Fournisseur(String raisonSociale, String matriculeFiscal, String telephone) {
        super(raisonSociale, matriculeFiscal, telephone);
    }
}
