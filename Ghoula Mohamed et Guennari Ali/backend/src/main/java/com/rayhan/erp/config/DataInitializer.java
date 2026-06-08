package com.rayhan.erp.config;

import com.rayhan.erp.model.ERole;
import com.rayhan.erp.model.Role;
import com.rayhan.erp.model.User;
import com.rayhan.erp.repository.RoleRepository;
import com.rayhan.erp.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.Set;

/**
 * Initialise la base de données avec les rôles et un utilisateur PDG par défaut.
 * S'exécute au démarrage de l'application si la base est vide.
 */
@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired private RoleRepository roleRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        initRoles();
        initDefaultAdmin();
    }

    private void initRoles() {
        for (ERole eRole : ERole.values()) {
            if (roleRepository.findByName(eRole).isEmpty()) {
                roleRepository.save(new Role(eRole));
            }
        }
    }

    private void initDefaultAdmin() {
        if (!userRepository.existsByUsername("admin")) {
            User admin = new User(
                "admin",
                "admin@rayhan.tn",
                passwordEncoder.encode("123456"),
                "Ahmed",
                "Fekih");
            Role pdgRole = roleRepository.findByName(ERole.ROLE_PDG)
                .orElseThrow(() -> new RuntimeException("Rôle PDG non trouvé"));
            admin.setRoles(Set.of(pdgRole));
            userRepository.save(admin);
        }
    }
}
