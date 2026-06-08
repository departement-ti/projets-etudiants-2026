package com.recrutement.recrutement.config;

import com.recrutement.recrutement.entities.Role;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.repositories.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class DataInitializer implements CommandLineRunner {
    private final UserRepository userRepository;
    private final PasswordEncoder  passwordEncoder ;
    public DataInitializer(UserRepository userRepository, PasswordEncoder  passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) throws Exception {
        String adminEmail = "chaffaraziz54@gmail.com";
        String adminPassword = "admin";
        if (userRepository.findByEmail(adminEmail).isEmpty()) {

            User admin = new User();
            admin.setEmail(adminEmail);
            admin.setPassword(passwordEncoder.encode(adminPassword));
            admin.setNom("System Admin");
            admin.setRole(Role.ADMIN);
            admin.setStatutCompte(true);

            userRepository.save(admin);

            System.out.println("===========================================");
            System.out.println("✅ Admin par défaut créé avec succès !");
            System.out.println("✅ Email: " + adminEmail);
            System.out.println("✅ Mot de passe: " + adminPassword);
            System.out.println("===========================================");
        } else {
            System.out.println("ℹ️ L'admin " + adminEmail + " existe déjà dans le système.");
        }
    }
}
