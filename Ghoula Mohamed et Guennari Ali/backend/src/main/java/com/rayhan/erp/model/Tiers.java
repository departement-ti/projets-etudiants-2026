package com.rayhan.erp.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "tiers")
@Inheritance(strategy = InheritanceType.JOINED)
@Getter
@Setter
@NoArgsConstructor
public abstract class Tiers {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String raisonSociale;

    @Column(length = 20)
    private String matriculeFiscal;

    @Column(length = 200)
    private String adresse;

    @Column(length = 20)
    private String telephone;

    @Column(length = 100)
    private String email;

    @Column(length = 50)
    private String ville;

    private boolean actif = true;

    public Tiers(String raisonSociale, String matriculeFiscal, String telephone) {
        this.raisonSociale = raisonSociale;
        this.matriculeFiscal = matriculeFiscal;
        this.telephone = telephone;
    }
}
