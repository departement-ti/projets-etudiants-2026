package com.recrutement.recrutement.entities;

import jakarta.persistence.*;
import lombok.*;

import java.util.Date;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String message;

    @Temporal(TemporalType.TIMESTAMP)
    private Date dateEnvoi;

    private boolean lue;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;
}
