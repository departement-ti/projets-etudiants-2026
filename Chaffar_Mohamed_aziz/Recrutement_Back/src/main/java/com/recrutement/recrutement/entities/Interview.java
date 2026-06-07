package com.recrutement.recrutement.entities;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Temporal;
import jakarta.persistence.TemporalType;
import java.util.Date;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Interview {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "candidature_id")
    private Candidature candidature;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recruiter_id")
    private Recruiter recruiter;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "candidate_id")
    private Candidate candidate;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "offre_id")
    private Offre offre;

    @Temporal(TemporalType.TIMESTAMP)
    private Date interviewDateTime;

    private Integer durationMinutes;

    @Enumerated(EnumType.STRING)
    private InterviewType interviewType;

    @Enumerated(EnumType.STRING)
    private InterviewMode mode;

    @Column(columnDefinition = "TEXT")
    private String meetingLink;

    @Column(columnDefinition = "TEXT")
    private String location;

    @Column(columnDefinition = "TEXT")
    private String invitationMessage;

    @Column(columnDefinition = "TEXT")
    private String aiSuggestedQuestionsJson;

    @Enumerated(EnumType.STRING)
    private InterviewStatus status;

    private Boolean reminder24hSent;

    private Boolean reminder1hSent;

    @Enumerated(EnumType.STRING)
    private AttendanceStatus attendanceStatus;

    @Temporal(TemporalType.TIMESTAMP)
    private Date absenceCheckedAt;

    @Temporal(TemporalType.TIMESTAMP)
    private Date createdAt;

    @Temporal(TemporalType.TIMESTAMP)
    private Date updatedAt;

    @PrePersist
    void prePersist() {
        Date now = new Date();
        if (createdAt == null) {
            createdAt = now;
        }
        updatedAt = now;
        if (status == null) {
            status = InterviewStatus.PLANNED;
        }
        if (attendanceStatus == null) {
            attendanceStatus = AttendanceStatus.UNKNOWN;
        }
        if (reminder24hSent == null) {
            reminder24hSent = Boolean.FALSE;
        }
        if (reminder1hSent == null) {
            reminder1hSent = Boolean.FALSE;
        }
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = new Date();
    }
}
