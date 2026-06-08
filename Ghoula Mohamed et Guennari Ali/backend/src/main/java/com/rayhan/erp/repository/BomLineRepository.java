package com.rayhan.erp.repository;

import com.rayhan.erp.model.BomLine;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BomLineRepository extends JpaRepository<BomLine, Long> {
    List<BomLine> findByProduitFiniId(Long produitFiniId);
    void deleteByProduitFiniId(Long produitFiniId);
}
