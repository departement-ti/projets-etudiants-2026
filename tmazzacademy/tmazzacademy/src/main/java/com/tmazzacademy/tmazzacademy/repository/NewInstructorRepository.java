package com.tmazzacademy.tmazzacademy.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import com.tmazzacademy.tmazzacademy.model.NewInstructor;

public interface NewInstructorRepository extends JpaRepository<NewInstructor, Long> {
	boolean existsByEmail(String email);
}