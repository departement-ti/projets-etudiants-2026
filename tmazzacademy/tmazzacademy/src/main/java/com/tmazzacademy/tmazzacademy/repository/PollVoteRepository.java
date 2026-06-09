package com.tmazzacademy.tmazzacademy.repository;

import com.tmazzacademy.tmazzacademy.model.ChatMessage;
import com.tmazzacademy.tmazzacademy.model.PollVote;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PollVoteRepository extends JpaRepository<PollVote, Long> {
    boolean existsByUserIdAndMessage(Long userId, ChatMessage message);
}