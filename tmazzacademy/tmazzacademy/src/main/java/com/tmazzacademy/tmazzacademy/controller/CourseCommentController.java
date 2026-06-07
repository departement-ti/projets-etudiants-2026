package com.tmazzacademy.tmazzacademy.controller;

import com.tmazzacademy.tmazzacademy.model.CourseComment;
import com.tmazzacademy.tmazzacademy.service.CourseCommentService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/comments")
@CrossOrigin(origins = "http://localhost:4200")
public class CourseCommentController {

    private final CourseCommentService commentService;

    public CourseCommentController(CourseCommentService commentService) {
        this.commentService = commentService;
    }

    @PostMapping("/student/{studentId}/course/{coursId}")
    public CourseComment addComment(
            @PathVariable Long studentId,
            @PathVariable Long coursId,
            @RequestBody CourseComment comment
    ) {
        return commentService.addComment(studentId, coursId, comment);
    }

    @GetMapping("/course/{coursId}")
    public List<CourseComment> getCommentsByCourse(@PathVariable Long coursId) {
        return commentService.getCommentsByCourse(coursId);
    }
}