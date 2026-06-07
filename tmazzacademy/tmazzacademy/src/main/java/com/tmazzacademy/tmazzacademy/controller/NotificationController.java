package com.tmazzacademy.tmazzacademy.controller;

import com.tmazzacademy.tmazzacademy.model.Notification;
import com.tmazzacademy.tmazzacademy.service.NotificationService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
@CrossOrigin(origins = "http://localhost:4200")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @GetMapping("/role/{role}")
    public List<Notification> getByRole(@PathVariable String role) {
        return notificationService.getByRole(role);
    }

    @GetMapping("/user/{userId}")
    public List<Notification> getByUser(@PathVariable Long userId) {
        return notificationService.getByUser(userId);
    }
}