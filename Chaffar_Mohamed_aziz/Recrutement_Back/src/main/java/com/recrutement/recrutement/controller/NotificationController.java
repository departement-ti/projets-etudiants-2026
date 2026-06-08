package com.recrutement.recrutement.controller;

import com.recrutement.recrutement.dto.NotificationResponse;
import com.recrutement.recrutement.service.NotificationService;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class NotificationController {
    private final NotificationService notificationService;

    @GetMapping
    public ResponseEntity<List<NotificationResponse>> getNotifications() {
        String email = getCurrentUserEmail();
        return ResponseEntity.ok(notificationService.getNotificationsForUser(email));
    }

    @GetMapping("/unread-count")
    public ResponseEntity<Map<String, Long>> getUnreadCount() {
        String email = getCurrentUserEmail();
        long count = notificationService.getUnreadCount(email);
        return ResponseEntity.ok(Map.of("count", count));
    }

    @PostMapping("/mark-read")
    public ResponseEntity<Void> markAllRead() {
        String email = getCurrentUserEmail();
        notificationService.markAllAsRead(email);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{id}/read")
    public ResponseEntity<Void> markRead(@PathVariable Long id) {
        String email = getCurrentUserEmail();
        notificationService.markAsRead(email, id);
        return ResponseEntity.ok().build();
    }

    private String getCurrentUserEmail() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getName() == null) {
            throw new RuntimeException("Utilisateur non authentifie.");
        }
        return authentication.getName();
    }
}
