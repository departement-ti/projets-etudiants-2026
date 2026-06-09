package com.tmazzacademy.tmazzacademy.service;

import com.tmazzacademy.tmazzacademy.model.MonthlyPayment;
import com.tmazzacademy.tmazzacademy.model.Student;
import com.tmazzacademy.tmazzacademy.repository.MonthlyPaymentRepository;
import com.tmazzacademy.tmazzacademy.repository.StudentRepository;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
public class MonthlyPaymentService {

    private final MonthlyPaymentRepository paymentRepository;
    private final StudentRepository studentRepository;
    private final NotificationService notificationService;

    public MonthlyPaymentService(
            MonthlyPaymentRepository paymentRepository,
            StudentRepository studentRepository,
            NotificationService notificationService
    ) {
        this.paymentRepository = paymentRepository;
        this.studentRepository = studentRepository;
        this.notificationService = notificationService;
    }

    public MonthlyPayment uploadPayment(
            Long studentId,
            MultipartFile image
    ) {

        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("Student not found"));

        LocalDate now = LocalDate.now();

        int month = now.getMonthValue();
        int year = now.getYear();

        if (paymentRepository.findByStudentAndMonthAndYear(student, month, year).isPresent()) {
            throw new RuntimeException("You already uploaded payment receipt for this month");
        }

        try {
            String uploadDir =
                    System.getProperty("user.dir")
                            + File.separator
                            + "uploads"
                            + File.separator
                            + "monthly-payments"
                            + File.separator;

            new File(uploadDir).mkdirs();

            String fileName =
                    UUID.randomUUID()
                            + "_"
                            + image.getOriginalFilename();

            File file = new File(uploadDir + fileName);

            image.transferTo(file);

            MonthlyPayment payment = new MonthlyPayment();

            payment.setStudent(student);
            payment.setMonth(month);
            payment.setYear(year);
            payment.setStatus("PENDING");
            payment.setImagePath("uploads/monthly-payments/" + fileName);

            MonthlyPayment saved = paymentRepository.save(payment);

            notificationService.createNotification(
                    "New Monthly Payment",
                    student.getName() + " " + student.getLastname() + " uploaded monthly payment receipt",
                    "ADMIN",
                    null
            );

            return saved;

        } catch (Exception e) {
            throw new RuntimeException("Error uploading payment image");
        }
    }

    public List<MonthlyPayment> getStudentPayments(Long studentId) {

        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("Student not found"));

        return paymentRepository.findByStudentOrderByUploadedAtDesc(student);
    }

    public List<MonthlyPayment> getAllPayments() {
        return paymentRepository.findAllByOrderByUploadedAtDesc();
    }

    public MonthlyPayment acceptPayment(Long id) {

        MonthlyPayment payment = paymentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Payment not found"));

        payment.setStatus("ACCEPTED");

        return paymentRepository.save(payment);
    }

    public MonthlyPayment rejectPayment(Long id) {

        MonthlyPayment payment = paymentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Payment not found"));

        payment.setStatus("REJECTED");

        return paymentRepository.save(payment);
    }
}