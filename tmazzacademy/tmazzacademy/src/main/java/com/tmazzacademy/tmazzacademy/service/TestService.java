package com.tmazzacademy.tmazzacademy.service;

import com.tmazzacademy.tmazzacademy.dto.SubmitTestDTO;
import com.tmazzacademy.tmazzacademy.dto.TestStatusDTO;
import com.tmazzacademy.tmazzacademy.model.*;
import com.tmazzacademy.tmazzacademy.repository.*;

import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class TestService {

    private static final int PASS_SCORE = 10;
    private static final int RETRY_HOURS = 24;

    private final QuestionTestRepository questionRepository;
    private final TestResultRepository resultRepository;
    private final StudentRepository studentRepository;
    private final CoursRepository coursRepository;
    private final CertificateRepository certificateRepository;
    private final TestAttemptRepository testAttemptRepository;
    private final NotificationService notificationService;

    public TestService(
            QuestionTestRepository questionRepository,
            TestResultRepository resultRepository,
            StudentRepository studentRepository,
            CoursRepository coursRepository,
            CertificateRepository certificateRepository,
            TestAttemptRepository testAttemptRepository,
            NotificationService notificationService
    ) {
        this.questionRepository = questionRepository;
        this.resultRepository = resultRepository;
        this.studentRepository = studentRepository;
        this.coursRepository = coursRepository;
        this.certificateRepository = certificateRepository;
        this.testAttemptRepository = testAttemptRepository;
        this.notificationService = notificationService;
    }

    public TestResult submitTest(Long studentId, Long coursId, SubmitTestDTO dto) {

        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("Student not found"));

        Cours cours = coursRepository.findById(coursId)
                .orElseThrow(() -> new RuntimeException("Course not found"));

        TestStatusDTO status = getTestStatus(studentId, coursId);

        if (!status.isCanStart()) {
            throw new RuntimeException(status.getMessage());
        }

        List<QuestionTest> questions = questionRepository.findByCours(cours);

        if (questions.isEmpty()) {
            throw new RuntimeException("No questions found");
        }

        if (dto == null || dto.getAnswers() == null) {
            throw new RuntimeException("Answers are required");
        }

        int correctAnswers = 0;
        Map<Long, String> answers = dto.getAnswers();

        for (QuestionTest q : questions) {
            String studentAnswer = answers.get(q.getId());

            if (
                    studentAnswer != null &&
                    studentAnswer.equalsIgnoreCase(q.getCorrectAnswer())
            ) {
                correctAnswers++;
            }
        }

        double scoreOn20 = ((double) correctAnswers / questions.size()) * 20;
        int finalScore = (int) Math.round(scoreOn20);
        boolean passed = finalScore >= PASS_SCORE;

        TestAttempt attempt = new TestAttempt();
        attempt.setStudent(student);
        attempt.setCours(cours);
        attempt.setScore(finalScore);
        attempt.setPassed(passed);
        attempt.setAttemptedAt(LocalDateTime.now());

        testAttemptRepository.save(attempt);

        TestResult result = new TestResult();
        result.setStudent(student);
        result.setCours(cours);
        result.setScore(finalScore);

        TestResult savedResult = resultRepository.save(result);

        if (passed) {
            Certificate certificate = new Certificate();

            certificate.setStudent(student);
            certificate.setCours(cours);
            certificate.setStudentName(student.getName() + " " + student.getLastname());
            certificate.setCourseTitle(cours.getTitre());
            certificate.setScore(finalScore);

            certificateRepository.save(certificate);

            notificationService.createNotification(
                    "Student Passed",
                    student.getName() + " " + student.getLastname()
                            + " passed your course: "
                            + cours.getTitre()
                            + " with score "
                            + finalScore
                            + "/20",
                    "INSTRUCTOR",
                    cours.getInstructor().getId()
            );
        }

        return savedResult;
    }

    public TestStatusDTO getTestStatus(Long studentId, Long coursId) {

        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("Student not found"));

        Cours cours = coursRepository.findById(coursId)
                .orElseThrow(() -> new RuntimeException("Course not found"));

        if (testAttemptRepository.existsByStudentAndCoursAndPassedTrue(student, cours)) {
            return new TestStatusDTO(
                    false,
                    "You already passed this test.",
                    0,
                    0
            );
        }

        Optional<TestAttempt> lastAttemptOpt =
                testAttemptRepository.findFirstByStudentAndCoursOrderByAttemptedAtDesc(
                        student,
                        cours
                );

        if (lastAttemptOpt.isPresent()) {
            TestAttempt lastAttempt = lastAttemptOpt.get();

            if (!lastAttempt.isPassed()) {
                LocalDateTime nextAllowedTime =
                        lastAttempt.getAttemptedAt().plusHours(RETRY_HOURS);

                if (LocalDateTime.now().isBefore(nextAllowedTime)) {
                    long secondsLeft =
                            Duration.between(
                                    LocalDateTime.now(),
                                    nextAllowedTime
                            ).getSeconds();

                    return new TestStatusDTO(
                            false,
                            "You can retry after 24 hours.",
                            secondsLeft,
                            -1
                    );
                }
            }
        }

        return new TestStatusDTO(
                true,
                "You can start the test.",
                0,
                -1
        );
    }

    public List<TestResult> getStudentResults(Long studentId) {

        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("Student not found"));

        return resultRepository.findByStudent(student);
    }
}