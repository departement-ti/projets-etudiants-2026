package com.rayhan.erp.service;

import com.rayhan.erp.model.ERole;
import com.rayhan.erp.model.Notification;
import com.rayhan.erp.model.Notification.TypeNotif;
import com.rayhan.erp.model.User;
import com.rayhan.erp.repository.NotificationRepository;
import com.rayhan.erp.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class NotificationService {

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private UserRepository userRepository;

    public Notification create(Long userId, TypeNotif type, Long referenceId, String message) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) return null;
        Notification notif = new Notification(user, type, referenceId, message);
        return notificationRepository.save(notif);
    }

    public void notifyStaff(ERole role, TypeNotif type, Long referenceId, String message) {
        List<User> staff = userRepository.findByRole(role);
        for (User u : staff) {
            create(u.getId(), type, referenceId, message);
        }
    }

    public List<Notification> getUnread(Long userId) {
        return notificationRepository.findByUserIdAndLuFalseOrderByCreatedAtDesc(userId);
    }

    public long getUnreadCount(Long userId) {
        return notificationRepository.countByUserIdAndLuFalse(userId);
    }

    public List<Notification> getAll(Long userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public void markAsRead(Long id) {
        notificationRepository.findById(id).ifPresent(n -> {
            n.setLu(true);
            notificationRepository.save(n);
        });
    }

    public void markAllAsRead(Long userId) {
        List<Notification> unread = notificationRepository.findByUserIdAndLuFalseOrderByCreatedAtDesc(userId);
        for (Notification n : unread) {
            n.setLu(true);
        }
        notificationRepository.saveAll(unread);
    }
}
