package com.tmazzacademy.tmazzacademy.controller;

import com.tmazzacademy.tmazzacademy.dto.ChatRequestDTO;
import com.tmazzacademy.tmazzacademy.service.GeminiService;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/chatbot")
@CrossOrigin(origins = "http://localhost:4200")
public class ChatbotController {

    private final GeminiService geminiService;

    public ChatbotController(GeminiService geminiService) {
        this.geminiService = geminiService;
    }

    @PostMapping
    public String chat(@RequestBody ChatRequestDTO dto) {

        String prompt;

        if ("STUDENT".equals(dto.getRole())) {

            prompt = """
            You are a helpful e-learning assistant for students.

            Help students:
            - choose courses
            - understand certificates
            - understand tests
            - answer learning questions

            Student message:
            """ + dto.getMessage();

        } else if ("INSTRUCTOR".equals(dto.getRole())) {

            prompt = """
            You are an assistant for instructors.

            Help instructors:
            - write course descriptions
            - generate quiz questions
            - improve course quality
            - suggest learning plans

            Instructor message:
            """ + dto.getMessage();

        } else {

            prompt = dto.getMessage();
        }

        return geminiService.askGemini(prompt);
    }
}