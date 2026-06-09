package com.tmazzacademy.tmazzacademy.controller;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import com.tmazzacademy.tmazzacademy.model.NewStudent;
import com.tmazzacademy.tmazzacademy.model.NewInstructor;
import com.tmazzacademy.tmazzacademy.repository.NewStudentRepository;
import com.tmazzacademy.tmazzacademy.repository.NewInstructorRepository;
import com.tmazzacademy.tmazzacademy.repository.UserRepository;
import com.tmazzacademy.tmazzacademy.service.NotificationService;

@RestController
@RequestMapping("/api/inscription")
@CrossOrigin(origins = "http://localhost:4200")
public class InscriptionController {

    @Autowired
    private NewStudentRepository newStudentRepository;

    @Autowired
    private NewInstructorRepository newInstructorRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private NotificationService notificationService;

    @PostMapping("/student")
    public ResponseEntity<?> addStudentInscription(
            @RequestParam("name") String name,
            @RequestParam("lastname") String lastname,
            @RequestParam("email") String email,
            @RequestParam("tel") String tel,
            @RequestParam("recuPaiement") MultipartFile recuPaiement
    ) {

        if (userRepository.existsByEmail(email)
                || newStudentRepository.existsByEmail(email)
                || newInstructorRepository.existsByEmail(email)) {

            return ResponseEntity.status(409).body("Email already exists");
        }

        try {
            String uploadDir =
                    System.getProperty("user.dir")
                            + File.separator
                            + "uploads"
                            + File.separator
                            + "receipts"
                            + File.separator;

            new File(uploadDir).mkdirs();

            String fileName =
                    UUID.randomUUID()
                            + "_"
                            + recuPaiement.getOriginalFilename();

            File file = new File(uploadDir + fileName);

            recuPaiement.transferTo(file);

            NewStudent student = new NewStudent();

            student.setName(name);
            student.setLastname(lastname);
            student.setEmail(email);
            student.setTel(tel);
            student.setRecuPaiement("uploads/receipts/" + fileName);

            NewStudent savedStudent = newStudentRepository.save(student);

            notificationService.createNotification(
                    "New Student",
                    savedStudent.getName() + " " + savedStudent.getLastname() + " registered as student",
                    "ADMIN",
                    null
            );

            return ResponseEntity.ok(savedStudent);

        } catch (IOException e) {
            return ResponseEntity
                    .status(500)
                    .body("Error uploading receipt image");
        }
    }

    @PostMapping("/instructor")
    public ResponseEntity<?> addInstructorInscription(@RequestBody NewInstructor instructor) {

        String email = instructor.getEmail();

        if (userRepository.existsByEmail(email)
                || newInstructorRepository.existsByEmail(email)
                || newStudentRepository.existsByEmail(email)) {

            return ResponseEntity.status(409).body("Email already exists");
        }

        NewInstructor savedInstructor = newInstructorRepository.save(instructor);

        notificationService.createNotification(
                "New Instructor",
                savedInstructor.getName() + " " + savedInstructor.getLastname() + " registered as instructor",
                "ADMIN",
                null
        );

        return ResponseEntity.ok(savedInstructor);
    }

    @GetMapping("/students")
    public List<NewStudent> getAllStudentsInscription() {
        return newStudentRepository.findAll();
    }

    @GetMapping("/instructors")
    public List<NewInstructor> getAllInstructorsInscription() {
        return newInstructorRepository.findAll();
    }

    @GetMapping("/check-email")
    public ResponseEntity<Boolean> checkEmail(@RequestParam String email) {

        boolean exists =
                userRepository.existsByEmail(email)
                        || newStudentRepository.existsByEmail(email)
                        || newInstructorRepository.existsByEmail(email);

        return ResponseEntity.ok(exists);
    }
}