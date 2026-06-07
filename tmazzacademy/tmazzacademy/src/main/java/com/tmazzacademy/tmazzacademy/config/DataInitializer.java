package com.tmazzacademy.tmazzacademy.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.tmazzacademy.tmazzacademy.repository.RoleRepository;
import com.tmazzacademy.tmazzacademy.model.Role;

@Configuration
public class DataInitializer {

    @Bean
    CommandLineRunner initRoles(RoleRepository roleRepository) {
        return args -> {
            if (roleRepository.findByName("ADMIN").isEmpty()) {
                roleRepository.save(new Role(null, "ADMIN"));
            }

            if (roleRepository.findByName("INSTRUCTOR").isEmpty()) {
                roleRepository.save(new Role(null, "INSTRUCTOR"));
            }

            if (roleRepository.findByName("STUDENT").isEmpty()) {
                roleRepository.save(new Role(null, "STUDENT"));
            }
        };
    }
}