package com.tmazzacademy.tmazzacademy.repository;

import com.tmazzacademy.tmazzacademy.model.Cours;
import com.tmazzacademy.tmazzacademy.model.Instructor;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CoursRepository extends JpaRepository<Cours, Long> {

    List<Cours> findByInstructor(Instructor instructor);

    List<Cours> findByActiveTrue();

    List<Cours> findByInstructorAndActiveTrue(Instructor instructor);
}