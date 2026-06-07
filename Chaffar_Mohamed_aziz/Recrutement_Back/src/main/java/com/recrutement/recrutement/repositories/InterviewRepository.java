package com.recrutement.recrutement.repositories;

import com.recrutement.recrutement.entities.Interview;
import com.recrutement.recrutement.entities.InterviewStatus;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface InterviewRepository extends JpaRepository<Interview, Long> {
    Optional<Interview> findByIdAndRecruiter_Id(Long interviewId, Long recruiterId);

    Optional<Interview> findByIdAndCandidate_Id(Long interviewId, Long candidateId);

    Optional<Interview> findTopByCandidature_IdOrderByCreatedAtDesc(Long candidatureId);

    List<Interview> findByCandidate_IdOrderByInterviewDateTimeDesc(Long candidateId);

    List<Interview> findByStatusInOrderByInterviewDateTimeAsc(Collection<InterviewStatus> statuses);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from Interview i where i.offre.id = :offerId")
    void deleteByOfferId(@Param("offerId") Long offerId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from Interview i where i.recruiter.id = :recruiterId")
    void deleteByRecruiterId(@Param("recruiterId") Long recruiterId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from Interview i where i.candidate.id = :candidateId")
    void deleteByCandidateId(@Param("candidateId") Long candidateId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from Interview i where i.candidature.id = :applicationId")
    void deleteByApplicationId(@Param("applicationId") Long applicationId);
}
