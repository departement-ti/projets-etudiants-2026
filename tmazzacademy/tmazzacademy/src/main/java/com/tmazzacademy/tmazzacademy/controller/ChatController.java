package com.tmazzacademy.tmazzacademy.controller;

import com.tmazzacademy.tmazzacademy.model.ChatMessage;
import com.tmazzacademy.tmazzacademy.service.ChatService;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/chat")
@CrossOrigin(origins = "http://localhost:4200")
public class ChatController {

    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @GetMapping("/messages")
    public List<ChatMessage> getMessages() {
        return chatService.getMessages();
    }

    @PostMapping("/text")
    public ChatMessage sendText(@RequestBody Map<String, Object> body) {
        return chatService.sendText(
                body.get("content").toString(),
                Long.valueOf(body.get("senderId").toString()),
                body.get("senderName").toString(),
                body.get("senderRole").toString()
        );
    }

    @PostMapping("/image")
    public ChatMessage sendImage(
            @RequestParam("image") MultipartFile image,
            @RequestParam Long senderId,
            @RequestParam String senderName,
            @RequestParam String senderRole
    ) {
        return chatService.sendImage(
                image,
                senderId,
                senderName,
                senderRole
        );
    }

    @PostMapping("/poll")
    public ChatMessage createPoll(@RequestBody Map<String, Object> body) {
        return chatService.createPoll(
                body.get("question").toString(),
                (List<String>) body.get("options"),
                Long.valueOf(body.get("senderId").toString()),
                body.get("senderName").toString(),
                body.get("senderRole").toString()
        );
    }

    @PostMapping("/poll/{messageId}/vote/{optionId}/user/{userId}")
    public ChatMessage vote(
            @PathVariable Long messageId,
            @PathVariable Long optionId,
            @PathVariable Long userId
    ) {
        return chatService.vote(messageId, optionId, userId);
    }
}