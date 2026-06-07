package com.recrutement.recrutement.entities;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Temporal;
import jakarta.persistence.TemporalType;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AiTest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "application_id")
    private Candidature application;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "job_offer_id")
    private Offre jobOffer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "candidate_id")
    private Candidate candidate;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recruiter_id")
    private Recruiter recruiter;

    @Column(columnDefinition = "TEXT")
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    private Integer numberOfQuestions;

    private Double passingScore;

    private Integer totalDurationSeconds;

    @Column(length = 64)
    private String difficulty;

    private Boolean allowPreviousQuestion;

    @Column(columnDefinition = "TEXT")
    private String evaluationSkillsJson;

    @Column(length = 64)
    private String status;

    private Double threshold;

    private Integer durationMinutes;

    private Double score;

    @Column(columnDefinition = "TEXT")
    private String report;

    @Column(length = 64)
    private String recommendation;

    @Column(columnDefinition = "TEXT")
    private String proposedRejectionEmail;

    @Temporal(TemporalType.TIMESTAMP)
    private Date createdAt;

    @Temporal(TemporalType.TIMESTAMP)
    private Date startedAt;

    @Temporal(TemporalType.TIMESTAMP)
    private Date expiresAt;

    @Temporal(TemporalType.TIMESTAMP)
    private Date submittedAt;

    @Temporal(TemporalType.TIMESTAMP)
    private Date completedAt;

    @Temporal(TemporalType.TIMESTAMP)
    private Date updatedAt;

    @Column(columnDefinition = "TEXT")
    private String closedReason;

    private Boolean cheatingSuspicion;

    private Integer tabSwitchCount;

    private Integer warningCount;

    @OneToMany(mappedBy = "aiTest", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("id ASC")
    @Builder.Default
    private List<AiQuestion> questions = new ArrayList<>();

    @OneToMany(mappedBy = "aiTest", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("id ASC")
    @Builder.Default
    private List<AiAnswer> answers = new ArrayList<>();

    @OneToOne(mappedBy = "aiTest", cascade = CascadeType.ALL, orphanRemoval = true)
    private AiTestResult result;
}
