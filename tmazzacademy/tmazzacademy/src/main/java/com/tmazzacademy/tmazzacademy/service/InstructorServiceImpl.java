package com.tmazzacademy.tmazzacademy.service;

import com.tmazzacademy.tmazzacademy.model.Instructor;
import com.tmazzacademy.tmazzacademy.repository.InstructorRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class InstructorServiceImpl implements InstructorService {

    private final InstructorRepository instructorRepository;

    public InstructorServiceImpl(InstructorRepository instructorRepository) {
        this.instructorRepository = instructorRepository;
    }

    @Override
    public Instructor saveInstructor(Instructor instructor) {
        return instructorRepository.save(instructor);
    }

    @Override
    public List<Instructor> getAllInstructors() {
        return instructorRepository.findByActiveTrue();
    }

    @Override
    public Optional<Instructor> getInstructorById(Long id) {
        return instructorRepository.findById(id);
    }

    @Override
    public Instructor updateInstructor(Long id, Instructor updatedInstructor) {

        return instructorRepository.findById(id)

                .map(instructor -> {

                    instructor.setName(updatedInstructor.getName());

                    instructor.setLastname(updatedInstructor.getLastname());

                    instructor.setEmail(updatedInstructor.getEmail());

                    instructor.setPassword(updatedInstructor.getPassword());

                    instructor.setTel(updatedInstructor.getTel());

                    instructor.setSpeciality(updatedInstructor.getSpeciality());

                    return instructorRepository.save(instructor);
                })

                .orElseThrow(() ->
                        new RuntimeException(
                                "Instructor not found with id: " + id
                        )
                );
    }

    @Override
    public void deleteInstructor(Long id) {

        Instructor instructor = instructorRepository.findById(id)

                .orElseThrow(() ->
                        new RuntimeException(
                                "Instructor not found"
                        )
                );

        instructor.setActive(false);

        instructorRepository.save(instructor);
    }
}