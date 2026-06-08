package com.rayhan.erp.repository;

import com.rayhan.erp.model.PurchaseOrder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PurchaseOrderRepository extends JpaRepository<PurchaseOrder, Long> {
    Optional<PurchaseOrder> findByReference(String reference);
    boolean existsByReference(String reference);
    List<PurchaseOrder> findByStatutOrderByDateCommandeDesc(PurchaseOrder.StatutCommande statut);
    long countByStatutIn(List<PurchaseOrder.StatutCommande> statuts);
}
