package com.recrutement.recrutement.controller;

import com.recrutement.recrutement.dto.ContactMessageRequest;
import com.recrutement.recrutement.dto.ContactMessageResponse;
import com.recrutement.recrutement.service.ContactMessageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/contact")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ContactController {
    private final ContactMessageService contactMessageService;

    @PostMapping
    public ResponseEntity<ContactMessageResponse> submit(@RequestBody ContactMessageRequest request) {
        return ResponseEntity.ok(contactMessageService.submit(request));
    }
}
