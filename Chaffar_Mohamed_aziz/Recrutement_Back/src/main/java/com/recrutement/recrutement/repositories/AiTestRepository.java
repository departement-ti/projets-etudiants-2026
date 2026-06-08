package com.recrutement.recrutement.repositories;

import com.recrutement.recrutement.entities.AiTest;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface AiTestRepository extends JpaRepository<AiTest, Long> {
    List<AiTest> findByCandidate_IdOrderByCreatedAtDesc(Long candidateId);

    Optional<AiTest> findByIdAndCandidate_Id(Long testId, Long candidateId);

    Optional<AiTest> findByIdAndRecruiter_Id(Long testId, Long recruiterId);

    Optional<AiTest> findTopByJobOffer_IdAndApplicationIsNullOrderByCreatedAtDesc(Long offerId);

    Optional<AiTest> findByIdAndJobOffer_Recruiter_Id(Long testId, Long recruiterId);

    Optional<AiTest> findTopByApplication_IdOrderByCreatedAtDesc(Long applicationId);

    List<AiTest> findByApplication_IdOrderByCreatedAtDesc(Long applicationId);

    List<AiTest> findByStatusInOrderByCreatedAtAsc(List<String> statuses);

    @Query("select t.id from AiTest t where t.application.id = :applicationId")
    List<Long> findIdsByApplicationId(@Param("applicationId") Long applicationId);

    @Query("select t.id from AiTest t where t.jobOffer.id = :offerId")
    List<Long> findIdsByOfferId(@Param("offerId") Long offerId);

    @Query("select t.id from AiTest t where t.recruiter.id = :recruiterId")
    List<Long> findIdsByRecruiterId(@Param("recruiterId") Long recruiterId);

    @Query("select t.id from AiTest t where t.candidate.id = :candidateId")
    List<Long> findIdsByCandidateId(@Param("candidateId") Long candidateId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from AiTest t where t.application.id = :applicationId")
    void deleteByApplicationId(@Param("applicationId") Long applicationId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from AiTest t where t.jobOffer.id = :offerId")
    void deleteByOfferId(@Param("offerId") Long offerId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from AiTest t where t.recruiter.id = :recruiterId")
    void deleteByRecruiterId(@Param("recruiterId") Long recruiterId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from AiTest t where t.candidate.id = :candidateId")
    void deleteByCandidateId(@Param("candidateId") Long candidateId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from AiTest t where t.id in :testIds")
    void deleteByIds(@Param("testIds") List<Long> testIds);
}
