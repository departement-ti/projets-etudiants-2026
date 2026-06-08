package com.recrutement.recrutement.repositories;

import com.recrutement.recrutement.entities.Candidature;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface CandidatureRepository extends JpaRepository<Candidature, Long> {
    Optional<Candidature> findByCandidate_IdAndOffre_Id(Long candidateId, Long offreId);

    List<Candidature> findByCandidate_IdOrderByDateDepotDesc(Long candidateId);

    List<Candidature> findByCandidate_Id(Long candidateId);

    @Query("select c.id from Candidature c where c.candidate.id = :candidateId")
    List<Long> findIdsByCandidateId(@Param("candidateId") Long candidateId);

    List<Candidature> findByOffre_Recruiter_IdOrderByScoreCandidatDescDateDepotDesc(Long recruiterId);

    List<Candidature> findByOffre_Recruiter_Id(Long recruiterId);

    @Query("select c.id from Candidature c where c.offre.recruiter.id = :recruiterId")
    List<Long> findIdsByRecruiterId(@Param("recruiterId") Long recruiterId);

    @Query("select c.id from Candidature c where c.offre.id = :offerId")
    List<Long> findIdsByOfferId(@Param("offerId") Long offerId);

    List<Candidature> findByOffre_Recruiter_IdAndOffre_IdOrderByScoreCandidatDescDateDepotDesc(Long recruiterId, Long offreId);

    long countByOffre_Id(Long offreId);

    Optional<Candidature> findByIdAndOffre_Recruiter_Id(Long candidatureId, Long recruiterId);

    Optional<Candidature> findByIdAndCandidate_Id(Long candidatureId, Long candidateId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from Candidature c where c.offre.recruiter.id = :recruiterId")
    void deleteAllForRecruiter(@Param("recruiterId") Long recruiterId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from Candidature c where c.candidate.id = :candidateId")
    void deleteAllForCandidate(@Param("candidateId") Long candidateId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from Candidature c where c.offre.id = :offerId")
    void deleteAllForOffer(@Param("offerId") Long offerId);
}
