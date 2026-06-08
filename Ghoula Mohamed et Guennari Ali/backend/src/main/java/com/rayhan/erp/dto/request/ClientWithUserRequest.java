package com.rayhan.erp.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
public class ClientWithUserRequest {

    @NotBlank
    @Size(max = 100)
    private String raisonSociale;

    @Size(max = 20)
    private String matriculeFiscal;

    @Size(max = 200)
    private String adresse;

    @Size(max = 20)
    private String telephone;

    @Size(max = 100)
    private String email;

    @Size(max = 50)
    private String ville;

    @Size(max = 30)
    private String typeClient;

    private BigDecimal plafondCredit = BigDecimal.ZERO;

    private Integer delaiPaiement = 30;

    @Size(max = 50)
    private String representantNom;

    @Size(max = 20)
    private String representantTelephone;

    @NotBlank
    @Size(max = 50)
    private String firstName;

    @NotBlank
    @Size(max = 50)
    private String lastName;

    @NotBlank
    @Size(min = 6, max = 40)
    private String password;
}
