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
public class EntrepriseSchemaUpdater {

    private final JdbcTemplate jdbcTemplate;

    @Bean
    public ApplicationRunner updateEntrepriseColumnsToText() {
        return args -> {
            runAlter("ALTER TABLE entreprises ALTER COLUMN nom_entreprise TYPE TEXT");
            runAlter("ALTER TABLE entreprises ALTER COLUMN secteur TYPE TEXT");
            runAlter("ALTER TABLE entreprises ALTER COLUMN adresse TYPE TEXT");
            runAlter("ALTER TABLE entreprises ALTER COLUMN email TYPE TEXT");
            runAlter("ALTER TABLE entreprises ALTER COLUMN abonnement_actif TYPE TEXT");
            runAlter("ALTER TABLE entreprises ALTER COLUMN description TYPE TEXT");
            runAlter("ALTER TABLE entreprises ALTER COLUMN site_web TYPE TEXT");
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
