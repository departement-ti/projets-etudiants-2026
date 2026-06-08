package com.rayhan.erp.repository;

import com.rayhan.erp.model.ReferenceSequence;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface ReferenceSequenceRepository extends JpaRepository<ReferenceSequence, String> {

    @Modifying
    @Query("UPDATE ReferenceSequence r SET r.currentValue = r.currentValue + 1 WHERE r.type = :type")
    int incrementByType(@Param("type") String type);
}
