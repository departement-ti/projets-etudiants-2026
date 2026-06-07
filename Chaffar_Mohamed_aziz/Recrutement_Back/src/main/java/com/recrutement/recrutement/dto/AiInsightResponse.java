package com.recrutement.recrutement.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AiInsightResponse {
    private String title;
    private String description;
    private String tone;
}
