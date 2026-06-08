package com.rayhan.erp.repository;

import com.rayhan.erp.model.DeliveryNote;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface DeliveryNoteRepository extends JpaRepository<DeliveryNote, Long> {
    Optional<DeliveryNote> findByReference(String reference);
    boolean existsByReference(String reference);
}
