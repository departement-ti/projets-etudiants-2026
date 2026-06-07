package com.tmazzacademy.tmazzacademy.controller;

import com.tmazzacademy.tmazzacademy.model.Cours;
import com.tmazzacademy.tmazzacademy.service.CoursService;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/cours")
@CrossOrigin(origins = "http://localhost:4200")
public class CoursController {

    private final CoursService coursService;

    public CoursController(CoursService coursService) {
        this.coursService = coursService;
    }

    @PostMapping("/instructor/{instructorId}")
    public Cours addCourse(
            @PathVariable Long instructorId,
            @RequestParam String titre,
            @RequestParam String description,
            @RequestParam MultipartFile video,
            @RequestParam MultipartFile pdf
    ) {
        return coursService.addCourse(instructorId, titre, description, video, pdf);
    }

    @GetMapping
    public List<Cours> getAllCourses() {
        return coursService.getAllCourses();
    }

    @GetMapping("/{id}")
    public Cours getCourseById(@PathVariable Long id) {
        return coursService.getCourseById(id);
    }

    @GetMapping("/instructor/{instructorId}")
    public List<Cours> getCoursesByInstructor(@PathVariable Long instructorId) {
        return coursService.getCoursesByInstructor(instructorId);
    }

    @GetMapping("/stats/instructor/{instructorId}")
    public Map<String, Long> getInstructorCourseStats(
            @PathVariable Long instructorId
    ) {
        return coursService.getInstructorCourseStats(instructorId);
    }

    @PutMapping("/{id}")
    public Cours updateCourse(
            @PathVariable Long id,
            @RequestBody Cours cours
    ) {
        return coursService.updateCourse(id, cours);
    }

    @DeleteMapping("/{id}")
    public void deleteCourse(@PathVariable Long id) {
        coursService.deleteCourse(id);
    }
}