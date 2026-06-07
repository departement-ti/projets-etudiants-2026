package com.recrutement.recrutement.repositories;

import com.recrutement.recrutement.entities.Candidate;
import com.recrutement.recrutement.entities.CV;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface CVRepository extends JpaRepository<CV, Long> {
    Optional<CV> findTopByCandidateOrderByDateImportDesc(Candidate candidate);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from CV cv where cv.candidate.id = :candidateId")
    void deleteAllForCandidate(@Param("candidateId") Long candidateId);
}
