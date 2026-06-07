package com.tmazzacademy.tmazzacademy.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import com.tmazzacademy.tmazzacademy.model.NewStudent;

public interface NewStudentRepository extends JpaRepository<NewStudent, Long> {
    boolean existsByEmail(String email);
}