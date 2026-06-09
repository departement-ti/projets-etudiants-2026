package com.tmazzacademy.tmazzacademy.repository;

import com.tmazzacademy.tmazzacademy.model.NewInstructor;

import org.springframework.data.jpa.repository.JpaRepository;

public interface InstructorInscriptionRepository extends JpaRepository<NewInstructor, Long> {
}