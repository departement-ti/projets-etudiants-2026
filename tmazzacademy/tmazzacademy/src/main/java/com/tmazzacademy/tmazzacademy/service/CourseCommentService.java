package com.tmazzacademy.tmazzacademy.service;

import com.tmazzacademy.tmazzacademy.model.CourseComment;
import com.tmazzacademy.tmazzacademy.model.Cours;
import com.tmazzacademy.tmazzacademy.model.Student;
import com.tmazzacademy.tmazzacademy.repository.CourseCommentRepository;
import com.tmazzacademy.tmazzacademy.repository.CoursRepository;
import com.tmazzacademy.tmazzacademy.repository.StudentRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CourseCommentService {

    private final CourseCommentRepository commentRepository;
    private final CoursRepository coursRepository;
    private final StudentRepository studentRepository;
    private final NotificationService notificationService;

    public CourseCommentService(
            CourseCommentRepository commentRepository,
            CoursRepository coursRepository,
            StudentRepository studentRepository,
            NotificationService notificationService
    ) {
        this.commentRepository = commentRepository;
        this.coursRepository = coursRepository;
        this.studentRepository = studentRepository;
        this.notificationService = notificationService;
    }

    public CourseComment addComment(Long studentId, Long coursId, CourseComment commentRequest) {

        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("Student not found"));

        Cours cours = coursRepository.findById(coursId)
                .orElseThrow(() -> new RuntimeException("Course not found"));

        if (commentRequest.getStars() < 1 || commentRequest.getStars() > 5) {
            throw new RuntimeException("Stars must be between 1 and 5");
        }

        CourseComment comment = new CourseComment();
        comment.setComment(commentRequest.getComment());
        comment.setStars(commentRequest.getStars());
        comment.setStudent(student);
        comment.setCours(cours);

        CourseComment savedComment = commentRepository.save(comment);

        double total = (cours.getRating() * cours.getRatingCount()) + commentRequest.getStars();
        int newCount = cours.getRatingCount() + 1;

        cours.setRating(total / newCount);
        cours.setRatingCount(newCount);

        coursRepository.save(cours);

        notificationService.createNotification(
                "New Comment",
                student.getName() + " commented on your course: " + cours.getTitre(),
                "INSTRUCTOR",
                cours.getInstructor().getId()
        );

        return savedComment;
    }

    public List<CourseComment> getCommentsByCourse(Long coursId) {
        Cours cours = coursRepository.findById(coursId)
                .orElseThrow(() -> new RuntimeException("Course not found"));

        return commentRepository.findByCours(cours);
    }
}