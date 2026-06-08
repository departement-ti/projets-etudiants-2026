package com.rayhan.erp.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(name = "notifications")
@Getter
@Setter
@NoArgsConstructor
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id")
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private TypeNotif type;

    private Long referenceId;

    @Column(nullable = false, length = 255)
    private String message;

    private boolean lu = false;

    @Column(nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public enum TypeNotif {
        ORDER_STATUS_CHANGED,
        NEW_ORDER_PENDING
    }

    public Notification(User user, TypeNotif type, Long referenceId, String message) {
        this.user = user;
        this.type = type;
        this.referenceId = referenceId;
        this.message = message;
    }
}
