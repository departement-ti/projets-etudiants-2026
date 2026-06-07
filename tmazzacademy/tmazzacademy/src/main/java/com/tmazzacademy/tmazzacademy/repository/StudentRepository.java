package com.tmazzacademy.tmazzacademy.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import com.tmazzacademy.tmazzacademy.model.Student;

import java.util.List;

public interface StudentRepository extends JpaRepository<Student, Long> {

    List<Student> findByActiveTrue();
}