package com.tmazzacademy.tmazzacademy.service;

import com.tmazzacademy.tmazzacademy.model.Cours;
import com.tmazzacademy.tmazzacademy.model.QuestionTest;
import com.tmazzacademy.tmazzacademy.repository.CoursRepository;
import com.tmazzacademy.tmazzacademy.repository.QuestionTestRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class QuestionTestService {

    private final QuestionTestRepository questionRepository;
    private final CoursRepository coursRepository;

    public QuestionTestService(
            QuestionTestRepository questionRepository,
            CoursRepository coursRepository
    ) {
        this.questionRepository = questionRepository;
        this.coursRepository = coursRepository;
    }

    public QuestionTest addQuestion(Long coursId, QuestionTest question) {
        Cours cours = coursRepository.findById(coursId)
                .orElseThrow(() -> new RuntimeException("Course not found"));

        question.setCours(cours);

        return questionRepository.save(question);
    }

    public List<QuestionTest> getQuestionsByCourse(Long coursId) {
        Cours cours = coursRepository.findById(coursId)
                .orElseThrow(() -> new RuntimeException("Course not found"));

        return questionRepository.findByCours(cours);
    }

    public QuestionTest updateQuestion(Long id, QuestionTest updated) {
        QuestionTest question = questionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Question not found"));

        question.setQuestion(updated.getQuestion());
        question.setOptionA(updated.getOptionA());
        question.setOptionB(updated.getOptionB());
        question.setOptionC(updated.getOptionC());
        question.setOptionD(updated.getOptionD());
        question.setCorrectAnswer(updated.getCorrectAnswer());

        return questionRepository.save(question);
    }

    public void deleteQuestion(Long id) {
        questionRepository.deleteById(id);
    }
}