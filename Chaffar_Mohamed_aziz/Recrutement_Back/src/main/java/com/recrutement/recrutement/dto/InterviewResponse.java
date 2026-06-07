package com.recrutement.recrutement.dto;

import java.util.ArrayList;
import java.util.List;

public class InterviewResponse {
    private Long id;
    private Long applicationId;
    private Long offerId;
    private Long candidateId;
    private Long recruiterId;
    private String candidateName;
    private String offerTitle;
    private String companyName;
    private String interviewDateTime;
    private Integer durationMinutes;
    private String interviewType;
    private String mode;
    private String meetingLink;
    private String location;
    private String invitationMessage;
    private List<String> aiSuggestedQuestions = new ArrayList<>();
    private String status;
    private Boolean reminder24hSent;
    private Boolean reminder1hSent;
    private String attendanceStatus;
    private String absenceCheckedAt;
    private String createdAt;
    private String updatedAt;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getApplicationId() {
        return applicationId;
    }

    public void setApplicationId(Long applicationId) {
        this.applicationId = applicationId;
    }

    public Long getOfferId() {
        return offerId;
    }

    public void setOfferId(Long offerId) {
        this.offerId = offerId;
    }

    public Long getCandidateId() {
        return candidateId;
    }

    public void setCandidateId(Long candidateId) {
        this.candidateId = candidateId;
    }

    public Long getRecruiterId() {
        return recruiterId;
    }

    public void setRecruiterId(Long recruiterId) {
        this.recruiterId = recruiterId;
    }

    public String getCandidateName() {
        return candidateName;
    }

    public void setCandidateName(String candidateName) {
        this.candidateName = candidateName;
    }

    public String getOfferTitle() {
        return offerTitle;
    }

    public void setOfferTitle(String offerTitle) {
        this.offerTitle = offerTitle;
    }

    public String getCompanyName() {
        return companyName;
    }

    public void setCompanyName(String companyName) {
        this.companyName = companyName;
    }

    public String getInterviewDateTime() {
        return interviewDateTime;
    }

    public void setInterviewDateTime(String interviewDateTime) {
        this.interviewDateTime = interviewDateTime;
    }

    public Integer getDurationMinutes() {
        return durationMinutes;
    }

    public void setDurationMinutes(Integer durationMinutes) {
        this.durationMinutes = durationMinutes;
    }

    public String getInterviewType() {
        return interviewType;
    }

    public void setInterviewType(String interviewType) {
        this.interviewType = interviewType;
    }

    public String getMode() {
        return mode;
    }

    public void setMode(String mode) {
        this.mode = mode;
    }

    public String getMeetingLink() {
        return meetingLink;
    }

    public void setMeetingLink(String meetingLink) {
        this.meetingLink = meetingLink;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public String getInvitationMessage() {
        return invitationMessage;
    }

    public void setInvitationMessage(String invitationMessage) {
        this.invitationMessage = invitationMessage;
    }

    public List<String> getAiSuggestedQuestions() {
        return aiSuggestedQuestions;
    }

    public void setAiSuggestedQuestions(List<String> aiSuggestedQuestions) {
        this.aiSuggestedQuestions = aiSuggestedQuestions;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Boolean getReminder24hSent() {
        return reminder24hSent;
    }

    public void setReminder24hSent(Boolean reminder24hSent) {
        this.reminder24hSent = reminder24hSent;
    }

    public Boolean getReminder1hSent() {
        return reminder1hSent;
    }

    public void setReminder1hSent(Boolean reminder1hSent) {
        this.reminder1hSent = reminder1hSent;
    }

    public String getAttendanceStatus() {
        return attendanceStatus;
    }

    public void setAttendanceStatus(String attendanceStatus) {
        this.attendanceStatus = attendanceStatus;
    }

    public String getAbsenceCheckedAt() {
        return absenceCheckedAt;
    }

    public void setAbsenceCheckedAt(String absenceCheckedAt) {
        this.absenceCheckedAt = absenceCheckedAt;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }

    public String getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(String updatedAt) {
        this.updatedAt = updatedAt;
    }
}
