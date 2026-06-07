package com.recrutement.recrutement.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ServiceHealthResponse {
    private String service;
    private String status;
    private String detail;
    private String tone;
}
