package com.tmazzacademy.tmazzacademy.controller;

import com.tmazzacademy.tmazzacademy.model.Certificate;
import com.tmazzacademy.tmazzacademy.model.TestResult;
import com.tmazzacademy.tmazzacademy.repository.CertificateRepository;
import com.tmazzacademy.tmazzacademy.repository.TestResultRepository;

import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/dashboard")
@CrossOrigin(origins = "http://localhost:4200")
public class DashboardController {

    private final TestResultRepository testResultRepository;
    private final CertificateRepository certificateRepository;

    public DashboardController(
            TestResultRepository testResultRepository,
            CertificateRepository certificateRepository
    ) {
        this.testResultRepository = testResultRepository;
        this.certificateRepository = certificateRepository;
    }

    @GetMapping("/instructor/{instructorId}/passed-students")
    public List<TestResult> getInstructorPassedStudents(@PathVariable Long instructorId) {
        return testResultRepository.findByCoursInstructorIdAndSuccessTrue(instructorId);
    }

    @GetMapping("/instructor/{instructorId}/failed-students")
    public List<TestResult> getInstructorFailedStudents(@PathVariable Long instructorId) {
        return testResultRepository.findByCoursInstructorIdAndSuccessFalse(instructorId);
    }

    @GetMapping("/admin/passed-students")
    public List<TestResult> getAllPassedStudents() {
        return testResultRepository.findBySuccessTrue();
    }

    @GetMapping("/instructor/{instructorId}/passed-chart")
    public Map<String, Long> getInstructorPassedChart(@PathVariable Long instructorId) {

        List<TestResult> results =
                testResultRepository.findByCoursInstructorIdAndSuccessTrue(instructorId);

        return results.stream()
                .filter(r -> r.getPassedAt() != null)
                .collect(Collectors.groupingBy(
                        r -> r.getPassedAt().getMonth().toString(),
                        LinkedHashMap::new,
                        Collectors.counting()
                ));
    }

    @GetMapping("/admin/certificates-chart")
    public Map<String, Long> getCertificatesChart() {

        List<Certificate> certificates = certificateRepository.findAll();

        return certificates.stream()
                .filter(c -> c.getCreatedAt() != null)
                .collect(Collectors.groupingBy(
                        c -> c.getCreatedAt().getMonth().toString(),
                        LinkedHashMap::new,
                        Collectors.counting()
                ));
    }

    @GetMapping("/admin/active-instructors-chart")
    public Map<String, Long> getActiveInstructorsChart() {

        List<TestResult> results = testResultRepository.findBySuccessTrue();

        return results.stream()
                .filter(r -> r.getPassedAt() != null)
                .filter(r -> r.getCours() != null)
                .filter(r -> r.getCours().getInstructor() != null)
                .collect(Collectors.groupingBy(
                        r -> r.getPassedAt().getMonth().toString(),
                        LinkedHashMap::new,
                        Collectors.mapping(
                                r -> r.getCours().getInstructor().getId(),
                                Collectors.collectingAndThen(Collectors.toSet(), set -> (long) set.size())
                        )
                ));
    }
}