package com.recrutement.recrutement.repositories;

import com.recrutement.recrutement.entities.AiTestResult;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface AiTestResultRepository extends JpaRepository<AiTestResult, Long> {
    Optional<AiTestResult> findByAiTest_Id(Long aiTestId);

    Optional<AiTestResult> findByIdAndCandidate_Id(Long resultId, Long candidateId);

    Optional<AiTestResult> findByIdAndCandidature_Offre_Recruiter_Id(Long resultId, Long recruiterId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from AiTestResult r where r.aiTest.id in :testIds")
    void deleteByAiTestIds(@Param("testIds") List<Long> testIds);
}
