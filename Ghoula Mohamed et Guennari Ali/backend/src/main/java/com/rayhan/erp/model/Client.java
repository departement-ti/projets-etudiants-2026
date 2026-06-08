package com.rayhan.erp.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Entity
@Table(name = "clients")
@PrimaryKeyJoinColumn(name = "tiers_id")
@Getter
@Setter
@NoArgsConstructor
public class Client extends Tiers {

    @Column(length = 30)
    private String typeClient; // Grossiste, Détaillant, Industrie

    private BigDecimal plafondCredit = BigDecimal.ZERO;

    private Integer delaiPaiement = 30; // jours

    @Column(length = 50)
    private String representantNom;

    @Column(length = 20)
    private String representantTelephone;

    @JsonIgnore
    @OneToOne(mappedBy = "client")
    private User user;

    public Client(String raisonSociale, String matriculeFiscal, String telephone) {
        super(raisonSociale, matriculeFiscal, telephone);
    }
}
