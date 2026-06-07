package com.recrutement.recrutement.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;

@Slf4j
@Configuration
@RequiredArgsConstructor
public class OffreSchemaUpdater {

    private final JdbcTemplate jdbcTemplate;

    @Bean
    public ApplicationRunner updateOffreColumnsToText() {
        return args -> {
            runAlter("ALTER TABLE offre ALTER COLUMN titre TYPE TEXT");
            runAlter("ALTER TABLE offre ALTER COLUMN categorie TYPE TEXT");
            runAlter("ALTER TABLE offre ALTER COLUMN description TYPE TEXT");
            runAlter("ALTER TABLE offre ALTER COLUMN localisation TYPE TEXT");
            runAlter("ALTER TABLE offre ALTER COLUMN experience_requise TYPE TEXT");
            runAlter("ALTER TABLE offre ALTER COLUMN type_contrat TYPE TEXT");
            runAlter("UPDATE offre SET date_expiration = date WHERE date_expiration IS NOT NULL AND date IS NOT NULL AND date_expiration < date");
        };
    }

    private void runAlter(String sql) {
        try {
            jdbcTemplate.execute(sql);
        } catch (Exception ex) {
            log.debug("Schema update skipped for SQL [{}]: {}", sql, ex.getMessage());
        }
    }
}
