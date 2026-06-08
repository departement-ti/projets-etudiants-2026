package com.recrutement.recrutement.repositories;

import com.recrutement.recrutement.entities.Offre;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OffreRepository extends JpaRepository<Offre, Long> {
    List<Offre> findAllByOrderByDateDesc();

    List<Offre> findByStatutIgnoreCaseOrderByDateDesc(String statut);

    List<Offre> findByRecruiter_IdOrderByDateDesc(Long recruiterId);

    long countByRecruiter_IdAndStatutIgnoreCase(Long recruiterId, String statut);

    void deleteByRecruiter_Id(Long recruiterId);
}
