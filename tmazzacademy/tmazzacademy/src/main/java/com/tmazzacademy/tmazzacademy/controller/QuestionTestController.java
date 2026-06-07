package com.tmazzacademy.tmazzacademy.controller;

import com.tmazzacademy.tmazzacademy.model.QuestionTest;
import com.tmazzacademy.tmazzacademy.service.QuestionTestService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/questions")
@CrossOrigin(origins = "http://localhost:4200")
public class QuestionTestController {

    private final QuestionTestService questionService;

    public QuestionTestController(QuestionTestService questionService) {
        this.questionService = questionService;
    }

    @PostMapping("/course/{coursId}")
    public QuestionTest addQuestion(
            @PathVariable Long coursId,
            @RequestBody QuestionTest question
    ) {
        return questionService.addQuestion(coursId, question);
    }

    @GetMapping("/course/{coursId}")
    public List<QuestionTest> getQuestionsByCourse(@PathVariable Long coursId) {
        return questionService.getQuestionsByCourse(coursId);
    }

    @PutMapping("/{id}")
    public QuestionTest updateQuestion(
            @PathVariable Long id,
            @RequestBody QuestionTest question
    ) {
        return questionService.updateQuestion(id, question);
    }

    @DeleteMapping("/{id}")
    public void deleteQuestion(@PathVariable Long id) {
        questionService.deleteQuestion(id);
    }
}