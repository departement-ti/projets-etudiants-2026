package com.rayhan.erp.repository;

import com.rayhan.erp.model.ProductionOrder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProductionOrderRepository extends JpaRepository<ProductionOrder, Long> {
    Optional<ProductionOrder> findByReference(String reference);
    boolean existsByReference(String reference);
    List<ProductionOrder> findByStatutOrderByDatePlanifieeDesc(ProductionOrder.StatutOF statut);
    long countByStatut(ProductionOrder.StatutOF statut);
}
