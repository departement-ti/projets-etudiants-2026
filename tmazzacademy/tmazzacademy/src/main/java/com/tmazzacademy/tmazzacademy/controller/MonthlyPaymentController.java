package com.tmazzacademy.tmazzacademy.controller;

import com.tmazzacademy.tmazzacademy.model.MonthlyPayment;
import com.tmazzacademy.tmazzacademy.service.MonthlyPaymentService;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/monthly-payments")
@CrossOrigin(origins = "http://localhost:4200")
public class MonthlyPaymentController {

    private final MonthlyPaymentService paymentService;

    public MonthlyPaymentController(MonthlyPaymentService paymentService) {
        this.paymentService = paymentService;
    }

    @PostMapping("/student/{studentId}")
    public MonthlyPayment uploadPayment(
            @PathVariable Long studentId,
            @RequestParam("image") MultipartFile image
    ) {
        return paymentService.uploadPayment(studentId, image);
    }

    @GetMapping("/student/{studentId}")
    public List<MonthlyPayment> getStudentPayments(
            @PathVariable Long studentId
    ) {
        return paymentService.getStudentPayments(studentId);
    }

    @GetMapping
    public List<MonthlyPayment> getAllPayments() {
        return paymentService.getAllPayments();
    }

    @PutMapping("/{id}/accept")
    public MonthlyPayment acceptPayment(@PathVariable Long id) {
        return paymentService.acceptPayment(id);
    }

    @PutMapping("/{id}/reject")
    public MonthlyPayment rejectPayment(@PathVariable Long id) {
        return paymentService.rejectPayment(id);
    }
}