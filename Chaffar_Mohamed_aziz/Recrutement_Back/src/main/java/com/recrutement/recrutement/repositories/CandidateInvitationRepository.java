package com.recrutement.recrutement.repositories;

import com.recrutement.recrutement.entities.CandidateInvitation;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CandidateInvitationRepository extends JpaRepository<CandidateInvitation, Long> {
    Optional<CandidateInvitation> findTopByOffer_IdAndCandidate_IdOrderByInvitedAtDesc(Long offerId, Long candidateId);
}
