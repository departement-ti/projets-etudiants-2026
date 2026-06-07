package com.recrutement.recrutement.repositories;

import com.recrutement.recrutement.entities.Notification;
import com.recrutement.recrutement.entities.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {
    List<Notification> findByUserOrderByDateEnvoiDesc(User user);

    long countByUserAndLueFalse(User user);

    void deleteByUser(User user);
}
