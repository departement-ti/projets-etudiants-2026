package com.rayhan.erp.repository;

import com.rayhan.erp.model.Fournisseur;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FournisseurRepository extends JpaRepository<Fournisseur, Long> {
    List<Fournisseur> findByActifTrue();
    List<Fournisseur> findByRaisonSocialeContainingIgnoreCase(String search);
}
