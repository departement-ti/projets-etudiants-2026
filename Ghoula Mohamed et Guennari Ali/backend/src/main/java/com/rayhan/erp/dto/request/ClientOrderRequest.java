package com.rayhan.erp.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class ClientOrderRequest {

    private String dateLivraisonSouhaitee;

    private String notes;

    @NotEmpty
    @Valid
    private List<OrderLine> lignes;

    @Getter
    @Setter
    public static class OrderLine {
        private Long articleId;
        private double quantite;
    }
}
