package com.recrutement.recrutement.service;

import com.recrutement.recrutement.dto.NotificationResponse;
import com.recrutement.recrutement.entities.User;
import java.util.List;

public interface NotificationService {
    void notifyUser(User user, String message);

    void notifyAdmins(String message);

    List<NotificationResponse> getNotificationsForUser(String userEmail);

    long getUnreadCount(String userEmail);

    void markAllAsRead(String userEmail);

    void markAsRead(String userEmail, Long notificationId);

    void clearNotificationsForUser(User user);
}
