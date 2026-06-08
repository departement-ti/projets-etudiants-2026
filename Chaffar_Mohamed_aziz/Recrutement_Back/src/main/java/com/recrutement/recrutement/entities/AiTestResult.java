package com.recrutement.recrutement.entities;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
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
public class AiTestResult {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ai_test_id", unique = true)
    @OnDelete(action = OnDeleteAction.CASCADE)
    private AiTest aiTest;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "application_id")
    @OnDelete(action = OnDeleteAction.CASCADE)
    private Candidature candidature;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "candidate_id")
    @OnDelete(action = OnDeleteAction.CASCADE)
    private Candidate candidate;

    @Temporal(TemporalType.TIMESTAMP)
    private java.util.Date startedAt;

    @Temporal(TemporalType.TIMESTAMP)
    private java.util.Date submittedAt;

    @Temporal(TemporalType.TIMESTAMP)
    private java.util.Date createdAt;

    @Temporal(TemporalType.TIMESTAMP)
    private java.util.Date updatedAt;

    @Temporal(TemporalType.TIMESTAMP)
    private java.util.Date currentQuestionStartedAt;

    @Temporal(TemporalType.TIMESTAMP)
    private java.util.Date currentQuestionExpiresAt;

    private Integer currentQuestionIndex;

    private Double score;

    @Column(length = 64)
    private String status;

    @Column(columnDefinition = "TEXT")
    private String closedReason;

    private Double globalScore;

    @Column(columnDefinition = "TEXT")
    private String strengths;

    @Column(columnDefinition = "TEXT")
    private String weaknesses;

    @Column(length = 64)
    private String recommendation;

    @Column(columnDefinition = "TEXT")
    private String generatedReport;
}
