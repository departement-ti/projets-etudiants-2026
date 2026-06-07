package com.tmazzacademy.tmazzacademy.repository;

import com.tmazzacademy.tmazzacademy.model.FavoriteCourse;
import com.tmazzacademy.tmazzacademy.model.Student;
import com.tmazzacademy.tmazzacademy.model.Cours;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface FavoriteCourseRepository extends JpaRepository<FavoriteCourse, Long> {

    List<FavoriteCourse> findByStudent(Student student);

    List<FavoriteCourse> findByStudentAndCoursActiveTrue(Student student);

    Optional<FavoriteCourse> findByStudentAndCours(Student student, Cours cours);

    boolean existsByStudentAndCours(Student student, Cours cours);
}