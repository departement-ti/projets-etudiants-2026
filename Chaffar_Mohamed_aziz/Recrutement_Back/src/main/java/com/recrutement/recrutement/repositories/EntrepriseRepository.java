package com.recrutement.recrutement.repositories;

import com.recrutement.recrutement.entities.Entreprise;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EntrepriseRepository extends JpaRepository<Entreprise,Long> {
    Optional<Entreprise> findByEmailIgnoreCase(String email);
}
