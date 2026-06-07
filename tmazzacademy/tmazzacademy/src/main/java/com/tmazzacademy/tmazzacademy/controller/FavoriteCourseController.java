package com.tmazzacademy.tmazzacademy.controller;

import com.tmazzacademy.tmazzacademy.model.FavoriteCourse;
import com.tmazzacademy.tmazzacademy.service.FavoriteCourseService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/favorites")
@CrossOrigin(origins = "http://localhost:4200")
public class FavoriteCourseController {

    private final FavoriteCourseService favoriteService;

    public FavoriteCourseController(FavoriteCourseService favoriteService) {
        this.favoriteService = favoriteService;
    }

    @PostMapping("/student/{studentId}/course/{coursId}")
    public FavoriteCourse addFavorite(
            @PathVariable Long studentId,
            @PathVariable Long coursId
    ) {
        return favoriteService.addFavorite(studentId, coursId);
    }

    @DeleteMapping("/student/{studentId}/course/{coursId}")
    public void removeFavorite(
            @PathVariable Long studentId,
            @PathVariable Long coursId
    ) {
        favoriteService.removeFavorite(studentId, coursId);
    }

    @GetMapping("/student/{studentId}")
    public List<FavoriteCourse> getStudentFavorites(@PathVariable Long studentId) {
        return favoriteService.getStudentFavorites(studentId);
    }

    @GetMapping("/student/{studentId}/course/{coursId}/check")
    public boolean isFavorite(
            @PathVariable Long studentId,
            @PathVariable Long coursId
    ) {
        return favoriteService.isFavorite(studentId, coursId);
    }
}