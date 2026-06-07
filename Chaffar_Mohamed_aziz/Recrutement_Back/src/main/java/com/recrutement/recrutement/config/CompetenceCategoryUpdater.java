package com.recrutement.recrutement.config;

import com.recrutement.recrutement.service.CompetenceService;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class CompetenceCategoryUpdater implements CommandLineRunner {
    private final CompetenceService competenceService;

    public CompetenceCategoryUpdater(CompetenceService competenceService) {
        this.competenceService = competenceService;
    }

    @Override
    public void run(String... args) {
        competenceService.synchronizeStoredCategories();
    }
}
