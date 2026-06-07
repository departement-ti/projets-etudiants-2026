package com.tmazzacademy.tmazzacademy.service;

import com.tmazzacademy.tmazzacademy.model.Notification;
import com.tmazzacademy.tmazzacademy.repository.NotificationRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;

    public NotificationService(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    public Notification createNotification(
            String title,
            String message,
            String role,
            Long userId
    ) {
        Notification notification = new Notification();

        notification.setTitle(title);
        notification.setMessage(message);
        notification.setTargetRole(role);
        notification.setUserId(userId);

        return notificationRepository.save(notification);
    }

    public List<Notification> getByRole(String role) {
        return notificationRepository.findByTargetRoleOrderByCreatedAtDesc(role);
    }

    public List<Notification> getByUser(Long userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }
}