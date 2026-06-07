package com.recrutement.recrutement.repositories;

import com.recrutement.recrutement.entities.Competence;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CompetenceRepository extends JpaRepository<Competence, Long> {
    List<Competence> findAllByOrderByTypeAscNomAsc();

    List<Competence> findByTypeIgnoreCaseOrderByNomAsc(String type);

    List<Competence> findByNomContainingIgnoreCaseOrderByTypeAscNomAsc(String nom);

    List<Competence> findByNomContainingIgnoreCaseAndTypeIgnoreCaseOrderByNomAsc(String nom, String type);

    Optional<Competence> findFirstByNomIgnoreCase(String nom);

    boolean existsByNomIgnoreCase(String nom);

    boolean existsByNomIgnoreCaseAndIdNot(String nom, Long id);
}
