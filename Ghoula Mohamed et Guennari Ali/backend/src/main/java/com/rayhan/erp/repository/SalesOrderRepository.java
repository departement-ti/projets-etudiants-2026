package com.rayhan.erp.repository;

import com.rayhan.erp.model.SalesOrder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface SalesOrderRepository extends JpaRepository<SalesOrder, Long> {
    Optional<SalesOrder> findByReference(String reference);
    boolean existsByReference(String reference);
    List<SalesOrder> findByStatutOrderByDateCommandeDesc(SalesOrder.StatutCommande statut);
    List<SalesOrder> findByClientIdOrderByDateCommandeDesc(Long clientId);
    List<SalesOrder> findByStatut(SalesOrder.StatutCommande statut);

    @Query("SELECT COALESCE(SUM(s.totalTTC), 0) FROM SalesOrder s WHERE s.dateCommande BETWEEN :debut AND :fin")
    BigDecimal sumTotalTTCByDateCommandeBetween(LocalDate debut, LocalDate fin);

    long countByDateCommandeBetween(LocalDate debut, LocalDate fin);
}
