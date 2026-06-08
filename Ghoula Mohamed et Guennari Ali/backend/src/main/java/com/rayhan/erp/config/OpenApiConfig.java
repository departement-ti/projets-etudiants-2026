package com.rayhan.erp.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("ERP Rayhan — API REST")
                .description("API de gestion ERP pour SUARL Rayhan (plasturgie). PFE Ali Guennari.\n\n" +
                    "**Comment utiliser :**\n" +
                    "1. Cliquez sur `POST /api/auth/signin` → Try it out → Execute\n" +
                    "2. Copiez le `token` de la réponse\n" +
                    "3. Cliquez sur le bouton **Authorize 🔒** en haut à droite\n" +
                    "4. Collez le token et cliquez Authorize\n" +
                    "5. Tous les endpoints sont maintenant accessibles !\n\n" +
                    "**Identifiants par défaut :** admin / Rayhan2024!")
                .version("1.0.0")
                .contact(new Contact()
                    .name("Ali Guennari — PFE SUARL Rayhan")
                    .email("ali.guennari@rayhan.tn")))
            .addSecurityItem(new SecurityRequirement().addList("Bearer Authentication"))
            .components(new Components()
                .addSecuritySchemes("Bearer Authentication",
                    new SecurityScheme()
                        .type(SecurityScheme.Type.HTTP)
                        .scheme("bearer")
                        .bearerFormat("JWT")
                        .description("Entrez votre token JWT (sans le préfixe 'Bearer ')")));
    }
}
