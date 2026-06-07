package com.tmazzacademy.tmazzacademy.service;

import com.tmazzacademy.tmazzacademy.model.Cours;
import com.tmazzacademy.tmazzacademy.model.FavoriteCourse;
import com.tmazzacademy.tmazzacademy.model.Student;
import com.tmazzacademy.tmazzacademy.repository.CoursRepository;
import com.tmazzacademy.tmazzacademy.repository.FavoriteCourseRepository;
import com.tmazzacademy.tmazzacademy.repository.StudentRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class FavoriteCourseService {

    private final FavoriteCourseRepository favoriteRepository;
    private final StudentRepository studentRepository;
    private final CoursRepository coursRepository;

    public FavoriteCourseService(
            FavoriteCourseRepository favoriteRepository,
            StudentRepository studentRepository,
            CoursRepository coursRepository
    ) {
        this.favoriteRepository = favoriteRepository;
        this.studentRepository = studentRepository;
        this.coursRepository = coursRepository;
    }

    public FavoriteCourse addFavorite(Long studentId, Long coursId) {

        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("Student not found"));

        Cours cours = coursRepository.findById(coursId)
                .orElseThrow(() -> new RuntimeException("Course not found"));

        if (!cours.isActive()) {
            throw new RuntimeException("Cannot add inactive course to favorites");
        }

        if (favoriteRepository.existsByStudentAndCours(student, cours)) {
            throw new RuntimeException("Course already in favorites");
        }

        FavoriteCourse favorite = new FavoriteCourse();
        favorite.setStudent(student);
        favorite.setCours(cours);

        return favoriteRepository.save(favorite);
    }

    public void removeFavorite(Long studentId, Long coursId) {

        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("Student not found"));

        Cours cours = coursRepository.findById(coursId)
                .orElseThrow(() -> new RuntimeException("Course not found"));

        FavoriteCourse favorite = favoriteRepository.findByStudentAndCours(student, cours)
                .orElseThrow(() -> new RuntimeException("Favorite not found"));

        favoriteRepository.delete(favorite);
    }

    public List<FavoriteCourse> getStudentFavorites(Long studentId) {

        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("Student not found"));

        return favoriteRepository.findByStudentAndCoursActiveTrue(student);
    }

    public boolean isFavorite(Long studentId, Long coursId) {

        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("Student not found"));

        Cours cours = coursRepository.findById(coursId)
                .orElseThrow(() -> new RuntimeException("Course not found"));

        if (!cours.isActive()) {
            return false;
        }

        return favoriteRepository.existsByStudentAndCours(student, cours);
    }
}