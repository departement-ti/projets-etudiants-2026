package com.tmazzacademy.tmazzacademy.repository;

import com.tmazzacademy.tmazzacademy.model.MonthlyPayment;
import com.tmazzacademy.tmazzacademy.model.Student;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MonthlyPaymentRepository extends JpaRepository<MonthlyPayment, Long> {

    List<MonthlyPayment> findByStudentOrderByUploadedAtDesc(Student student);

    List<MonthlyPayment> findAllByOrderByUploadedAtDesc();

    Optional<MonthlyPayment> findByStudentAndMonthAndYear(
            Student student,
            int month,
            int year
    );
}