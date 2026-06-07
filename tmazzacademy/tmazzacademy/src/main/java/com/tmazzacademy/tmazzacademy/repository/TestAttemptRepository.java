package com.tmazzacademy.tmazzacademy.repository;

import com.tmazzacademy.tmazzacademy.model.Cours;
import com.tmazzacademy.tmazzacademy.model.Student;
import com.tmazzacademy.tmazzacademy.model.TestAttempt;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TestAttemptRepository extends JpaRepository<TestAttempt, Long> {

    List<TestAttempt> findByStudentAndCoursOrderByAttemptedAtDesc(
            Student student,
            Cours cours
    );

    Optional<TestAttempt> findFirstByStudentAndCoursOrderByAttemptedAtDesc(
            Student student,
            Cours cours
    );

    long countByStudentAndCours(
            Student student,
            Cours cours
    );

    boolean existsByStudentAndCoursAndPassedTrue(
            Student student,
            Cours cours
    );
}