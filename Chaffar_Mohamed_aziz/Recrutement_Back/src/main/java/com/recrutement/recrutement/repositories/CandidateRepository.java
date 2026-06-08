package com.recrutement.recrutement.repositories;

import com.recrutement.recrutement.entities.Candidate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CandidateRepository extends JpaRepository<Candidate,Long> {
    Candidate findByEmail(String email);
}
