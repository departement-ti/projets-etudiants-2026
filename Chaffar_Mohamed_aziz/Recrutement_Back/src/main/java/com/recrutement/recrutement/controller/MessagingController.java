package com.recrutement.recrutement.controller;

import com.recrutement.recrutement.dto.ConversationMessageRequest;
import com.recrutement.recrutement.dto.ConversationMessageResponse;
import com.recrutement.recrutement.dto.ConversationSummaryResponse;
import com.recrutement.recrutement.dto.MessageResponse;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.service.MessagingService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/messages")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class MessagingController {
    private final MessagingService messagingService;

    @GetMapping("/conversations")
    public ResponseEntity<List<ConversationSummaryResponse>> getConversations(Authentication authentication) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(messagingService.getConversations(currentUser));
    }

    @GetMapping("/conversations/{applicationId}")
    public ResponseEntity<List<ConversationMessageResponse>> getConversationMessages(
            Authentication authentication,
            @PathVariable Long applicationId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(messagingService.getConversationMessages(currentUser, applicationId));
    }

    @PostMapping("/conversations/{applicationId}")
    public ResponseEntity<ConversationMessageResponse> sendMessage(
            Authentication authentication,
            @PathVariable Long applicationId,
            @RequestBody ConversationMessageRequest request
    ) {
        User currentUser = (User) authentication.getPrincipal();
        return ResponseEntity.ok(messagingService.sendMessage(currentUser, applicationId, request.getContent()));
    }

    @PostMapping("/conversations/{applicationId}/mark-read")
    public ResponseEntity<MessageResponse> markConversationAsRead(
            Authentication authentication,
            @PathVariable Long applicationId
    ) {
        User currentUser = (User) authentication.getPrincipal();
        messagingService.markConversationAsRead(currentUser, applicationId);
        return ResponseEntity.ok(new MessageResponse(true, "Conversation marquee comme lue."));
    }
}
