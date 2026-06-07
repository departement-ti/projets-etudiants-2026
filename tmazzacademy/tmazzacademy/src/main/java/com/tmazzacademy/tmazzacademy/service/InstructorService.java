package com.tmazzacademy.tmazzacademy.service;

import com.tmazzacademy.tmazzacademy.model.Instructor;
import java.util.List;
import java.util.Optional;

public interface InstructorService {

    Instructor saveInstructor(Instructor instructor);

    List<Instructor> getAllInstructors();

    Optional<Instructor> getInstructorById(Long id);

    Instructor updateInstructor(Long id, Instructor instructor);

    void deleteInstructor(Long id);
}