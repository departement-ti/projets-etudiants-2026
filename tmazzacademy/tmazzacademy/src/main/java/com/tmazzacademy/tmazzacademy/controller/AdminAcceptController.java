package com.tmazzacademy.tmazzacademy.controller;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import com.tmazzacademy.tmazzacademy.dto.AcceptInstructorDTO;
import com.tmazzacademy.tmazzacademy.model.Instructor;
import com.tmazzacademy.tmazzacademy.model.NewInstructor;
import com.tmazzacademy.tmazzacademy.model.NewStudent;
import com.tmazzacademy.tmazzacademy.model.Role;
import com.tmazzacademy.tmazzacademy.model.Student;
import com.tmazzacademy.tmazzacademy.repository.NewInstructorRepository;
import com.tmazzacademy.tmazzacademy.repository.NewStudentRepository;
import com.tmazzacademy.tmazzacademy.repository.RoleRepository;
import com.tmazzacademy.tmazzacademy.repository.UserRepository;
import com.tmazzacademy.tmazzacademy.service.EmailService;

@RestController
@RequestMapping("/api/admin/inscriptions")
@CrossOrigin(origins = "http://localhost:4200")
public class AdminAcceptController {

    private final NewInstructorRepository newInstructorRepository;
    private final NewStudentRepository newStudentRepository;
    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;

    public AdminAcceptController(
            NewInstructorRepository newInstructorRepository,
            NewStudentRepository newStudentRepository,
            UserRepository userRepository,
            RoleRepository roleRepository,
            PasswordEncoder passwordEncoder,
            EmailService emailService
    ) {
        this.newInstructorRepository = newInstructorRepository;
        this.newStudentRepository = newStudentRepository;
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.passwordEncoder = passwordEncoder;
        this.emailService = emailService;
    }

    @PostMapping("/instructors/{id}/accept")
    public Instructor acceptInstructor(
            @PathVariable Long id,
            @RequestBody AcceptInstructorDTO dto
    ) {
        NewInstructor newInstructor = newInstructorRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Instructor inscription not found"));

        Role role = roleRepository.findByName("INSTRUCTOR")
                .orElseThrow(() -> new RuntimeException("Role INSTRUCTOR not found"));

        Instructor instructor = new Instructor();
        instructor.setName(newInstructor.getName());
        instructor.setLastname(newInstructor.getLastname());
        instructor.setEmail(newInstructor.getEmail());
        instructor.setTel(newInstructor.getTel());
        instructor.setSpeciality(newInstructor.getSpeciality());
        instructor.setPassword(passwordEncoder.encode(dto.getPassword()));
        instructor.setRole(role);

        Instructor savedInstructor = userRepository.save(instructor);

        emailService.sendInstructorCredentials(
                newInstructor.getEmail(),
                dto.getPassword()
        );

        newInstructorRepository.deleteById(id);

        return savedInstructor;
    }

    @PostMapping("/students/{id}/accept")
    public Student acceptStudent(
            @PathVariable Long id,
            @RequestBody AcceptInstructorDTO dto
    ) {
        NewStudent newStudent = newStudentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Student inscription not found"));

        Role role = roleRepository.findByName("STUDENT")
                .orElseThrow(() -> new RuntimeException("Role STUDENT not found"));

        Student student = new Student();
        student.setName(newStudent.getName());
        student.setLastname(newStudent.getLastname());
        student.setEmail(newStudent.getEmail());
        student.setTel(newStudent.getTel());
        student.setPassword(passwordEncoder.encode(dto.getPassword()));
        student.setRole(role);

        Student savedStudent = userRepository.save(student);

        newStudentRepository.deleteById(id);

        emailService.sendStudentCredentials(
                newStudent.getEmail(),
                dto.getPassword()
        );

        return savedStudent;
    }
}