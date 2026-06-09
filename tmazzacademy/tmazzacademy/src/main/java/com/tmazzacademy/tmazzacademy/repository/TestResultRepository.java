package com.tmazzacademy.tmazzacademy.repository;

import com.tmazzacademy.tmazzacademy.model.TestResult;
import com.tmazzacademy.tmazzacademy.model.Student;
import com.tmazzacademy.tmazzacademy.model.Cours;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TestResultRepository extends JpaRepository<TestResult, Long> {

    List<TestResult> findByStudent(Student student);

    List<TestResult> findByCours(Cours cours);

    TestResult findByStudentAndCours(Student student, Cours cours);

    List<TestResult> findBySuccessTrue();
    List<TestResult> findByCoursInstructorIdAndSuccessFalse(Long instructorId);

    List<TestResult> findByCoursInstructorIdAndSuccessTrue(Long instructorId);
}