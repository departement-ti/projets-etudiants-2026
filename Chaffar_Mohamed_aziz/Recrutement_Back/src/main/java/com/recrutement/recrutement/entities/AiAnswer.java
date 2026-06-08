package com.recrutement.recrutement.entities;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Temporal;
import jakarta.persistence.TemporalType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AiAnswer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ai_test_id")
    @OnDelete(action = OnDeleteAction.CASCADE)
    private AiTest aiTest;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "question_id")
    @OnDelete(action = OnDeleteAction.CASCADE)
    private AiQuestion question;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ai_test_result_id")
    @OnDelete(action = OnDeleteAction.CASCADE)
    private AiTestResult aiTestResult;

    @Column(columnDefinition = "TEXT")
    private String candidateAnswer;

    private Boolean correct;

    private Double pointsObtained;

    @Temporal(TemporalType.TIMESTAMP)
    private java.util.Date answeredAt;

    private Integer timeSpentSeconds;
}
