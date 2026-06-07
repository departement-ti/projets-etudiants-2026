package com.recrutement.recrutement.service.Impl;

import com.recrutement.recrutement.dto.NotificationResponse;
import com.recrutement.recrutement.entities.Notification;
import com.recrutement.recrutement.entities.Role;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.repositories.NotificationRepository;
import com.recrutement.recrutement.repositories.UserRepository;
import com.recrutement.recrutement.service.NotificationService;
import java.util.Date;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class NotificationServiceImpl implements NotificationService {
    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    public NotificationServiceImpl(NotificationRepository notificationRepository, UserRepository userRepository) {
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
    }

    @Override
    public void notifyUser(User user, String message) {
        if (user == null || message == null || message.isBlank()) {
            return;
        }

        Notification notification = Notification.builder()
                .message(message)
                .dateEnvoi(new Date())
                .lue(false)
                .user(user)
                .build();

        notificationRepository.save(notification);
    }

    @Override
    public void notifyAdmins(String message) {
        List<User> admins = userRepository.findAllByRole(Role.ADMIN);
        for (User admin : admins) {
            notifyUser(admin, message);
        }
    }

    @Override
    public List<NotificationResponse> getNotificationsForUser(String userEmail) {
        User user = getUserByEmail(userEmail);
        return notificationRepository.findByUserOrderByDateEnvoiDesc(user).stream()
                .map(notification ->
                        new NotificationResponse(
                                notification.getId(),
                                notification.getMessage(),
                                notification.getDateEnvoi(),
                                notification.isLue()
                        )
                )
                .collect(Collectors.toList());
    }

    @Override
    public long getUnreadCount(String userEmail) {
        User user = getUserByEmail(userEmail);
        return notificationRepository.countByUserAndLueFalse(user);
    }

    @Override
    public void markAllAsRead(String userEmail) {
        User user = getUserByEmail(userEmail);
        List<Notification> notifications = notificationRepository.findByUserOrderByDateEnvoiDesc(user);
        for (Notification notification : notifications) {
            if (!notification.isLue()) {
                notification.setLue(true);
            }
        }
        notificationRepository.saveAll(notifications);
    }

    @Override
    public void markAsRead(String userEmail, Long notificationId) {
        User user = getUserByEmail(userEmail);
        Optional<Notification> notification = notificationRepository.findById(notificationId);
        if (notification.isEmpty()) {
            return;
        }
        Notification target = notification.get();
        if (target.getUser() != null && target.getUser().getId().equals(user.getId())) {
            target.setLue(true);
            notificationRepository.save(target);
        }
    }

    @Override
    @Transactional
    public void clearNotificationsForUser(User user) {
        if (user == null) {
            return;
        }

        notificationRepository.deleteByUser(user);
    }

    private User getUserByEmail(String userEmail) {
        return userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouve."));
    }
}
