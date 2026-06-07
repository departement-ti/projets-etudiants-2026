package com.tmazzacademy.tmazzacademy.service;

import com.tmazzacademy.tmazzacademy.model.Cours;
import com.tmazzacademy.tmazzacademy.model.Instructor;
import com.tmazzacademy.tmazzacademy.repository.CoursRepository;
import com.tmazzacademy.tmazzacademy.repository.InstructorRepository;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class CoursService {

    private final CoursRepository coursRepository;
    private final InstructorRepository instructorRepository;
    private final NotificationService notificationService;

    public CoursService(
            CoursRepository coursRepository,
            InstructorRepository instructorRepository,
            NotificationService notificationService
    ) {
        this.coursRepository = coursRepository;
        this.instructorRepository = instructorRepository;
        this.notificationService = notificationService;
    }

    public Cours addCourse(
            Long instructorId,
            String titre,
            String description,
            MultipartFile video,
            MultipartFile pdf
    ) {
        Instructor instructor = instructorRepository.findById(instructorId)
                .orElseThrow(() -> new RuntimeException("Instructor not found"));

        try {
            String uploadDir =
                    System.getProperty("user.dir")
                            + File.separator
                            + "uploads"
                            + File.separator;

            new File(uploadDir).mkdirs();

            String videoName = UUID.randomUUID() + "_" + video.getOriginalFilename();
            String videoPath = uploadDir + videoName;
            video.transferTo(new File(videoPath));

            String pdfName = UUID.randomUUID() + "_" + pdf.getOriginalFilename();
            String pdfPath = uploadDir + pdfName;
            pdf.transferTo(new File(pdfPath));

            Cours cours = new Cours();

            cours.setTitre(titre);
            cours.setDescription(description);
            cours.setVideoPath("uploads/" + videoName);
            cours.setPdfPath("uploads/" + pdfName);
            cours.setInstructor(instructor);
            cours.setActive(true);

            Cours savedCourse = coursRepository.save(cours);

            notificationService.createNotification(
                    "New Course",
                    "New course added: " + savedCourse.getTitre(),
                    "STUDENT",
                    null
            );

            notificationService.createNotification(
                    "New Course Added",
                    instructor.getName() + " added a new course: " + savedCourse.getTitre(),
                    "ADMIN",
                    null
            );

            return savedCourse;

        } catch (IOException e) {
            throw new RuntimeException("Error uploading files: " + e.getMessage());
        }
    }

    public List<Cours> getAllCourses() {
        return coursRepository.findByActiveTrue();
    }

    public Cours getCourseById(Long id) {
        return coursRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Course not found"));
    }

    public List<Cours> getCoursesByInstructor(Long instructorId) {
        Instructor instructor = instructorRepository.findById(instructorId)
                .orElseThrow(() -> new RuntimeException("Instructor not found"));

        return coursRepository.findByInstructorAndActiveTrue(instructor);
    }

    public Map<String, Long> getInstructorCourseStats(Long instructorId) {
        Instructor instructor = instructorRepository.findById(instructorId)
                .orElseThrow(() -> new RuntimeException("Instructor not found"));

        List<Cours> courses = coursRepository.findByInstructor(instructor);

        long active = courses.stream().filter(Cours::isActive).count();
        long inactive = courses.stream().filter(c -> !c.isActive()).count();

        return Map.of(
                "total", active,
                "active", active,
                "inactive", inactive
        );
    }

    public Cours updateCourse(Long id, Cours updated) {
        Cours cours = getCourseById(id);

        cours.setTitre(updated.getTitre());
        cours.setDescription(updated.getDescription());

        return coursRepository.save(cours);
    }

    public void deleteCourse(Long id) {
        Cours cours = getCourseById(id);

        cours.setActive(false);

        coursRepository.save(cours);

        notificationService.createNotification(
                "Course Deleted",
                "Admin deleted your course: " + cours.getTitre(),
                "INSTRUCTOR",
                cours.getInstructor().getId()
        );
    }
}