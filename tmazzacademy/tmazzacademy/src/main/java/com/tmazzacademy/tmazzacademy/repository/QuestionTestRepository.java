package com.tmazzacademy.tmazzacademy.repository;

import com.tmazzacademy.tmazzacademy.model.QuestionTest;
import com.tmazzacademy.tmazzacademy.model.Cours;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface QuestionTestRepository extends JpaRepository<QuestionTest, Long> {
    List<QuestionTest> findByCours(Cours cours);
}