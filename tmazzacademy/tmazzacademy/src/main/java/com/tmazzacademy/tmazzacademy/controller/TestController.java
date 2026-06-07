package com.tmazzacademy.tmazzacademy.controller;

import com.tmazzacademy.tmazzacademy.dto.SubmitTestDTO;
import com.tmazzacademy.tmazzacademy.dto.TestStatusDTO;
import com.tmazzacademy.tmazzacademy.model.TestResult;
import com.tmazzacademy.tmazzacademy.service.TestService;

import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tests")
@CrossOrigin(origins = "http://localhost:4200")
public class TestController {

    private final TestService testService;

    public TestController(TestService testService) {
        this.testService = testService;
    }

    @PostMapping("/student/{studentId}/course/{coursId}")
    public TestResult submitTest(
            @PathVariable Long studentId,
            @PathVariable Long coursId,
            @RequestBody SubmitTestDTO dto
    ) {
        return testService.submitTest(studentId, coursId, dto);
    }

    @GetMapping("/student/{studentId}/course/{coursId}/status")
    public TestStatusDTO getTestStatus(
            @PathVariable Long studentId,
            @PathVariable Long coursId
    ) {
        return testService.getTestStatus(studentId, coursId);
    }

    @GetMapping("/student/{studentId}")
    public List<TestResult> getStudentResults(
            @PathVariable Long studentId
    ) {
        return testService.getStudentResults(studentId);
    }
}