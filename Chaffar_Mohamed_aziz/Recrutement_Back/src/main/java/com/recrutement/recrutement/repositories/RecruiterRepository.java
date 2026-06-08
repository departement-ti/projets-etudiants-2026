package com.recrutement.recrutement.repositories;

import com.recrutement.recrutement.entities.Recruiter;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RecruiterRepository extends JpaRepository<Recruiter,Long> {
    Recruiter findByEmail(String email);
}
