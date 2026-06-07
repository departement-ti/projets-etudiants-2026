package com.tmazzacademy.tmazzacademy.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import com.tmazzacademy.tmazzacademy.model.Instructor;

public interface InstructorRepository extends JpaRepository<Instructor, Long> {

    List<Instructor> findBySpeciality(String speciality);

    List<Instructor> findByActiveTrue();
}