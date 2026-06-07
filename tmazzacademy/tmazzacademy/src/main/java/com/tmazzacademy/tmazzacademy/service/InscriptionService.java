package com.tmazzacademy.tmazzacademy.service;

import com.tmazzacademy.tmazzacademy.model.Instructor;
import com.tmazzacademy.tmazzacademy.model.NewInstructor;
import com.tmazzacademy.tmazzacademy.model.Role;
import com.tmazzacademy.tmazzacademy.repository.InstructorInscriptionRepository;
import com.tmazzacademy.tmazzacademy.repository.InstructorRepository;
import com.tmazzacademy.tmazzacademy.repository.RoleRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class InscriptionService {

    private final InstructorInscriptionRepository inscriptionRepository;
    private final InstructorRepository instructorRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;
    private final RoleRepository roleRepository;

    public InscriptionService(
            InstructorInscriptionRepository inscriptionRepository,
            InstructorRepository instructorRepository,
            PasswordEncoder passwordEncoder,
            EmailService emailService,
            RoleRepository roleRepository
    ) {
        this.inscriptionRepository = inscriptionRepository;
        this.instructorRepository = instructorRepository;
        this.passwordEncoder = passwordEncoder;
        this.emailService = emailService;
        this.roleRepository = roleRepository;
    }

    public List<NewInstructor> getInstructorInscriptions() {
        return inscriptionRepository.findAll();
    }

    public void acceptInstructor(Long id, String password) {

        NewInstructor inscription = inscriptionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Instructor not found"));

        Role instructorRole = roleRepository.findByName("INSTRUCTOR")
                .orElseThrow(() -> new RuntimeException("Role INSTRUCTOR not found"));

        Instructor instructor = new Instructor();

        instructor.setName(inscription.getName());
        instructor.setLastname(inscription.getLastname());
        instructor.setEmail(inscription.getEmail());
        instructor.setTel(inscription.getTel());
        instructor.setSpeciality(inscription.getSpeciality());
        instructor.setPassword(passwordEncoder.encode(password));
        instructor.setRole(instructorRole);

        instructorRepository.save(instructor);

        emailService.sendInstructorCredentials(
                inscription.getEmail(),
                password
        );

        inscriptionRepository.delete(inscription);
    }
}