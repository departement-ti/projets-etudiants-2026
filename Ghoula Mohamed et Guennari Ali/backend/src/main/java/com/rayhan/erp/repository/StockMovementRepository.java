package com.rayhan.erp.repository;

import com.rayhan.erp.model.StockMovement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface StockMovementRepository extends JpaRepository<StockMovement, Long> {
    List<StockMovement> findByArticleIdOrderByDateHeureDesc(Long articleId);
    List<StockMovement> findByDateHeureBetweenOrderByDateHeureDesc(LocalDateTime debut, LocalDateTime fin);
}
